# EVAL-REPORT-1 — volunteerShiftCard LWC (Stage B pilot, iter 1)

## 1. Verdict

**SHIP** — Quality 94/100 (94.0%). All four hard-fail floors satisfied. Unit, integration, and smoke test rubric items all pass. No hard-fail breaches. No SPEC-DEFECT signal.

---

## 2. A11y probe results (deterministic)

Command: `grep -nE '<button[^>]*>|<a [^>]*>|<input[^>]*>|<img[^>]*>|<div[^>]*onclick|<span[^>]*onclick' volunteerShiftCard.html`

Result: **zero raw `<button>` / `<a>` / `<input>` / `<img>` elements; zero clickable-div widgets**.

Lightning base components used (line refs in `volunteerShiftCard.html`):

- `lightning-card` (line 2)
- `lightning-icon` with `alternative-text="Error"` (line 11–16)
- `lightning-formatted-date-time` × 2 (lines 26–33, 36–40)
- `lightning-icon` with `alternative-text="Shift full"` (line 54–59)
- `lightning-formatted-rich-text` (lines 75–77)
- `lightning-button` with explicit `label="Sign Up"` and `title="Sign up for this volunteer shift"` (lines 83–90)
- `lightning-spinner` with `alternative-text="Loading shift"` (lines 98–101)

Quoted evidence (line 83–90):
```
<lightning-button
    label="Sign Up"
    title="Sign up for this volunteer shift"
    variant="brand"
    disabled={signUpDisabled}
    onclick={handleSignUpClick}
    data-id="signup-button"
></lightning-button>
```

Quoted evidence — capacity-full visual treatment NOT color-only (line 52–66):
```
<template lwc:if={isFull}>
    <span class="capacity-full" aria-live="polite">
        <lightning-icon
            icon-name="utility:close"
            alternative-text="Shift full"
            ...
        ></lightning-icon>
        <span class="slds-m-left_xx-small">Full</span>
    </span>
</template>
```

A11y probe verdict: **CLEAN** — no Robustness deductions triggered. Score: 23/25 (kept 2 points back because there is no explicit `aria-labelledby` on the description region tying it to the card title — minor, not a hard-fail).

---

## 3. SLDS hardcoded-color probe results

Probes on `volunteerShiftCard.css`:

| Pattern | Result |
|---|---|
| `#[0-9a-fA-F]{3,8}` (hex colors) | **0 hits** |
| `rgb(`, `rgba(`, `hsl(`, `hsla(` | **0 hits** |
| Named colors (red, blue, white, black, gray, etc.) | **0 hits** |
| Inline `style=` in HTML | **0 hits** |

All color references resolve to `var(--slds-g-color-*)` design tokens (lines 15, 16, 33, 39, 43, 47, 54, 55, 66, 67):

```css
color: var(--slds-g-color-on-surface-1);
background-color: var(--slds-g-color-surface-container-1);
```

SLDS hardcoded-color probe verdict: **CLEAN** — no Fit hard-fail triggered. The Dark Mode breaker rule did not fire because there are no Dark Mode breakers.

---

## 4. SLDS deprecation probe results

| Pattern | Result |
|---|---|
| `--lwc-*` tokens (deprecated) | **0 hits** in CSS or HTML |
| `slds-text-color_default` / `_inverse` / `_weak` / `_error` | **0 hits** |
| `slds-text-heading_*` (deprecated) | **0 hits** |
| `slds-theme_default` | **0 hits** |

SLDS classes actually used (all valid in SLDS 2):
`slds-assistive-text`, `slds-m-horizontal_xx-small`, `slds-m-left_x-small`, `slds-m-left_xx-small`, `slds-m-top_medium`, `slds-m-top_small`, `slds-p-around_medium`, `slds-p-around_small`, `slds-p-bottom_medium`, `slds-p-horizontal_medium`, `slds-text-body_regular`, `slds-text-title`.

Deprecation probe verdict: **CLEAN** — no Fit hard-fail triggered.

---

## 5. Reactivity model probe results

| Pattern | Result |
|---|---|
| `@track` on primitive | **0 hits** — only a comment "Internal state — primitives are reactive without @track in modern LWC." (line 46) |
| `document.querySelector` / `getElementById` / `getElementsByClassName` | **0 hits** |
| `!important` in CSS or HTML | **0 hits** |
| `fetch(` / `XMLHttpRequest` in JS | **0 hits** |
| `renderedCallback` | **0 hits** (only a doc-comment reference) |
| Mutation of `@api` props inside class (`this.shiftId = ...`) | **0 hits** |
| `@import` in CSS | **0 hits** |

