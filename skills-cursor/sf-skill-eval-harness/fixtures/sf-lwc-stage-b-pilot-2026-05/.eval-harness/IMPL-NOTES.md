# IMPL-NOTES — volunteerShiftCard LWC (Stage B pilot)

## What was built

A self-contained `volunteerShiftCard` LWC bundle (`.js`, `.html`, `.css`, `.js-meta.xml`,
`__tests__/volunteerShiftCard.test.js`) that displays one `VolunteerShift__c` record fetched via
`@wire(getRecord, ...)` and conditionally exposes a Sign Up action. The component honors the three
documented `@api` properties (`shiftId`, `allowSignup`, `compactMode`), renders a "Full" textual
indicator (not color-only) when capacity is reached, calls
`@salesforce/apex/VolunteerSignupController.signUp` imperatively on click, dispatches a bubbling
`signupcomplete` `CustomEvent` with `{shiftId, contactId}` on success, and surfaces success/error
toasts via `lightning/platformShowToastEvent`.

## PICKLES architecture choices

- **I — Integrate:** `@wire(getRecord, ...)` for the read path (auto-refresh, cache-aware,
  field-level imports via `@salesforce/schema/...`); imperative Apex for the write path
  (signup). No GraphQL — single record by Id is the textbook LDS case.
- **C — Composition:** parent → child via three `@api` props; child → parent via the
  `signupcomplete` CustomEvent (bubbles + composed so a sibling list wrapper can listen at the
  host boundary). No LMS — no cross-DOM communication needed.
- **K — Kinetics:** synchronous `_submitting = true` flip in the click handler before the
  Apex promise — guards against double-click without waiting for a microtask round-trip. The
  `disabled` template binding and the test both rely on this ordering.
- **L — Libraries:** `lightning-card`, `lightning-button`, `lightning-formatted-date-time`,
  `lightning-formatted-rich-text`, `lightning-icon`, `lightning-spinner`, and
  `ShowToastEvent`. Zero raw `<button>` / `<a>` elements in the rendered tree.
- **E — Execution:** all derived values (`spotsRemaining`, `isFull`, `showDescription`,
  `canSignUp`, `cardTitle`, `spotsLabel`) are getters — LWC caches them per render. No work in
  `renderedCallback`. No imperative network calls in any getter or render path. No `@track` on
  primitives (modern LWC reactivity handles that natively).
- **S — Security:** the Apex method is the FLS/CRUD enforcement boundary (out of scope per
  OOS-2). The component does not bypass that contract.

## Test coverage

The Jest bundle declares 10 `it(...)` cases covering:

1. `shiftId` setter feeds the wire adapter (TC-U1)
2. Default `allowSignup=false` hides the button (TC-U2 negative)
3. `allowSignup=true` + capacity → button rendered (TC-U2 positive)
4. `compactMode=true` removes the description region (TC-U3 hide)
5. `compactMode=false` keeps the description region (TC-U3 show)
6. Wire response renders shift name, site, spots remaining (TC-U4)
7. Capacity-full state hides the button and shows "Full" text (TC-U5)
8. Click disables synchronously + dispatches `signupcomplete` with `{shiftId, contactId}` on
   Apex success (TC-U6 + TC-U7 + TC-S1 collapsed into one end-to-end happy-path test)
9. Apex rejection re-enables the button and suppresses `signupcomplete` (TC-U8)
10. Apex returning an object shape (`{contactId, status}`) is unwrapped correctly into
    `detail.contactId`

Public-surface coverage: 3 `@api` setters exercised, 1 wire adapter exercised, 1 imperative
Apex method exercised, 1 dispatched CustomEvent exercised. ≥80% coverage of the public
surface is satisfied.

## Spec ambiguities surfaced

- **AC-13 / Apex return shape:** the SPEC notes the implementer can choose how `contactId` is
  extracted — "the value returned from the Apex method, or extracted from the resolved promise
  per the implementer's choice". I support both shapes (raw String Id OR an object with a
  `contactId` key) in the JS, and assert both shapes in the tests. If the downstream Apex is
  later locked to one specific shape, only the assertion lines move; the component logic
  already handles both.
- **AC-9 / "Full" visual treatment:** the SPEC requires a non-color-only indicator. I render
  both a `lightning-icon` with `alternative-text="Shift full"` AND the literal text "Full"
  inside a `<template lwc:if={isFull}>` branch. Either alone would satisfy the AC; rendering
  both is belt-and-suspenders and keeps the visual cue robust under reduced-motion or
  high-contrast themes.
- **OOS-2 confirmation:** the Apex method `VolunteerSignupController.signUp(String shiftId)`
  is assumed to exist with the Aura-enabled signature. The component imports it via
  `@salesforce/apex/VolunteerSignupController.signUp` — if the controller lives in a managed
  package namespace, the import path will need updating, but that is a deployment-time
  concern outside this artifact's scope.

## Nothing was deferred

All 33 ACs in SPEC.md are addressable by reading the artifacts. The component would compile
under a Spring '26 LWC compiler. No org deploy was attempted (per OOS-1).
