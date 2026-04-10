---
name: sf-nonprofit-experience-cloud
description: >
  Nonprofit Experience Cloud architecture with 120-point scoring. TRIGGER when:
  user builds donor portals, volunteer portals, client portals, grantee portals,
  community sites, self-service portals, or configures sharing rules, guest
  access, LWR sites, or Aura sites for nonprofit constituents on Experience
  Cloud. DO NOT TRIGGER when: portal UX/UI design (use sf-nonprofit-experience-cloud-ux),
  generic LWC components (use sf-lwc), or non-nonprofit Experience Cloud work.
license: MIT
metadata:
  version: "1.0.0"
  scoring: "120 points across 6 categories"
---

# sf-nonprofit-experience-cloud: Nonprofit Portal Architect

Expert Salesforce architect specializing in Experience Cloud for nonprofits: constituent portals (donor, volunteer, client, grantee), sharing and access architecture, LWR site configuration, self-service workflows, and community engagement.

## Core Responsibilities

1. **Portal Strategy**: Design portal types for nonprofit constituent segments
2. **Sharing Architecture**: Sharing sets, sharing rules, guest user access, record visibility
3. **Site Configuration**: LWR vs Aura sites, templates, navigation, authentication
4. **Self-Service Workflows**: Forms, record creation, status tracking, document upload
5. **Security & Access**: Permission sets, profile configuration, object/field visibility
6. **Validation & Scoring**: Score designs against 6 categories (0-120 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Sharing architecture** | [references/sharing-architecture.md](references/sharing-architecture.md) | Sharing sets, rules, guest access, record visibility |
| **Portal patterns** | [references/portal-patterns.md](references/portal-patterns.md) | Donor, volunteer, client, grantee portal designs |

---

## Portal Types for Nonprofits

| Portal | Audience | Key Features |
|--------|----------|-------------|
| **Volunteer Portal** | Volunteers | Profile, hours, shifts, background checks, program enrollment |
| **Donor Portal** | Donors | Giving history, receipts, recurring giving, campaigns |
| **Client Portal** | Program participants | Enrollment status, appointments, assessments, case updates |
| **Grantee Portal** | Grant applicants/recipients | Application submission, award status, reports, disbursements |
| **Board Portal** | Board members | Meeting materials, dashboards, governance documents |
| **Partner Portal** | Partner organizations | Referrals, shared clients, collaborative case management |

---

## Architecture Patterns

### Site Type Decision

| Factor | LWR (Build Your Own) | Aura (Template-Based) |
|--------|---------------------|----------------------|
| **Customization** | Full control, modern framework | Template-driven, less flexible |
| **Performance** | Faster page loads, modern rendering | Heavier, legacy rendering |
| **Components** | LWC only | LWC + Aura |
| **Recommended** | New builds (default) | Legacy sites, AppExchange dependencies |

**Default**: Use LWR for all new nonprofit portals.

### Authentication Model

| Method | Use Case |
|--------|----------|
| **Self-registration** | Volunteers, donors (low barrier) |
| **Admin-created** | Clients with sensitive data (controlled access) |
| **Social sign-on** | Google, Facebook (convenience for donors/volunteers) |
| **SSO / SAML** | Partner orgs, enterprise integrations |

### Portal User: NPC vs NPSP

| Aspect | NPC (Person Account) | NPSP (Contact) |
|--------|---------------------|----------------|
| **Portal user source** | Person Account's embedded Contact | Standard Contact record |
| **Account relationship** | Person Account = the user | Contact → Household Account |
| **Sharing set key** | Contact ID from Person Account | Contact ID |
| **License** | Customer Community / Plus | Customer Community / Plus |
| **Email requirement** | Person Account PersonEmail | Contact Email |
| **External profile** | Assigned to Person Account user | Assigned to Contact user |

Both platforms use Experience Cloud the same way — the difference is the underlying constituent model. Sharing sets, sharing rules, and guest access patterns work identically.

---

## Sharing Architecture

### Sharing Sets (Primary for Portal Access)

Map portal user's Contact to related records. The portal user sees records where their Contact ID matches a lookup field.

| Object | Access Field | Access Level | Example |
|--------|-------------|-------------|---------|
| Program Enrollment | Contact | Read/Write | Volunteer sees own enrollments |
| PersonExamination | ContactId | Read/Write | Volunteer sees own background checks |
| Gift | DonorId (Contact) | Read Only | Donor sees own giving history |
| Case | ContactId | Read/Write | Client sees own cases |
| Grant Application | Contact | Read/Write | Grantee sees own applications |

### Sharing Rules

For records not directly owned or linked to the portal user's Contact:

| Scenario | Sharing Rule Type | Example |
|----------|------------------|---------|
| Template records | Criteria-based | Active Examination records shared with all portal users |
| Public content | Criteria-based | Published Program records readable by all |
| Group-based | Owner-based | Share records owned by internal role group |

### Guest User Access

For unauthenticated pages (public-facing content):

- Minimize guest user permissions (read-only on public objects)
- Never expose PII through guest access
- Use `Site.isGuest()` in Apex to conditionally show content
- Guest user sharing rules are separate from authenticated sharing

---

## Key Configuration Steps

### 1. Enable Experience Cloud

Setup → Digital Experiences → Settings → Enable Digital Experiences

### 2. Create Site

Setup → Digital Experiences → All Sites → New → Build Your Own (LWR)

### 3. Configure Network

- Assign profiles/permission sets to network members
- Enable self-registration (if applicable)
- Configure login page branding
- Set up email templates (welcome, password reset)

### 4. Enable Object Pages

In Experience Builder → Settings → Object Pages → Toggle on objects that need record detail pages.

### 5. Configure Sharing

- Create sharing sets for record-level access
- Create sharing rules for template/public records
- Configure org-wide defaults (Private for sensitive objects)
- Test access as portal user (`Login As` feature)

### 6. Deploy Navigation

- Navigation Menu: define menu items
- Theme Layout: configure header, footer, branding
- Page assignments: route URLs to pages

---

## Self-Service Patterns

| Pattern | Implementation | Example |
|---------|---------------|---------|
| **Record creation** | Screen Flow or LWC form | Submit background check, apply for program |
| **Status tracking** | List view + record detail | View application status, case updates |
| **Document upload** | File upload component | Submit supporting documents |
| **Profile management** | Person Account edit form | Update contact info, preferences |
| **Knowledge base** | Knowledge articles on portal | FAQ, program descriptions, resources |

---

## Validation & Scoring

```
Score: XX/120
├─ Sharing Architecture: XX/25   (Sets, rules, guest access, OWD)
├─ Security & Access: XX/25      (Permissions, profiles, FLS, CRUD)
├─ Site Configuration: XX/20     (LWR setup, navigation, auth, branding)
├─ Self-Service Flows: XX/20     (Forms, status tracking, documents)
├─ Performance: XX/15            (Caching, lazy load, component efficiency)
└─ Best Practices: XX/15         (Testing as user, mobile, accessibility)
```

---

## Anti-Patterns

- Granting portal users access to internal-only objects
- Using org-wide default "Public Read/Write" to solve sharing issues
- No sharing sets (relying solely on sharing rules is fragile)
- Guest user with Create/Edit permissions on sensitive objects
- Hardcoding record IDs in portal components
- Skipping "Login As" testing during development
- Missing email templates for portal user lifecycle (welcome, reset)
- Not enabling object pages in Experience Builder (broken record navigation)

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Portal UX/UI design and branding | sf-nonprofit-experience-cloud-ux |
| LWC components for portal pages | sf-lwc |
| Portal self-service flows | sf-flow |
| Apex controllers for portal data | sf-apex |
| Volunteer portal features | sf-nonprofit-program-case |
| Donor portal features | sf-nonprofit-fundraising |
| Grantee portal features | sf-nonprofit-grants |
| Permission sets for portal users | sf-permissions |
| NPSP constituent model for portals | sf-nonprofit-npsp |
| Deploy portal metadata | sf-deploy |
| Sharing and access configuration | sf-metadata |

---

## Terminology

- **Experience Cloud** — Salesforce platform for external-facing sites and portals
- **LWR** — Lightning Web Runtime (modern site framework, "Build Your Own")
- **Sharing Set** — Maps portal user Contact to records via lookup field
- **Guest User** — Unauthenticated site visitor
- **Network** — Experience Cloud site configuration (members, branding, settings)
- **Customer Community License** — Portal user license type
- **Object Pages** — Experience Builder setting to enable record detail pages
- **Self-Registration** — Portal users create their own accounts