Quoted evidence — synchronous click-disable (lines 147–155):
```js
handleSignUpClick() {
    if (this._submitting) {
        return;
    }
    // Synchronous disable BEFORE awaiting the Apex promise — guards against double-click.
    this._submitting = true;

    const shiftId = this.shiftId;
    signUp({ shiftId })
```

Reactivity probe verdict: **CLEAN** — no Correctness or Performance hard-fail triggered.

---

## 6. Base component usage — confirmed

The implementer's claim of "zero raw `<button>` / `<a>` / `<img>`" is **verified**. All structural primitives use the `lightning-*` family. The Sign Up button is `<lightning-button>` (line 83), not a raw `<button>`. Datetime values are rendered with `<lightning-formatted-date-time>` (lines 26, 36). Decorative dash on line 34 is correctly marked `aria-hidden="true"` and an `slds-assistive-text` "to" is provided on line 35 for screen readers.

---

## 7. Jest test class verification

10 `it(...)` cases declared. Mapping to TC-* requirements:

| TC | Covered? | Evidence |
|---|---|---|
| TC-U1 (`shiftId` setter feeds wire) | yes | `passes shiftId to the wire adapter` (lines 95–104), uses `getRecord.getLastConfig()` and asserts `recordId` + ≥7 fields |
| TC-U2 negative (`allowSignup=false` hides button) | yes | `does not render Sign Up button when allowSignup is false (default)` (lines 107–114) |
| TC-U2 positive (`allowSignup=true` + capacity → button) | yes | `renders Sign Up button when allowSignup is true and capacity remains` (lines 116–124) |
| TC-U3 hide (`compactMode=true`) | yes | `hides description when compactMode is true` (lines 127–137) — also asserts site name still rendered |
| TC-U3 show (`compactMode=false`) | yes | `renders description when compactMode is false (default)` (lines 139–146) |
| TC-U4 (wire response renders fields) | yes | `renders shift name, site, and spots remaining from the wire response` (lines 149–158) |
| TC-U5 (capacity full → no button + accessible "Full") | yes | `shows a "Full" indicator and hides the Sign Up button` (lines 161–171) |
| TC-U6+TC-U7+TC-S1 (sync disable + signupcomplete dispatch) | yes (one combined test) | `disables Sign Up synchronously on click and dispatches signupcomplete on Apex success` (lines 174–206) — asserts `disabled === true` after `await Promise.resolve()` (lines 193–195), then asserts `signUp` called with `{shiftId}`, event fired once, `detail.shiftId` and `detail.contactId` present |
| TC-U8 (Apex error re-enables, no event) | yes | `re-enables Sign Up and skips signupcomplete when Apex rejects` (lines 209–226) |
| Bonus (object-shape contactId unwrap) | yes | `accepts an object return shape with explicit contactId from Apex` (lines 229–244) |

Public-surface coverage: 3 `@api` setters × 1 wire adapter × 1 Apex method × 1 dispatched event = all touched. ≥80% coverage of public surface satisfied. Uses `createElement('c-volunteer-shift-card', { is: VolunteerShiftCard })` and `document.body.appendChild` per `@salesforce/sfdx-lwc-jest` conventions. Apex mock via `jest.mock('@salesforce/apex/...')`. `flushPromises` helper present.

Test rubric verdict: **unit pass, integration pass (XML well-formed), smoke pass**.

Caveat noted but not penalized: TC-U6 / TC-U7 / TC-S1 are collapsed into one combined test rather than three named cases. The implementer disclosed this in IMPL-NOTES. SPEC's TC-S1 says "MUST exist as its own named test case asserting the entire chain end-to-end" — strictly read, this is a partial soft-fail of TC-S1 nomenclature, not behavior. Behavior is fully exercised; the assertions exist. Counted as a -1 in Correctness (already reflected in 24/25), not a hard-fail.

---

## 8. AC pass/fail table (33 ACs)

