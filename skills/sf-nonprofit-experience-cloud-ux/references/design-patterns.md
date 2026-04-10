# Design Patterns Reference

## Component Patterns for Nonprofit Portals

### Hero Banner

The primary visual element on the home page. Communicates mission and provides entry points.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│    Background: mission-aligned photography              │
│    Overlay: semi-transparent brand color                │
│                                                         │
│    Headline: "Hope Lives Here"                          │
│    Subtext: "Making a difference in our community"      │
│                                                         │
│    [Get Started]  [Learn More]                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Implementation:**
- Use `background-image` with overlay for text readability
- Minimum contrast: 4.5:1 for text over image
- Responsive: stack CTA buttons on mobile
- Alt text on background image for screen readers
- Lazy load hero image for performance

### Quick Action Card

Three-column card layout for primary portal actions.

```
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│    [Icon]     │  │    [Icon]     │  │    [Icon]     │
│               │  │               │  │               │
│  My Profile   │  │  My Hours     │  │  Background   │
│               │  │               │  │  Checks       │
│  Update your  │  │  View your    │  │               │
│  info         │  │  schedule     │  │  Submit new   │
│               │  │               │  │               │
│  [View →]     │  │  [View →]     │  │  [Submit →]   │
└───────────────┘  └───────────────┘  └───────────────┘
```

**Implementation:**
- Equal-height cards using CSS Grid or Flexbox
- Icon: SLDS utility icon or custom SVG
- Hover state: subtle elevation or border change
- Mobile: stack to single column
- Keyboard: entire card is focusable and activatable

### Status Badge

Visual indicator for record status.

| Status | Color | Icon | Example |
|--------|-------|------|---------|
| Active/Approved | Green | checkmark | `✓ Approved` |
| Pending | Amber | clock | `◷ Pending Review` |
| Submitted | Blue | send | `↗ Submitted` |
| Draft | Gray | edit | `✎ Draft` |
| Declined/Rejected | Red | close | `✕ Not Approved` |
| Expired | Gray | warning | `⚠ Expired` |

**Accessibility:** Never use color alone. Always include icon + text label.

### Record List Card

Card-based list item for portal record lists.

```
┌─────────────────────────────────────────────────────────┐
│  [Status Badge: Pending]                    March 2026  │
│                                                         │
│  Volunteer Background Check                             │
│  Examination: Annual Volunteer Check                    │
│                                                         │
│  [View Details →]                                       │
└─────────────────────────────────────────────────────────┘
```

**Implementation:**
- Card border-left color indicates status (supplementary to badge)
- Key info visible without clicking into detail
- Action button/link right-aligned or at bottom
- Mobile: full-width cards with adequate padding

---

## Page Layout Templates

### Dashboard Home

For portals with multiple data points (donor, board).

```
┌──────────────┬──────────────┬──────────────┐
│  Metric 1    │  Metric 2    │  Metric 3    │
│  Total Given │  This Year   │  Impact      │
│  $12,450     │  $3,200      │  42 served   │
├──────────────┴──────────────┴──────────────┤
│  Chart: Giving Over Time                    │
├─────────────────────┬──────────────────────┤
│  Recent Activity    │  Upcoming Events      │
│  - Gift $100 3/15   │  - Gala 4/20         │
│  - Gift $50 2/28    │  - Walk 5/10         │
└─────────────────────┴──────────────────────┘
```

### Application Form

Multi-step form for complex submissions (grants, programs).

```
Step 2 of 5: Organization Details
[●━━━━●━━━━○━━━━○━━━━○]

Organization Name *
┌─────────────────────────────────────────────┐
│  City Union Community Services              │
└─────────────────────────────────────────────┘

EIN / Tax ID *
┌─────────────────────────────────────────────┐
│  12-3456789                                 │
└─────────────────────────────────────────────┘

Annual Operating Budget *
┌─────────────────────────────────────────────┐
│  $500,000 - $1,000,000              [▼]     │
└─────────────────────────────────────────────┘

⚠ Fields marked with * are required

┌──────────┐  ┌────────────────┐  ┌──────────┐
│  ← Back  │  │  Save Draft    │  │  Next →  │
└──────────┘  └────────────────┘  └──────────┘
```

---

## Responsive Grid System

### Grid Specifications

| Screen | Columns | Gutter | Margin |
|--------|---------|--------|--------|
| Phone (<576px) | 4 | 16px | 16px |
| Tablet (576-1024px) | 8 | 24px | 24px |
| Desktop (>1024px) | 12 | 24px | auto (max-width: 1200px) |

### Component Sizing by Breakpoint

| Component | Phone | Tablet | Desktop |
|-----------|-------|--------|---------|
| Quick Action Cards | 4 col (full) | 4 col (2-up) | 4 col (3-up) |
| Record List Cards | 4 col (full) | 8 col (full) | 8 col (2/3) |
| Side Panel | Hidden (toggle) | 3 col | 4 col |
| Hero Banner | 4 col (full) | 8 col (full) | 12 col (full) |
| Form Fields | 4 col (full) | 6 col (3/4) | 6 col (1/2) |

---

## Loading States

### Skeleton Screens

Use skeleton placeholders instead of spinners for better perceived performance.

```
┌─────────────────────────────────────────────┐
│  ████████████████                           │
│  ██████████████████████████████████         │
│  ████████████████████████                   │
│                                             │
│  ████████████████                           │
│  ██████████████████████████████████         │
└─────────────────────────────────────────────┘
```

### Loading Patterns

| Context | Pattern | Duration Threshold |
|---------|---------|-------------------|
| Page load | Skeleton screen | >200ms |
| Form submit | Button spinner + disable | Immediate |
| Data refresh | Inline spinner | >500ms |
| File upload | Progress bar with percentage | Immediate |
| Long operation | Progress bar + cancel option | >3s |

---

## Empty States

When a list or section has no data, provide helpful empty states.

```
┌─────────────────────────────────────────────┐
│                                             │
│           [Illustration/Icon]                │
│                                             │
│      No background checks yet               │
│                                             │
│   Submit your first background check to      │
│   get started with volunteering.             │
│                                             │
│      [Submit Background Check]               │
│                                             │
└─────────────────────────────────────────────┘
```

**Requirements:**
- Friendly illustration or icon (not a blank page)
- Clear explanation of what belongs here
- Action to create the first record
- Tone: encouraging, not punitive

---

## Notification Patterns

### Toast Messages

| Type | Duration | Color | Use |
|------|----------|-------|-----|
| Success | 5 seconds, auto-dismiss | Green | Record created, saved |
| Info | 5 seconds, auto-dismiss | Blue | Status update, FYI |
| Warning | Manual dismiss | Amber | Deadline approaching |
| Error | Manual dismiss | Red | Save failed, validation error |

### In-Page Alerts

For persistent messages that shouldn't be missed:

```
┌─ ⚠ Warning ──────────────────────────────────┐
│  Your background check expires in 30 days.    │
│  [Renew Now]                          [✕]     │
└───────────────────────────────────────────────┘
```

---

## Imagery Guidelines

### Photography

| Do | Don't |
|----|-------|
| Authentic photos of community members (with consent) | Generic stock photos |
| Diverse representation | Homogeneous imagery |
| Action shots (people doing, building, learning) | Posed/staged photos |
| Local context (recognizable places, events) | Generic cityscapes |
| Optimized file size (WebP, lazy load) | Uncompressed large images |

### Iconography

- Use SLDS utility icons as baseline
- Custom icons: consistent style (line weight, corner radius)
- Meaningful icons that supplement text, not replace it
- Avoid ambiguous icons without labels
