---
name: sf-lightning-app-builder
description: >
  Lightning App Builder: record / app / home pages, FlexiPage, Dynamic Forms,
  Dynamic Actions, Dynamic Interactions, Component Visibility, Record Page
  Assignments, Utility Bar.
  TRIGGER when: user composes Lightning pages in App Builder; touches
  `.flexipage-meta.xml`; migrates Page Layouts to Dynamic Forms; configures
  Dynamic Actions / Dynamic Interactions / Component Visibility; assigns
  record pages per profile / record type / app / form factor; configures
  utility bar or app navigation.
  DO NOT TRIGGER when: component authoring — LWC/Aura (sf-lwc), Apex (sf-apex),
  Flow (sf-flow); object / field metadata (sf-metadata); permissions
  (sf-permissions); Experience Cloud site pages (sf-experience-cloud,
  sf-nonprofit-experience-cloud); charts (sf-reports-dashboards); FlexCard
  authoring (sf-industry-commoncore-flexcard) — placement stays here;
  industry pack ships the record page template (matching sf-industry-* /
  sf-nonprofit-* skill); Slack Canvas (sf-slack); Mobile Publisher (out of
  scope).
license: MIT
compatibility: "Available in Lightning Experience across all editions. Dynamic Forms GA on all standard and custom objects as of Spring '24."
metadata:
  version: "1.0.0"
  author: "NGOSkills"
  scoring: "120 points across 7 categories — Page plan+template 15 / Dynamic Forms 25 / Dynamic Actions/Interactions 15 / Component Visibility 20 / Record Page Assignment 15 / Performance 15 / Accessibility+mobile 15 (90 is passing)"
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "120-pt rubric (7 categories) extracted from existing 'Scoring Rubric — 120 Points' section in this SKILL.md (line 213). Mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  lab_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "Page plan + Dynamic Forms migration + Component Visibility logic. Maps to Page plan (15) + Dynamic Forms (25) + Component Visibility (20). FlexiPage shape + Dynamic Forms migration accuracy + correct visibility filters drive whether the page renders the right thing for the right user."
      automatic_hard_fail_rules:
        - "Record page on a Dynamic-Forms-supported object still using Record Detail component instead of Dynamic Forms"
        - "Page Layout raw-copied to Dynamic Forms without semantic re-grouping (carries Page Layout debt forward)"
        - "Visibility filter set to 'show always' on a component that should be conditional"
        - "Component Visibility filter logic doesn't reflect business conditions (silent always-show or always-hide)"
        - "Per-field visibility / read-only / required conditions absent where the business case requires them"
        - "30-component single-column sprawl (cognitive overload + render-time hit)"
    - name: Robustness
      max: 25
      hard_fail_below: 12
      description: "Record Page Assignment coverage. Maps to Record Page Assignment (15). Every relevant profile × record type × app × form factor must be covered; orphaned users fall back to Org Default which is rarely the intended page."
      automatic_hard_fail_rules:
        - "Assignment combinations not all covered (profile × record type × app × form factor — orphan users fall back to Org Default)"
        - "Orphaned users falling back to Org Default page when they shouldn't"
        - "Form-factor-specific page (mobile / phone) absent when the audience uses both desktop + mobile"
        - "Assignment combination changes not regression-tested (every combination must be opened on a real account in that combination)"
        - "Industry-pack-shipped record page template overridden silently (industry skill should own the template)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Dynamic Actions + Dynamic Interactions + template choice. Maps to Dynamic Actions (15) + Page plan template (15). Right pattern for the use case; declarative wiring over Aura app events; tabs used for dense content."
      automatic_hard_fail_rules:
        - "Static actions used on a record page when Dynamic Actions cover the conditional case"
        - "Aura application event used when Dynamic Interactions express the same wiring declaratively"
        - "Single-column sprawl when tabs / accordion would group dense content"
        - "Template chosen doesn't match the page shape (e.g., Header+Right Sidebar where 3-column is needed)"
        - "Dynamic Action without visibility filter on conditional actions (action visible to everyone regardless of context)"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Performance + Accessibility + Mobile. Maps to Performance+composition (15) + Accessibility+mobile (15). >12 data-fetching components on first render = render cliff; mobile / a11y not optional."
      automatic_hard_fail_rules:
        - ">12 data-fetching components on first render (record-detail render cliff on mid-tier devices)"
        - "Heavy components not lazy-loaded behind tabs / visibility filters"
        - "Page load >3s on a typical record"
        - "Mobile preview not run / not passing"
        - "Tab order illogical / screen reader labels absent on custom LWCs"
        - "Contrast inadequate / keyboard-only navigation broken"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.lightning_app_builder_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://help.salesforce.com/s/articleView?id=sf.lightning_page_components_dynamic_forms.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/decision-guides/ux
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_lab.htm
---

