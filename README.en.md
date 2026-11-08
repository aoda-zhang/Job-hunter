# Job Hunter Configuration Guide

Job Hunter uses one root file, `job-hunter.config.json`, for multi-country, multi-role job discovery. **Vacancies are filtered only by three dimensions: job title, job-description language, and technical keywords in the JD.**

Country, location, posting recency and source define the search scope; they are not candidate-fit scoring criteria.

## 1. Complete configuration example

```json
{
  "search": {
    "countries": ["Germany"],
    "locations": ["Munich", "Berlin", "Hamburg", "Remote"],
    "lookbackHours": 72,
    "maxResultsPerSource": 50,
    "sources": ["company-career-pages", "LinkedIn", "StepStone"],
    "jobTitles": {
      "include": ["Senior Frontend Engineer", "Senior Frontend Developer", "Frontend Platform Engineer", "Senior React Engineer", "Senior Full-Stack Engineer"]
    },
    "jdLanguages": {
      "include": ["English", "German"]
    },
    "technicalKeywords": {
      "include": ["React", "TypeScript", "JavaScript", "HTML", "CSS", "Next.js", "Node.js", "NestJS", "Express", "Redux"],
      "matchMode": "any"
    }
  }
}
```

## 2. Field reference

### Search scope (not matching criteria)

| Field | Type | Required | Description |
|---|---|---:|---|
| `countries` | string[] | Yes | Target countries, e.g. `["Germany", "Japan", "United States"]`. Multiple countries are supported. |
| `locations` | string[] | No | Cities, regions or Remote. Omit to avoid an additional location restriction. |
| `lookbackHours` | integer | Yes | How far back to search, in hours; 72 means the last three days. |
| `maxResultsPerSource` | integer | Yes | Maximum number of vacancies collected per source. |
| `sources` | string[] | Yes | Source identifiers. A source runs only when a permitted adapter has actually been implemented. |

### The three vacancy filters

| Field | Type | Required | Description |
|---|---|---:|---|
| `jobTitles.include` | string[] | Yes | Accepted job titles and common variants. Use semantic matching; exact title equality is not required. |
| `jdLanguages.include` | string[] | Yes | Accepted JD languages, e.g. English, German or Japanese. Detect the actual primary JD language rather than inferring it from the country. |
| `technicalKeywords.include` | string[] | Yes | Technologies to look for in the JD. Include core technologies and common aliases where useful. |
| `technicalKeywords.matchMode` | enum | Yes | `any` means one keyword hit is enough; `all` requires every configured keyword. `any` is recommended to reduce false negatives. |

## 3. Filtering behavior

1. **Job title:** use case-insensitive semantic matching and common title variants rather than exact string equality.
2. **JD language:** detect the primary language of the job description and accept only configured languages.
3. **Technical keywords:** search the full JD. With the recommended `any` mode, a single matching keyword is sufficient.

A vacancy is marked Matched only when all three dimensions are confirmed matches.

If the title or JD is missing, too short or ambiguous, mark the vacancy Review and keep it available for manual inspection. Mark Not matched only when there is clear evidence of a mismatch in at least one dimension.

## 4. Explicit non-filters

Do not filter by candidate years of experience, seniority, salary, visa/work authorization, candidate language proficiency, industry background, architecture experience or any other candidate-profile attribute. There is no overall candidate-fit score or score-based rejection threshold.

## 5. Validation and current limitations

Run `npm run config:check` to validate the configuration. The Zod schema is in `src/config.ts`.

The configuration and filtering policy are defined, but real job-board adapters, vacancy collection and the deterministic filter executor still need implementation. Listing a source in the config does not mean its adapter is available. Respect each source's terms, access controls and rate limits. The project does not automatically submit applications or contact employers.
