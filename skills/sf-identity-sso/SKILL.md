---
name: sf-identity-sso
description: >
  Salesforce Identity, SSO, and MFA architecture with 130-point scoring.
  Owns My Domain (mandatory), SAML 2.0 SSO (IdP-initiated + SP-initiated,
  SAML Assertion validator, request signing), OpenID Connect (OIDC) SSO,
  Social Sign-On, Just-In-Time (JIT) provisioning, Salesforce as Identity
  Provider (IdP) via Connected App, Identity for Customers & Partners
  (ICP / Customer 360 Identity), Multi-Factor Authentication (MFA —
  mandatory since Feb 2022), WebAuthn, TOTP authenticators, Lightning
  Login, Password Policies, Session Settings, IP Restrictions, Login Flows,
  and Auth. Providers. TRIGGER when: user configures My Domain, stands up
  SAML or OIDC federated SSO, troubleshoots SAML assertion errors, sets up
  Social Sign-On, designs JIT provisioning, makes Salesforce the IdP for
  another service, rolls out MFA (WebAuthn / security key / TOTP / SF
  Authenticator), hardens session settings, defines a Login Flow, builds
  a customer/partner identity experience (ICP), or enables Lightning
  Login; also phrases like "SSO with Okta / Entra / Azure AD / PingOne /
  Google Workspace", "SAML not working", "MFA rollout plan", "customer
  portal login", "JIT provision new users", "enforce MFA by profile",
  "session timeout too long", "restrict login by IP".
  DO NOT TRIGGER when: user is only configuring a Connected App / OAuth
  scopes / JWT bearer for API integration (use sf-connected-apps — that
  is the prerequisite layer; this skill picks up once we're doing SSO,
  Identity, or MFA); configuring Permission Sets for object/field access
  post-login (use sf-permissions); reviewing audit logs of logins (use
  sf-shield-event-monitoring).
license: MIT
compatibility: "My Domain is mandatory on all orgs (enforced since Winter '24); MFA is mandatory for direct-login users (enforced since Feb 2022); Identity for Customers & Partners requires Identity Community licenses"
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "130 points across 7 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.identity_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.sso_saml.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/decision-guides/identity
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_security_identity.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "130-pt rubric inline (7 categories: Foundation + scope clarity 15, Federation protocol + IdP design 25, Provisioning model 20, MFA strategy 25, Session + password + IP hardening 20, ICP + Login Flow 15, Operational runbook 10), mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  identity_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Federation + IdP designed correctly. Maps to Federation protocol + IdP design (25)."
      automatic_hard_fail_rules:
        - "Any SAML / OIDC config missing signature validation (token forgery risk)"
        - "Any IdP-initiated SSO without RelayState validation"
    - name: Robustness
      max: 25
      hard_fail_below: 18
      description: "MFA + session hardening. Maps to MFA strategy (25). Heaviest robustness — auth weakness compounds across all data."
      automatic_hard_fail_rules:
        - "Any production user without MFA enforcement (compliance + breach risk)"
        - "Any service account without IP-allowlist or certificate-bound auth"
        - "Any session policy >12 hours without business justification"
    - name: Fit
      max: 25
      hard_fail_below: 10
      description: "Provisioning + ICP. Maps to Provisioning model (20) + ICP + Login Flow (15)."
      automatic_hard_fail_rules:
        - "Any JIT provisioning without role mapping (default Standard User profile assigned to elevated roles)"
        - "Any external user portal without ICP (Identity Connect Portal) or appropriate Login Flow"
    - name: Performance
      max: 25
      hard_fail_below: 10
      description: "Operational runbook. Maps to Operational runbook (10) + Foundation + scope (15)."
      automatic_hard_fail_rules:
        - "Any identity deploy without runbook for cert rotation, IdP failover, password reset"
  test_rubric:
    unit:
      required: true
      criteria: "SAML / OIDC config validates against IdP. JIT provisioning rules unit-tested."
    integration:
      required: true
      criteria: "End-to-end login flow tested for each user type (internal, external, service account)."
    smoke:
      required: true
      criteria: "Cert rotation rehearsed without downtime. IdP failover tested. MFA enforcement verified across all surfaces (web, mobile, API)."
---

