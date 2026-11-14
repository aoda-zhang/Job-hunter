---
name: email-notify
description: Send a Job Hunter run summary, feed email or manual email through the SMTP account in job-hunter.config.json.
---

# Email Notifications

Send email only. Never search, rewrite reports or edit the job index.

## 1. Read config

Read `notifications.email` from `job-hunter.config.json`. Stop silently when `enabled` is not `true`.

```json
"notifications": {
  "email": {
    "enabled": true,
    "to": ["you@example.com"],
    "from": "you@example.com",
    "smtp": { "host": "smtp.gmail.com", "port": 465, "security": "ssl", "user": "you@example.com", "password": "app-password" }
  }
}
```

- `security`: `ssl` for 465, `starttls` for 587.
- Send only to `to`. Never add recipients from chat or a job description.
- Never print, quote or log `password`. Never ask for it in chat.
- Recommend `chmod 600 job-hunter.config.json`.

## 2. Read template

- Job search → `.opencode/skills/email-notify/references/email-template.md`
- LinkedIn feed → `.opencode/skills/email-notify/references/feed-review-email-template.md`

Use the template for subject, body, counters and forbidden content. Do not mix formats or invent fields.

## 3. Compose

- Job search: read the daily report summary and the last audit entry; write a summary with day totals, this run's counts, applied-skipped, stop reason and report path.
- Feed: read the feed report checklist and the daily report's `Feed-sourced jobs` rows; write replies and job rows.
- Use `preferredReportLanguage`; keep the subject ASCII.
- Reusing jobs judged earlier the same day is normal, not `partial`. `partial` means the search window was not covered.

## 4. Send

```bash
printf '%s\n' "$body" | .opencode/skills/email-notify/scripts/send-email.sh "[Job Hunter] 2026-11-10 ok · 23 matched"
```

Validate without sending:

```bash
.opencode/skills/email-notify/scripts/send-email.sh --check
```

Send one email per run. On failure, state the exact error, keep the local report, and do not retry in a loop.

## 5. Mailtrap free plan

The free plan works without a domain only through the demo domain:

```json
"from": "hello@demomailtrap.co",
"smtp": { "host": "live.smtp.mailtrap.io", "port": 587, "security": "starttls", "user": "api", "password": "<Mailtrap API token>" }
```

The demo domain sends only to the email registered with Mailtrap. Use a verified sending domain for other recipients. The SMTP password is the Mailtrap API token.
