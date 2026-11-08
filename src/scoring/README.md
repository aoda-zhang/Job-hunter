# Vacancy filtering

This module evaluates only the three configured discovery filters:
1. Job title.
2. Primary job-description language.
3. Technical keywords in the job description.

It must not calculate a candidate-fit score or use candidate seniority, salary, visa status, language proficiency, industry, or other profile information.

Each dimension returns `match`, `no_match`, or `unknown`, with evidence. Overall results are:
- `matched`: all three dimensions match.
- `not_matched`: at least one dimension is a confirmed mismatch.
- `review`: no confirmed mismatch, but at least one dimension is unknown.

For technical keywords, `matchMode: "any"` means one hit is sufficient and is the recommended default. Never silently discard incomplete records; retain them for manual review.
