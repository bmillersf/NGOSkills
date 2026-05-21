import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import signUp from '@salesforce/apex/VolunteerSignupController.signUp';

import NAME_FIELD from '@salesforce/schema/VolunteerShift__c.Name';
import START_FIELD from '@salesforce/schema/VolunteerShift__c.Start__c';
import END_FIELD from '@salesforce/schema/VolunteerShift__c.End__c';
import CAPACITY_FIELD from '@salesforce/schema/VolunteerShift__c.Capacity__c';
import SIGNUPS_FIELD from '@salesforce/schema/VolunteerShift__c.SignupsCount__c';
import DESCRIPTION_FIELD from '@salesforce/schema/VolunteerShift__c.Description__c';
import SITE_NAME_FIELD from '@salesforce/schema/VolunteerShift__c.Site__r.Name';

const SHIFT_FIELDS = [
    NAME_FIELD,
    START_FIELD,
    END_FIELD,
    CAPACITY_FIELD,
    SIGNUPS_FIELD,
    DESCRIPTION_FIELD,
    SITE_NAME_FIELD
];

/**
 * volunteerShiftCard
 *
 * PICKLES notes:
 *   I (Integrate)   — Lightning Data Service via @wire(getRecord) for read; imperative Apex for write.
 *   C (Composition) — @api props in (shiftId, allowSignup, compactMode); CustomEvent 'signupcomplete' out.
 *   K (Kinetics)    — Click disables button synchronously to prevent double-submit.
 *   L (Libraries)   — lightning-card, lightning-button, lightning-formatted-date-time, lightning-icon,
 *                     ShowToastEvent. No reinvented base components.
 *   E (Execution)   — Computed values exposed via getters (cached per render); no work in renderedCallback.
 *   S (Security)    — FLS/CRUD enforcement is delegated to the Apex controller (out of scope per OOS-2).
 */
export default class VolunteerShiftCard extends LightningElement {
    /** VolunteerShift__c record Id. Reactive — drives the wire adapter. */
    @api shiftId;

    /** Show the Sign Up action when capacity remains. */
    @api allowSignup = false;

    /** Hide the description region; show a denser layout. */
    @api compactMode = false;

    // Internal state — primitives are reactive without @track in modern LWC.
    _record;
    _wireError;
    _submitting = false;

    @wire(getRecord, { recordId: '$shiftId', fields: SHIFT_FIELDS })
    wiredShift({ data, error }) {
        if (data) {
            this._record = data;
            this._wireError = undefined;
        } else if (error) {
            this._record = undefined;
            this._wireError = error;
        }
    }

    // ---- Derived state (getters) ----------------------------------------------------------

    get hasRecord() {
        return Boolean(this._record);
    }

    get hasError() {
        return Boolean(this._wireError);
    }

    get errorMessage() {
        return this._wireError && this._wireError.body && this._wireError.body.message
            ? this._wireError.body.message
            : 'Unable to load this volunteer shift.';
    }

    get shiftName() {
        return getFieldValue(this._record, NAME_FIELD);
    }

    get startDateTime() {
        return getFieldValue(this._record, START_FIELD);
    }

    get endDateTime() {
        return getFieldValue(this._record, END_FIELD);
    }

    get capacity() {
        const v = getFieldValue(this._record, CAPACITY_FIELD);
        return typeof v === 'number' ? v : 0;
    }

    get signupsCount() {
        const v = getFieldValue(this._record, SIGNUPS_FIELD);
        return typeof v === 'number' ? v : 0;
    }

    get spotsRemaining() {
        const remaining = this.capacity - this.signupsCount;
        return remaining > 0 ? remaining : 0;
    }

    get description() {
        return getFieldValue(this._record, DESCRIPTION_FIELD);
    }

    get siteName() {
        return getFieldValue(this._record, SITE_NAME_FIELD);
    }

    get isFull() {
        return this.hasRecord && this.spotsRemaining <= 0;
    }

    get showDescription() {
        return !this.compactMode && Boolean(this.description);
    }

    get canSignUp() {
        return Boolean(this.allowSignup) && this.hasRecord && !this.isFull;
    }

    get signUpDisabled() {
        // Synchronously disabled while an in-flight signup is pending.
        return this._submitting;
    }

    get cardTitle() {
        return this.shiftName || 'Volunteer Shift';
    }

    get spotsLabel() {
        if (!this.hasRecord) {
            return '';
        }
        if (this.isFull) {
            return 'Full';
        }
        const word = this.spotsRemaining === 1 ? 'spot' : 'spots';
        return `${this.spotsRemaining} ${word} remaining`;
    }

    // ---- Event handlers -------------------------------------------------------------------

    handleSignUpClick() {
        if (this._submitting) {
            return;
        }
        // Synchronous disable BEFORE awaiting the Apex promise — guards against double-click.
        this._submitting = true;

        const shiftId = this.shiftId;
        signUp({ shiftId })
            .then((result) => {
                // Apex contract: returns the Contact Id of the signup record. We surface it on the event.
                const contactId =
                    result && typeof result === 'object' && 'contactId' in result
                        ? result.contactId
                        : result;

                this.dispatchEvent(
                    new CustomEvent('signupcomplete', {
                        detail: { shiftId, contactId },
                        bubbles: true,
                        composed: true
                    })
                );

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Signed up',
                        message: 'You are confirmed for this shift.',
                        variant: 'success'
                    })
                );
            })
            .catch((error) => {
                const message =
                    (error && error.body && error.body.message) ||
                    (error && error.message) ||
                    'Sign-up failed. Please try again.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Sign-up failed',
                        message,
                        variant: 'error'
                    })
                );
            })
            .finally(() => {
                this._submitting = false;
            });
    }
}
