# Submission checklist

- [ ] Deploy the current commit over HTTPS and record the public URL.
- [ ] Run `db:prepare` and `db:seed` in production.
- [ ] Verify `/up`, manifest, service worker, locale switching, and offline fallback.
- [ ] Run the full RSpec suite and Brakeman with zero warnings.
- [ ] Run dependency audit with `bundler-audit`.
- [ ] Test the seeded demo case end to end on desktop and mobile widths.
- [ ] Capture screenshots for the homepage, guide, assessment, discrepancy, action, AI, Twi, and offline views.
- [ ] Record a 3–5 minute demo and prepare a pitch deck and written summary.
- [ ] Export a backup of the final repository and database seed configuration.
# Hackathon release gate

Record each item as `PASS`, `FAIL`, or `BLOCKED`. A submission build must have no P0/P1 `FAIL`.

| Gate | Result |
|---|---|
| Browse Lands Commission and open Official Search, Deed, and First Registration guides | PASS |
| View publisher, provision, authoritative link, and last-verified source metadata | PASS |
| Create an anonymous UUID case without entering PII | PASS |
| Calculate 14 calendar days, 10 working days, and 65 working days deterministically | PASS |
| Keep the 14-day Title objection period inside the 65-day published target | PASS |
| Keep Deed/Title portal milestones disabled until independently verified | PASS |
| Record portal and institution-provided evidence for Official Search | PASS |
| Detect a possible stale public status and show one primary verified action | PASS |
| Return a service-scoped AI answer with CivicRoute-owned citations | PASS |
| Preserve English, Twi, or French across navigation, forms, and redirects | PASS |
| Save only a minimal service/case reference on the device and reconnect from Saved | PASS |
| Reopen a previously visited public guide offline; do not cache case/admin/saved pages | PASS |
| Complete the core flow by keyboard at 375px without horizontal overflow | PASS (manual check required for each release candidate) |
| Handle offline and AI failure without hiding verified civic information | PASS |

Future expansion remains intentionally out of the submission build: optional accounts and case claiming, broader languages/agencies, a full draft/review/approve/publish curator workflow, and content-hash change detection with human verification.
