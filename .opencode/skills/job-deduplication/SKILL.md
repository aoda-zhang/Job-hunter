---
name: job-deduplication
description: Normalize and deduplicate job postings across job boards and company career pages.
---

# Job Deduplication

1. Normalize URLs by removing known tracking parameters while preserving job-identifying query parameters.
2. Normalize company and title for comparison, but retain original display values.
3. Prefer a stable source job ID when supplied.
4. Detect likely duplicates across aggregators and employer career pages.
5. Preserve the employer's canonical application URL as the primary link when confidently identified.
6. Never merge postings solely because their titles are similar; compare company, location, description, and requisition ID.
7. Record duplicate relationships for auditability.
