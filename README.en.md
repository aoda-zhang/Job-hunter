# Job Hunter Configuration Guide

Job Hunter uses **one root configuration file only**: `job-hunter.config.json`. Search scope, candidate profile, and matching policy are configured together. Change this file to target different countries, roles, and markets without editing application code.

## 1. Configuration layout

There are three top-level sections:

| Section | Purpose |
|---|---|
| `search` | Countries, job titles, locations, work modes, and discovery sources |
| `candidate` | Candidate experience, skills, languages, salary reference, and work-authorization context |
| `matching` | Match-score weights, thresholds, and analysis rules |

## 2. Complete example

```json
{
  "search": {
    "countries": ["Germany", "Netherlands"],
    "roles": ["Senior Frontend Engineer", "React Developer"],
    "locations": ["Berlin", "Amsterdam", "Remote"],
    "workModes": ["remote", "hybrid"],
    "lookbackHours": 72,
    "maxResultsPerSource": 50,
    "sources": ["company-career-pages", "LinkedIn", "Indeed"],
    "excludeKeywords": ["intern", "junior"]
  },
  "candidate": {
    "headline": "Senior Frontend Engineer",
    "experienceYears": 9,
    "currentCountry": "China",
    "workAuthorization": {
      "status": "Assess separately for each target country",
      "note": "Verify eligibility and sponsorship requirements for each vacancy."
    },
    "languages": {
      "preferred": ["English"],
      "additional": [
        {"language": "German", "level": "B1", "note": "Currently learning"}
      ]
    },
    "salary": {
      "preferredMinimum": 65000,
      "currency": "EUR",
      "note": "Reference expectation; evaluate against local market."
    },
    "coreSkills": ["React", "TypeScript", "JavaScript"],
    "secondarySkills": ["Node.js", "NestJS"],
    "architectureSkills": ["Microfrontend", "Design Systems"],
    "experienceEvidence": ["Built enterprise frontend platforms with React and TypeScript."]
  },
  "matching": {
    "weights": {
      "roleTitle": 20,
      "coreSkills": 25,
      "architecture": 15,
      "seniority": 10,
      "domainExperience": 10,
      "locationAndWorkMode": 8,
      "language": 7,
      "salary": 5
    },
    "thresholds": {
      "strongMatch": 85,
      "goodMatch": 70,
      "possibleMatch": 55
    },
    "rules": [
      "Score evidence in the job description, not keyword frequency alone.",
      "Mark unstated requirements as unknown."
    ]
  }
}
```

## 3. search — discovery scope

| Field | Type | Required | Description |
|---|---|---:|---|
| `countries` | string[] | Yes | One or more target countries, e.g. `["Germany", "Japan", "United States"]`. Use consistent, commonly recognized English country names. |
| `roles` | string[] | Yes | Target job titles and title variants, e.g. `["React Developer", "Frontend Engineer"]`. Use titles commonly found in the target market. |
| `locations` | string[] | No | Cities, regions, or `Remote`, e.g. `["Munich", "Tokyo", "Remote"]`. Omit or leave empty to avoid an additional location filter. Cross-border remote eligibility must be verified per vacancy. |
| `workModes` | enum[] | No | Work arrangement: `remote`, `hybrid`, `onsite`, or `flexible`. |
| `lookbackHours` | integer | Yes | How far back to search, in hours. `72` means postings from the last three days. Must be greater than zero. |
| `maxResultsPerSource` | integer | Yes | Maximum number of results to collect from each source. Must be greater than zero. |
| `sources` | string[] | Yes | Source identifiers, e.g. `company-career-pages`, `LinkedIn`, `StepStone`, `Indeed`. A source only runs when a permitted adapter has been implemented. |
| `excludeKeywords` | string[] | No | Keywords to exclude from job titles or descriptions, e.g. `["intern", "working student", "junior"]`. Exact filtering behavior is implemented by the discovery engine. |

