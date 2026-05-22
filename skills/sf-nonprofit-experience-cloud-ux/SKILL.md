---
name: sf-nonprofit-experience-cloud-ux
description: >
  Nonprofit Experience Cloud UX/UI design with 100-point scoring. TRIGGER when:
  user designs portal branding, page layouts, navigation flows, content strategy,
  responsive design, accessibility, user journeys, wireframes, or visual design
  for nonprofit Experience Cloud sites. Also triggers when user asks about
  "donor journey", "volunteer onboarding experience", "portal usability", or
  "portal look and feel". DO NOT TRIGGER when: portal architecture
  and sharing (use sf-nonprofit-experience-cloud), LWC component code (use sf-lwc),
  or non-nonprofit portal design.
license: MIT
metadata:
  version: "1.0.0"
  scoring: "100 points across 5 categories"
release_pinned: "Spring '26"
docs_last_verified: 2026-05-01
upstream_refs:
  - url: https://help.salesforce.com/s/articleView?id=sf.experience_cloud_overview.htm
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://www.lightningdesignsystem.com/
    anchor: ""
    sha256: ""
    importance: authoritative
  - url: https://architect.salesforce.com/design/experience-cloud
    anchor: ""
    sha256: ""
    importance: supplemental
upstream_release_notes:
  - release: "Spring '26"
    url: https://help.salesforce.com/s/articleView?id=release-notes.rn_networks.htm
eval_harness:
  enabled: true
  pilot: true
  harness_skill: sf-skill-eval-harness
  rubric_ref: "100-pt rubric (5 categories: User Journey 25 / Visual Design 25 / Accessibility 20 / Content & Microcopy 15 / Responsiveness 15) — newly authored 2026-05-22 — mapped onto 4-dim default rubric per skill-eval-harness-SPEC.md §5.1"
  hard_fail_dimensions: [Correctness, Robustness, Fit, Performance]
  max_iterations: 3
  per_loop_replan_budget: 1
  improvement_threshold_points: 5
  apply_when: artifact_produced
  exp_ux_dimensions:
    - name: Correctness
      max: 25
      hard_fail_below: 14
      description: "User journey + task completion. Maps to User Journey (25). Each constituent journey (donor, volunteer, grantee, client) has a documented happy path + error recovery; multi-step forms expose progress; success states confirm next steps."
      automatic_hard_fail_rules:
        - "User journey shipped without an explicit happy path documented end-to-end (entry → action → confirmation → next step)"
        - "Multi-step form without progress indicator (step counter or progress bar) — user can't tell where they are"
        - "Form submission with no confirmation message / page redirect / next-step guidance (silent success)"
        - "Error path with no recovery (form fails and user has to start over instead of seeing inline validation + retry)"
        - "Auto-save absent on long forms (>3 steps or >5 minutes typical fill time) — abandonment on session loss"
    - name: Robustness
      max: 25
      hard_fail_below: 14
      description: "Accessibility floor. Maps to Accessibility (20). WCAG 2.1 AA is the floor — nonprofit audiences are diverse (assistive tech, low bandwidth, varying digital literacy); skipping a11y is a constituent exclusion problem, not a polish issue."
      automatic_hard_fail_rules:
        - "Color contrast below WCAG 2.1 AA (4.5:1 body / 3:1 large text) on any text-bearing element"
        - "Status indicated by color alone (red/green badge) without an icon, label, or pattern (color-blind exclusion)"
        - "Interactive element (button / link / form control) missing accessible name (no aria-label, no visible label, no associated text)"
        - "Keyboard inaccessibility — any action requires a mouse / touch (Tab cannot reach it, or Enter/Space cannot activate it)"
        - "Form field without programmatic label (placeholder-only inputs — screen readers can't announce the field)"
        - "Auto-playing video / heavy media on landing page without user-initiated control (bandwidth + a11y violation)"
    - name: Fit
      max: 25
      hard_fail_below: 12
      description: "Visual + content design fidelity. Maps to Visual Design (25) + Content & Microcopy (15). Mission-aligned imagery (not stock), branded color tokens (no hardcoded colors), navigation labels human-readable (not Salesforce API names), microcopy plain-language."
      automatic_hard_fail_rules:
        - "Salesforce API names exposed in UI labels (e.g., 'PersonExamination' instead of 'Background Check', 'GiftTransaction' instead of 'My Giving')"
        - "Hardcoded colors in component styles instead of CSS custom properties / SLDS styling hooks (breaks dark mode + theming)"
        - "Generic stock photography on hero / landing instead of mission-aligned imagery from the org's brand library"
        - "Wall-of-text landing page with no progressive disclosure (>3 paragraphs above the fold without a CTA)"
        - "Navigation menu with >7 top-level items (cognitive overload + mobile-menu overflow)"
        - "Jargon-heavy labels — measured by failing the 5th-grade reading level test on primary nav + form labels"
    - name: Performance
      max: 25
      hard_fail_below: 12
      description: "Mobile responsiveness + interaction performance. Maps to Responsiveness (15). Mobile-first layouts, 44px+ touch targets, 16px+ body text (prevents iOS zoom), thumb-zone primary actions, offline-resilient confirmation."
      automatic_hard_fail_rules:
        - "Touch targets below 44x44px on mobile (interactive elements not tappable for users with motor impairment)"
        - "Body text below 16px on mobile (triggers iOS auto-zoom + readability cliff)"
        - "Layout untested at <576px breakpoint — content overflows, columns don't collapse, primary CTAs not reachable"
        - "Loading states absent — form submission / data fetch >300ms with no spinner / skeleton (user assumes broken)"
        - "Primary action positioned above the fold on mobile (out of thumb-zone) when bottom-anchored CTA is the convention"
  test_rubric:
    unit:
      required: true
      criteria: "Design tokens validated: CSS custom properties cover brand-primary / secondary / accent / text / background / surface / error / success / border-radius / spacing-unit. WCAG contrast checked on every text/background pairing. Form spec documents required fields with asterisk + legend pattern. Touch-target audit lists every interactive element at ≥44px."
    integration:
      required: true
      criteria: "Built portal page passes axe-core / Lighthouse a11y audit at WCAG 2.1 AA. All journey happy paths complete in click-through testing. Multi-step forms persist drafts every 60s. Loading + error + success states render at correct moments. Mobile breakpoints tested at 320 / 576 / 768 / 1024px."
    smoke:
      required: true
      criteria: "Constituent walk-through: representative user (donor / volunteer / grantee / client) completes the documented journey on mobile + desktop without help. Screen-reader spot check verifies labels announced correctly. Color-blind simulation passes status-conveyance check. Reading-level audit on primary nav + form labels passes 5th-grade target."
