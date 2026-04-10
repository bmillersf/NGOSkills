# Case Management Reference

## Case Types for Nonprofits

| Case Type | Use Case | Priority Model |
|-----------|----------|---------------|
| **Service Case** | Ongoing client support, benefits navigation | Standard (Low/Med/High) |
| **Crisis Case** | Emergency intervention, safety concern | Urgent/Critical |
| **Housing Case** | Housing placement, stability support | Timeline-driven |
| **Health Case** | Health navigation, appointment coordination | Clinical priority |
| **Legal Case** | Legal aid, immigration, benefits appeal | Court-date driven |
| **Employment Case** | Job placement, training, career support | Milestone-based |

---

## Case Lifecycle

```
New → In Progress → Pending (External) → Resolved → Closed
          ↓                                   ↓
      Escalated                          Re-Opened
```

### Status Definitions

| Status | Meaning |
|--------|---------|
| New | Case created, not yet assigned or triaged |
| In Progress | Actively being worked by assigned staff |
| Pending | Waiting on external party (client, partner, agency) |
| Escalated | Elevated to supervisor or specialist |
| Resolved | Intervention complete, pending client confirmation |
| Closed | Case fully resolved and documented |
| Re-Opened | Closed case reopened due to recurring need |

---

## Care Plan Pattern

NPC provides a native **Care Plan** object with lifecycle stages: **Proposed → Draft → Active → Completed → Canceled**. Care Plans contain **Goal Definitions** for measurable milestones.

### Structure

```
Case
└── Care Plan (native NPC object)
    │   Status: Proposed → Draft → Active → Completed → Canceled
    ├── Goal Definition 1: Stable Housing
    │   ├── Task: Complete housing application
    │   ├── Task: Attend housing interview
    │   └── Task: Sign lease
    ├── Goal Definition 2: Employment
    │   ├── Task: Resume workshop
    │   ├── Task: Job interviews (3)
    │   └── Task: Employment verification
    └── Goal Definition 3: Health
        ├── Task: Enroll in insurance
        └── Task: Schedule primary care visit
```

### Implementation Options

| Approach | Pros | Cons |
|----------|------|------|
| **Native Care Plan + Goal Definition** | NPC-native, full hierarchy, lifecycle stages | Requires NPC license |
| **Tasks on Case** | Simple, available on all platforms | Flat structure, no goal grouping |
| **Action Plans** | Standard feature, templates | Requires Action Plans license, no care plan stages |

---

## Case Notes

### Note Types

| Type | Content | Access |
|------|---------|--------|
| **Progress Note** | Session summary, client update | Case team |
| **Clinical Note** | Assessment, diagnosis, treatment | Restricted (clinical staff) |
| **Administrative Note** | Process update, scheduling, logistics | Full team |
| **Supervisory Note** | Case review, guidance, decision | Supervisor + worker |

### Implementation

- Use `CaseComment` for simple notes (standard object)
- Use custom `Case_Note__c` for structured notes (type, date, author, visibility)
- Apply field-level security for sensitive note types
- Consider `ContentNote` for rich-text notes with file attachments

---

## Referral Coordination

NPC provides a native **Referral** object for inter-program and inter-organization referrals.

### Referral Object (Native NPC)

| Field | Type | Purpose |
|-------|------|---------|
| Referring Program | Lookup(Program) | Source program |
| Receiving Program | Lookup(Program) | Target program |
| Client | Lookup(Account) | Person Account |
| Status | Picklist | Pending, Accepted, Declined, Completed |
| Reason | Text Area | Why referral is needed |
| Urgency | Picklist | Routine, Urgent, Emergency |
| Outcome | Text Area | Result of referral |

### Referral Workflow

1. Staff creates Referral from Case or Program Enrollment
2. Auto-notify receiving program coordinator
3. Receiving coordinator reviews and accepts/declines
4. If accepted: create enrollment or case in receiving program
5. Update Referral status and notify referring staff
6. Track Referral outcome for network effectiveness reporting

---

## Caseload Management

### Assignment Rules

| Strategy | When to Use |
|----------|-------------|
| **Round-robin** | Even distribution, general cases |
| **Skill-based** | Specialized cases (language, expertise) |
| **Geographic** | Field-based services, home visits |
| **Caseload cap** | Ensure quality (e.g., max 25 active cases per worker) |

### Caseload Dashboard Metrics

| Metric | Calculation |
|--------|-------------|
| Active cases per worker | Count where Status = In Progress |
| Average case duration | Avg(Close Date - Open Date) |
| Cases opened this period | Count where Created Date in period |
| Cases closed this period | Count where Closed Date in period |
| Overdue tasks | Tasks past due on active cases |
| Client-to-staff ratio | Active enrollments / FTE staff |

---

## Privacy & Consent

### Data Sensitivity Levels

| Level | Examples | Controls |
|-------|----------|----------|
| Public | Program name, schedule | No restrictions |
| Internal | Enrollment status, attendance | Staff access only |
| Sensitive | Income, immigration status, health | Role-based, audit trail |
| Restricted | Clinical notes, legal records | Named access, encryption |

### Consent Tracking

- Track consent per data category (services, data sharing, research)
- Consent has start and expiration dates
- Consent can be withdrawn (update record, trigger data review)
- Store consent records linked to Person Account
- Validate consent before sharing data with external partners