**Search expansion:** the intended discovery planner combines countries, roles, and locations into individual tasks. Two countries × three roles produce at least six country/role search combinations. Actual collection depends on available source adapters.

## 4. candidate — candidate profile

| Field | Type | Required | Description |
|---|---|---:|---|
| `headline` | string | Yes | Target professional headline, e.g. `Senior Frontend Engineer`. |
| `experienceYears` | number | Yes | Total years of experience. Fractions are allowed; negative values are not. |
| `currentCountry` | string | Yes | Candidate's current country, used to assess location and cross-border context. |
| `workAuthorization.status` | string | Yes | Short description of current work-authorization status. Never assume it applies to every target country. |
| `workAuthorization.note` | string | Yes | Additional context instructing the analysis to verify visa, permit, and sponsorship requirements per vacancy. |
| `languages.preferred` | string[] | Yes | Languages preferred for work, e.g. `["English"]`. |
| `languages.additional` | object[] | Yes | Other languages. Each item requires `language` and `level`, with optional `note`. CEFR levels (A1–C2) are recommended where applicable. |
| `salary.preferredMinimum` | number | Yes | Numeric minimum salary expectation. Interpret together with `currency`; do not apply one market's salary threshold universally. |
| `salary.currency` | string | Yes | Three-letter currency code such as EUR, USD, GBP, or JPY. |
| `salary.note` | string | Yes | Context such as gross annual salary, negotiability, or whether the amount is indicative only. |
| `coreSkills` | string[] | Yes | Core skills expected to be central to the target role. |
| `secondarySkills` | string[] | Yes | Supporting or secondary skills. |
| `architectureSkills` | string[] | Yes | Architecture, system design, and engineering-practice skills. |
| `experienceEvidence` | string[] | Yes | Concise evidence from projects and employment. Include project context, responsibilities, technologies, and outcomes rather than keywords alone. |

## 5. matching — evaluation policy

### weights

Each key represents a scoring dimension; its number is its relative weight.

| Key | Current weight | Meaning |
|---|---:|---|
| `roleTitle` | 20 | Alignment between vacancy title and target role |
| `coreSkills` | 25 | Core technical-skill alignment |
| `architecture` | 15 | Architecture, system design, and engineering practices |
| `seniority` | 10 | Seniority and experience level |
| `domainExperience` | 10 | Industry and domain experience |
| `locationAndWorkMode` | 8 | Location and work arrangement |
| `language` | 7 | Working-language requirements |
| `salary` | 5 | Compensation alignment |

Weights should normally sum to 100; the current values do. If you change them, normalize them to 100 for an interpretable percentage score. The scoring implementation should apply weights, not merely count keywords.

### thresholds

| Key | Current value | Meaning |
|---|---:|---|
| `strongMatch` | 85 | Strong-match threshold |
| `goodMatch` | 70 | Good-match threshold |
| `possibleMatch` | 55 | Worth-reviewing threshold |

Scores below `possibleMatch` may be classified as low matches, but must not trigger automatic rejection. Keep the ordering `strongMatch >= goodMatch >= possibleMatch`.

### rules

An array of natural-language instructions for analysis. Examples: distinguish required from preferred skills; mark unstated salary or sponsorship details as unknown; support every major score with evidence from the job description and candidate profile. Add or remove rules to reflect your evaluation policy.

## 6. Common scenarios

- **Change target markets:** edit `search.countries`.
- **Change job families:** edit `search.roles`.
- **Add cities:** edit `search.locations`.
- **Remote-only search:** set `workModes` to `["remote"]`.
- **No work-mode filter:** omit `workModes`.
- **Change scoring priorities:** edit `matching.weights` and `matching.thresholds`.
- **Update your profile:** edit `candidate`; do not put personal skills into search keywords.

## 7. Validation and limitations

Run `npm run config:check` to validate the configuration. The runtime schema is defined with Zod in `src/config.ts`.

A valid configuration does not mean every source is implemented. Source adapters must be developed separately and must respect each platform's terms, access controls, and rate limits. The project does not automatically submit applications or contact employers.