---

# sf-nonprofit-experience-cloud-ux: Nonprofit Portal UX/UI Designer

Expert UX/UI designer specializing in nonprofit Experience Cloud portals: user journey design, information architecture, branding, accessibility, responsive layouts, content strategy, and constituent-centered design patterns.

## Eval Harness Wrap

When `eval_harness.enabled: true` (frontmatter), this skill is wrapped by [sf-skill-eval-harness](../../skills-cursor/sf-skill-eval-harness/SKILL.md). 100-pt rubric across 5 portal-UX categories, newly authored 2026-05-22 to fill the harness coverage gap on nonprofit constituent-portal design. Robustness floor at 14 — WCAG 2.1 AA is the floor, not aspiration; nonprofit audiences include assistive-tech users + low-bandwidth + varying digital literacy and skipping a11y is a constituent-exclusion problem. Hard-fail rules block contrast violations, color-only status, keyboard-inaccessible UI, Salesforce API names in labels, hardcoded colors, sub-44px touch targets, and missing journey confirmations. Disable with `eval_harness.enabled: false`.

---

## Core Responsibilities

1. **User Journey Design**: Map constituent journeys across portal touchpoints
2. **Information Architecture**: Navigation, page hierarchy, content organization
3. **Visual Design**: Branding, theming, component styling, responsive layouts
4. **Accessibility**: WCAG 2.1 AA compliance, inclusive design, assistive technology
5. **Content Strategy**: Microcopy, help text, error messages, mission-driven messaging
6. **Validation & Scoring**: Score designs against 5 categories (0-100 points)

## Document Map

| Need | Document | Description |
|------|----------|-------------|
| **Design patterns** | [references/design-patterns.md](references/design-patterns.md) | Page layouts, component patterns, responsive design |
| **Accessibility guide** | [references/accessibility-nonprofit.md](references/accessibility-nonprofit.md) | WCAG compliance, inclusive design for nonprofit audiences |

---

## Design Principles for Nonprofit Portals

### 1. Mission-First

Every page reinforces the organization's mission. The portal is an extension of the nonprofit's brand and values, not a generic Salesforce site.

### 2. Constituent-Centered

