# Discovery — Riverside Food Network (regional food bank)

Meeting: 2026-04-30 with Carla (Operations Director) and Devon (Volunteer & Partner Manager).

## Background

Riverside Food Network is a 12-year-old regional food bank serving 3 counties in Oregon. They distribute about 2.4M pounds of food per year through 38 partner agencies (church pantries, school programs, mobile distributions). Annual budget ~$3.8M, 11 staff, 400+ active volunteers.

Currently running NPSP. They're not switching off it — but they want to add a service-request portal for partner agencies and modernize their volunteer scheduling, both of which are duct-taped today.

## What they want to show

### Partner Agency Portal (Experience Cloud)

- Today, partner agencies email or call Devon to request food deliveries. Devon transcribes the request into a Google Sheet, then Carla reads the sheet on Mondays to plan that week's distributions. Lead time can be 5-10 days.
- They want partner agency leads to log into a portal, see their current month's allotment, request specific food categories (produce, protein, dry goods, infant formula), and see the status of their pending requests in real time.
- The "wow" is supposed to be: a partner submits a request at 9am Monday, and by Tuesday morning Carla's distribution plan dashboard already shows the request mapped to a specific truck route and warehouse pull list.
- Devon specifically said: "I want to stop being a transcription robot." His pain quote.

### Volunteer Shift Self-Service (Experience Cloud + Cases)

- Volunteers currently sign up via a Google Form, get a confirmation email, and the data lives in three places: the form's spreadsheet, a printed sign-in sheet at each site, and Devon's mental model.
- They want volunteers to sign up via the same portal as partners (different user license), see their upcoming shifts, cancel/reschedule themselves, and have no-shows automatically create a case for Devon to follow up.
- No-shows are a real pain — Devon estimates 15-20% no-show rate, and reaching out manually is what eats his Tuesdays.

### Distribution Planning Dashboard (Reports + maybe Tableau later)

- Carla needs a single Monday-morning view: how many pounds of each category are pledged this week, how many partner requests are open, how many volunteer slots are unfilled, and a map of distribution routes.
- Today she rebuilds this in Excel every Monday. Takes her 90 minutes.
- "I want to walk in Monday morning, look at one screen, and know if I'm short on protein for Thursday." — Carla's exact quote.

### Donor Receipt Automation (NPSP)

- Donors today get a generic year-end letter. They want personalized acknowledgments at the gift level, automatically, for gifts >$250.
- Lower priority — Carla mentioned it but didn't flag pain. Probably aspirational, not must-demo.

## Constraints

- Org is on NPSP, not migrating. Don't propose Nonprofit Cloud.
- 30-minute demo. Audience is Carla, Devon, and the board chair (Janet, who funds operations and is skeptical of "more software").
- Janet's concern: "we already have software that doesn't get used." Demo needs to show staff time saved, not feature breadth.
- Must run on a real-looking org with realistic Oregon partner agency names. No "Test Company A" placeholders.
- Don't show Setup. Janet has zero patience for admin views.

## Personas

- Carla, Operations Director — wants the Monday-morning dashboard
- Devon, Volunteer & Partner Manager — wants out of transcription work
- Janet, Board Chair — needs to see staff time saved
- Maria, fictional partner agency lead at a Latino community center pantry — submits the partner request that drives the wow moment
- Jordan, fictional volunteer — uses the self-service portal

## Out of scope for this demo

- Tableau / advanced analytics (Carla mentioned but shelved)
- The donor receipt automation (lower priority)
- Anything requiring a new license or product purchase
