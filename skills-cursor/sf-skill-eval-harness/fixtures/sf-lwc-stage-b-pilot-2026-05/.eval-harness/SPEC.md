# SPEC — volunteer-shift-card LWC

## 1. Goal

Generate a self-contained `volunteerShiftCard` Lightning Web Component bundle (`.js`, `.html`, `.css`, `.js-meta.xml`, and `__tests__/*.test.js`) that displays a single VolunteerShift__c record fetched via `@wire(getRecord, ...)`, exposes the three documented `@api` properties, conditionally renders a Sign Up button that calls the assumed `VolunteerSignupController.signUp` Apex method and dispatches a `signupcomplete` CustomEvent on success, and which is verifiably accessible, theme-token-only, and Jest-tested.

## 2. Acceptance Criteria

Every AC below is independently checkable by reading the artifact files (no org deploy required for AC verification).

### Component identity & metadata

- **AC-1** — A directory `volunteerShiftCard/` exists containing exactly four sibling source files (`volunteerShiftCard.js`, `volunteerShiftCard.html`, `volunteerShiftCard.css`, `volunteerShiftCard.js-meta.xml`) plus a `__tests__/` subdirectory.
- **AC-2** — `volunteerShiftCard.js-meta.xml` is well-formed XML, declares `<isExposed>true</isExposed>`, and includes at minimum the targets `lightning__RecordPage`, `lightning__AppPage`, and `lightningCommunity__Page` (Experience Cloud is the documented consumer).
- **AC-3** — `volunteerShiftCard.js-meta.xml` declares an `apiVersion` of `60.0` or higher.

### Public API contract (`@api` properties)

- **AC-4** — The JS module exports a default class extending `LightningElement` and declares three public properties via `@api`: `shiftId` (string), `allowSignup` (boolean, default `false`), and `compactMode` (boolean, default `false`). Defaults are realized either via class field initializers or via getter/setter pairs that return the documented default when the parent has not set the property.
- **AC-5** — Setting `allowSignup = false` (the default) results in zero `<lightning-button>` (or any button element) with the Sign Up label being rendered, regardless of capacity.
- **AC-6** — Setting `compactMode = true` results in the description region not being rendered (no DOM nodes carrying the description body); name, time range, site name, and capacity remain rendered.

### Wire service & data binding

- **AC-7** — The component uses `@wire(getRecord, { recordId: '$shiftId', fields: [...] })` (imported from `lightning/uiRecordApi`) and the fields list contains references to all of: `Name`, `Start__c`, `End__c`, `Capacity__c`, `SignupsCount__c`, `Description__c`, and `Site__r.Name` on the `VolunteerShift__c` object. Field references use the schema-import form (`@salesforce/schema/VolunteerShift__c.Name` etc.) rather than raw strings.
- **AC-8** — The template renders the shift name, the start/end datetime range using a Lightning base formatter component (e.g. `lightning-formatted-date-time`), the site name, and a "spots remaining" value computed as `Capacity__c - SignupsCount__c`.
- **AC-9** — When spots remaining equals 0, the template applies a visual treatment that is **not conveyed by color alone** — i.e., text content (e.g., "Full") or a non-decorative icon with accessible label is present, in addition to any styling change. (This is verifiable by reading the template: a `<template lwc:if={isFull}>` branch must contain text or a labeled icon, not only a CSS class change.)
- **AC-10** — The Sign Up button is rendered only when both `allowSignup` is true AND spots remaining > 0. When either condition is false, no Sign Up button element is in the DOM.

### Sign-up interaction

- **AC-11** — The Sign Up button click handler imports and calls the Apex method `VolunteerSignupController.signUp` from `@salesforce/apex/VolunteerSignupController.signUp` and passes the `shiftId` as a parameter.
- **AC-12** — Immediately on click (synchronously, before the Apex promise settles), the button's `disabled` attribute becomes `true`. This is verifiable by inspecting the click-handler logic in JS and the template's `disabled={...}` binding.
- **AC-13** — On Apex success, the component dispatches a `CustomEvent` with type `signupcomplete` whose `detail` is an object containing `shiftId` (the component's current `shiftId`) and `contactId` (the value returned from the Apex method, or extracted from the resolved promise per the implementer's choice — but the `contactId` key MUST be present in `detail`).
- **AC-14** — On Apex error, the button's `disabled` attribute returns to `false`, and the component shows an error toast (via `lightning/platformShowToastEvent` or equivalent) whose message includes the rejected error's message text.
- **AC-15** — On Apex success, the component shows a success toast (via `lightning/platformShowToastEvent` or equivalent).

### Accessibility (verifiable by static analysis of `.html`)

