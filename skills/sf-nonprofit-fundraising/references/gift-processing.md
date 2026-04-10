# Gift Processing Reference

## Gift Lifecycle

```
Draft → Authorized → Completed → Acknowledged
  ↓                      ↓
Failed               Refunded
```

### Status Transitions

| From | To | Trigger |
|------|----|---------|
| Draft | Authorized | Payment method captured |
| Authorized | Completed | Payment settled |
| Authorized | Failed | Payment declined |
| Completed | Refunded | Donor request / error |
| Completed | Acknowledged | Receipt sent |

---

## Batch Gift Entry

Use for processing high-volume donations (events, direct mail, phonathons).

### Process

1. Create Batch Header (date, source, expected count/total)
2. Enter gifts in batch (donor lookup, amount, date, payment method)
3. Validate batch (count and total match)
4. Post batch (creates Gift + Payment records)
5. Auto-allocate GAUs based on rules

### Validation Rules

- Amount must be > 0
- Gift Date cannot be future
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

## GAU Allocation Patterns

### Single-Fund Allocation

```
Gift ($100) → GAU Allocation: General Fund ($100, 100%)
```

### Split Allocation

```
Gift ($100)
├── GAU Allocation: General Fund ($60, 60%)
└── GAU Allocation: Youth Programs ($40, 40%)
```

### Default Allocation Rule

Set a default GAU on the Gift Entry form or via Flow. Gifts without explicit allocation auto-assign to the default GAU.

---

## Soft Credit Patterns

| Scenario | Soft Credit Role | Example |
|----------|-----------------|---------|
| Household member | Household Member | Spouse credited for joint gift |
| Solicitor | Solicitor | Board member who secured donation |
| Matching gift | Matched Donor | Employee whose employer matches |
| Tribute / Honor | Honoree | Gift made in someone's honor |

### Soft Credit Flow

1. Gift created with primary donor (Person Account)
2. Soft Credit record created linking additional Person Account
3. Role assigned (Household, Solicitor, etc.)
4. Amount = full gift amount (default) or partial

---

## Recurring Gift Processing

### Gift Commitment Setup

1. Donor selects frequency (Monthly, Quarterly, Annually)
2. Gift Commitment created with amount and schedule
3. Gift Commitment Schedule defines payment cadence
4. System auto-generates Gift + Payment per schedule period

### Failed Payment Handling

1. Payment gateway returns decline
2. Payment status → Failed
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

1. Gift status → Completed
2. Flow evaluates acknowledgment rules (amount threshold, donor preference)
3. Generate receipt (email template or document)
4. Update Gift: Acknowledgment Date, Acknowledgment Status
5. Log activity on Person Account

### Tax Receipt Requirements

- Organization name and EIN
- Donor name and address
- Gift date and amount
- Description of any goods/services provided
- Statement of tax deductibility
- For in-kind: description only (no valuation)
