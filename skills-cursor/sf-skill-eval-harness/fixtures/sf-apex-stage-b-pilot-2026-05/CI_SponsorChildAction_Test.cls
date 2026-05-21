/**
 * @description Test class for CI_SponsorChildAction. Covers positive
 *              (single happy path), negative (invalid input + duplicate),
 *              and bulk (251+ requests with measured Limits deltas)
 *              scenarios. Uses Assert (Spring '21+) throughout.
 */
@IsTest(IsParallel=false)
private class CI_SponsorChildAction_Test {

    private static final String STATUS_SPONSORED = 'Sponsored';
    private static final String GC_STATUS_ACTIVE = 'Active';
    private static final String GT_STATUS_UNPAID = 'Unpaid';

    // -----------------------------------------------------------------
    // Test Data Factory helpers (no inline record creation in tests).
    // -----------------------------------------------------------------

    private static List<Account> makeDonors(Integer howMany) {
        List<Account> donors = new List<Account>();
        for (Integer i = 0; i < howMany; i++) {
            donors.add(new Account(Name = 'Test Donor ' + i));
        }
        insert donors;
        return donors;
    }

    private static List<Child__c> makeChildren(Integer howMany) {
        List<Child__c> kids = new List<Child__c>();
        for (Integer i = 0; i < howMany; i++) {
            kids.add(new Child__c(Name = 'Test Child ' + i, Status__c = 'Available'));
        }
        insert kids;
        return kids;
    }

    private static CI_SponsorChildAction.Request buildRequest(
        Id donorId,
        Id childId,
        Decimal amount,
        Date startDate
    ) {
        CI_SponsorChildAction.Request req = new CI_SponsorChildAction.Request();
        req.donorId = donorId;
        req.childId = childId;
        req.monthlyAmount = amount;
        req.startDate = startDate;
        return req;
    }

    // -----------------------------------------------------------------
    // Positive: single happy-path sponsorship.
    // -----------------------------------------------------------------
    @IsTest
    static void positive_singleSponsorshipCreatesAllRecords() {
        List<Account> donors = makeDonors(1);
        List<Child__c> kids = makeChildren(1);
        Date today = Date.today();

        List<CI_SponsorChildAction.Request> reqs = new List<CI_SponsorChildAction.Request>{
            buildRequest(donors[0].Id, kids[0].Id, 50, today)
        };

        Test.startTest();
        List<CI_SponsorChildAction.Response> resps = CI_SponsorChildAction.sponsor(reqs);
        Test.stopTest();

        Assert.areEqual(1, resps.size(), 'Should return one response per request.');
        CI_SponsorChildAction.Response r = resps[0];
        Assert.isTrue(r.isSuccess, 'Single sponsorship should succeed.');
        Assert.isFalse(r.alreadySponsored, 'New sponsorship should not be flagged duplicate.');
        Assert.isNotNull(r.giftCommitmentId, 'Should return a new GiftCommitment Id.');

        Integer gcCount = [
            SELECT COUNT() FROM GiftCommitment
            WHERE Id = :r.giftCommitmentId
        ];
        Assert.areEqual(1, gcCount, 'Exactly one GiftCommitment expected.');

        Integer schedCount = [
            SELECT COUNT() FROM GiftCommitmentSchedule
            WHERE GiftCommitmentId__c = :r.giftCommitmentId
        ];
        Assert.areEqual(12, schedCount, 'Twelve monthly schedules expected.');

        Integer txnCount = [
            SELECT COUNT() FROM GiftTransaction
            WHERE GiftCommitmentId__c = :r.giftCommitmentId
              AND Status__c = :GT_STATUS_UNPAID
        ];
        Assert.areEqual(1, txnCount, 'One initial unpaid transaction expected.');

        Child__c refreshed = [
            SELECT Id, Status__c FROM Child__c WHERE Id = :kids[0].Id LIMIT 1
        ];
        Assert.areEqual(STATUS_SPONSORED, refreshed.Status__c, 'Child status should flip to Sponsored.');
    }