- **AC-16** — Every `<button>` element and every `<a>` element in the rendered template has either visible text content OR an `aria-label` attribute OR an `aria-labelledby` attribute. ("Visible text content" includes a child `<lightning-icon>` with an `alternative-text` attribute as the accessible label of an icon-only button, AS LONG AS the parent button itself also has text or aria-label.)
- **AC-17** — Every `<img>` element in the template has an `alt` attribute (empty `alt=""` is acceptable for purely decorative images; missing `alt` is not).
- **AC-18** — Any custom interactive widget — defined as a non-`<button>`/`<a>`/`<input>`/`<select>`/`<textarea>` element that has an `onclick`, `onkeydown`, `onkeyup`, or `onkeypress` template handler — has all of: a `role` attribute, a `tabindex` attribute, AND a keyboard handler (`onkeydown` or `onkeyup` or `onkeypress`) in addition to any click handler.
- **AC-19** — Form inputs (`<input>`, `<select>`, `<textarea>`, or any `<lightning-input*>` family component) have either a `label` attribute, an associated `<label for="...">`, an `aria-label`, or an `aria-labelledby`.

### Theming, SLDS 2, Dark Mode (verifiable by static analysis of `.css`)

- **AC-20** — `volunteerShiftCard.css` contains no hardcoded color values. Specifically: no `#` followed by 3, 4, 6, or 8 hexadecimal characters as a CSS color value; no `rgb(` or `rgba(` function calls; no `hsl(` or `hsla(` function calls; no CSS named colors (`red`, `blue`, `white`, `black`, `gray`, etc.) used as color values. All color references resolve to `var(--slds-g-color-*)` design tokens.
- **AC-21** — `volunteerShiftCard.css` contains no references to `--lwc-*` CSS custom properties (these are SLDS 1 deprecated tokens).
- **AC-22** — Neither `volunteerShiftCard.css` nor inline `style=` attributes in `volunteerShiftCard.html` contain the string `!important`.
- **AC-23** — Neither `volunteerShiftCard.css` nor `volunteerShiftCard.html` contains any reference to deprecated SLDS 1 utility class names. Specifically forbidden patterns include (non-exhaustive but probed by the evaluator): `slds-text-color_default`, `slds-text-color_inverse`, `slds-text-color_weak`, `slds-text-color_error`, `slds-text-heading_*` (deprecated heading utilities replaced by SLDS 2 typography hooks), `slds-theme_default`, and any other SLDS 1 token-bearing utility superseded in SLDS 2.

### Component structure & libraries

- **AC-24** — The template uses Lightning base components for the structural primitives where they exist: a `lightning-card` wraps the component body, a `lightning-button` is used for the Sign Up action (not a raw `<button>`), and `lightning-formatted-date-time` (or `lightning-formatted-time` + `lightning-formatted-date`) is used for the start/end datetime values.
- **AC-25** — `volunteerShiftCard.js` does not contain `document.querySelector`, `document.getElementById`, or `document.getElementsByClassName` calls targeting the component's own internal DOM. (Use of `this.template.querySelector` is permitted.)

### Reactivity model

- **AC-26** — `volunteerShiftCard.js` does not apply `@track` to a primitive (string, number, boolean) field. (`@track` is only legitimate on objects/arrays where deep reactivity is needed; primitives are reactive by default.)
- **AC-27** — `volunteerShiftCard.js` does not contain logic that mutates an `@api` property from within the component (e.g., `this.shiftId = ...` outside of an explicit setter that the parent invokes). Setters for `@api` properties may store derived values into private fields.

### Performance

- **AC-28** — `volunteerShiftCard.js` does not invoke `fetch(`, `XMLHttpRequest`, or any imperative Apex call from within a getter, from `render()`, or from `renderedCallback()`.
- **AC-29** — The component bundle does not import a stylesheet from outside its own bundle directory. `volunteerShiftCard.css` is the only stylesheet loaded by the component.

### Tests (Jest unit tests in `__tests__/`)

- **AC-30** — A file `__tests__/volunteerShiftCard.test.js` exists.
- **AC-31** — The Jest test file covers, at minimum, named test cases for: (a) setting each of the three `@api` properties and asserting the rendered DOM responds correctly; (b) the wire response (mocked via `@salesforce/sfdx-lwc-jest` wire adapter test utilities) populating the displayed fields; (c) the Sign Up button being absent when `allowSignup=false`; (d) the Sign Up button being absent when capacity is full even with `allowSignup=true`; (e) the Sign Up button click disabling the button synchronously and then dispatching `signupcomplete` with the correct `detail` shape on Apex success; (f) the Sign Up button click handling Apex error by re-enabling the button.
- **AC-32** — The test file uses `@salesforce/sfdx-lwc-jest` conventions: `createElement` from `lwc`, `document.body.appendChild`, and either `flushPromises` or `await Promise.resolve()` patterns to handle reactivity. Apex calls are mocked via `jest.mock('@salesforce/apex/...')`.
- **AC-33** — Test count and coverage: at least one assertion per public API surface element (3 `@api` properties + 1 dispatched event + 1 Apex method invocation = at least 5 distinct assertion targets), and the test file declares ≥6 `it(...)` or `test(...)` cases.

