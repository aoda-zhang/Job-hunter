# Feed hiring-post matching

Reference for `linkedin-feed-jobs`. Every gate reads its values from `job-hunter.config.json`. This file must never contain a hardcoded list of job titles, cities, regions or countries.

## 0. Order

1. Hiring signal
2. Job title
3. Location
4. Time window
5. Third-party gate (only when `common.thirdPartyPostings` is `exclude`)
6. Validity
7. Soft notes

Hard gates are 1–6. Step 7 never removes a post.

## 1. Hiring signal

Keep only a post that names a specific role and at least one hiring signal.

- Use `platforms.LinkedIn.feedJobs.searchKeywords` as the canonical signal list.
- Also accept clear equivalents in the post language: a declaration that the team is hiring or growing, an invitation to apply or send a CV, or an invitation to DM about the role.
- A generic "we are hiring people" without a specific role fails step 2.
- A post that only shares a job-board link with no role text fails here.

## 2. Job title

Require a `common.jobTitles.include` title, or a variant of one.

A variant is allowed only when it keeps the configured role's meaning:

- case, punctuation, hyphen, slash and spacing differences;
- joined or separated spellings of the same words;
- abbreviation expansion, but only to the full form of a configured term;
- the local-language translation of the configured title (e.g. `Entwickler` = `Developer`, `Softwareentwickler` = `Software Engineer`, `Fullstack-Entwickler` = `Fullstack Developer`), and `Developer`/`Engineer` count as the same role noun.

Reject a post whose role is not in the configured set, even when it shares a stack with a configured role. Also reject any title containing a word from `common.jobTitles.excludeWords` (default `lead`, `staff`, `principal`, `head of`, `manager`, `architect`, `cto`, `director`, `vp`) — a lead or staff role is not a configured role. When a post lists several roles, it passes when at least one listed role passes and the post states the location.

Never add a title that is not in the config. Never treat the query terms as the matching set.

## 3. Location

The post must state a location inside `common.countries` and, when `common.locations` is non-empty, inside `common.locations`.

Accepted:

- the configured country name or its local-language name;
- a configured `common.locations` value, or its local-language variant for the same place;
- a city or region that you can verify lies inside a configured country;
- a remote or hybrid phrase only when the same post also names a configured country, a configured location, or a place inside a configured country.

Rejected:

- a foreign place as the role location;
- a continental or multi-country remote scope that does not name a configured country or location;
- a bare remote/hybrid phrase with no place evidence;
- no location at all.

Do not use a hardcoded city or region list. Verify geography from the post text and general knowledge; skip when you cannot confirm it. Never infer location from the author's profile, the company headquarters, the post language or the time zone. Multi-location posts pass when one stated location is inside the configured scope.

## 4. Time window

Use the post's rendered relative time. Keep `age <= feed window`. Include `1d` when the feed window is 24 hours and mark `24h boundary`. Reject older or undated posts.

## 5. Third-party gate

When `common.thirdPartyPostings` is `exclude`, reject a confirmed staffing agency, headhunter, or "our client"/"on behalf of a client" post, including its local-language equivalent.

When `common.thirdPartyPostings` is `separate` or `include`, keep it and note `third party: <client>` or `third party: client not stated` when the post names or omits the client. Keep and note `poster type unclear` when the poster's relation to the employer is not stated.

## 6. Validity

Reject a post that says the role is filled, closed, paused or no longer accepting applications. A stale relative time alone is not proof of closure.

## 7. Soft notes

Never reject for these. Record the evidence in `Notes`:

| Dimension | Keep and note |
|---|---|
| Stack | `common.technicalKeywords.include` terms named; `stack not stated` when none |
| Work mode | Stated mode; `mode not specified` when absent |
| Employment type | Stated type; `employment not specified` when absent |
| Seniority | Stated level; `level not specified` when absent |
| JD language | Full JD outside `common.jdLanguages.include`; write `JD language: <language>` |
| Poster type | `third party: <client>` / `third party: client not stated` / `poster type unclear` |
| Time | `24h boundary` when applicable |

## 8. Normalization and dedupe

Normalize company and title before comparing:

- lowercase, trim, collapse whitespace;
- `&` → `and`; remove punctuation except `+` and `#`;
- remove gender markers and their common variants;
- remove legal suffixes;
- keep seniority words, because they identify different roles;
- never merge different cities.

Legal suffixes and gender markers come from the values in the report and post; do not maintain a hardcoded country or company list.

Dedupe key, in order:

1. canonical permalink;
2. `normalized company | normalized title | normalized location`.

Skip when the key already appears in today's report, the previous 7 daily reports, or `reports/job-index.json` as `appliedOn`, `matched` or `review`. When two posts describe the same job, keep the newer or the one that states more fields.

## 9. Notes vocabulary

Start `Notes` with `来自搜索` or `来自 feed` (`From search` / `From feed`), then one verifiable fact such as a stated poster role, an apply instruction, or `multi-city post`. Append soft-note phrases with `;`.

Allowed markers: `stack not stated`, `mode not specified`, `employment not specified`, `level not specified`, `third party: <client>`, `third party: client not stated`, `poster type unclear`, `JD language: <language>`, `24h boundary`. Do not invent other status text.
