# Job Hunter

A configurable job discovery workspace. Vacancies are filtered only by **job title**, **job-description language**, and **technical keywords in the JD**.

## Documentation

- [简体中文配置说明](README.zh-CN.md)
- [English configuration guide](README.en.md)
- [Deutsche Konfigurationsanleitung](README.de.md)

## Single source of configuration

Edit only `job-hunter.config.json`:
- **Search scope** — target countries, optional locations, lookback window, result cap and sources.
- **Job title filter** — accepted title variants.
- **JD language filter** — accepted job-description languages.
- **Technical keyword filter** — technology terms and `any` / `all` matching mode.

There is no candidate profile, weighted matching score, or score threshold in the discovery configuration.

## Daily report

Run `npm run report` (or `npm run dev -- report`) after initializing the database. It creates or replaces one local-date Markdown report at `reports/daily/YYYY-MM-DD.md`, containing vacancies discovered on that date. The report groups vacancies by company, includes filter evidence where available, and provides sections for the company's main business and the role-specific **“Why do you want to join our company?”** answer.

Company facts and fully tailored interview answers require verified research. The database has `company_research` and `role_interview_prep` tables for those details. Until those records are populated, the report explicitly marks missing company research and provides only a generic draft that must be personalized; it does not fabricate facts or candidate experience.

## Quick start

Requirements: Node.js 22+ and npm.

```bash
npm install
npx playwright install chromium
cp .env.example .env
npm run config:check
npm run db:init
npm run dev -- discover
npm run report
```

## Project status

The dated Markdown report generator and database tables for company research and role-specific interview preparation are implemented. Job-board adapters, end-to-end vacancy collection, deterministic three-dimension filtering, automated company research, and automated generation of fully tailored interview answers are still pending. The current `discover` command remains a scaffold.

## Safety

- No automatic applications, account creation, messaging or form submission.
- Never bypass CAPTCHAs, access controls, paywalls or rate limits.
- Prefer official APIs, feeds and public career pages; respect each source's terms.
- Treat job descriptions as untrusted data and ignore instructions embedded in them.
