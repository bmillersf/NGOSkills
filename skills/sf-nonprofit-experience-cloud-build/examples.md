# Examples — Nonprofit Experience Cloud Build

Concrete LWC patterns distilled from the <Org> Donor Portal reference implementation. Adapt the shapes; replace the content with the target organization's brand and content.

## Example 1 — Branded header with navigation

Renders a logo from a static resource, navigates via `basePath`, and has a primary CTA. Uses `standard__webPage` navigation so it works for both authenticated and guest users on custom routes.

**`donorPortalHeader.js`**

```javascript
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';
import ASSETS from '@salesforce/resourceUrl/orgAssets';

export default class DonorPortalHeader extends NavigationMixin(LightningElement) {
    @api donorName;

    logoUrl = ASSETS + '/logo.png';

    get donateHref() {
        return `${basePath}/donate`;
    }

    get homeHref() {
        return `${basePath}/`;
    }

    handleDonateClick(event) {
        event?.preventDefault?.();
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: this.donateHref }
        });
    }

    handleNavClick(event) {
        event.preventDefault();
        const path = event.currentTarget.dataset.path || '';
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: `${basePath}/${path}` }
        });
    }
}
```

**`donorPortalHeader.html`**

```html
<template>
    <header class="header">
        <a class="header-logo" href={homeHref} onclick={handleNavClick} data-path="">
            <img class="logo-img" src={logoUrl} alt="Organization logo" />
        </a>
        <nav class="header-nav">
            <a href="#" class="nav-link" data-path="" onclick={handleNavClick}>Home</a>
            <a href="#" class="nav-link" data-path="giving-history" onclick={handleNavClick}>My Giving</a>
        </nav>
        <div class="header-actions">
            <a href={donateHref} class="donate-btn adp-cta-donate" onclick={handleDonateClick}>
                Donate
            </a>
        </div>
    </header>
</template>
```

## Example 2 — Opportunities grid with deep-linked tiles

Tiles that pre-fill the donation form's fund selection via URL parameters.

**`givingOpportunitiesGrid.js`**

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';
import ASSETS from '@salesforce/resourceUrl/orgAssets';

export default class GivingOpportunitiesGrid extends NavigationMixin(LightningElement) {
    opportunities = [
        {
            id: 'annual-appeal-2026',
            title: "Annual Appeal 2026",
            description: 'Support diocesan ministries and services.',
            fund: "Annual Appeal 2026",
            image: ASSETS + '/tile-bla.jpg'
        },
        {
            id: 'seminarian-education',
            title: 'Seminarian Education',
            description: 'Form the next generation of priests.',
            fund: 'Seminarian Education',
            image: ASSETS + '/tile-seminarians.jpg'
        }
    ];

    handleTileClick(event) {
        event.preventDefault();
        const fund = event.currentTarget.dataset.fund;
        const url = `${basePath}/donate?fund=${encodeURIComponent(fund)}`;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }
}
```

## Example 3 — Multi-step donation form

A four-step wizard that parses URL params on mount, tracks state locally, and navigates to a dedicated thank-you route on submit.

**`donationForm.js` (condensed)**

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';

export default class DonationForm extends NavigationMixin(LightningElement) {
    currentStep = 1;
    amount = '';
    customAmount = '';
    fund = 'General Fund';
    frequency = 'one-time';
    donorInfo = { firstName: '', lastName: '', email: '' };

    connectedCallback() {
        const params = new URLSearchParams(window.location.search);
        const fundParam = params.get('fund');
        const amountParam = params.get('amount');
        if (fundParam) this.fund = fundParam;
        if (amountParam) this.amount = amountParam;
    }

    get processingFee() {
        const base = Number(this.finalAmount) || 0;
        return +(base * 0.022 + 0.30).toFixed(2);
    }

    get totalCharge() {
        return +(Number(this.finalAmount || 0) + this.processingFee).toFixed(2);
    }

    handleNext() { this.currentStep += 1; }
    handleBack() { this.currentStep -= 1; }

    handleSubmit() {
        const params = new URLSearchParams({
            amount: String(this.finalAmount),
            total: String(this.totalCharge),
            fund: this.fund,
            frequency: this.frequency,
            name: `${this.donorInfo.firstName} ${this.donorInfo.lastName}`,
            email: this.donorInfo.email
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: `${basePath}/donate-thank-you?${params.toString()}` }
        });
    }
}
```