# sf-lightning-app-builder: Lightning App Builder + Dynamic Forms + Dynamic Actions + FlexiPage

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 120-pt rubric across 7 LAB categories, extracted from this skill's existing Scoring Rubric section (line 213) and mapped onto the 4-dim shape. Correctness floor at 14 — FlexiPage shape + Dynamic Forms migration accuracy drive whether the page renders the right thing for the right user. Hard-fail rules block Record Detail used when Dynamic Forms is supported, Page Layout raw-copy to Dynamic Forms, 'show always' on conditional components, 30-component single-column sprawl, missing assignment combinations (profile × record type × app × form factor), >12 data-fetching components on first render, and mobile/accessibility skip. Disable with `eval_harness.enabled: false`.

Use this skill when the user is composing or editing a **Lightning page** — a record page, app page, home page, or email application page — in **Lightning App Builder**, serialized as `.flexipage-meta.xml`. This includes Dynamic Forms (field-level region composition that replaces classic Page Layouts), Dynamic Actions (per-component button bars that replace the static object action list), Dynamic Interactions (cross-component event wiring), Component Visibility filters (conditional display), page-template choice, Record Page Assignments (per profile / record type / app / form factor), and Utility Bar configuration.

This skill is a **platform-level primitive**: it does not run an industry pre-check, but it does defer to industry skills when the industry ships a customized record page template and the ask is to modify industry-specific components on that template. When in doubt, route to the industry skill first — they call back into this skill for generic FlexiPage mechanics.

---

## 1. When This Skill Owns the Task

This skill owns the task when the user is **composing the page surface** — deciding which components go where, under what conditions they render, and which page assignment applies. It does not own the authoring of the components themselves, the underlying data model, or industry-packaged page templates.

Delegate when the task is outside page composition:

| User need | Route to | Why |
|---|---|---|
| Write the LWC or Aura component placed on the page | [sf-lwc](../sf-lwc/SKILL.md) | Component authoring |
| Write the Apex behind a quick action / invocable used by the page | [sf-apex](../sf-apex/SKILL.md) | Apex implementation |
| Write the Flow called by a screen flow component or quick action | [sf-flow](../sf-flow/SKILL.md) | Flow authoring |
| Create / modify the custom object, fields, or validation rules the page surfaces | [sf-metadata](../sf-metadata/SKILL.md) | Metadata XML |
| FLS / permission set audit for fields on the page | [sf-permissions](../sf-permissions/SKILL.md) | Access analysis |
| Chart on a dashboard / report placed on the page | [sf-reports-dashboards](../sf-reports-dashboards/SKILL.md) | Report engine |
| OmniStudio FlexCard placed on the page | [sf-industry-commoncore-flexcard](../sf-industry-commoncore-flexcard/SKILL.md) | FlexCard authoring (placement is here) |
| Experience Cloud LWR / Aura site page (different builder) | [sf-experience-cloud](../sf-experience-cloud/SKILL.md) / [sf-nonprofit-experience-cloud](../sf-nonprofit-experience-cloud/SKILL.md) | Experience Builder, not App Builder |
| Industry-packaged record page template customization (FSC Household, Health Cloud Patient Card, etc.) | [sf-industry-fsc](../sf-industry-fsc/SKILL.md) / [sf-industry-health](../sf-industry-health/SKILL.md) / [sf-industry-education](../sf-industry-education/SKILL.md) / [sf-industry-public-sector](../sf-industry-public-sector/SKILL.md) / [sf-field-service](../sf-field-service/SKILL.md) / [sf-nonprofit-cloud](../sf-nonprofit-cloud/SKILL.md) family | Industry owns the template |
| Slack Canvas / Slack-app surface | [sf-slack](../sf-slack/SKILL.md) | Slack surface |
| Mobile Publisher app shell | out of scope | Different product |

---

## 2. Phase 0 Note — No Industry Pre-Check

