# LWC requirements — Volunteer Shift Card

This is a Stage B harness pilot test. The user (sf-nonprofit-experience-cloud-build, hypothetically) wants an LWC component that:

## Functional requirements

The component is named `volunteer-shift-card`. It displays a single volunteer shift in a card format. A coordinator's dashboard renders a list of these cards.

1. Accept `@api shiftId` (string, the VolunteerShift__c record Id).
2. Accept `@api allowSignup` (boolean, default false). If true, show a "Sign Up" button.
3. Accept `@api compactMode` (boolean, default false). If true, hide the description and show only name + time + capacity.
4. Use `@wire(getRecord, ...)` to fetch:
   - `Name` (shift name)
   - `Start__c`, `End__c` (datetime)
   - `Capacity__c`, `SignupsCount__c` (numbers)
   - `Description__c` (rich text)
   - `Site__r.Name` (related site name)
5. Display:
   - Shift name (heading)
   - Date + time range (formatted, locale-aware)
   - Site name
   - Spots remaining (Capacity__c - SignupsCount__c) with visual treatment if 0 (full)
   - Description (only when not compactMode)
   - Sign-up button (only when allowSignup AND spots remain)
6. Sign-up button click:
   - Disable the button immediately to prevent double-click
   - Call Apex `VolunteerSignupController.signUp(shiftId)`
   - On success: dispatch `signupcomplete` custom event with `{shiftId, contactId}` detail; show success toast
   - On error: re-enable the button, show error toast with the message

## Non-functional requirements

1. **Accessible:** the component must work with keyboard navigation, screen readers, and dark mode.
2. **SLDS 2 compliant:** use only `--slds-g-color-*` design tokens. No hardcoded colors. No deprecated SLDS 1 utilities.
3. **Lightning base components:** use `lightning-card`, `lightning-button`, `lightning-formatted-date-time`, `lightning-icon` etc. where they exist instead of reimplementing.
4. **Responsive:** the card must look correct at 320px wide (mobile) up to 1200px (desktop).
5. **Test class:** Jest tests cover `@api` setters, the wire response, the sign-up button enable/disable behavior, and the event dispatch. ≥80% coverage of public surface.

## Out of scope

- Don't deploy to an org. Just generate the .html, .js, .css, .js-meta.xml, and __tests__/*.test.js files.
- Don't write the Apex controller (`VolunteerSignupController.signUp` is assumed to exist).
- Don't write the Experience Cloud page that uses the card.
- Don't handle pagination, filtering, or list rendering — that's the parent component's job.

## Audience

The downstream consumer is a coordinator's Lightning App Page on Experience Cloud (volunteer portal). Real users include screen reader users (some volunteers have visual impairments) and people on slow mobile connections. Dark Mode will be enabled on this Experience site as part of the org's accessibility initiative.