Design for the actual user: volunteers who may be non-technical, donors who want quick actions, clients who may have limited internet access, grantees managing complex applications.

### 3. Progressive Disclosure

Show only what's needed at each step. Complex forms use multi-step flows. Advanced features are accessible but not overwhelming.

### 4. Trust & Transparency

Nonprofits depend on trust. Show clear data usage policies, progress indicators, and confirmation messages. Explain why data is collected.

### 5. Inclusive by Default

Nonprofit audiences are diverse. Design for screen readers, low bandwidth, mobile-first, multiple languages, and varying digital literacy.

---

## Branding & Theming

### Theme Configuration

| Element | Configuration | Notes |
|---------|--------------|-------|
| **Logo** | Header logo (max 250x50px recommended) | SVG preferred for clarity |
| **Primary color** | Brand color for buttons, links, active states | Ensure 4.5:1 contrast ratio |
| **Secondary color** | Accent color for highlights, badges | Complement primary |
| **Font** | System font stack or branded web font | Performance vs brand |
| **Hero imagery** | Mission-aligned photography | Authentic, not stock |
| **Favicon** | 32x32px icon | Brand recognition in tabs |

### CSS Custom Properties (theme layer for Aura BYO + custom LWCs)

```css
:root {
    --c-brand-primary: #1B5E20;
    --c-brand-secondary: #4CAF50;
    --c-brand-accent: #FF9800;
    --c-text-primary: #212121;
    --c-text-secondary: #616161;
    --c-background: #FAFAFA;
    --c-surface: #FFFFFF;
    --c-error: #D32F2F;
    --c-success: #388E3C;
    --c-border-radius: 8px;
    --c-spacing-unit: 8px;
}
```

### Dark Mode Considerations

Use SLDS 2 styling hooks (`--slds-g-color-*`) for components. Custom CSS should reference CSS custom properties, never hardcoded color values.

---

## Page Layout Patterns

### Home Page

```
┌─────────────────────────────────────────────────┐
│  Navigation Bar (logo, menu, profile)            │
├─────────────────────────────────────────────────┤
│  Hero Banner                                     │
│  "Hope Lives Here" + mission statement           │
│  [Primary CTA]  [Secondary CTA]                 │
├──────────────┬──────────────┬───────────────────┤
│  Card 1      │  Card 2      │  Card 3           │
│  Quick Action│  Quick Action│  Quick Action      │
│  (Profile)   │  (Hours)     │  (Bg Check)       │
├──────────────┴──────────────┴───────────────────┤
│  Recent Activity / Announcements                 │
├─────────────────────────────────────────────────┤
│  Footer (contact, links, social, privacy)        │
└─────────────────────────────────────────────────┘
```

### List Page

```
┌─────────────────────────────────────────────────┐
│  Page Title + Description                        │
│  [Create New] button                             │
├─────────────────────────────────────────────────┤
│  Filter Bar (status, date range)                 │
├─────────────────────────────────────────────────┤
│  Record Card 1 (status badge, key info, action) │
│  Record Card 2                                   │
│  Record Card 3                                   │
├─────────────────────────────────────────────────┤
│  Pagination / Load More                          │
└─────────────────────────────────────────────────┘
```

### Record Detail Page

```
┌─────────────────────────────────────────────────┐
│  Breadcrumb: Home > Section > Record Name        │
├─────────────────────────────────────────────────┤
│  Record Header (name, status badge, actions)     │
├────────────────────────┬────────────────────────┤
│  Primary Details       │  Status / Timeline      │
│  (key fields)          │  (progress indicator)   │
├────────────────────────┴────────────────────────┤
│  Tabbed Content (Details | History | Documents)  │
└─────────────────────────────────────────────────┘
```

---

## Navigation Patterns

### Primary Navigation

| Pattern | Best For | Implementation |
|---------|----------|---------------|
| **Top bar** | 5-7 items, simple hierarchy | Navigation Menu component |
| **Sidebar** | Deep hierarchy, many sections | Custom LWC navigation |
| **Hamburger** | Mobile-first, complex nav | Responsive menu component |

### Navigation Menu Design

Keep navigation items to 5-7 maximum. Use clear, action-oriented labels.

| Good Label | Bad Label | Why |
|-----------|-----------|-----|
| My Hours | Volunteer Hours Management | Too long, jargon |
| Submit Check | PersonExamination Create | Exposes internal naming |
| My Giving | Gift Transaction History | Too technical |
| Apply Now | Grant Application Submission | Unnecessary words |

### Breadcrumbs

