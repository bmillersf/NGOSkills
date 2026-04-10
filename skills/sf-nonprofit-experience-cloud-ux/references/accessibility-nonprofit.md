# Accessibility Guide for Nonprofit Portals

## Why Accessibility Matters for Nonprofits

Nonprofit audiences are among the most diverse user groups: varying ages, abilities, languages, devices, and digital literacy levels. Many constituents (clients, elderly volunteers, people with disabilities) rely on assistive technology. Accessibility is both a legal requirement and a mission imperative.

---

## WCAG 2.1 AA Compliance Checklist

### Perceivable

| Requirement | Implementation | Test Method |
|-------------|---------------|------------|
| **Text alternatives** | `alt` on images, `aria-label` on icons | Screen reader (VoiceOver/NVDA) |
| **Captions** | Video content has captions | Manual review |
| **Color contrast** | 4.5:1 for normal text, 3:1 for large text | Contrast checker tool |
| **Color independence** | Status uses icon + text, not color alone | Grayscale screenshot test |
| **Resize** | Content usable at 200% zoom | Browser zoom test |
| **Text spacing** | Content readable with increased spacing | CSS override test |

### Operable

| Requirement | Implementation | Test Method |
|-------------|---------------|------------|
| **Keyboard navigation** | All interactive elements reachable via Tab | Tab through entire page |
| **Focus visible** | Clear focus indicator (outline or ring) | Tab and verify visual |
| **Skip links** | "Skip to main content" link at top | Tab on page load |
| **No keyboard traps** | User can Tab out of any component | Tab through modals, menus |
| **Touch targets** | Minimum 44x44px tap area | Mobile device test |
| **Motion** | Respect `prefers-reduced-motion` | OS setting + verify |

### Understandable

| Requirement | Implementation | Test Method |
|-------------|---------------|------------|
| **Language** | `lang` attribute on `<html>` | View source |
| **Labels** | All form fields have visible labels | Screen reader test |
| **Error identification** | Errors described in text, not just color | Submit invalid form |
| **Consistent navigation** | Same nav position and order on all pages | Browse multiple pages |
| **Help text** | Complex fields have instructions | Review all forms |

### Robust

| Requirement | Implementation | Test Method |
|-------------|---------------|------------|
| **Valid HTML** | Proper semantic elements | HTML validator |
| **ARIA roles** | Correct ARIA when native HTML insufficient | Screen reader test |
| **Status messages** | `aria-live` for dynamic updates | Screen reader test |
| **Component state** | `aria-expanded`, `aria-selected`, etc. | Screen reader test |

---

## Nonprofit-Specific Accessibility Patterns

### Low Digital Literacy

Many nonprofit constituents have limited technology experience.

| Pattern | Implementation |
|---------|---------------|
| Simple language | Grade 6-8 reading level for all UI text |
| Explicit instructions | "Click the green button to submit" not "Submit" |
| Confirmation steps | "Are you sure?" before destructive actions |
| Visual cues | Icons paired with text labels |
| Error recovery | Clear path to fix mistakes, undo support |
| Help documentation | Contextual help, not buried FAQ |

### Multilingual Support

| Approach | When to Use |
|----------|-------------|
| Salesforce Translation Workbench | Standard object labels and picklist values |
| Custom labels | LWC component text, button labels, help text |
| CMS content | Knowledge articles, home page content |
| Language selector | Top navigation, auto-detect browser language |

### Mobile-First for Low-Bandwidth

Many nonprofit clients access portals on mobile with limited data plans.

| Optimization | Implementation |
|-------------|---------------|
| Image optimization | WebP format, lazy loading, responsive sizes |
| Minimal JavaScript | Avoid heavy libraries, use platform components |
| Offline indication | "You appear to be offline" message |
| Reduced data | Paginate lists (10 per page), lazy load sections |
| Progressive enhancement | Core functions work without JavaScript |

---

## Screen Reader Testing Guide

### VoiceOver (macOS/iOS)

| Action | Shortcut |
|--------|----------|
| Turn on/off | Cmd + F5 |
| Read next element | VO + Right Arrow |
| Activate element | VO + Space |
| Read page summary | VO + Shift + I |
| Navigate headings | VO + Cmd + H |

### Test Scenarios

1. **Navigate home page**: Can user understand page structure from headings alone?
2. **Complete a form**: Can user fill out and submit a form without sight?
3. **Read a list**: Are list items announced with count and position?
4. **Status updates**: Are toast messages and status changes announced?
5. **Error handling**: Are form errors read aloud with field association?

---

## Keyboard Navigation Map

### Focus Order

```
1. Skip to main content link
2. Logo (linked to home)
3. Navigation menu items (left to right)
4. Profile menu
5. Main content area (top to bottom)
6. Footer links
```

### Custom Component Requirements

| Component | Keyboard Pattern |
|-----------|-----------------|
| Modal | Focus trapped inside; Esc closes; return focus to trigger |
| Dropdown menu | Arrow keys navigate; Enter selects; Esc closes |
| Tabs | Arrow keys switch tabs; Tab moves into panel |
| Accordion | Enter/Space toggles; Arrow keys move between headers |
| Date picker | Arrow keys navigate days; Enter selects |
| Data table | Arrow keys navigate cells; Enter activates actions |

---

## Color and Contrast

### Minimum Contrast Ratios

| Element | Ratio | Example |
|---------|-------|---------|
| Normal text (<18px) | 4.5:1 | Body copy, labels |
| Large text (>18px or >14px bold) | 3:1 | Headings, buttons |
| UI components | 3:1 | Borders, icons, focus rings |
| Inactive elements | No requirement | Disabled buttons (but still readable) |

### Status Colors with Alternatives

Always pair color with a text label and/or icon:

| Status | Color | Icon | Label |
|--------|-------|------|-------|
| Approved | Green (#388E3C) | ✓ checkmark | "Approved" |
| Pending | Amber (#F57C00) | ◷ clock | "Pending" |
| Rejected | Red (#D32F2F) | ✕ close | "Not Approved" |
| Draft | Gray (#757575) | ✎ edit | "Draft" |

---

## Testing Tools

| Tool | Purpose | Free |
|------|---------|------|
| axe DevTools | Automated accessibility audit | Yes (basic) |
| Lighthouse | Performance + accessibility audit | Yes |
| WAVE | Visual accessibility evaluation | Yes |
| Color Contrast Analyzer | Precise contrast measurement | Yes |
| VoiceOver (macOS) | Screen reader testing | Built-in |
| NVDA (Windows) | Screen reader testing | Free |
| Mobile accessibility scanner (Android) | Mobile testing | Free |

---

## Common Fixes

| Issue | Fix |
|-------|-----|
| Image without alt text | Add descriptive `alt`; decorative images use `alt=""` |
| Link with no text | Add `aria-label` or visible text |
| Form field without label | Add `<label>` element or `aria-label` |
| Low contrast text | Increase contrast to 4.5:1 minimum |
| Missing heading hierarchy | Use h1 → h2 → h3 in order (no skipping levels) |
| Focus not visible | Add `:focus-visible` outline style |
| Dynamic content not announced | Add `aria-live="polite"` to container |
| Table without headers | Add `<th>` elements with `scope` attribute |
