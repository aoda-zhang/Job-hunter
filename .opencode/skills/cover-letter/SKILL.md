---
name: cover-letter
description: Fill the fixed cover-letter template from a small JSON file. Personal facts stay fixed; only the company/JD fields change.
---

# Cover Letter

Use this skill whenever the user asks for a cover letter or a cover letter PDF.

The letter is a fixed template. Personal facts (name, age, job title, years, React, Manulife, achievements, start date) are baked into `render.py` and must not be rewritten per application. Only the company/JD fields change.

## 1. Read the inputs

1. Read `job-hunter.config.json` for `applicant.firstName`, `lastName`, `email`, `phone`, `currentCity`, `linkedinUrl`.
2. Read the job description and record only facts visible on the page: company, role, product/market, what the team owns, location, technical stack.
3. Use the real experience already fixed in `render.py`; do not invent new employers, metrics, dates, degrees or languages.

## 2. Fill the JSON

Create `reports/cover-letters/<company-slug>/<jobId-or-role-slug>.json`:

```json
{
  "company": "KoRo",
  "role": "Fullstack Software Engineer (f/m/d)",
  "company_street": "",
  "company_city": "",
  "backend_scope": "end-to-end e-commerce storefront features",
  "product": "e-commerce storefront",
  "tech_points": "Node.js and REST APIs",
  "non_tech_1": "clean, maintainable code",
  "non_tech_2": "reliable delivery",
  "jd_quote": "you will develop and deliver end-to-end features across KoRo's e-commerce storefront",
  "team_location": "Berlin"
}
```

Only these fields change per application. Fill 2–3 technical points and exactly 2 non-technical points from the JD; do not invent a technology the JD does not mention or the CV does not support.

- `company` → header and `Dear <company> Team,`
- `role` → `Application as <role>`
- `company_street` / `company_city` → optional recipient address lines
- `backend_scope` → `take care of your <backend_scope>`
- `tech_points` → `I believe we’re a match because <tech_points> have been my strong suit`
- `non_tech_1` / `non_tech_2` → `I put strong emphasis on <non_tech_1> and <non_tech_2>`
- `product` → `sustainable success of your <product>`
- `jd_quote` → `You write that <jd_quote>.`
- `team_location` → `join your team in <team_location>`

Everything else is fixed: name, age, job title, 9 years of complex enterprise software experience, Manulife, achievements, previous work, strength phrases, relocation/no-sponsorship, availability, closing and signature.

## 3. Personal facts

Personal facts live in the `PERSONAL` dict at the top of `scripts/render.py`. If the user asks to correct one, edit it there once; then every future letter uses the corrected value.

If a personal fact is missing or uncertain (currently `age`), stop and ask the user. Never guess.

## 4. Header, date and signature

The uploaded template does not highlight these lines, but they are still placeholders:

- `Company / Street / City`
- `Place, dd.mm.2021`
- `Firstname Lastname`

By default the renderer fills them (`fill_header` is `true`). Set `"fill_header": false` only when the user wants the literal placeholder lines kept.

## 5. Render

```bash
python3 .opencode/skills/cover-letter/scripts/render.py reports/cover-letters/<company-slug>/<jobId-or-role-slug>.json
```

The script prints the absolute PDF path. Verify the file exists.

To rebuild the yellow base template (personal facts filled, company/JD placeholders highlighted):

```bash
python3 .opencode/skills/cover-letter/scripts/render.py reports/cover-letters/base/base.json
```

## 6. Report back

State the PDF path and the company/JD fields you filled. The fixed body wording and personal facts must remain unchanged.

## Why this stays cheap

The renderer owns layout, fonts, margins, justification and page breaks. The agent only produces the small company/JD JSON.