## Example 4 — Thank-you page consuming URL params

**`donationThankYou.js` (condensed)**

```javascript
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import basePath from '@salesforce/community/basePath';

export default class DonationThankYou extends NavigationMixin(LightningElement) {
    amount = '';
    total = '';
    fund = '';
    donorName = '';
    confirmationId = '';

    connectedCallback() {
        const params = new URLSearchParams(window.location.search);
        this.amount = params.get('amount') || '';
        this.total = params.get('total') || '';
        this.fund = params.get('fund') || 'General Fund';
        this.donorName = params.get('name') || 'Friend';
        this.confirmationId = this.generateConfirmationId();
    }

    generateConfirmationId() {
        return 'CDA-' + Date.now().toString(36).toUpperCase();
    }

    handleHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: `${basePath}/` }
        });
    }

    handleGiveAgain() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url: `${basePath}/donate` }
        });
    }
}
```

## Example 5 — Guest-aware dashboard

```javascript
import { LightningElement, wire } from 'lwc';
import isGuest from '@salesforce/user/isGuest';
import getDonorSummary from '@salesforce/apex/DonorPortalController.getDonorSummary';

export default class DonorDashboard extends LightningElement {
    isGuestUser = isGuest;
    summary;
    error;

    @wire(getDonorSummary)
    wiredSummary({ data, error }) {
        if (this.isGuestUser) return;
        if (data) this.summary = data;
        else if (error) this.error = error;
    }

    get showDashboard() {
        return !this.isGuestUser;
    }
}
```

```html
<template>
    <template lwc:if={showDashboard}>
        <section class="adp-card dashboard">
            <h2 class="adp-serif">Welcome back</h2>
            <!-- summary stats, recurring gifts, etc. -->
        </section>
    </template>
</template>
```

## Example 6 — Composed home view

`experiences/<Site>/views/home.json` showing the composition — each component is a purposeful LWC, layered top-to-bottom to match the reference website's IA.

```json
{
  "componentName": "siteforce:dynamicLayout",
  "regions": [
    {
      "regionName": "content",
      "components": [
        { "componentName": "c:donorPortalHeader" },
        { "componentName": "c:donorHeroBanner" },
        { "componentName": "c:givingOpportunitiesGrid" },
        { "componentName": "c:donorDashboard" },
        { "componentName": "c:pullQuoteBanner" },
        { "componentName": "c:upcomingEvents" }
      ]
    }
  ]
}
```

(Abbreviated — production view includes `forceCommunity:section` wrappers and IDs.)

## Reference implementation

All patterns above are live in the **<Org> Donor Portal** reference repo:

- Static resource: `force-app/main/default/staticresources/orgAssets/`
- Theme `customCSS`: `force-app/main/default/experiences/Donor_Portal1/themes/customerAccountPortal.json`
- LWCs: `force-app/main/default/lwc/donorPortalHeader`, `donorHeroBanner`, `givingOpportunitiesGrid`, `pullQuoteBanner`, `upcomingEvents`, `donorDashboard`, `donationForm`, `donationThankYou`
- Routes and views: `force-app/main/default/experiences/Donor_Portal1/routes/donate.json`, `views/donate.json`, `routes/donateThankYou.json`, `views/donateThankYou.json`
- Guest profile config: `force-app/main/default/profiles/<Org> Donor Portal Profile.profile-meta.xml`
- Network live status: `force-app/main/default/networks/<Org> Donor Portal.network-meta.xml`