Always provide breadcrumbs on detail pages. Format: `Home > Section > Record Name`

---

## Form Design

### Multi-Step Form Pattern

For complex forms (applications, intake):

```
Step 1 of 4: Basic Info
[●─────○─────○─────○]

┌─────────────────────────┐
│  Field 1                │
│  Field 2                │
│  Field 3                │
│                         │
│  [Back]    [Save Draft]  [Next →] │
└─────────────────────────┘
```

### Form Best Practices

| Practice | Implementation |
|----------|---------------|
| One column layout | Single column for mobile readability |
| Inline validation | Validate on blur, show error below field |
| Required field indicator | Asterisk (*) with legend at top |
| Help text | Info icon with tooltip, not paragraph blocks |
| Auto-save | Save draft every 60 seconds for long forms |
| Progress indicator | Step indicator or progress bar |
| Confirmation | Success message with next steps after submission |

### Error Messaging

| Type | Format | Example |
|------|--------|---------|
| Field error | Below field, red text | "Please enter a valid email address" |
| Form error | Top of form, summary | "Please fix 2 errors before submitting" |
| System error | Toast notification | "Something went wrong. Please try again." |
| Success | Toast or page redirect | "Your application was submitted successfully" |

---

## Mobile Responsiveness

### Breakpoints

| Breakpoint | Target | Layout |
|------------|--------|--------|
| <576px | Phone | Single column, stacked cards |
| 576-768px | Tablet portrait | 2-column grid |
| 768-1024px | Tablet landscape | 2-3 column grid |
| >1024px | Desktop | Full layout |

### Mobile Priorities

1. **Touch targets**: Minimum 44x44px tap area
2. **Font size**: Minimum 16px body text (prevents zoom on iOS)
3. **Thumb zone**: Primary actions in bottom half of screen
4. **Reduced content**: Hide secondary info behind expandable sections
5. **Offline resilience**: Graceful handling of intermittent connectivity

---

## Validation & Scoring

```
Score: XX/100
├─ User Journey: XX/25          (Flow clarity, task completion, error recovery)
├─ Visual Design: XX/25         (Branding, consistency, hierarchy, whitespace)
├─ Accessibility: XX/20         (WCAG 2.1 AA, screen reader, keyboard, contrast)
├─ Content & Microcopy: XX/15   (Clarity, tone, help text, error messages)
└─ Responsiveness: XX/15        (Mobile-first, breakpoints, touch targets)
```

---

## Anti-Patterns

- Exposing Salesforce API names in UI labels (e.g., "PersonExamination" instead of "Background Check")
- No mobile testing (assuming desktop-only usage)
- Wall of text on landing pages (no progressive disclosure)
- Generic stock photography that doesn't reflect the community served
- Missing error states (forms fail silently)
- No loading states (user unsure if action was received)
- Color-only status indicators (fails for color-blind users)
- Tiny tap targets on mobile (<44px)
- Auto-playing video on home page (bandwidth, accessibility)
- Jargon-heavy navigation labels

---

## Cross-Skill Integration

| Task | Skill |
|------|-------|
| Portal architecture and sharing | sf-nonprofit-experience-cloud |
| LWC custom components for portal | sf-lwc |
| Screen Flows for portal forms | sf-flow |
| Branding assets and image generation | sf-diagram-nanobananapro |
| Mermaid diagrams for user journeys | sf-diagram-mermaid |
| Accessibility compliance for LWC | sf-lwc (accessibility reference) |

---

## Terminology

- **Build Your Own (Aura)** — the default Experience Cloud scaffold for new nonprofit portals; Aura runtime hosting custom LWCs in Aura regions
- **Build Your Own (LWR)** — Lightning Web Runtime alternative; permitted only with a named, irreplaceable blocker (see sf-nonprofit-experience-cloud-build Phase 0)
- **Packaged Aura templates** (Customer Service, Partner Central, Customer Account Portal) — never used as scaffolding; baked-in regions and CSS fight branding
- **Theme Layout** — Controls header, footer, and navigation wrapper for all pages
- **Hero Banner** — Large visual section at top of home page with mission messaging
- **Card Pattern** — Content container with icon, title, description, and action
- **Progressive Disclosure** — Revealing information incrementally as needed
- **Microcopy** — Short UI text: button labels, help text, error messages, tooltips
- **Touch Target** — Minimum tappable area for mobile (44x44px per WCAG)
- **Breadcrumb** — Navigation trail showing current location in page hierarchy