    // -----------------------------------------------------------------
    // Negative: invalid input — missing required fields.
    // -----------------------------------------------------------------
    @IsTest
    static void negative_missingFieldsReturnErrorMessage() {
        List<Account> donors = makeDonors(1);
        List<Child__c> kids = makeChildren(1);
        Date today = Date.today();

        List<CI_SponsorChildAction.Request> reqs = new List<CI_SponsorChildAction.Request>{
            buildRequest(null, kids[0].Id, 25, today),               // missing donor
            buildRequest(donors[0].Id, null, 25, today),             // missing child
            buildRequest(donors[0].Id, kids[0].Id, null, today),     // missing amount
            buildRequest(donors[0].Id, kids[0].Id, -10, today),      // non-positive amount
            buildRequest(donors[0].Id, kids[0].Id, 25, null)         // missing date
        };

        Test.startTest();
        List<CI_SponsorChildAction.Response> resps = CI_SponsorChildAction.sponsor(reqs);
        Test.stopTest();

        Assert.areEqual(5, resps.size(), 'Should return one response per request even on invalid input.');
        for (CI_SponsorChildAction.Response r : resps) {
            Assert.isFalse(r.isSuccess, 'Invalid request should not be marked success.');
            Assert.isNotNull(r.errorMessage, 'Invalid request should have an error message.');
            Assert.isNull(r.giftCommitmentId, 'Invalid request should not yield a commitment Id.');
        }

        Integer gcCount = [SELECT COUNT() FROM GiftCommitment];
        Assert.areEqual(0, gcCount, 'No GiftCommitment should be created when every request is invalid.');
    }

    // -----------------------------------------------------------------
    // Negative: duplicate-prevention on second invocation for same pair.
    // -----------------------------------------------------------------
    @IsTest
    static void negative_duplicatePairReturnsAlreadySponsored() {
        List<Account> donors = makeDonors(1);
        List<Child__c> kids = makeChildren(1);
        Date today = Date.today();

        List<CI_SponsorChildAction.Request> firstCall = new List<CI_SponsorChildAction.Request>{
            buildRequest(donors[0].Id, kids[0].Id, 50, today)
        };
        List<CI_SponsorChildAction.Request> secondCall = new List<CI_SponsorChildAction.Request>{
            buildRequest(donors[0].Id, kids[0].Id, 50, today)
        };

        Test.startTest();
        List<CI_SponsorChildAction.Response> firstResps = CI_SponsorChildAction.sponsor(firstCall);
        List<CI_SponsorChildAction.Response> secondResps = CI_SponsorChildAction.sponsor(secondCall);
        Test.stopTest();

        Assert.isTrue(firstResps[0].isSuccess, 'First call should succeed.');
        Assert.isFalse(firstResps[0].alreadySponsored, 'First call must not be duplicate.');

        Assert.isTrue(secondResps[0].isSuccess, 'Duplicate call should still report success.');
        Assert.isTrue(secondResps[0].alreadySponsored, 'Duplicate call should set alreadySponsored=true.');

        Integer gcCount = [
            SELECT COUNT() FROM GiftCommitment
            WHERE DonorId__c = :donors[0].Id AND Child__c = :kids[0].Id
        ];
        Assert.areEqual(1, gcCount, 'Only one GiftCommitment should exist for the pair.');

        Integer schedCount = [
            SELECT COUNT() FROM GiftCommitmentSchedule
            WHERE GiftCommitmentId__c = :firstResps[0].giftCommitmentId
        ];
        Assert.areEqual(12, schedCount, 'Schedules should not double on duplicate call.');
    }

