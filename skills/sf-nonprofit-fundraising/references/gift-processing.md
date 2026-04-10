# Gift Transaction Processing Reference

## Gift Transaction Lifecycle

```
Unpaid → Pending → Paid
            ↓
          Failed
```

- **Unpaid** — Awaiting payment (auto-created by Gift Commitment for future installments)
- **Pending** — Payment processing (e.g., direct debit settlement)
- **Paid** — Payment received and banked
- **Failed** — Payment declined or processing error
- Refunds tracked via separate **Gift Refund** object (not a Gift Transaction status)
- Acknowledgment tracked via separate fields + **Document Generation** for PDF receipts

### Status Transitions

| From | To | Trigger |
|------|----|---------|
| Unpaid | Pending | Payment submitted to gateway |
| Unpaid | Paid | Immediate settlement (check, cash) |
| Pending | Paid | Payment settled by gateway |
| Pending | Failed | Payment declined or timed out |
| Unpaid | Failed | Payment attempt failed |

---

## Batch Gift Entry

Use for processing high-volume donations (events, direct mail, phonathons).

### Process

1. Create Batch Header (date, source, expected count/total)
2. Enter gifts in batch (donor lookup, amount, date, payment method)
3. Validate batch (count and total match)
4. Post batch (creates Gift Transaction records)
5. Auto-allocate Gift Designations via Gift Transaction Designations based on rules

### Validation Rules

- Amount must be > 0
- ReceivedDate cannot be future
- Donor (Person Account) must exist
- Payment Method is required
- Batch totals must balance before posting

---

## Payment Methods

| Method | Processing | Notes |
|--------|-----------|-------|
| Credit Card | Gateway (Elevate/Stripe) | PCI compliance required |
| ACH / Bank Transfer | Gateway | Lower fees, longer settlement |
| Check | Manual entry | Track check number |
| Cash | Manual entry | No refund path |
| In-Kind | Manual entry | Fair market value |
| Stock / Securities | Manual entry | Valuation at transfer date |
| DAF (Donor Advised Fund) | Manual entry | Track recommending fund |

---

## Gift Designation Patterns

### Single-Fund Allocation

```
Gift Transaction ($100) → Gift Transaction Designation: General Fund ($100, 100%)
```

### Split Allocation

```
Gift Transaction ($100)
├── Gift Transaction Designation: General Fund ($60, 60%)
└── Gift Transaction Designation: Youth Programs ($40, 40%)
```

### Default Allocation Rule

Configure a **Gift Default Designation** at the org or campaign level. Gift Transactions without an explicit Gift Transaction Designation auto-assign to the default Gift Designation.

---

## Gift Soft Credit Patterns

| Scenario | Gift Soft Credit Role | Example |
|----------|----------------------|---------|
| Household member | Household Member | Spouse credited for joint gift |
| Solicitor | Solicitor | Board member who secured donation |
| Matching gift | Matched Donor | Employee whose employer matches |
| Tribute / Honor | Honoree | Gift made in someone's honor (see also Gift Tribute) |

### Gift Soft Credit Flow

1. Gift Transaction created with primary donor (Person Account)
2. Gift Soft Credit record created linking additional Person Account
3. Role assigned (Household, Solicitor, etc.)
4. Amount = full Gift Transaction amount (default) or partial
5. **Gift Default Soft Credit** rules can auto-create Gift Soft Credits (e.g., household member auto-credit)

---

## Recurring Gift Processing

### Gift Commitment Setup

1. Donor selects frequency (Monthly, Quarterly, Annually)
2. Gift Commitment created with amount and schedule
3. Gift Commitment Schedule defines payment cadence
4. System auto-generates Gift Transactions per schedule period (initially Unpaid)
5. Payment Instrument stores the reusable payment method for recurring charges

### Failed Payment Handling

1. Payment gateway returns decline
2. Gift Transaction status → Failed
3. Retry logic (configurable: 3 attempts, 3-day intervals)
4. After max retries: notify donor, flag commitment for review
5. Stewardship team follows up

### Retention Metrics

| Metric | Calculation |
|--------|-------------|
| Retention Rate | Active commitments / (Active + Cancelled) |
| Upgrade Rate | Commitments with increased amount / Total |
| Average Lifetime | Months from start to cancellation |
| Churn Rate | Cancelled in period / Active at period start |

---

## Acknowledgment & Receipting

### Auto-Acknowledgment Flow

1. Gift Transaction status → Paid
2. Flow evaluates acknowledgment rules (amount threshold, donor preference)
3. Generate receipt via NPC **Document Generation** (PDF receipts) or email template
4. Update Gift Transaction: Acknowledgment Date, Acknowledgment Status
5. Log activity on Person Account

### Tax Receipt Requirements

- Organization name and EIN
- Donor name and address
- Gift Transaction date (ReceivedDate) and amount
- Description of any goods/services provided
- Statement of tax deductibility
- For in-kind: description only (no valuation)
