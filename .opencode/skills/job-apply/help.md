# Job Apply — blocked fields

One row per blocker. `job-apply` appends a row every time an automatic submission is blocked, so the user can answer the field once and the next run fills it automatically.

| # | Date | Company | Role | Field | Why blocked | Status | Answer / next step |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-20 | ABOUT YOU | Senior Frontend Engineer - Checkout | `city` | The form rejects "Chengdu, China" (German cities only) | answered | Munich |
| 2 | 2026-11-20 | ABOUT YOU | Senior Frontend Engineer (all genders) | `country_code` | Phone prefix is prefilled with +49 and cannot be changed to +86 | answered | If a German number is mandatory, abandon the application, but always try +86 first |
| 3 | 2026-11-20 | NiCE | Senior AI Software Engineer | Relatives at NICE / previously worked at NICE | Required yes/no question with no config entry | answered | I have never worked at any German company; whenever asked whether I or a relative worked at the applying company, answer No |
| 4 | 2026-11-20 | Kärcher | Senior Software Engineer - Kärcher Connected Cleaning (m/w/d) | — | Login or account creation required | answered | If registration is required, abandon the application |
| 5 | 2026-11-20 | EMIL Group | Senior/Leading Software Engineer (f/m/d/x) | — | Blocked by a Cloudflare Turnstile human check | answered | Skip for now; I will apply manually |
| 6 | 2026-11-20 | Kombo / Almedia / TeleClinic / Air Apps | — | — | Browser relay dropped before the form was complete | answered | Infrastructure issue; retry on the next run |

| 7 | 2026-11-21 | go-e | Frontend Engineer (m/f/x) | — | Greenhouse form did not load; job board 404 | open | — |
| 8 | 2026-11-21 | Leapsome | Senior Software Engineer in Test / SDET | `relocation_required` | Required yes/no: do you require relocation support | open | — |
| 9 | 2026-11-21 | Riverty | Frontend Engineer - Angular | — | SmartRecruiters application page rendered blank | open | — |
| 10 | 2026-11-21 | Skalar | Senior Software Engineer (w/m/d) | — | reCAPTCHA challenge on submit | open | — |

## How this file is used

- **On every blocked submission**, append one row: date, company, role, the exact field label, the concrete blocker, `open`, and `—`.
- **When the user answers**, fill the `Answer / next step` cell and set `Status` to `answered`.
- **When the answer is in `job-hunter.config.json` or the rule is fixed**, set `Status` to `fixed`; the next run fills it without asking again.
- One row per company + role + field. Never duplicate an open row; update it instead.
- CAPTCHA, login walls and browser failures are recorded too, but marked as not answerable through config.
- This file is local working state, not a report: never publish it, never put candidate values in it.
