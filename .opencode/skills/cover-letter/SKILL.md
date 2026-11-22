---
name: cover-letter
description: Fill the fixed cover-letter template from a small JSON file. Personal facts stay fixed; only the company/JD fields change.
---

# Cover Letter

Use this skill whenever the user asks for a cover letter or a cover letter PDF.

**The letter is always written in English**, regardless of `common.preferredReportLanguage`, the JD language or the report language. The template and every generated PDF are English.

Every matched job gets one letter — Easy Apply and No Easy Apply alike; the letter is written even when the form has no cover-letter field or the JD says one is not required. The letter is a fixed template. Personal facts (name, age, job title, years, React, Manulife, achievements, start date) are baked into `render.py` and must not be rewritten per application. Only the company/JD fields change.

## 1. Read the inputs

1. Read `job-hunter.config.json` for `applicant.firstName`, `lastName`, `email`, `phone`, `currentCity`, `linkedinUrl`.
2. Read the job description and record only facts visible on the page: company, role, product/market, what the team owns, location, technical stack.
3. Use the real experience already fixed in `render.py`; do not invent new employers, metrics, dates, degrees or languages.

## 2. Fill the JSON

Create `<run>/<Company>-<JobTitle>/cover-letter.json` — the vacancy folder of the current run (`reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/<Company>-<JobTitle>/`). **There is no separate cover-letter folder anywhere, with no exceptions.** An ad-hoc request uses the same rule: use the run in progress, else the latest run of that day, else create that day's run folder (`reports/daily/<YYYY-MM-DD>/<YYYY-MM-DD>-<HHMM>/`), and write the letter into the vacancy folder inside it.

```json
{
  "company": "KoRo",
  "role": "Fullstack Software Engineer (f/m/d)",
  "company_street": "",
  "company_city": "Berlin, Germany",
  "backend_scope": "end-to-end e-commerce storefront features",
  "product": "e-commerce storefront",
  "company_fact": "KoRo sells directly to customers without a middleman.",
  "jd_match": "The role's Node.js and REST API work matches the services I build and maintain.",
  "tech_points": "Node.js and REST APIs",
  "manulife_focus": "fullstack",
  "salutation": "Dear Hiring Manager,"
}
```

Layout is DIN 5008 on **A4** (595 × 842 pt), margins left 2.5 cm, right 2.0 cm, sender block starting 4.5 cm from the top (recipient block below it), bottom 2.5 cm. Sender block top right, recipient block left (company + city; add `company_street` only when you know it), place and date right-aligned, bold subject line without `Betreff` or a final period, salutation with a comma, left-aligned body, `Kind regards` without a comma, and the signature. Only these fields change per application. Fill 2–3 technical points and exactly 2 non-technical points from the JD; do not invent a technology the JD does not mention or the CV does not support.

- `company` → recipient block and subject context
- `role` → `Application as <role>`
- `company_city` → recipient block (`company_street` only when known)
- `backend_scope` → `I would own your <backend_scope>`
- `product` → `and contribute to your <product>`
- `tech_points` → `are the tools I use daily`
- `company_fact` + `jd_match` → the third paragraph, both from the JD
- `manulife_focus` → `fullstack` (frontend/full-stack roles: end-to-end delivery + design tokens + PDF), `backend` (backend roles: end-to-end + REST APIs + PDF only), or `ai` (AI roles: AI harness + design tokens + PDF); never mix them

Everything else is fixed and comes from `cover-letter-personal.json`: name, job title, years of experience, current company, the two Manulife achievements, the AI delivery sentence, German level, work permit and notice period, closing and signature. Never repeat the achievement text in the JSON; edit it once in `cover-letter-personal.json`.

## 2.1 Content checklist (check all seven before rendering)

Every letter must fill these, in this order. A missing item blocks the render.

| # | Item | JSON field | Source |
|---|---|---|---|
| 1 | Exact role, used in the subject line | `role` | JD title |
| 2 | Company and city, used in the recipient block | `company`, `company_city` | JD |
| 3 | What you would own | `backend_scope` | JD responsibilities |
| 4 | Product / business | `product` | JD |
| 5 | One verifiable company fact | `company_fact` | JD only, no guessing |
| 6 | One or two JD requirements matched by your evidence | `tech_points`, `jd_match` | JD + CV |
| 7 | Optional: salary only when asked; German level recommended for Germany-based roles | `salary_expectation`, `german_level` | config |