## 3. Out of Scope (the implementer MUST NOT do these)

- **OOS-1** — Do not run `sf project deploy start` or attempt to deploy the component to any org. The deliverable is source files only.
- **OOS-2** — Do not author or modify the Apex controller `VolunteerSignupController`. It is assumed to exist with a `@AuraEnabled` `signUp(String shiftId)` method.
- **OOS-3** — Do not author the parent dashboard component, the Experience Cloud page, FlexiPage XML, or any list-rendering wrapper.
- **OOS-4** — Do not implement pagination, filtering, sorting, or any multi-shift list logic.
- **OOS-5** — Do not author additional LWCs beyond `volunteerShiftCard`.
- **OOS-6** — Do not write end-to-end Playwright / Selenium tests. Jest is the only test layer required.
- **OOS-7** — Do not modify any file outside the `volunteerShiftCard/` bundle directory.

## 4. Test Plan

The implementer must produce tests in the following named cases. Naming is illustrative — the implementer chooses exact `describe`/`it` strings — but each named behavior MUST be exercised by at least one test case.

### Unit tests (Jest, in `__tests__/volunteerShiftCard.test.js`)

- **TC-U1 — `@api shiftId` setter** — Setting `shiftId` after `appendChild` causes the wire adapter to receive the new id (verified via the `@salesforce/sfdx-lwc-jest` wire adapter mock).
- **TC-U2 — `@api allowSignup` toggle** — Default (`false`) renders no Sign Up button. Setting `allowSignup = true` (with capacity available) renders the Sign Up button.
- **TC-U3 — `@api compactMode` toggle** — Default (`false`) renders the description region. Setting `compactMode = true` removes the description region from the DOM while leaving name, time, capacity, site visible.
- **TC-U4 — Wire response renders fields** — Emit a mock record via the wire adapter; assert that the rendered DOM contains the mocked values for shift name, datetime range, site name, and computed spots remaining.
- **TC-U5 — Capacity full state** — Emit a wire record where `Capacity__c === SignupsCount__c`; assert (a) no Sign Up button is rendered even with `allowSignup=true`, and (b) text or a labeled icon indicating the full state is present in the DOM.
- **TC-U6 — Sign Up click disables synchronously** — With `allowSignup=true` and capacity available, click the Sign Up button. In the same microtask cycle (before resolving the Apex promise), assert the button's `disabled` property is `true`.
- **TC-U7 — Sign Up success dispatches `signupcomplete`** — Mock the Apex method to resolve with a contactId value. Click Sign Up. Assert a `signupcomplete` CustomEvent fires with `detail.shiftId` matching the component's `shiftId` and `detail.contactId` present.
- **TC-U8 — Sign Up error re-enables** — Mock the Apex method to reject. Click Sign Up. After the rejection settles, assert the button's `disabled` property returns to `false`, and assert that no `signupcomplete` event was dispatched.

### Integration test (lightweight, no live org for this pilot)

- **TC-I1 — Metadata XML validates** — `volunteerShiftCard.js-meta.xml` parses as well-formed XML, declares `<isExposed>true</isExposed>`, includes at least the three required targets, and declares a Spring '26-compatible `apiVersion`. (The evaluator will probe this by parsing the XML; a real org deploy is out of scope per OOS-1.)

### Smoke test

- **TC-S1 — End-to-end primary user interaction** — A Jest test simulates the full coordinator user path: component is created, `shiftId` is set, wire adapter emits a record with available capacity, `allowSignup` is set to `true`, the Sign Up button is found in the rendered DOM, the button is clicked, the mocked Apex resolves, and a `signupcomplete` event is captured by an attached listener with the correct `detail` payload. (This may be the same test as TC-U7 with the additional `appendChild + listener attachment + full chain` flow made explicit, but it MUST exist as its own named test case asserting the entire chain end-to-end.)

## 5. Rubric

Scoring is delegated to the target skill `sf-lwc`. The 4-dimension shape, max points, and hard-fail floors are defined in the `lwc_dimensions` block of `sf-lwc/SKILL.md` frontmatter, mapped onto the underlying 165-point rubric in `sf-lwc/references/scoring-and-testing.md` (8 categories: SLDS Class Usage, Accessibility, Dark Mode Readiness, SLDS Migration, Styling Hooks, Component Structure, Performance, PICKLES Compliance). The evaluator owns the rubric and the hard-fail enforcement; the implementer fits to the ACs above.

The binary test rubric (unit + integration + smoke) is also defined in the `sf-lwc/SKILL.md` `test_rubric` block. All three must be satisfied for SHIP — no partial credit.