# sf-identity-sso

Salesforce Identity is a broad platform: **authentication** (who is the user?), **federation** (which external IdP does Salesforce trust?), **provisioning** (how do user records get created?), and **factors** (how strong is the auth?). This skill owns the end-to-end identity design: My Domain, SAML, OIDC, Social Sign-On, JIT, Salesforce-as-IdP, ICP, MFA, Login Flows, Session and Password policies.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). Three subagents grade against the 130-pt rubric in fresh context. Robustness floor at 18 — auth weakness compounds across all data; production users without MFA = breach waiting to happen. Disable with `eval_harness.enabled: false`.

---

## 1. When this skill owns the task

Use this skill when the request is about **login, federation, provisioning, or factors**. Delegate when:

| If the user wants... | Route to | Why |
|---|---|---|
| Configure a Connected App for API OAuth / JWT (no SSO) | [sf-connected-apps](../sf-connected-apps/SKILL.md) | OAuth app config is the prerequisite layer; this skill picks up at SSO/Identity/MFA |
| Grant permission set X to user Y | [sf-permissions](../sf-permissions/SKILL.md) | Post-authn access control |
| Audit who logged in, LoginAs events, credential stuffing | [sf-shield-event-monitoring](../sf-shield-event-monitoring/SKILL.md) | Detection, not configuration |
| Deploy the identity metadata to UAT/prod | [sf-devops-center](../sf-devops-center/SKILL.md) / [sf-deploy](../sf-deploy/SKILL.md) | Shipping mechanism |
| Configure Experience Cloud site navigation, branding | [sf-experience-cloud](../sf-experience-cloud/SKILL.md) / [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) | Site UX, not identity |
| Build a customer portal (UX + content) layered on ICP | [sf-nonprofit-experience-cloud-build](../sf-nonprofit-experience-cloud-build/SKILL.md) | ICP provides the identity backbone; portal UX is separate |

**Key boundary with sf-connected-apps**: A Connected App is the plumbing. This skill picks up when the plumbing is wired to an **identity flow** (SSO, IdP, MFA-enforcement, JIT provisioning). Order of operations: build Connected App (sf-connected-apps) → configure SSO/IdP settings (this skill).

---

## 2. Cross-cloud scope note (replaces Phase 0)

Identity, SSO, and MFA are **platform-level** capabilities: they behave identically across Sales, Service, Marketing Cloud Growth, Revenue, Nonprofit, and every industry cloud. **Skip the industry pre-check** — this skill is the destination for any industry's authentication and federation work.

However, industry compliance regimes drive specific Identity configurations:

- **Health Cloud / HIPAA** → MFA mandatory for everyone with PHI access (45 CFR §164.308(a)(5)); session timeout ≤ 15 min inactivity; WebAuthn / hardware key preferred over SMS (NIST SP 800-63B). Cross-reference [sf-industry-health](../sf-industry-health/SKILL.md).
- **FSC / SOX + GLBA** → MFA mandatory; privileged admin accounts use WebAuthn security key; IP restrictions on admin profiles; Login Flow enforcing terms-of-service acknowledgment. Cross-reference [sf-industry-fsc](../sf-industry-fsc/SKILL.md).
- **Public Sector / FedRAMP** → PIV/CAC card login via SAML from an agency IdP (Login.gov, PIV-federated); FedRAMP Moderate baseline requires MFA; session timeout ≤ 30 min inactivity; password complexity elevated. Cross-reference [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md).
- **Education Cloud / FERPA** → Social Sign-On (Google Workspace, Apple) common for student portals; JIT provisioning from SIS; parent portal via ICP with guardian-student relationship. Cross-reference [sf-industry-education](../sf-industry-education/SKILL.md).
- **Nonprofit / donor + constituent portals** → ICP for donor and grantee portals; Social Sign-On for low-friction donor account creation; JIT from an email signup Flow. Cross-reference [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md).

**MFA is universally mandatory** for all direct-login users (Feb 2022 rollout, now enforced). Federated users inherit MFA from their IdP — confirm the IdP enforces MFA.

---

## 3. Required context to gather first

Ask or infer:

1. **My Domain state** — deployed? Yes (mandatory since Winter '24). Confirm the My Domain name is the one the customer wants customer-facing.
2. **User populations** — internal employees, partners (PRM), customers (ICP), or mixed? Drives license type.
3. **IdP** — is there an existing corporate IdP (Okta, Entra ID / Azure AD, PingOne, Google Workspace, ADFS, OneLogin, Login.gov, a FedRAMP IdP)? Or is Salesforce expected to **be** the IdP for downstream services?
4. **Federation protocol** — SAML 2.0 or OIDC? SAML is dominant in enterprise, OIDC in B2C / mobile. Both are first-class in Salesforce.
5. **Provisioning model** — pre-provisioned (users created in Salesforce before first login), JIT (created on first SSO login), or SCIM (push from IdP on user lifecycle events)?
6. **MFA strategy** — WebAuthn, Salesforce Authenticator (push), TOTP (Google Authenticator / Authy), SMS (discouraged, acceptable as fallback), email (discouraged), security key (FIDO2)?
7. **Session + password policy targets** — inactive timeout, force re-auth at elevated actions, min password length, rotation, reuse.
8. **IP restrictions** — trusted IP ranges, bypass-MFA ranges, hard-blocked ranges?
9. **Login Flow requirements** — terms of service, data-consent pop-up, captcha, custom branding, first-login profile selector?
10. **Existing Connected Apps** — if Salesforce is becoming IdP for downstream apps, which Connected Apps represent them?

---

## 4. Workflow phases

### Phase 1 — My Domain (foundation, mandatory)

My Domain gives the org a unique, stable login URL (e.g., `https://ngo-dev.my.salesforce.com`) and is a **prerequisite** for Lightning, SSO, and the full Salesforce Identity stack.

- Enabled by default on all new orgs.
- Older orgs: Setup → My Domain → register name → deploy → force redirect.
- Customer-facing UIs and SSO callbacks bind to the My Domain. Changing the name post-deployment breaks all those bindings — pick carefully.
- **Enhanced Domains** (required Spring '23+) — adds `.my.salesforce.com` suffix style; all orgs now use Enhanced Domains.

### Phase 2 — Federation choice: SAML vs OIDC

**SAML 2.0**
- XML-based assertion.
- IdP-initiated (user goes to IdP portal, clicks Salesforce app) or SP-initiated (user goes to Salesforce login page, is bounced to IdP).
- Dominant in enterprise (Okta, Entra ID, ADFS, PingOne).
- Salesforce is the **Service Provider** by default; becomes **IdP** via Identity license.

**OIDC (OpenID Connect on OAuth 2.0)**
- JSON-based ID Token.
- Dominant in B2C, mobile, SPA.
- Salesforce supports OIDC as SP (Auth. Provider) and as IdP (via Connected App).

**Picking**
- Corporate IdP speaks SAML first, OIDC second → choose whatever the IdP prefers. Both are supported identically.
- Customer/partner identity (ICP) → OIDC more common due to mobile/SPA use.
- Government / FedRAMP → SAML (Login.gov speaks SAML; some agencies support OIDC).

### Phase 3 — SAML SSO setup (Salesforce as SP)

**Steps**
1. Setup → Single Sign-On Settings → Enable SAML.
2. Create a SAML SSO Config: name, Issuer (matches IdP), Entity Id, Identity Provider Login URL, Identity Provider Logout URL, IdP Certificate.
3. SAML Identity Type: Username (Salesforce username) or Federation ID.
4. SAML Identity Location: Subject NameID (default) or attribute.
5. Service Provider-Initiated Request Binding: HTTP POST (default) or HTTP Redirect.
6. Download Salesforce SP metadata → give to IdP admin.
7. IdP admin configures Salesforce as a SAML app; returns IdP metadata.
8. Test assertion: Setup → SAML Assertion Validator → paste an IdP-issued assertion → see 14-step validation.

**Critical fields**
- **Issuer**: must match `<saml:Issuer>` in the assertion exactly. Common error.
- **Federation ID** on User record must match the assertion's `<saml:Subject><saml:NameID>` if Identity Type is Federation ID.
- **Certificate** rotated on IdP = Salesforce breaks until the new cert is pasted in. Calendar cert expiry ≥ 30 days in advance.

**Request signing**
- SP-initiated requests can be signed with a Salesforce-managed cert — improves IdP trust. Enable in SSO Config.

### Phase 4 — OIDC SSO setup

**Via Auth. Provider** (Setup → Auth. Providers)
- Pre-built providers: Facebook, Google, LinkedIn, Twitter, Microsoft, Salesforce, Apple, GitHub, Amazon.
- Or custom: provide Authorize URL, Token URL, User Info URL, Client Id, Client Secret.
- Auth. Provider generates a callback URL — register with the IdP.
- Bind Auth. Provider to a Community / Experience Cloud site login page, or an Apex Registration Handler for JIT.

**Registration Handler (Apex)**
- Implements `Auth.RegistrationHandler`:
  - `createUser(portalId, data)` — called on first SSO login; returns a User record to insert.
  - `updateUser(userId, portalId, data)` — called on subsequent logins; sync attributes.

### Phase 5 — Just-In-Time (JIT) Provisioning

Two modes:

**SAML JIT**
- Setup → Single Sign-On Settings → enable JIT.
- Handler: Apex class implementing `Auth.SamlJitHandler`:
  - `createUser(samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion)`
  - `updateUser(userId, samlSsoProviderId, communityId, portalId, federationIdentifier, attributes, assertion)`
- Attributes from the SAML assertion populate the User record.
- Required attributes: Federation Id (or Username), Email, First/Last Name, Profile Id (or Profile name → resolve), optional Permission Set assignments.

**OIDC JIT via Registration Handler**
- Same pattern via `Auth.RegistrationHandler`.

**Gotcha**
- Mapping Profile/Role from IdP-supplied group membership is a common request. Handle in the Apex handler; do not hard-code.

### Phase 6 — Salesforce as Identity Provider (IdP)

Useful when Salesforce is the source of truth for users, and other apps (Slack, Tableau, internal web apps) should trust Salesforce as IdP.

1. Setup → Identity Provider → Enable.
2. Generate or upload IdP certificate.
3. Create a Connected App for each downstream service; configure as SAML or OIDC:
   - **SAML**: set ACS URL, Entity Id, Subject Type (User Name or Federation Id), Name ID format.
   - **OIDC**: set Start URL, Callback URL, OpenID scope.
4. Provision users via normal Salesforce user admin.
5. Users log in to Salesforce → click the downstream app → SSO'd into it.

Salesforce-as-IdP is required for Identity for Customers & Partners (ICP).

### Phase 7 — Identity for Customers & Partners (ICP)

ICP is Salesforce's customer-identity product (CIAM). Delivered via:
- Experience Cloud site (the portal UI).
- External Identity or Customer Community licenses.
- Auth. Providers (Social Sign-On), SAML, or OIDC for federation.
- Self-registration via `CommunitiesSelfRegConfig` or Apex `Site.createPortalUser()`.
- JIT from federated sources.

**Typical nonprofit flow**
1. Donor lands on donor-portal site.
2. Clicks "Log in with Google" → Auth. Provider → Registration Handler creates Person Account + User.
3. Subsequent logins → `updateUser` syncs name/email.
4. MFA optional for constituents (often weaker than internal MFA).

### Phase 8 — Multi-Factor Authentication (MFA)

**Mandatory** since Feb 2022 for direct-login users.

**Factors (from strongest to weakest)**
1. **WebAuthn** (FIDO2 / passkey / security key) — phishing-resistant, preferred.
2. **Salesforce Authenticator** (push notification) — strong, UX-friendly.
3. **TOTP** (Google Authenticator, Authy, 1Password) — strong, offline-capable.
4. **Built-in verification code via registered device / email** — acceptable fallback.
5. **SMS** — **discouraged** (NIST SP 800-63B deprecates SMS MFA); allowed only as last resort.
6. **Lightning Login** — passwordless; phone + biometric. Strong but limited to Lightning UX.

**Enforcement**
- Setup → Identity Verification → enable MFA for API logins.
- Profile: "Multi-Factor Authentication for User Interface Logins" — enforce at profile or permission set level.
- Federated users inherit MFA from the IdP. If IdP doesn't enforce MFA, Salesforce-side MFA is ineffective for them — verify IdP config.

**Exemptions**
- Automated integration users (Connected App JWT, service accounts) — use the Integration User license type and exempt; do not weaken MFA for interactive users.

### Phase 9 — Session, Password, IP policies

**Session Settings** (Setup → Session Settings)
- Session timeout (inactive): default 2h; HIPAA/FedRAMP tighten to 15-30 min.
- Force logout on session timeout (vs. warn).
- Require HttpOnly attribute.
- Enable SMS identity verification.
- High-assurance sessions: promotable via MFA step-up for privileged actions.

**Password Policies** (Setup → Password Policies, per profile)
- Min length ≥ 12 (modern baseline).
- Complexity: ≥ 2 character types (1 letter + 1 number at minimum).
- Rotation: NIST SP 800-63B recommends no forced rotation absent compromise. Legacy requirements (90 days) still common in SOX shops.
- Reuse: forbid last 3-5 passwords.
- Lockout: 5 failed attempts → 15 min lockout.

**IP Restrictions**
- Profile-level: Trusted IP Ranges (no MFA required from these) + Login IP Ranges (only allow login from these).
- Org-wide: Setup → Network Access.
- Admin profiles should usually have tighter Login IP Ranges.

### Phase 10 — Login Flows

Flows that execute **post-authentication, pre-session-grant**. Use cases:
- Terms of service acknowledgment.
- Consent banner (GDPR).
- CAPTCHA for high-risk logins.
- Force profile selection at first login.
- Capture demographic info at first login.

Build as a Screen Flow, assign to profile via Setup → Login Flows → Assign Flow to Profile / License. The flow runs on first login after assignment; subsequent logins skip it unless re-triggered.

### Phase 11 — Verification + rollout

- Test SAML/OIDC with the IdP in a sandbox first.
- Use the SAML Assertion Validator to debug assertion errors before going live.
- Stage MFA rollout: opt-in pilot → single profile → org-wide enforcement. Communicate early; have a help desk runbook for MFA-related lockouts.
- Document the My Domain URL, IdP metadata location, cert rotation schedule, and MFA reset process in the identity runbook.

---

## 5. Scoring rubric (130 points, 7 categories)

| Category | Max | Passing | What to check |
|---|---|---|---|
| **Foundation + scope clarity** | 15 | 10 | My Domain confirmed; user populations identified; IdP direction (SP or IdP) stated; industry regime named |
| **Federation protocol + IdP design** | 25 | 17 | SAML vs OIDC justified; Issuer, Entity Id, certificates planned; SAML Identity Type (Username vs Federation Id) correct; request signing where appropriate |
| **Provisioning model** | 20 | 14 | Pre-provisioned / JIT / SCIM chosen per use case; Apex handler required fields covered; Profile/PermSet mapping from IdP groups documented |
| **MFA strategy** | 25 | 17 | WebAuthn or Authenticator app primary; SMS explicitly marked fallback only; federated users' IdP MFA verified; integration users exempted via license, not via weakening policy |
| **Session + password + IP hardening** | 20 | 14 | Session timeout matches regulatory regime; password policy modern (length ≥ 12, NIST-aligned rotation); admin profiles have tighter IP restrictions |
| **ICP + Login Flow (if applicable)** | 15 | 10 | For customer/partner portals: external license chosen correctly; Social Sign-On via Auth. Provider; Registration Handler handles create + update; Login Flow for consent/terms where regime requires |
| **Operational runbook** | 10 | 7 | Certificate expiry calendar (≥ 30 day lead time); MFA reset / lockout process; sandbox parity; documented IdP metadata exchange |

**Passing threshold: 89 / 130 (~68%).**

---

## 6. Anti-patterns (min 7)

1. **Relying on SMS MFA for privileged users.** SMS is vulnerable to SIM-swap and NIST SP 800-63B deprecated it for federal workloads. Use WebAuthn / security keys for admins; reserve SMS as last-resort fallback.
2. **Matching SAML on Username instead of Federation Id.** Usernames change (people get married, change names); Federation Ids are stable. Use Federation Id + populate it on User records before rolling out SSO.
3. **Forgetting to rotate IdP signing certificates before expiry.** Expired cert = instant SSO outage. Set calendar reminders at 60 / 30 / 14 / 7 days pre-expiry.
4. **Weakening MFA for "integration users" instead of using the Integration User license.** The Integration User license is MFA-exempt by design. Weakening interactive-user MFA to accommodate a service account is a recurring compliance finding.
5. **Skipping MFA verification on the IdP side for federated users.** Federated users inherit MFA from the IdP. If the IdP doesn't enforce MFA, Salesforce-side settings are cosmetic. Always confirm IdP MFA policy.
6. **Using JIT provisioning without mapping Profile/PermSet from IdP attributes.** JIT creates users with whatever default Profile the handler picks — often over- or under-privileged. Map Profile from IdP group membership in the handler.
7. **Changing the My Domain name post-deployment casually.** All SSO callbacks, bookmarks, Experience Cloud URLs break. Treat My Domain name as effectively permanent; change only with a full comms + remediation plan.
8. **Enabling "Full" OAuth scope on Connected Apps used for SSO.** Federation is not API access. Use `openid profile email` for OIDC SSO; do not grant `full` or `api` scopes on login-only apps.
9. **Running Login Flow on every login instead of first-login.** Repeating a ToS Flow every session trains users to click through. Scope the Flow to first login or event-triggered.
10. **Treating ICP as a free addition to a Salesforce license.** External Identity / Customer Community licenses are paid seats metered per login or per user. Model cost before designing a million-user donor portal.
11. **Using the same Connected App for both interactive SSO and API JWT.** Mixing interactive and headless flows muddles audit and policy. One Connected App per purpose.
12. **Skipping the SAML Assertion Validator.** "SSO isn't working" is 90% solvable by pasting the assertion into the validator and reading the 14-step output. Teach this to IdP admins on Day 1.

---

## 7. Common failure modes + remediation

| Symptom | Root cause | Fix |
|---|---|---|
| "SAML login returns `The Issuer in the SAML Response doesn't match the Issuer in the Salesforce SAML SSO Configuration`" | Case sensitivity, trailing slash, or tenant-specific URL difference | Copy-paste the Issuer from the assertion XML (via SAML Assertion Validator) directly into the SSO Config; do not retype |
| "SSO works in sandbox but breaks in prod" | IdP metadata not updated for prod SP Entity Id / ACS URL (different per org) | Download prod's SP metadata from Setup → Single Sign-On Settings → Download, give to IdP admin, register prod Salesforce as a separate app in the IdP |
| "OIDC login returns `Invalid_client` from the IdP token endpoint" | Client Secret mismatch between Salesforce Auth. Provider and IdP, or Auth. Provider using wrong Token URL | Re-enter Client Secret (it's write-only from Salesforce perspective, so re-entry is the fix); verify Token URL matches IdP's documented endpoint |
| "JIT provisioning fails: `Insufficient Privileges` on User insert" | Apex handler runs in the user context; the auth session doesn't yet have Modify All Users | Ensure the Apex handler class has `without sharing` and the flow context grants necessary Modify All Users permission; in practice, handler runs in system context when invoked by the JIT framework — verify class is correctly bound |
| "MFA rollout: 40% of users locked out on Day 1" | No prior comms, no self-enrollment window, no helpdesk runbook | Roll back enforcement; re-run with 30-day self-enrollment window, clear comms, dedicated helpdesk MFA-reset process, exemption list for edge cases (seasonal workers, shared accounts — ideally eliminated) |
| "Session timeout too aggressive; users complain about re-logins mid-task" | Inactivity timeout set below realistic task length | Measure real session durations; raise timeout to p95 task length; use High Assurance session promotion for privileged operations only |
| "Federation Id populated on User record but SSO still falls back to Username match" | SAML Identity Type in SSO Config still set to Username | Change Identity Type to Federation Id in the SSO Config and re-test; be aware that this means users without a Federation Id value can no longer SSO — remediate those users first |
| "ICP portal: every login creates a new User record" | Registration Handler's `createUser` is called each time because `updateUser` doesn't find a match | Ensure the handler looks up the User by stable key (Federation Id, email, or external IdP Subject) before falling through to create; return the existing User from `updateUser` |
| "Salesforce-as-IdP: downstream app shows `SAML assertion signature invalid`" | IdP certificate in Salesforce rotated; downstream app still has old cert | Export new IdP cert from Setup → Identity Provider, reload in downstream app's SAML config; set calendar reminder for next rotation |
| "IP Restriction blocks a legitimate user working from home" | Login IP Ranges on profile too restrictive; no VPN path | Add VPN egress range to Trusted IP Ranges (bypass MFA challenge but still allow login); only Login IP Range-block admin profiles; for standard users, rely on MFA + anomaly detection (sf-shield-event-monitoring) |

---

## 8. Cheat sheet

### SAML SSO Config (minimal metadata)

```xml
<!-- SSOConfigs/CorporateOkta.samlssoconfig-meta.xml -->
<SamlSsoConfig xmlns="http://soap.sforce.com/2006/04/metadata">
    <attributeName>FederationIdentifier</attributeName>
    <decryptionCertificate>SelfSignedCert_15May2026</decryptionCertificate>
    <errorUrl>https://ngo-prod.my.salesforce.com/saml-error</errorUrl>
    <identityLocation>SubjectNameId</identityLocation>
    <identityMapping>FederationId</identityMapping>
    <issuer>https://okta.ngo.org/saml/metadata</issuer>
    <loginUrl>https://okta.ngo.org/app/salesforce/sso/saml</loginUrl>
    <logoutUrl>https://okta.ngo.org/logout</logoutUrl>
    <name>Corporate Okta</name>
    <oauthTokenEndpoint>https://okta.ngo.org/oauth2/token</oauthTokenEndpoint>
    <redirectBinding>false</redirectBinding>
    <requestSignatureMethod>RSA-SHA256</requestSignatureMethod>
    <requestSigningCertId>SelfSignedCert_15May2026</requestSigningCertId>
    <salesforceLoginUrl>https://ngo-prod.my.salesforce.com</salesforceLoginUrl>
    <samlEntityId>https://ngo-prod.my.salesforce.com</samlEntityId>
    <samlJitHandlerId>NGOSamlJitHandler</samlJitHandlerId>
    <samlVersion>SAML2_0</samlVersion>
    <useConfigRequestMethod>true</useConfigRequestMethod>
    <userProvisioning>true</userProvisioning>
    <validationCert>MIIDX...</validationCert>
</SamlSsoConfig>
```

### SAML JIT Handler (Apex skeleton)

```apex
global class NGOSamlJitHandler implements Auth.SamlJitHandler {
    global User createUser(
        Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String,String> attributes,
        String assertion
    ) {
        Profile p = [SELECT Id FROM Profile
                     WHERE Name = :resolveProfile(attributes) LIMIT 1];
        User u = new User(
            FederationIdentifier = federationIdentifier,
            Username = attributes.get('User.Username'),
            Email = attributes.get('User.Email'),
            FirstName = attributes.get('User.FirstName'),
            LastName = attributes.get('User.LastName'),
            Alias = attributes.get('User.FirstName').substring(0,1)
                    + attributes.get('User.LastName').substring(0, Math.min(4, attributes.get('User.LastName').length())),
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert u;
        assignPermSetsFromGroups(u.Id, attributes.get('User.Groups'));
        return u;
    }

    global void updateUser(
        Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String,String> attributes,
        String assertion
    ) {
        User u = [SELECT Id, Email, FirstName, LastName FROM User WHERE Id = :userId];
        u.Email = attributes.get('User.Email');
        u.FirstName = attributes.get('User.FirstName');
        u.LastName = attributes.get('User.LastName');
        update u;
        syncPermSets(userId, attributes.get('User.Groups'));
    }

    private String resolveProfile(Map<String,String> attributes) {
        String groups = attributes.get('User.Groups');
        if (groups != null && groups.contains('sf-admin')) return 'System Administrator';
        if (groups != null && groups.contains('sf-donor-ops')) return 'Donor Operations';
        return 'Standard Platform User';
    }

    private void assignPermSetsFromGroups(Id userId, String groups) { /* ... */ }
    private void syncPermSets(Id userId, String groups) { /* ... */ }
}
```

### OIDC Auth. Provider (generic OpenID)

```
Setup → Auth. Providers → New → Provider Type: OpenID Connect
  Name: GoogleWorkspaceDonorPortal
  Consumer Key: <from Google Cloud Console>
  Consumer Secret: <from Google>
  Authorize Endpoint URL: https://accounts.google.com/o/oauth2/v2/auth
  Token Endpoint URL: https://oauth2.googleapis.com/token
  User Info Endpoint URL: https://openidconnect.googleapis.com/v1/userinfo
  Token Issuer: https://accounts.google.com
  Default Scopes: openid profile email
  Registration Handler: NGODonorRegistrationHandler
  Execute Registration As: Automated Process User
  → Save

  Copy the Callback URL; register it in Google Cloud Console as
    an authorized redirect URI for the OAuth client.
```

### MFA enforcement at profile level

```xml
<!-- Profile excerpt -->
<userPermissions>
    <enabled>true</enabled>
    <name>MultiFactorAuthenticationForUiLogins</name>
</userPermissions>
```

Or via permission set group for per-user enforcement without profile-wide change.

### Session Settings (HIPAA-tight, example)

```xml
<!-- securitySettings.settings-meta.xml excerpt -->
<sessionSettings>
    <disableTimeoutWarning>false</disableTimeoutWarning>
    <enableCSPOnEmail>true</enableCSPOnEmail>
    <enableClickjackSetup>true</enableClickjackSetup>
    <enableClickjackNonsetup>true</enableClickjackNonsetup>
    <enableClickjackNonsetupSFDC>true</enableClickjackNonsetupSFDC>
    <enableClickjackNonsetupUser>true</enableClickjackNonsetupUser>
    <enableClickjackNonsetupUserHeaderless>true</enableClickjackNonsetupUserHeaderless>
    <enableCSRFOnGet>true</enableCSRFOnGet>
    <enableCSRFOnPost>true</enableCSRFOnPost>
    <enableContentSniffingProtection>true</enableContentSniffingProtection>
    <enableXssProtection>true</enableXssProtection>
    <forceLogoutOnSessionTimeout>true</forceLogoutOnSessionTimeout>
    <forceRelogin>true</forceRelogin>
    <hstsOnForcedomains>true</hstsOnForcedomains>
    <lockSessionsToDomain>true</lockSessionsToDomain>
    <lockSessionsToIp>false</lockSessionsToIp>
    <requireHttpOnly>true</requireHttpOnly>
    <requireHttps>true</requireHttps>
    <sessionTimeout>FifteenMinutes</sessionTimeout>
</sessionSettings>
```

### Password Policies (modern baseline)

```xml
<!-- ProfilePasswordPolicies.profilePasswordPolicy-meta.xml -->
<ProfilePasswordPolicy xmlns="http://soap.sforce.com/2006/04/metadata">
    <forgotPasswordRedirect>false</forgotPasswordRedirect>
    <lockoutInterval>15</lockoutInterval>
    <maxLoginAttempts>FiveAttempts</maxLoginAttempts>
    <minimumPasswordLength>12</minimumPasswordLength>
    <minimumPasswordLifetime>false</minimumPasswordLifetime>
    <obscure>true</obscure>
    <passwordComplexity>AlphaNumericAndSpecialCharacters</passwordComplexity>
    <passwordExpiration>OneEightyDays</passwordExpiration>
    <passwordHistory>FivePasswords</passwordHistory>
    <passwordQuestion>CannotContainPassword</passwordQuestion>
    <profile>Donor Operations</profile>
</ProfilePasswordPolicy>
```

### Login Flow (ToS acknowledgment, sketch)

```
Screen Flow: NGO_ToS_Acknowledgment
  Start → Get Records: find User's existing ToS acknowledgment
  Decision: acknowledgment exists?
    Yes: End (user proceeds to app)
    No:  Screen: show ToS text, require checkbox
         → Create Records: new ToS_Acknowledgment__c(User=$User, Accepted=true, Date=TODAY)
         → End

Setup → Login Flows → Assign
  Profile: All Standard Users
  Flow: NGO_ToS_Acknowledgment
```

---

## 9. Verified against

- Spring '26 Release Notes — Security & Identity
- `help.salesforce.com/s/articleView?id=sf.identity_overview.htm`
- `help.salesforce.com/s/articleView?id=sf.sso_saml.htm`
- `architect.salesforce.com` Identity decision guides
