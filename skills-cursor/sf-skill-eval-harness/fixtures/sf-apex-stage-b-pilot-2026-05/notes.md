# Apex requirements — Sponsorship Action

This is a Stage B harness pilot test. The user (sf-demo-validate Phase 5 fix logic, hypothetically) wants an Apex Invocable class that:

## Functional requirements

1. Be invocable from a Flow (Sponsor screen flow on Child__c records).
2. Accept a list of requests, each with: donorId (Id), childId (Id), monthlyAmount (Decimal), startDate (Date).
3. For each request, create a GiftCommitment record linking the donor to the child, $monthlyAmount/month, starting startDate.
4. Auto-generate the next 12 GiftCommitmentSchedule records (one per month).
5. Auto-generate the first GiftTransaction record (status=Unpaid, future-dated to startDate).
6. Update the Child__c.Status__c to "Sponsored".
7. Return a response per request indicating success/failure and the new GiftCommitment Id.

## Non-functional requirements

1. **Bulk-safe:** the class MUST handle N=200 requests within governor limits. SOQL/DML usage MUST be sub-linear in N — ideally constant or 1-2 SOQL + 4 DML regardless of N.
2. **Duplicate prevention:** if a request's donor+child pair already has an active GiftCommitment, return alreadySponsored=true instead of double-creating.
3. **Security:** WITH USER_MODE on all SOQL queries, with sharing on the class, Security.stripInaccessible() not strictly required (Flow context handles FLS), but bind variables required.
4. **Test class:** 90%+ coverage, includes positive, negative, AND bulk (251+ records) test methods.

## Out of scope

- Don't deploy to an org. Just generate the .cls file content.
- Don't deal with Person Accounts vs Contacts — assume donorId is whatever the org's NPC config requires.
- Don't write the Flow XML.

## Audience

The downstream consumer is sf-demo-validate Phase 5 (fix logic). It will deploy this class to a connected org as part of demo prep. If the class is N+1, the demo will look fine at N=1 (single sponsorship in the click path) but break under bulk invocation in production.