| AC | Status | Evidence |
|---|---|---|
| AC-1 (4 sibling files + `__tests__/`) | PASS | Directory listing confirms `volunteerShiftCard.{js,html,css,js-meta.xml}` + `__tests__/volunteerShiftCard.test.js` |
| AC-2 (`isExposed=true`, 3 targets minimum) | PASS | meta.xml lines 4 + 8–11 declare `lightning__RecordPage`, `lightning__AppPage`, `lightning__HomePage`, `lightningCommunity__Page` |
| AC-3 (`apiVersion ≥ 60.0`) | PASS | meta.xml line 3: `<apiVersion>62.0</apiVersion>` |
| AC-4 (3 `@api` props with documented defaults) | PASS | js lines 38, 41, 44 — `shiftId`, `allowSignup = false`, `compactMode = false` via class field initializers |
| AC-5 (no Sign Up button when `allowSignup=false`) | PASS | html line 81 wraps the button in `<template lwc:if={canSignUp}>`; js line 121–123 `canSignUp` returns false when `allowSignup` is falsy |
| AC-6 (`compactMode=true` removes description) | PASS | html line 70 `<template lwc:if={showDescription}>`; js line 117–119 returns false when `compactMode` is true |
| AC-7 (wire with schema-import fields) | PASS | js lines 6–22 import all 7 fields via `@salesforce/schema/...`; line 51 `@wire(getRecord, { recordId: '$shiftId', fields: SHIFT_FIELDS })` |
| AC-8 (name + datetime range + site + spots remaining) | PASS | html lines 26–40 (date-time), line 46 (site), line 64 (`spotsLabel`); js line 134–143 computes "N spot(s) remaining" |
| AC-9 (full state — non-color-only indicator) | PASS | html line 52–66: text "Full" + labeled icon both present inside `<template lwc:if={isFull}>` |
| AC-10 (button gated by `allowSignup` AND spots > 0) | PASS | js line 121–123 — `canSignUp = allowSignup && hasRecord && !isFull` |
| AC-11 (Apex import + shiftId param) | PASS | js line 4 imports `signUp`; line 155 calls `signUp({ shiftId })` |
| AC-12 (synchronous disable on click) | PASS | js lines 147–152 set `_submitting = true` synchronously before the Apex promise; `signUpDisabled` getter (line 125–128) returns `_submitting`; html line 87 `disabled={signUpDisabled}` |
| AC-13 (`signupcomplete` event with `detail.contactId`) | PASS | js lines 163–169 — dispatches CustomEvent with `detail: { shiftId, contactId }` |
| AC-14 (Apex error re-enables button + error toast) | PASS | js lines 179–193 — error path dispatches ShowToastEvent with `error.body.message`; `finally` block (line 192–194) resets `_submitting = false` |
| AC-15 (success toast on Apex success) | PASS | js lines 171–177 — success ShowToastEvent dispatched |
| AC-16 (button/anchor labeling) | PASS | `<lightning-button label="Sign Up">` is the only interactive element with text label; no raw `<a>`; lightning-icon nodes carry `alternative-text` |
| AC-17 (img alt) | PASS | zero `<img>` elements in template; vacuously satisfied |
| AC-18 (custom interactive widgets — role + tabindex + keyboard) | PASS | zero clickable non-interactive elements (no `onclick` on `<div>`/`<span>`); vacuously satisfied |
| AC-19 (form input labels) | PASS | zero form inputs in this read-only-display + click-button surface; vacuously satisfied |
| AC-20 (no hardcoded colors) | PASS | grep verified — 0 hits across hex/rgb/hsl/named colors |
| AC-21 (no `--lwc-*` tokens) | PASS | grep verified — 0 hits in CSS or HTML |
| AC-22 (no `!important`) | PASS | grep verified — 0 hits |
| AC-23 (no SLDS 1 deprecated utility classes) | PASS | grep verified — 0 hits for the named-forbidden patterns |
| AC-24 (lightning-card / lightning-button / lightning-formatted-date-time) | PASS | html lines 2, 26, 36, 83 |
| AC-25 (no `document.querySelector`) | PASS | grep verified — 0 hits |
| AC-26 (no `@track` on primitive) | PASS | grep verified — only a doc-comment mention |
| AC-27 (no mutation of `@api` props from inside class) | PASS | grep verified — no `this.shiftId =` / `this.allowSignup =` / `this.compactMode =` assignments |
| AC-28 (no fetch/XHR/imperative-Apex inside getter or render path) | PASS | grep verified — no `fetch`/`XMLHttpRequest`; imperative Apex only invoked from `handleSignUpClick` event handler |
| AC-29 (no @import) | PASS | grep verified — 0 hits |
| AC-30 (`__tests__/volunteerShiftCard.test.js` exists) | PASS | file present (245 lines) |
| AC-31 (named test cases for a–f) | PASS | all six required behaviors covered (a: shiftId+allowSignup+compactMode; b: wire response; c: button absent on `allowSignup=false`; d: button absent when full; e: sync disable + dispatch; f: error path re-enables) |
| AC-32 (`@salesforce/sfdx-lwc-jest` conventions) | PASS | `createElement` from `lwc`, `document.body.appendChild`, `flushPromises`, `jest.mock('@salesforce/apex/...')` all present |
| AC-33 (≥6 `it(...)` cases, ≥5 distinct assertion targets) | PASS | 10 `it(...)` cases; 3 @api setters + wire + Apex + event = 6 distinct targets exercised |

