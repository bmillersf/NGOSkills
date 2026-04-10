# Nonprofit Portal Patterns Reference

## Volunteer Portal

### Core Pages

| Page | Components | Data Source |
|------|-----------|-------------|
| **Home** | Hero banner, quick actions, upcoming shifts | Program Enrollment, Volunteer Shift |
| **My Profile** | Person Account edit form | Person Account (self) |
| **My Hours** | Hours log, total summary | Volunteer Hours, Program Enrollment |
| **My Shifts** | Upcoming/past shift calendar | Volunteer Shift |
| **Background Checks** | List + create form | PersonExamination |
| **Programs** | Available programs to join | Program (public) |

### Sharing Configuration

| Object | Sharing Method | Access |
|--------|---------------|--------|
| Person Account | Self (automatic) | Read/Write |
| Program Enrollment | Sharing Set (ContactId) | Read/Write |
| Volunteer Hours | Sharing Set (ContactId) | Read Only |
| PersonExamination | Sharing Set (ContactId) | Read/Write |
| Examination | Sharing Rule (criteria: Active) | Read Only |
| Volunteer Shift | Sharing Rule (criteria: Published) | Read Only |

### Self-Service Flows

- Submit background check (create PersonExamination)
- Update profile info (edit Person Account fields)
- Sign up for shift (create Volunteer Hours record)
- Log hours (create/edit Volunteer Hours)

---

## Donor Portal

### Core Pages

| Page | Components | Data Source |
|------|-----------|-------------|
| **Home** | Giving summary, impact stats, quick donate | Gift (aggregate), Campaign |
| **My Giving** | Gift history list with filters | Gift |
| **Receipts** | Downloadable tax receipts | Gift (completed, acknowledged) |
| **Recurring Giving** | Active commitments, manage | Gift Commitment |
| **Campaigns** | Active campaigns, progress bars | Campaign (public) |
| **My Profile** | Contact info, communication prefs | Person Account (self) |

### Sharing Configuration

| Object | Sharing Method | Access |
|--------|---------------|--------|
| Person Account | Self (automatic) | Read/Write |
| Gift | Sharing Set (DonorContactId) | Read Only |
| Gift Commitment | Sharing Set (ContactId) | Read/Write |
| Campaign | Sharing Rule (criteria: Active) | Read Only |
| Payment | Controlled by Parent (Gift) | Read Only |

### Self-Service Flows

- Make a donation (create Gift + Payment via gateway)
- Update recurring giving (edit Gift Commitment)
- Download receipt (generate PDF from Gift data)
- Update communication preferences

---

## Client Portal

### Core Pages

| Page | Components | Data Source |
|------|-----------|-------------|
| **Home** | Active enrollments, upcoming appointments, messages | Program Enrollment, Case |
| **My Programs** | Enrollment list with status | Program Enrollment |
| **My Cases** | Case list with status updates | Case |
| **Appointments** | Scheduled services | Service Delivery |
| **Assessments** | Pending/completed assessments | Assessment |
| **Documents** | Uploaded/shared files | ContentDocument |
| **My Profile** | Personal info (limited fields) | Person Account (self) |

### Sharing Configuration

| Object | Sharing Method | Access |
|--------|---------------|--------|
| Person Account | Self (automatic) | Read (limited fields) |
| Program Enrollment | Sharing Set (ContactId) | Read Only |
| Case | Sharing Set (ContactId) | Read Only |
| Service Delivery | Controlled by Parent | Read Only |
| Assessment | Sharing Set (ContactId) | Read/Write |

### Privacy Considerations

- Limit visible Person Account fields (no internal notes, income, etc.)
- Case comments visible to client must be marked "Public"
- Assessment responses editable only while status = "In Progress"
- Document uploads scanned for malware before association

---

## Grantee Portal

### Core Pages

| Page | Components | Data Source |
|------|-----------|-------------|
| **Home** | Active grants, upcoming deadlines, alerts | Funding Award, Grant Report |
| **Applications** | Application list + new application | Grant Application |
| **My Awards** | Active funding awards, terms | Funding Award |
| **Reports** | Due/submitted grant reports | Grant Report |
| **Disbursements** | Payment history | Disbursement |
| **Budget** | Budget vs actual tracker | Budget |
| **Documents** | Required documents upload | ContentDocument |

### Sharing Configuration

| Object | Sharing Method | Access |
|--------|---------------|--------|
| Business Account | Self (for org grantees) | Read/Write |
| Grant Application | Sharing Set (ContactId) | Read/Write |
| Funding Award | Sharing Set (ContactId) | Read Only |
| Disbursement | Controlled by Parent | Read Only |
| Grant Report | Sharing Set (ContactId) | Read/Write |
| Budget | Sharing Set (ContactId) | Read Only |

### Self-Service Flows

- Submit grant application (create Grant Application + attachments)
- Submit progress report (create Grant Report)
- Submit financial report (create Grant Report, financial type)
- Upload required documents (attach to Funding Award)

---

## Board Portal

### Core Pages

| Page | Components | Data Source |
|------|-----------|-------------|
| **Home** | Meeting calendar, key metrics | Event, Report Chart |
| **Meetings** | Agenda, minutes, materials | Event, ContentDocument |
| **Dashboards** | Financial, program, fundraising KPIs | Dashboard embed |
| **Documents** | Governance docs, policies | ContentDocument (library) |
| **Directory** | Board member contact list | Account (board members) |

### Access Model

- Board members are Person Accounts with Board Member record type
- Use a dedicated permission set with dashboard and report access
- Content libraries for controlled document sharing
- Meeting materials published via CMS or Content

---

## Multi-Portal Strategy

Organizations often need multiple portals. Design considerations:

| Decision | Recommendation |
|----------|---------------|
| Separate sites vs one site | Separate sites for distinct audiences (volunteer vs donor) |
| Shared branding | Use theme components for consistent brand across sites |
| Single sign-on | Enable SSO if user may access multiple portals |
| Unified profile | Person Account is the single source; portals show relevant fields |
| License optimization | Customer Community for basic; Community Plus for advanced sharing |
