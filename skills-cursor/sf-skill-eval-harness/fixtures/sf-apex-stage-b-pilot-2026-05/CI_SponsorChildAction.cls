/**
 * @description Flow-invocable action that sponsors a Child by creating one
 *              GiftCommitment + 12 monthly GiftCommitmentSchedule rows + one
 *              initial GiftTransaction, and flipping Child__c.Status__c to
 *              'Sponsored'. Idempotent on the (donorId, childId) pair —
 *              repeat invocations return alreadySponsored=true rather than
 *              double-creating commitments. Bulk-safe at N=200: constant
 *              SOQL/DML count regardless of input size.
 *
 * @group Sponsorship
 */
public with sharing class CI_SponsorChildAction {

    private static final Integer SCHEDULE_MONTHS = 12;
    private static final String STATUS_SPONSORED = 'Sponsored';
    private static final String GC_STATUS_ACTIVE = 'Active';
    private static final String GT_STATUS_UNPAID = 'Unpaid';

    /**
     * @description Custom business exception raised on unrecoverable input
     *              validation failures inside the invocable action.
     */
    public class SponsorChildException extends Exception {}

    /**
     * @description Sponsors one or more children. For each request, creates
     *              GiftCommitment + 12 GiftCommitmentSchedule + 1 GiftTransaction
     *              and updates Child__c.Status__c. Returns one Response per
     *              Request, in input order.
     *
     * @param requests Flow-supplied list of sponsorship requests.
     * @return List<Response> One response per input request, same order.
     */
    @InvocableMethod(
        label='Sponsor Child'
        description='Creates GiftCommitment, 12 monthly schedules, initial GiftTransaction, and flips Child status to Sponsored. Idempotent on donor+child pair.'
        category='Sponsorship'
    )
    public static List<Response> sponsor(List<Request> requests) {
        List<Response> responses = new List<Response>();

        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        // Pre-allocate one response slot per request so we preserve order
        // even when we short-circuit on validation failures.
        for (Integer i = 0; i < requests.size(); i++) {
            Response r = new Response();
            r.isSuccess = false;
            r.alreadySponsored = false;
            responses.add(r);
        }

        // ---------------------------------------------------------------
        // Phase 1: validate input + collect keys (no SOQL, no DML).
        // ---------------------------------------------------------------
        Set<Id> donorIds = new Set<Id>();
        Set<Id> childIds = new Set<Id>();
        List<Integer> validIndexes = new List<Integer>();

        for (Integer i = 0; i < requests.size(); i++) {
            Request req = requests[i];
            Response res = responses[i];

            if (req == null) {
                res.errorMessage = 'Request is null.';
                continue;
            }
            if (req.donorId == null || req.childId == null) {
                res.errorMessage = 'donorId and childId are required.';
                continue;
            }
            if (req.monthlyAmount == null || req.monthlyAmount <= 0) {
                res.errorMessage = 'monthlyAmount must be a positive number.';
                continue;
            }
            if (req.startDate == null) {
                res.errorMessage = 'startDate is required.';
                continue;
            }

            donorIds.add(req.donorId);
            childIds.add(req.childId);
            validIndexes.add(i);
        }

        if (validIndexes.isEmpty()) {
            return responses;
        }

        // ---------------------------------------------------------------
        // Phase 2: single SOQL to detect existing active commitments
        // for any (donor, child) pair in this batch. Bind variables, no
        // string concatenation, WITH USER_MODE for FLS/CRUD enforcement.
        // ---------------------------------------------------------------
        Set<String> existingPairs = new Set<String>();
        List<GiftCommitment> existingCommitments = [SELECT Id, DonorId__c, Child__c FROM GiftCommitment WHERE DonorId__c IN :donorIds AND Child__c IN :childIds AND Status__c = :GC_STATUS_ACTIVE WITH USER_MODE];
        for (GiftCommitment gc : existingCommitments) {
            existingPairs.add(pairKey(gc.DonorId__c, gc.Child__c));
        }

        // ---------------------------------------------------------------
        // Phase 3: build NEW records in memory. No DML in this loop.
        // We track the index alignment between requests and the
        // GiftCommitments we create so we can stamp Ids back onto the
        // correct response slot after the bulk insert below.
        // ---------------------------------------------------------------
        List<GiftCommitment> commitmentsToInsert = new List<GiftCommitment>();
        List<Integer> commitmentRequestIndexes = new List<Integer>();
        Set<Id> childrenToFlip = new Set<Id>();

        for (Integer idx : validIndexes) {
            Request req = requests[idx];
            Response res = responses[idx];
            String key = pairKey(req.donorId, req.childId);

            if (existingPairs.contains(key)) {
                res.alreadySponsored = true;
                res.isSuccess = true;
                continue;
            }

            // Guard against the same (donor, child) pair appearing twice
            // inside one batch — second occurrence is treated as
            // alreadySponsored to preserve the AC-9 invariant.
            existingPairs.add(key);

            GiftCommitment gc = new GiftCommitment();
            gc.DonorId__c = req.donorId;
            gc.Child__c = req.childId;
            gc.Amount__c = req.monthlyAmount;
            gc.StartDate__c = req.startDate;
            gc.Status__c = GC_STATUS_ACTIVE;

            commitmentsToInsert.add(gc);
            commitmentRequestIndexes.add(idx);
            childrenToFlip.add(req.childId);
        }

        if (commitmentsToInsert.isEmpty()) {
            // All inputs were duplicates or invalid — nothing left to do.
            return responses;
        }

        // ---------------------------------------------------------------
        // Phase 4: single bulk insert of all GiftCommitments.
        // ---------------------------------------------------------------
        try {
            insert as user commitmentsToInsert;
        } catch (DmlException e) {
            for (Integer ci = 0; ci < commitmentRequestIndexes.size(); ci++) {
                Response res = responses[commitmentRequestIndexes[ci]];
                res.isSuccess = false;
                res.errorMessage = 'GiftCommitment insert failed: ' + e.getMessage();
            }
            throw new SponsorChildException(
                'Sponsorship batch insert failed: ' + e.getMessage()
            );
        }

        // ---------------------------------------------------------------
        // Phase 5: build child collections (schedules + transactions) and
        // a Child status update list, all in memory.
        // ---------------------------------------------------------------
        List<GiftCommitmentSchedule> schedulesToInsert = new List<GiftCommitmentSchedule>();
        List<GiftTransaction> transactionsToInsert = new List<GiftTransaction>();

        for (Integer ci = 0; ci < commitmentsToInsert.size(); ci++) {
            GiftCommitment newGc = commitmentsToInsert[ci];
            Integer reqIdx = commitmentRequestIndexes[ci];
            Request req = requests[reqIdx];
            Response res = responses[reqIdx];

            // Stamp the new commitment Id back onto the response.
            res.giftCommitmentId = newGc.Id;
            res.isSuccess = true;
            res.alreadySponsored = false;

            // Twelve monthly schedules anchored at startDate.
            for (Integer m = 0; m < SCHEDULE_MONTHS; m++) {
                GiftCommitmentSchedule sched = new GiftCommitmentSchedule();
                sched.GiftCommitmentId__c = newGc.Id;
                sched.ScheduledDate__c = req.startDate.addMonths(m);
                sched.Amount__c = req.monthlyAmount;
                sched.SequenceNumber__c = m + 1;
                schedulesToInsert.add(sched);
            }

            // One initial transaction at startDate, status Unpaid.
            GiftTransaction txn = new GiftTransaction();
            txn.GiftCommitmentId__c = newGc.Id;
            txn.TransactionDate__c = req.startDate;
            txn.Amount__c = req.monthlyAmount;
            txn.Status__c = GT_STATUS_UNPAID;
            transactionsToInsert.add(txn);
        }

        // ---------------------------------------------------------------
        // Phase 6: bulk DML for schedules, transactions, and child
        // status flip. Three statements, regardless of N.
        // ---------------------------------------------------------------
        try {
            if (!schedulesToInsert.isEmpty()) {
                insert as user schedulesToInsert;
            }
            if (!transactionsToInsert.isEmpty()) {
                insert as user transactionsToInsert;
            }

            if (!childrenToFlip.isEmpty()) {
                List<Child__c> childUpdates = new List<Child__c>();
                for (Id cid : childrenToFlip) {
                    childUpdates.add(new Child__c(
                        Id = cid,
                        Status__c = STATUS_SPONSORED
                    ));
                }
                update as user childUpdates;
            }
        } catch (DmlException e) {
            // Surface the failure on every freshly-created response so the
            // Flow surfaces a useful error per request.
            for (Integer ci = 0; ci < commitmentRequestIndexes.size(); ci++) {
                Response res = responses[commitmentRequestIndexes[ci]];
                res.isSuccess = false;
                res.errorMessage = 'Sponsorship downstream DML failed: ' + e.getMessage();
            }
            throw new SponsorChildException(
                'Sponsorship downstream DML failed: ' + e.getMessage()
            );
        }

        return responses;
    }

    /**
     * @description Build a stable composite key for a (donorId, childId)
     *              pair so we can membership-test in O(1) without a nested
     *              loop over the existing-commitments query result.
     */
    private static String pairKey(Id donorId, Id childId) {
        return String.valueOf(donorId) + '|' + String.valueOf(childId);
    }

    /**
     * @description Flow-facing input wrapper. One Request = one sponsorship.
     */
    public class Request {
        @InvocableVariable(label='Donor Id' description='Account or Contact Id of the donor.' required=true)
        public Id donorId;

        @InvocableVariable(label='Child Id' description='Child__c record Id to sponsor.' required=true)
        public Id childId;

        @InvocableVariable(label='Monthly Amount' description='Recurring sponsorship amount per month.' required=true)
        public Decimal monthlyAmount;

        @InvocableVariable(label='Start Date' description='First scheduled gift date.' required=true)
        public Date startDate;
    }

    /**
     * @description Flow-facing output wrapper. One Response per Request,
     *              returned in the same order as the input list.
     */
    public class Response {
        @InvocableVariable(label='Is Success' description='True when the sponsorship completed (or was already in place).')
        public Boolean isSuccess;

        @InvocableVariable(label='Gift Commitment Id' description='Id of the newly-created GiftCommitment, if any.')
        public Id giftCommitmentId;

        @InvocableVariable(label='Already Sponsored' description='True when a duplicate active commitment already existed.')
        public Boolean alreadySponsored;

        @InvocableVariable(label='Error Message' description='Populated only on failure.')
        public String errorMessage;
    }
}
