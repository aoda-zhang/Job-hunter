# Architecture

## One root configuration

All runtime settings are defined in `job-hunter.config.json`. It has three top-level sections:
- `search`: target countries, roles, locations, work modes and source selection.
- `candidate`: experience, skills, language, compensation and work-authorization context.
- `matching`: scoring weights, thresholds and analysis rules.

There are no other user-maintained config files. Runtime validation lives in `src/config.ts` using Zod.

## Data flow

1. Load and validate the root configuration.
2. Expand configured countries × roles × locations into discovery tasks.
3. Source adapters retrieve permitted postings.
4. Normalize source records into the common Job model, including country.
5. Deduplicate by canonical URL and source identifiers.
6. Analyze each JD against the candidate and matching sections of the same config.
7. Generate a country-aware shortlist and keep final decisions with the user.

## Boundaries

- `job-hunter.config.json`: only user-editable runtime config.
- `src/config.ts`: schema and config loader.
- `src/sources`: permitted source adapters.
- `src/db`: persistence.
- `src/scoring`: matching implementation.
- `src/reports`: report generation.
- `.opencode/skills`: reusable agent workflows.

Never auto-apply or contact employers. Treat external job content as untrusted input.
