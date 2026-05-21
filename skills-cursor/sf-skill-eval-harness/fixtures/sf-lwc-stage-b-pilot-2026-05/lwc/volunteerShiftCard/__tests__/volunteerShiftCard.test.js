import { createElement } from 'lwc';
import VolunteerShiftCard from 'c/volunteerShiftCard';
import { getRecord } from 'lightning/uiRecordApi';
import signUp from '@salesforce/apex/VolunteerSignupController.signUp';

// ---- Mocks --------------------------------------------------------------------------------

// Apex method mock
jest.mock(
    '@salesforce/apex/VolunteerSignupController.signUp',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

// Schema imports
jest.mock(
    '@salesforce/schema/VolunteerShift__c.Name',
    () => ({ default: 'VolunteerShift__c.Name' }),
    { virtual: true }
);
jest.mock(
    '@salesforce/schema/VolunteerShift__c.Start__c',
    () => ({ default: 'VolunteerShift__c.Start__c' }),
    { virtual: true }
);
jest.mock(
    '@salesforce/schema/VolunteerShift__c.End__c',
    () => ({ default: 'VolunteerShift__c.End__c' }),
    { virtual: true }
);
jest.mock(
    '@salesforce/schema/VolunteerShift__c.Capacity__c',
    () => ({ default: 'VolunteerShift__c.Capacity__c' }),
    { virtual: true }
);
jest.mock(
    '@salesforce/schema/VolunteerShift__c.SignupsCount__c',
    () => ({ default: 'VolunteerShift__c.SignupsCount__c' }),
    { virtual: true }
);
jest.mock(
    '@salesforce/schema/VolunteerShift__c.Description__c',
    () => ({ default: 'VolunteerShift__c.Description__c' }),
    { virtual: true }
);
jest.mock(
    '@salesforce/schema/VolunteerShift__c.Site__r.Name',
    () => ({ default: 'VolunteerShift__c.Site__r.Name' }),
    { virtual: true }
);

// ---- Helpers ------------------------------------------------------------------------------

const SHIFT_ID = 'a01000000000001AAA';
const CONTACT_ID = '003000000000002BBB';

function buildRecord({ capacity = 5, signups = 2, description = 'Bring water bottles.' } = {}) {
    return {
        apiName: 'VolunteerShift__c',
        id: SHIFT_ID,
        fields: {
            Name: { value: 'Saturday Park Cleanup' },
            Start__c: { value: '2026-06-15T13:00:00.000Z' },
            End__c: { value: '2026-06-15T16:00:00.000Z' },
            Capacity__c: { value: capacity },
            SignupsCount__c: { value: signups },
            Description__c: { value: description },
            Site__r: { value: { fields: { Name: { value: 'Riverside Park' } } } }
        }
    };
}

async function flushPromises() {
    return new Promise((resolve) => setImmediate(resolve));
}

function createCard(props = {}) {
    const element = createElement('c-volunteer-shift-card', { is: VolunteerShiftCard });
    Object.assign(element, { shiftId: SHIFT_ID, ...props });
    document.body.appendChild(element);
    return element;
}

// ---- Lifecycle ----------------------------------------------------------------------------

describe('c-volunteer-shift-card', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    // TC-U1: shiftId setter drives the wire adapter
    it('passes shiftId to the wire adapter', async () => {
        const element = createCard({ shiftId: SHIFT_ID });
        await flushPromises();

        const lastConfig = getRecord.getLastConfig();
        expect(lastConfig).toBeTruthy();
        expect(lastConfig.recordId).toBe(SHIFT_ID);
        expect(Array.isArray(lastConfig.fields)).toBe(true);
        expect(lastConfig.fields.length).toBeGreaterThanOrEqual(7);
    });

    // TC-U2: allowSignup gates the Sign Up button
    it('does not render Sign Up button when allowSignup is false (default)', async () => {
        const element = createCard();
        getRecord.emit(buildRecord());
        await flushPromises();

        const button = element.shadowRoot.querySelector('[data-id="signup-button"]');
        expect(button).toBeNull();
    });

    it('renders Sign Up button when allowSignup is true and capacity remains', async () => {
        const element = createCard({ allowSignup: true });
        getRecord.emit(buildRecord({ capacity: 5, signups: 2 }));
        await flushPromises();

        const button = element.shadowRoot.querySelector('[data-id="signup-button"]');
        expect(button).not.toBeNull();
        expect(button.label).toBe('Sign Up');
    });

    // TC-U3: compactMode toggles description visibility
    it('hides description when compactMode is true', async () => {
        const element = createCard({ compactMode: true });
        getRecord.emit(buildRecord());
        await flushPromises();

        const description = element.shadowRoot.querySelector('[data-id="description"]');
        expect(description).toBeNull();

        // Other meta still rendered
        expect(element.shadowRoot.textContent).toContain('Riverside Park');
    });

    it('renders description when compactMode is false (default)', async () => {
        const element = createCard();
        getRecord.emit(buildRecord());
        await flushPromises();

        const description = element.shadowRoot.querySelector('[data-id="description"]');
        expect(description).not.toBeNull();
    });

    // TC-U4: wire response renders fields
    it('renders shift name, site, and spots remaining from the wire response', async () => {
        const element = createCard();
        getRecord.emit(buildRecord({ capacity: 10, signups: 3 }));
        await flushPromises();

        const text = element.shadowRoot.textContent;
        expect(text).toContain('Riverside Park');
        expect(text).toContain('7'); // 10 - 3 spots remaining
        expect(text).toContain('remaining');
    });

    // TC-U5: capacity-full state — no button + accessible "Full" indicator
    it('shows a "Full" indicator and hides the Sign Up button when capacity is reached', async () => {
        const element = createCard({ allowSignup: true });
        getRecord.emit(buildRecord({ capacity: 4, signups: 4 }));
        await flushPromises();

        const button = element.shadowRoot.querySelector('[data-id="signup-button"]');
        expect(button).toBeNull();

        const text = element.shadowRoot.textContent;
        expect(text).toContain('Full');
    });

    // TC-U6 + TC-U7 + TC-S1: full happy-path including synchronous disable & event dispatch
    it('disables Sign Up synchronously on click and dispatches signupcomplete on Apex success', async () => {
        signUp.mockResolvedValue(CONTACT_ID);

        const element = createCard({ allowSignup: true });
        getRecord.emit(buildRecord({ capacity: 5, signups: 1 }));
        await flushPromises();

        const eventHandler = jest.fn();
        element.addEventListener('signupcomplete', eventHandler);

        const button = element.shadowRoot.querySelector('[data-id="signup-button"]');
        expect(button).not.toBeNull();
        expect(button.disabled).toBe(false);

        // Click — fires the handler synchronously.
        button.click();

        // Immediately (before promise resolves), the button must be disabled.
        // The component sets _submitting = true synchronously; one microtask flush propagates it.
        await Promise.resolve();
        const buttonAfterClick = element.shadowRoot.querySelector('[data-id="signup-button"]');
        expect(buttonAfterClick.disabled).toBe(true);

        // Resolve the Apex promise and assert event payload.
        await flushPromises();

        expect(signUp).toHaveBeenCalledWith({ shiftId: SHIFT_ID });
        expect(eventHandler).toHaveBeenCalledTimes(1);
        const dispatched = eventHandler.mock.calls[0][0];
        expect(dispatched.detail).toBeDefined();
        expect(dispatched.detail.shiftId).toBe(SHIFT_ID);
        expect(dispatched.detail.contactId).toBe(CONTACT_ID);
    });

    // TC-U8: error path re-enables the button and does not fire signupcomplete
    it('re-enables Sign Up and skips signupcomplete when Apex rejects', async () => {
        signUp.mockRejectedValue({ body: { message: 'No capacity' } });

        const element = createCard({ allowSignup: true });
        getRecord.emit(buildRecord({ capacity: 3, signups: 1 }));
        await flushPromises();

        const eventHandler = jest.fn();
        element.addEventListener('signupcomplete', eventHandler);

        const button = element.shadowRoot.querySelector('[data-id="signup-button"]');
        button.click();
        await flushPromises();

        const buttonAfter = element.shadowRoot.querySelector('[data-id="signup-button"]');
        expect(buttonAfter.disabled).toBe(false);
        expect(eventHandler).not.toHaveBeenCalled();
    });

    // Bonus: detail.contactId support when Apex returns an object with a contactId key
    it('accepts an object return shape with explicit contactId from Apex', async () => {
        signUp.mockResolvedValue({ contactId: CONTACT_ID, status: 'ok' });

        const element = createCard({ allowSignup: true });
        getRecord.emit(buildRecord());
        await flushPromises();

        const eventHandler = jest.fn();
        element.addEventListener('signupcomplete', eventHandler);

        element.shadowRoot.querySelector('[data-id="signup-button"]').click();
        await flushPromises();

        expect(eventHandler).toHaveBeenCalledTimes(1);
        expect(eventHandler.mock.calls[0][0].detail.contactId).toBe(CONTACT_ID);
    });
});