**33/33 ACs PASS.** No SPEC-DEFECT signal — every AC is independently checkable from the artifacts and every one resolved cleanly.

---

## 9. 4-dimension scorecard (with quoted evidence)

### Correctness — 24/25 (floor 15)

Renders correctly per spec; @api props exposed; getter-based derived state cached per render; wire adapter receives `$shiftId`; signupcomplete dispatched with `{shiftId, contactId}` on Apex success; error path re-enables and shows toast. -1 for collapsing TC-U6/TC-U7/TC-S1 into a single combined test rather than three discretely-named cases (SPEC TC-S1 says "MUST exist as its own named test case"). Behavioral coverage is complete; nomenclature is partial.

Evidence (js line 51, line 154, lines 163–169):
```js
@wire(getRecord, { recordId: '$shiftId', fields: SHIFT_FIELDS })
...
const shiftId = this.shiftId;
signUp({ shiftId })
    .then((result) => {
        ...
        this.dispatchEvent(
            new CustomEvent('signupcomplete', {
                detail: { shiftId, contactId },
                bubbles: true,
                composed: true
            })
        );
```

### Robustness — 23/25 (floor 12)

Zero raw interactive primitives; lightning-icon nodes all carry `alternative-text`; lightning-spinner carries `alternative-text="Loading shift"`; lightning-button has explicit `label`; capacity-full state shows text + icon (not color-only); `aria-live="assertive"` on error region (line 9); `aria-live="polite"` on capacity-full span (line 53); `aria-hidden="true"` on decorative dash (line 34); `slds-assistive-text` "to" provides screen-reader narrative for the datetime range (line 35). -2 for: (a) the `<dl>` semantics rely on `display: contents` (line 30) which historically had a11y-tree quirks in some screen readers (Safari/VoiceOver bug, mostly resolved post-2022 but worth noting), and (b) no explicit `aria-labelledby` linking the description region back to the card title.

Evidence (html line 5–18 — accessible error region):
```
<div class="error-region slds-p-around_small" role="alert" aria-live="assertive">
    <lightning-icon icon-name="utility:error" alternative-text="Error" .../>
    <span class="slds-m-left_x-small">{errorMessage}</span>
</div>
```

### Fit — 24/25 (floor 10)

All four Fit hard-fail rules pass (no hardcoded colors, no SLDS 1 deprecated tokens, no @import outside the bundle, no reimplemented base components). SLDS 2 design tokens used throughout. PICKLES alignment is documented in the JS class doc-block (lines 24–35). -1 because `--slds-g-radius-border-2` and `--slds-g-font-weight-bold` are used with fallback values (`0.25rem`, `700`) that may not match SLDS 2's exact runtime values — minor, but not a guaranteed-correct fallback.

Evidence (css line 15–17):
```css
.card-body {
    color: var(--slds-g-color-on-surface-1);
    background-color: var(--slds-g-color-surface-container-1);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
}
```

### Performance — 23/25 (floor 12)

Zero `!important`. No fetch/XHR. No imperative Apex in render path. Getters compute derived state once per render cycle. No `renderedCallback`. Synchronous `_submitting = true` flip on click prevents double-submit without a microtask round-trip. -2 because the wire reactivity will refire the entire tree of getters whenever the wire response changes (acceptable but no `lwc:if` lazy-load on the description region beyond the `{showDescription}` gate; the wire is also non-cancellable, so a fast `shiftId` reassignment in a parent dashboard would flush in-flight wire data — a minor coordinator-dashboard concern, not a hard-fail).

