# Enrollment Patterns Reference

## Enrollment Lifecycle States

```
                    ┌──────────┐
                    │ Referred │
                    └────┬─────┘
                         ↓
                    ┌──────────┐
              ┌─────│ Applied  │─────┐
              │     └────┬─────┘     │
              ↓          ↓           ↓
        ┌──────────┐ ┌────────┐ ┌──────────┐
        │ Rejected │ │Screened│ │Waitlisted│
        └──────────┘ └───┬────┘ └────┬─────┘
                         ↓           ↓
                    ┌──────────┐     │
                    │ Enrolled │←────┘
                    └────┬─────┘
                         ↓
                    ┌──────────┐
                    │  Active  │
                    └──┬───┬───┘
                       ↓   ↓
              ┌──────────┐ ┌───────────┐
              │Completed │ │ Withdrawn │
              └──────────┘ └───────────┘
```

---

## Intake Workflow (Flow-Based)

### Step 1: Client Identification

- Search existing Person Accounts (name, DOB, email)
- If match found: link to existing record
- If no match: create new Person Account
- Duplicate detection: fuzzy match on name + DOB

### Step 2: Intake Assessment

- Collect demographics, needs, and preferences
- Use Screen Flow with conditional visibility
- Store responses on Person Account or Assessment record
- Capture consent for services and data sharing

### Step 3: Eligibility Determination

- Flow evaluates criteria (age, income, geography, prior enrollment)
- Auto-match to eligible programs
- Present available programs with capacity info
- Allow manual override for exceptions (with reason)

### Step 4: Program Assignment

- Create Program Enrollment record
- Set status based on capacity:
  - Capacity available → Enrolled
  - At capacity → Waitlisted (with position number)
- Assign case worker / program coordinator
- Trigger welcome notification

### Step 5: Onboarding

- Create onboarding tasks (document collection, orientation, etc.)
- Schedule initial service delivery sessions
- Link to related cases if wraparound services needed

---

## Waitlist Management

### Priority Logic

| Factor | Weight | Notes |
|--------|--------|-------|
| Referral urgency | High | Emergency/crisis = top priority |
| Date applied | Medium | FIFO within same priority |
| Prior enrollment | Low | Returning clients may get preference |
| Eligibility match | Medium | Stronger match = higher priority |

### Auto-Promotion Flow

1. Enrollment completed or withdrawn → capacity opens
2. Flow queries waitlist: oldest eligible applicant
3. Auto-update status: Waitlisted → Enrolled
4. Notify participant and assigned staff
5. Start onboarding process

---

## Capacity Management

### Program-Level

- Max enrollment per Program (custom field)
- Current enrollment count (rollup or Flow-maintained)
- Waitlist count (rollup)
- Available spots = Max - Current

### Cohort-Level

For programs with defined start/end dates and cohorts:

- Program represents the overall service
- Use a related Cohort object or Program with date-specific records
- Enrollment links to specific cohort
- Capacity tracked per cohort

---

## Multi-Program Enrollment

A single Person Account can enroll in multiple programs simultaneously. Design considerations:

- **Primary program**: Enrollment marked as primary for reporting
- **Service coordination**: Case team sees all enrollments
- **Scheduling conflicts**: Validate against existing enrollments
- **Shared outcomes**: Outcome Activities linked to specific enrollment
- **Holistic view**: Person Account record page shows all active enrollments

---

## Re-Enrollment Patterns

| Scenario | Approach |
|----------|----------|
| Same program, new term | New Program Enrollment record; link to prior via lookup |
| Different program | New Program Enrollment; existing Person Account |
| Return after withdrawal | New enrollment (do not reopen old record) |
| Program extension | Update end date on existing enrollment |

---

## Referral Patterns

### Internal Referral

Program A staff refers participant to Program B:

1. Create referral record (from enrollment, to program, reason)
2. Notify receiving program coordinator
3. Receiving program creates enrollment or adds to waitlist
4. Update referral status (Accepted, Declined, Pending)

### External Referral

Partner organization refers client:

1. External referral received (form, email, phone)
2. Create Person Account + intake assessment
3. Attribute referral source (partner org = Business Account)
4. Standard eligibility and enrollment flow
5. Notify referring partner of outcome (if consented)