Lightning App Builder is a **platform-level primitive**. The FlexiPage runtime renders every record page in Lightning Experience, including industry-packaged ones. Industry skills that ship custom record pages (FSC Household with Relationship Map, Health Cloud Patient Card with Care Team, PSS Benefit with Application Timeline, etc.) do not replace App Builder — they layer on top of it. When a user wants to put a component on a page, toggle a visibility filter, or migrate a Page Layout, that is FlexiPage work regardless of industry.

**This skill therefore skips the industry pre-check.** When the ask is narrowly about page composition, this skill owns it. When the ask is about customizing an industry-packaged template's industry-specific components (e.g., "make the FSC Life Event Timeline component wider"), route to the industry skill first — they understand the template's intent and call back into this skill for placement mechanics.

---

## 3. Required Context to Gather First

Before editing any page, establish:

- **Page type.** Record Page, App Page, Home Page, or Email Application Page? Each has different components available, different templates, and different assignment rules.
- **Object (if record page).** Which sObject? Standard or custom? Does it have Record Types? Does the current org have industry-packaged templates for this object?
- **Template.** Which page template? Header-and-Right-Sidebar, Three-Region, One-Region, Pinned-Header, Custom (LWC template)? Template choice constrains where components can go.
- **Current state.** Is there an existing Lightning page? A classic Page Layout? A default system-provided page? Is Dynamic Forms already enabled on this page or still using the old Record Detail component?
- **Audience and assignment.** Who should see this page — which profile(s), which record type(s), which app(s), which form factor (Desktop / Phone / Tablet)? Record Page Assignments have a specificity order; understand which is overriding which.
- **Dynamic Forms readiness.** If migrating from a Page Layout, is the object on the supported list (as of Spring '24+ most standard and custom objects are supported)? How many fields on the current layout? What related lists? Any quick actions?
- **Dynamic Actions scope.** Does the page need conditional actions (shown based on record state, user profile, etc.), or is the static object action list sufficient?
- **Visibility filter scope.** Which components have conditional display rules — by field value, user profile, user permission, form factor, or record type? Design the filter logic before wiring.
- **Dynamic Interactions scope.** Does the page need components to communicate (one component's selection filters another)? Dynamic Interactions replace Aura's appEvents pattern declaratively.
- **Utility Bar.** What global utilities does the user need (History, Notes, custom LWC, Lightning Dialer, etc.)? Utility Bar is app-scoped, not page-scoped.
- **Component inventory.** What custom LWCs / Aura components / OmniStudio FlexCards / standard components does this page require? Which of those are already authored vs need to be built?
- **Performance budget.** A record page with 30 components (especially with multiple data-fetching LWCs) is slow. Aim for ≤ 12 data-fetching components on initial render; lazy-load the rest in tabs or behind visibility filters.

Missing the object, template, or assignment target is a design-blocking gap. Do not guess.

---

## 4. Workflow Phases

Run in order.

### Phase 1 — Page Plan

1. Write the page's intent in plain English: *"The Account record page for our sales reps, featuring Dynamic Forms field sections that reveal conditionally by account type, a Related Lists region, a related contacts compact view, and a Quick Links utility, assigned to the Sales Rep profile in the Sales Cloud app on desktop."*
2. Sketch the layout — header, main regions, sidebars, tabs. Identify which regions are field areas (Dynamic Forms), which are component regions (Related Lists, LWC, Reports), and which are tabbed regions.
3. For record pages, decide Dynamic Forms vs. classic Record Detail component. The modern default is Dynamic Forms; only stay on Record Detail if the object isn't supported yet.
4. For record pages, decide Dynamic Actions vs. the static object action list. The modern default is Dynamic Actions with visibility filters; only stay on static actions for very simple cases.
5. For home / app pages, sketch tile layouts.

### Phase 2 — Template and Regions

1. In Lightning App Builder, create the page — select page type and template.
2. Template choices include:
   - **Header and Right Sidebar** — classic record page shape
   - **Header, Subheader, Left Sidebar** — fuller layout
   - **Pinned Left Sidebar** — sidebar stays visible on scroll
   - **One Region** — single full-width column
   - **Three Regions** — balanced
   - **Custom Template** — LWC-authored (requires the template LWC to exist)
3. For record pages on standard objects, consider **Clone from Existing** — clone the current production page and iterate rather than starting blank.
4. Add component regions. Use **Tabs** to organize dense pages; each tab becomes a region.

### Phase 3 — Dynamic Forms (Record Pages)

If migrating from a Page Layout OR building a new record page:

1. Remove the **Record Detail** component (the monolithic one). Replace with a **Field Section** for each logical grouping of fields.
2. Add fields to sections by drag-and-drop from the Fields palette. Each field is a **Field** component instance.
3. Per-field settings: Read-Only, Required (overrides object-level when stricter), conditionally visible, conditionally read-only.
4. Per-section settings: collapsed by default, visibility filter.
5. Apply **Visibility Filter** to sections, fields, and regions:
   - Record field criteria: `Account.Type = 'Partner'`
   - User profile: `$Profile.Name = 'Sales Rep'`
   - User permission: `$Permission.View_Financials = true`
   - Form factor: `$Client.FormFactor = 'Large'` (desktop)
   - Record type: handled via page assignment, not usually visibility filter
   - Compound AND / OR logic across multiple criteria
6. Deploy and spot-test with representative users / record types.

**Migration from classic Page Layout.** Dynamic Forms doesn't automatically read Page Layout. Migration Tooling (Setup → Lightning App Builder → Dynamic Forms Migration) generates an initial Dynamic Forms layout from the existing Page Layout. Review, refine (visibility filters, section renames, field removals), and assign.

### Phase 4 — Dynamic Actions

1. On the Highlights Panel, click **Upgrade Now** (if available) or **Add Action** to convert static actions to Dynamic Actions.
2. Each action (quick action, global action, URL action) becomes an individually-configurable list item with its own visibility filter.
3. Order actions by frequency of use. The first N appear inline; the rest appear under the action overflow menu (count depends on form factor).
4. Apply visibility filters per action:
   - "Close Case" visible only when `Status != 'Closed'`
   - "Delete Account" visible only for admin profile
   - "Schedule Appointment" visible only on desktop form factor
5. Test on each form factor — Dynamic Actions render differently on Phone, Tablet, and Desktop.

### Phase 5 — Dynamic Interactions

1. If two components on the page should communicate (e.g., selecting a row in a List LWC filters a Detail LWC), use Dynamic Interactions.
2. The **source component** must expose an event in its `.js-meta.xml` (`<targets>`, `<targetConfigs>` + `<event>`).
3. The **target component** must expose an input property in its `.js-meta.xml`.
4. In Lightning App Builder, select the source component → Interactions tab → Add Interaction → pick event → pick target component → map event payload to target property.
5. Test: interacting on source updates target as expected.
6. Dynamic Interactions are declarative — they replace the old Aura `registerEvent` / `handleEvent` pattern. If the components were written for Aura app events, refactor them for LWC Dynamic Interactions.

### Phase 6 — Component Placement Strategy

1. **Above-the-fold (visible without scroll)**: Highlights Panel, key summary fields, 1–2 most-used components. Keep light — these load first.
2. **Tabs** for dense detail: Related Lists tab, Activity tab, Reports tab, LWC tab. Users pay the load cost only when they click the tab.
3. **Right / Left Sidebar** for context: recent items, quick notes, call-to-action LWCs.
4. **Lazy-loaded LWCs**: for heavy data components, use a Visibility Filter to defer rendering until a tab is selected or a field is a certain value.
5. **Avoid component sprawl**: > 12 data-fetching components on first render degrades page load.

### Phase 7 — Record Page Assignment

1. Save and **Activate** the page.
2. Choose assignment scope:
   - **Org Default** — everyone in every app, unless overridden
   - **App Default** — default for this app (e.g., Sales Cloud app gets one page, Service Console gets another)
   - **App + Record Type** — different page per record type within an app
   - **App + Record Type + Profile** — most specific; different page per profile × record type × app
   - **Form Factor** — separate page for Phone vs Desktop
3. Specificity order: more-specific assignment wins. App + Record Type + Profile overrides App + Record Type overrides App Default overrides Org Default.
4. Test every assignment path: log in as each affected profile / in each affected app / on each form factor, open a record of each record type, verify correct page renders.

### Phase 8 — Home Page / App Page

1. For Home Pages: use standard components (News, Today's Tasks, Recent Items, Key Deals, Assistant) + custom LWCs. Assign per profile (Org Default / App Default / Profile).
2. For App Pages: these are free-form Lightning pages accessed via app navigation, not tied to a record. Add a tab in the App Builder's Utility or Navigation settings.

### Phase 9 — Utility Bar

1. Utility Bar is **app-scoped**, configured in the App Manager, not the page.
2. Standard utilities: History, Notes, Lightning Voice (Dialer), Open CTI Softphone, Omni-Channel.
3. Custom utilities: any LWC exposing `lightning__UtilityBar` as a target.
4. Each utility can be pinned (opens on app load) or on-demand.

### Phase 10 — Testing and Validation

1. **Profile × Record Type × App × Form Factor matrix** — test every assignment combination. An untested combination is a production bug waiting to happen.
2. **Visibility filter coverage** — for every visibility filter, toggle the condition and verify the component shows/hides.
3. **Dynamic Forms field-level verification** — confirm required / read-only / visibility settings work per visibility filter.
4. **Dynamic Actions coverage** — verify each action appears under the right conditions.
5. **Dynamic Interaction wiring** — verify source-to-target event flows work.
6. **Performance** — open the page in Lightning Usage App or Chrome DevTools; verify first-contentful-paint is < 3s for typical records.
7. **Mobile preview** — open Lightning App Builder's Mobile preview; verify responsive rendering on Phone and Tablet.
8. **Accessibility** — tab order, screen reader labels on custom LWCs, sufficient contrast, keyboard-only navigation works.

---

## 5. Scoring Rubric — 120 Points

Apply to any Lightning page design or build deliverable. Minimum passing: **90 / 120**. Sub-threshold categories must be fixed.

| Category | Max | Passing | What "passing" looks like |
|---|---|---|---|
| **Page plan and template choice** | 15 | 11 | Intent stated in plain English; template matches the page shape; tabs used for dense content; no 30-component single-column sprawl |
| **Dynamic Forms migration / authoring** | 25 | 19 | Record pages use Dynamic Forms (not Record Detail) on supported objects; field sections are semantic groupings; per-field visibility / read-only / required applied where the business case requires; migration from Page Layout reviewed, not raw-copied |
| **Dynamic Actions and Dynamic Interactions** | 15 | 11 | Dynamic Actions used over static on record pages; each action has visibility filter where conditional; Dynamic Interactions used declaratively, not Aura app events |
| **Component Visibility filter logic** | 20 | 15 | Visibility filters scoped to real business conditions; no "show always" on components that should be conditional; no duplicated filter logic across components that could share; filters tested per branch |
| **Record Page Assignment** | 15 | 11 | Assignments cover every relevant profile × record type × app × form factor; no orphaned users falling back to Org Default when they shouldn't; every assignment combination tested |
| **Performance and composition** | 15 | 11 | ≤ 12 data-fetching components on first render; heavy components lazy-loaded behind tabs or visibility filters; page load < 3s on typical records |
| **Accessibility and mobile** | 15 | 11 | Mobile preview passes; tab order logical; screen reader labels present; contrast adequate; keyboard navigation works |

---

## 6. Anti-Patterns

- **Leaving the Record Detail component on a record page when Dynamic Forms is available.** The Record Detail component shows fields per the object's Page Layout — an obsolete assignment surface. Dynamic Forms lives inside the Lightning page, versions with the page, and allows field-level visibility filters. Migrate.
- **Copying every field from the old Page Layout into a single Field Section in Dynamic Forms.** This defeats the purpose of migration. Group fields into semantic sections ("Key Info", "Financials", "Relationships", "Audit"), apply visibility filters, and drop fields that aren't actually useful.
- **Using Dynamic Actions without visibility filters.** If every action is visible to every user in every state, Dynamic Actions provide no benefit over the static list. The whole point is conditional exposure.
- **Wiring Aura app events between components instead of Dynamic Interactions.** Dynamic Interactions are declarative, visible in App Builder, and survive refactors. Aura app events are invisible until someone debugs a broken page.
- **Duplicate component placement across tabs.** Putting the same LWC in 3 tabs "in case users miss it" triples its load cost. Pick one placement and make it obvious.
- **Ignoring form factor.** A page that works beautifully on desktop may be unusable on Phone. Use the Mobile preview and apply visibility filters by form factor where the mobile experience diverges.
- **Assignment fallthrough to Org Default for unintended users.** Forgetting to assign a page for a specific profile means those users get Org Default — which may be a stale older version of the page. Audit every profile.
- **Using Record Page Assignment by Profile as a replacement for permissions.** Hiding a component from a profile via assignment is a UX choice, not a security boundary. A user with API access can still see the underlying data. For real access control, use FLS, permission sets, or sharing — delegate to [sf-permissions](../sf-permissions/SKILL.md).
- **Placing 30 data-fetching components on a record page.** Load time balloons, wire errors compound, and no user reads 30 components anyway. Prioritize ≤ 12 above-the-fold; lazy-load the rest in tabs.
- **Building on an industry-packaged template and not consulting the industry skill.** FSC, Health Cloud, PSS, EDU, Field Service, and NPC ship opinionated record pages. Modifying them without understanding the intent breaks the packaged experience. Route to the industry skill first.

---

## 7. Common Failure Modes and Remediation

### Failure 1 — "Users are seeing the old record page, not my new one"
- **Symptom:** Admin has activated a new Lightning page but certain users still see the previous layout or page.
- **Root cause:** Assignment specificity — a more-specific assignment (App + Record Type + Profile) is overriding the Org Default / App Default. Or cache — the user's session hasn't picked up the new page.
- **Fix:** Open the page → Activation → review the assignment tree. Confirm the target users' profile × record type × app combination is assigned to the new page. If needed, add a more-specific assignment. Ask users to log out / log back in or refresh hard to clear cache.

### Failure 2 — "Dynamic Forms migration wizard missed half our fields"
- **Symptom:** After running the migration wizard, the Dynamic Forms version is missing fields from the original Page Layout.
- **Root cause:** The wizard generates an initial layout based on the current Page Layout's Field Layout section but skips fields in Visual Page Layout, certain custom field types, or fields in related blocks. Some fields require manual re-add.
- **Fix:** Compare the Page Layout and the migrated Dynamic Forms page side by side. Manually re-add missing fields. This is expected; treat the migration wizard as a starting point, not a finisher.

### Failure 3 — "Visibility filter isn't hiding the component"
- **Symptom:** Filter set to `Account.Type = 'Partner'` but the component shows on all account types.
- **Root cause:** The filter references the wrong merge field path, OR the field is not selected on the Account page's field context, OR the record has a NULL value (filter may not match NULL as expected without explicit `IS NULL`).
- **Fix:** Open the filter → confirm the merge path is `{!Record.Type}` (not `{!Account.Type}`). Verify the field is populated on the tested record. For NULL handling, add an OR clause explicitly.

### Failure 4 — "Dynamic Action conditional visibility doesn't apply to Mobile"
- **Symptom:** On desktop, the action respects its visibility filter; on mobile, the action always shows.
- **Root cause:** Mobile renders Dynamic Actions differently — some filters may not be honored in all mobile contexts (especially mobile offline). Known limitation on certain form factors.
- **Fix:** Test on the target form factor explicitly. If the filter isn't honored, layer a second guardrail (e.g., the action's underlying Flow or Apex can re-check the condition and abort with a message). Do not rely on UI visibility alone for business rules.

### Failure 5 — "Dynamic Interaction doesn't fire — target component never updates"
- **Symptom:** Source LWC's event fires (confirmed in console), but the target LWC's input property doesn't update.
- **Root cause:** The target component's `@api` input property isn't named correctly in `.js-meta.xml`, OR the source component's event payload keys don't match the target's expected property, OR Dynamic Interaction is misconfigured (wrong target selected in App Builder).
- **Fix:** Open target component's `.js-meta.xml` — confirm `<targetConfigs>` exposes the input. Open source component's `.js-meta.xml` — confirm the event schema. In App Builder, re-open the Dynamic Interaction and verify the payload-to-property mapping.

### Failure 6 — "Record page load is > 8 seconds on the Account record"
- **Symptom:** Users complain the Account record takes too long to render.
- **Root cause:** Too many data-fetching components on the initial (non-tabbed) region; each makes its own Apex or API call; no lazy loading.
- **Fix:** Audit component count on the first visible region. Move all but the most essential into tabs. Use visibility filters to defer rendering. Measure with Lightning Usage App. Combine multiple LWCs that all call `getRecord` on the same record into one parent LWC that passes data down.

### Failure 7 — "Migrated a page to production but half the profiles see a blank record page"
- **Symptom:** Post-deploy, some users open a record and see an empty page or an error.
- **Root cause:** The deployed FlexiPage was not re-activated in production, OR the Record Page Assignments were not included in the deployment, OR a referenced LWC / Apex class the page depends on wasn't deployed.
- **Fix:** Open Setup → Lightning App Builder → find the page → verify Activated status. Verify all Record Page Assignments match dev/UAT. Check the Deploy manifest for included dependencies (`FlexiPage`, `FlexiPageRegion`, LWCs referenced, `CustomApplication` if app assignment).

---

## 8. Lightning App Builder Cheat Sheet

### Metadata files

| File suffix | Purpose |
|---|---|
| `.flexipage-meta.xml` | The Lightning page (record / app / home / email app) |
| `.app-meta.xml` / `.customApplication-meta.xml` | The Lightning App (utility bar, navigation, default pages) |
| `.flexiPageRegion` (within FlexiPage) | A region inside a page |
| `.layout-meta.xml` | Legacy Page Layout (being replaced by Dynamic Forms) |

### Page type quick reference

| Page type | Context | Primary components |
|---|---|---|
| Record Page | A specific sObject record | Highlights Panel, Record Detail / Dynamic Forms, Related Lists, custom LWC |
| App Page | Free-form app tab | Any component; no record context |
| Home Page | User's home | News, Tasks, Recent Items, custom LWC |
| Email Application Page | In the Email side panel | Limited component subset |

### Template chooser

| Shape | Template |
|---|---|
| Header + Right Sidebar | classic record |
| Header + Subheader + Left Sidebar | fuller context |
| Pinned Left Sidebar | sidebar stays on scroll |
| One Region (Full Width) | simple single-column |
| Three Regions | balanced |
| Custom | LWC-authored template |

### Visibility filter cheatsheet

| Filter dimension | Example |
|---|---|
| Record field value | `{!Record.Status__c} = 'Active'` |
| User profile | `{!$Profile.Name} = 'Sales Rep'` |
| Permission set assignment | `{!$Permission.ViewFinancials} = true` |
| Form factor | `{!$Client.FormFactor} = 'Large'` (desktop) |
| User | `{!$User.Id} = '005...'` (rare; prefer profile/perm) |
| Record type | handled via page assignment, not visibility |
| Compound | `AND(cond1, OR(cond2, cond3))` |

### Record Page Assignment specificity (most specific wins)

1. App + Record Type + Profile + Form Factor
2. App + Record Type + Profile
3. App + Record Type
4. App Default (per form factor)
5. App Default
6. Org Default

### Performance budget

| Budget | Guideline |
|---|---|
| Data-fetching LWCs on first render | ≤ 12 |
| First Contentful Paint | < 3s typical record |
| Tabs per record page | ≤ 6 before UX degrades |
| Related Lists exposed inline | 3–5; rest in Related tab |

### Cross-skill integration

| Need | Delegate to | Reason |
|---|---|---|
| Author the LWC placed on the page | [sf-lwc](../sf-lwc/SKILL.md) | Component code |
| Apex behind quick action | [sf-apex](../sf-apex/SKILL.md) | Code |
| Flow behind screen component | [sf-flow](../sf-flow/SKILL.md) | Flow authoring |
| Field / object / validation rule metadata | [sf-metadata](../sf-metadata/SKILL.md) | Metadata XML |
| Report / dashboard on the page | [sf-reports-dashboards](../sf-reports-dashboards/SKILL.md) | Report engine |
| OmniStudio FlexCard on the page | [sf-industry-commoncore-flexcard](../sf-industry-commoncore-flexcard/SKILL.md) | FlexCard authoring |
| Industry-packaged record page customization | industry skill (FSC / Health / EDU / PSS / FS / NPC) | Template owner |
| Experience Cloud site page | [sf-experience-cloud](../sf-experience-cloud/SKILL.md) | Different builder |
| Deployment | [sf-deploy](../sf-deploy/SKILL.md) | DevOps |
| Diagram the page composition | [sf-diagram-mermaid](../sf-diagram-mermaid/SKILL.md) | Architecture diagram |

---

## 9. Output Format

When finishing, report in this order:

1. **Task classification** — new-page / migrate-from-page-layout / add-components / assign / troubleshoot
2. **Industry pre-check** — skipped (platform-level primitive); note any caller industry skill
3. **Page type and template** — Record / App / Home / Email App + template name
4. **Dynamic Forms status** — in-use / migrated / skipped-why
5. **Dynamic Actions status** — in-use / static / reason
6. **Dynamic Interactions** — any wired, source-target pairs
7. **Visibility filter summary** — count + dimensions used
8. **Record Page Assignment tree** — profile × record type × app × form factor
9. **Scoring total** — N / 120, with any sub-threshold category flagged
10. **Next recommended step** — next phase or cross-skill handoff