Evidence (js lines 147–155):
```js
handleSignUpClick() {
    if (this._submitting) { return; }
    this._submitting = true;
    const shiftId = this.shiftId;
    signUp({ shiftId })
```

### Total: 94/100 (94.0%)

---

## 10. Test rubric

| Category | Required | Result | Evidence |
|---|---|---|---|
| **unit** | yes | **PASS** | 10 `it(...)` cases; covers all 3 `@api` setters, wire, dispatched event, Apex method, success path, error path. ≥80% public surface coverage. Uses `@salesforce/sfdx-lwc-jest` conventions throughout. |
| **integration** | yes | **PASS** (static) | meta.xml is well-formed: `<apiVersion>62.0</apiVersion>`, `<isExposed>true</isExposed>`, three required targets (`RecordPage`, `AppPage`, `lightningCommunity__Page`) plus `HomePage`. Property declarations on lines 20–22 declare `shiftId`/`allowSignup`/`compactMode` on the AppPage / Community targets so it appears configurable in Lightning App Builder. |
| **smoke** | yes | **PASS** | The TC-S1 end-to-end happy path is exercised in the combined `disables Sign Up synchronously...` test (lines 174–206): create → `shiftId` set → wire emits record → `allowSignup=true` → button found → click → mocked Apex resolves → `signupcomplete` listener captures event with full `{shiftId, contactId}` detail. |

All three test rubric required = pass.

---

## 11. What self-evaluation would have missed

Honestly, **not much** in this iteration — the implementer's bundle is well-aligned with the SPEC and the deterministic probes. The one observable gap that self-evaluation would likely have rationalized away:

> **Combined-test naming for TC-S1.** SPEC §4 explicitly says TC-S1 "MUST exist as its own named test case asserting the entire chain end-to-end". The implementer's IMPL-NOTES disclosed that TC-U6, TC-U7, and TC-S1 are collapsed into a single test (line 47 of IMPL-NOTES). Self-evaluation, with sunk cost, would call that "fine, the behavior is covered" and move on. Fresh-context reading lands a soft-deduction (Correctness -1) for the SPEC nomenclature, even though it's not hard-fail-worthy. The point is that the rubric is doing exactly what it should: catching paper-thin SPEC compliance vs. deep SPEC compliance.

A second observation that self-evaluation might miss because it requires running probes: the `display: contents` rule on `.meta-row` (css line 30) is technically a known a11y edge case for `<dl>` semantics in older screen readers. It's not a hard-fail; it's not even called out by the rubric directly. But fresh-context evaluation should at least note it. (Counted into the -2 Robustness deduction.)

Beyond those two, self-eval would have arrived at the same SHIP verdict — the implementer's claims hold under verification.

---

## 12. Stage B LWC pilot validation finding — are the rules calibrated correctly?

**The harness's automatic hard-fail rules behaved correctly. None of them fired on this clean implementation, which is the right outcome.**

This validates the harness in the negative direction: when an implementer follows the SPEC and the rubric, the deterministic probes return clean. None of the four hard-fail floors were even close to breaching:

- **Correctness 24/25** — comfortably above 15 floor. No `@track` on primitive, no DOM bypass, no infinite re-render.
- **Robustness 23/25** — comfortably above 12 floor. No unlabeled interactive widget, no missing alt, no clickable div without role+tabindex.
- **Fit 24/25** — comfortably above 10 floor. No hardcoded color, no SLDS 1 deprecated token, no @import, no reimplemented base component.
- **Performance 23/25** — comfortably above 12 floor. No `!important`, no synchronous network in getter, no missing-debounce on rapid input (no rapid-input surface in this component).

**The Stage B pilot now needs an adversarial counter-case to fully validate the rules' precision.** This pilot demonstrates the rules are not over-strict on a clean implementation. To validate they're not under-strict, we'd want a deliberately broken bundle (e.g., one with `#FFFFFF` in CSS, one with `<button>onclick</button>`, one with `--lwc-color-text-default`) to confirm each rule actually fires and drops the score below the relevant floor. That's a follow-up pilot, not a finding against this iteration.

**Calibration verdict: rules are well-calibrated for the clean case. Sensitivity testing (deliberate-failure pilot) is needed to confirm precision on the dirty case. Recommend that as Stage B pilot #3.**

---

## 13. Critical gaps (hard-fail breaches)

**None.** The verdict is SHIP.

---

## 14. Remediation if ITERATE

N/A — verdict is SHIP. No EVAL-FEEDBACK.md written.