Rules:

- Items 1–6 are mandatory. Salary is written **only** when the ad asks; the German level may be stated for Germany-based roles even when German is not required.
- `company_fact` and `jd_match` must come from the JD; never invent a company detail or a quote. Do not write `You write that …` unless the sentence is verbatim.
- Choose **one** Manulife angle via `manulife_focus`:
  - `fullstack` — frontend or full-stack roles: end-to-end delivery + design-token modernization + PDF refactor.
  - `backend` — backend roles: end-to-end delivery + REST APIs + PDF refactor only; do not include the design-token story.
  - `ai` — AI/SDET/AI-platform roles: AI engineering harness + design-token modernization + PDF refactor.
  Never write more than one angle.
- Banned phrases, checked before every render: `Hiermit bewerbe ich mich`, `Mein Name ist`, `I am … years old`, `with great interest`, `I was immediately drawn`, `next step in my career`, `take care of your`, `sustainable success of your`, `I believe we're a match`, `teamfähig`, `belastbar`, `flexibel`, leadership claims (`I led`), and any unverified claim (remote onboarding, WhatsApp, a technology with no CV evidence).
- No previous employer; only the current role (`current_company`).
- Do not claim leadership: write `worked on` / `contributed to`, never `I led`.
- AI agents and skills were built by your team, not the whole company: scope them to `in my team at Manulife`.

## 2.2 Length (enforced by the renderer)

- One page, **body 200–320 words** (JACVault's range is 250–400; Simple Germany requires one page and four paragraphs). Below 200 words add verified facts, never adjectives; above 320 cut repetition.
- Four paragraphs: role/company → evidence → JD match + company fact → availability and interview.
- Verify the rendered PDF: one page, no overflow, no orphan signature.

`render.py` enforces §2.1 and §2.2: it aborts when a required field is empty, a banned phrase appears, the body is outside 200–320 words, the signature path is missing, or the PDF is not exactly one page. A failed render writes no file.

## 3. Personal facts

Personal facts live in the `PERSONAL` dict at the top of `scripts/render.py`. If the user asks to correct one, edit it there once; then every future letter uses the corrected value.

A scanned signature is optional: set `signature` in `cover-letter-personal.json` to a PNG with transparency; it is placed above the printed name. Keep it under the git-ignored `.opencode/skills/cover-letter/assets/`. If a personal fact is missing or uncertain, stop and ask the user. Never guess. The letter must not open with the name or age; the header already carries them.

## 4. Header, date and signature

The uploaded template does not highlight these lines, but they are still placeholders:

- `Company / Street / City`
- `Place, dd.mm.2021`
- `Firstname Lastname`

By default the renderer fills them (`fill_header` is `true`). Set `"fill_header": false` only when the user wants the literal placeholder lines kept.

## 5. Render

```bash
python3 .opencode/skills/cover-letter/scripts/render.py <run>/<Company>-<JobTitle>/cover-letter.json
```

The script prints the absolute PDF path. Verify the file exists.

Output naming: `<First>_<Last>_<JD role>_Cover_Letter.pdf`, next to the JSON — the role as published in the JD with the `(m/f/d)` / `(all genders)` marker stripped, exactly like the CV name (`Qi_Zhang_<Role>_CV.pdf`). A JD that dictates a file name overrides it through `"filename"` in the JSON. **One vacancy = one PDF**: never copy or render the same letter to a second filename.

To rebuild the yellow base template (personal facts filled, company/JD placeholders highlighted):

```bash
python3 .opencode/skills/cover-letter/scripts/render.py <run>/base/base.json
```

## 6. Report back

State the PDF path and the company/JD fields you filled. The fixed body wording and personal facts must remain unchanged.

## 7. Short hiring-team message

When the form has a `Message to the Hiring Team` / `Message to the team` box, write a shortened 3–5 sentence text from the same JSON fields (`company`, `role`, `tech_points`, `backend_scope`, `team_location`) plus the fixed availability. Save it as `<run>/<Company>-<JobTitle>/message.md`; do not render a PDF for it. Put the text in the daily report.

## Why this stays cheap

The renderer owns layout, fonts, margins, justification and page breaks. The agent only produces the small company/JD JSON.