    // -----------------------------------------------------------------
    // Bulk: N=251 requests inside Test.startTest() / stopTest() with
    // measured Limits.getQueries() and Limits.getDmlStatements() deltas.
    // Asserts AC-13 (≤5 SOQL) and AC-14 (≤6 DML) AT N>=200.
    // -----------------------------------------------------------------
    @IsTest
    static void bulk_governorLimitProbe() {
        Integer n = 251;
        List<Account> donors = makeDonors(n);
        List<Child__c> kids = makeChildren(n);
        Date today = Date.today();

        List<CI_SponsorChildAction.Request> reqs = new List<CI_SponsorChildAction.Request>();
        for (Integer i = 0; i < n; i++) {
            reqs.add(buildRequest(donors[i].Id, kids[i].Id, 25, today));
        }

        Test.startTest();
        Integer soqlBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();

        List<CI_SponsorChildAction.Response> resps = CI_SponsorChildAction.sponsor(reqs);

        Integer soqlAfter = Limits.getQueries();
        Integer dmlAfter = Limits.getDmlStatements();
        Test.stopTest();

        Integer deltaSoql = soqlAfter - soqlBefore;
        Integer deltaDml = dmlAfter - dmlBefore;

        Assert.areEqual(n, resps.size(), 'One response per request expected at N=251.');
        Assert.isTrue(
            deltaSoql <= 5,
            'AC-13: SOQL delta must be <= 5 at N=251. Measured: ' + deltaSoql
        );
        Assert.isTrue(
            deltaDml <= 6,
            'AC-14: DML delta must be <= 6 at N=251. Measured: ' + deltaDml
        );

        Integer successCount = 0;
        for (CI_SponsorChildAction.Response r : resps) {
            if (r.isSuccess && !r.alreadySponsored) {
                successCount++;
            }
        }
        Assert.areEqual(n, successCount, 'All bulk requests should succeed and be non-duplicate.');

        Integer gcCount = [SELECT COUNT() FROM GiftCommitment];
        Assert.areEqual(n, gcCount, 'GiftCommitment count should equal N.');

        Integer schedCount = [SELECT COUNT() FROM GiftCommitmentSchedule];
        Assert.areEqual(n * 12, schedCount, 'Schedule count should equal N * 12.');

        Integer txnCount = [SELECT COUNT() FROM GiftTransaction];
        Assert.areEqual(n, txnCount, 'Transaction count should equal N.');
    }

    // -----------------------------------------------------------------
    // Bulk-at-200: explicit measurement at the exact AC-13/AC-14 N.
    // This is the number we report in IMPL-NOTES.md.
    // -----------------------------------------------------------------
    @IsTest
    static void bulk_n200LimitsEvidence() {
        Integer n = 200;
        List<Account> donors = makeDonors(n);
        List<Child__c> kids = makeChildren(n);
        Date today = Date.today();

        List<CI_SponsorChildAction.Request> reqs = new List<CI_SponsorChildAction.Request>();
        for (Integer i = 0; i < n; i++) {
            reqs.add(buildRequest(donors[i].Id, kids[i].Id, 30, today));
        }

        Test.startTest();
        Integer soqlBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();

        List<CI_SponsorChildAction.Response> resps = CI_SponsorChildAction.sponsor(reqs);

        Integer soqlAfter = Limits.getQueries();
        Integer dmlAfter = Limits.getDmlStatements();
        Test.stopTest();

        Integer deltaSoql = soqlAfter - soqlBefore;
        Integer deltaDml = dmlAfter - dmlBefore;

        System.debug('N=200 deltaSOQL=' + deltaSoql + ' deltaDML=' + deltaDml);

        Assert.areEqual(n, resps.size(), 'One response per request at N=200.');
        Assert.isTrue(deltaSoql <= 5, 'N=200 SOQL delta must be <= 5. Measured: ' + deltaSoql);
        Assert.isTrue(deltaDml <= 6, 'N=200 DML delta must be <= 6. Measured: ' + deltaDml);
    }

    // -----------------------------------------------------------------
    // Empty / null input contracts.
    // -----------------------------------------------------------------
    @IsTest
    static void edge_emptyAndNullInputReturnEmptyList() {
        Test.startTest();
        List<CI_SponsorChildAction.Response> emptyResp =
            CI_SponsorChildAction.sponsor(new List<CI_SponsorChildAction.Request>());
        List<CI_SponsorChildAction.Response> nullResp =
            CI_SponsorChildAction.sponsor(null);
        Test.stopTest();

        Assert.areEqual(0, emptyResp.size(), 'Empty input should yield empty output.');
        Assert.areEqual(0, nullResp.size(), 'Null input should yield empty output.');
    }
}
