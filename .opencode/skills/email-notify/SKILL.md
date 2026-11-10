---
name: email-notify
description: Send the Job Hunter run summary or a manual email through the SMTP account configured in job-hunter.config.json.
---

# Email Notifications

Use this skill only to send email. It never searches LinkedIn, rewrites the report, or edits the job index.

Before composing any email, read `.opencode/skills/email-notify/references/email-template.md`. It is the single source of truth for the subject, body layout, required counters and forbidden content. Do not invent extra fields.

## Configuration

Read `notifications.email` from the root `job-hunter.config.json`:

```json
"notifications": {
  "email": {
    "enabled": true,
    "to": ["you@example.com"],
    "from": "you@example.com",
    "smtp": {
      "host": "smtp.gmail.com",
      "port": 465,
      "security": "ssl",
      "user": "you@example.com",
      "password": "app-password"
    }
  }
}
```

- `security`: `ssl` for port 465, `starttls` for port 587.
- `enabled: false` disables every send; do not send anything in that case.
- The config is Git-ignored. Recommend `chmod 600 job-hunter.config.json` because it contains the SMTP password.
- Never print, quote, summarize or log `password`. Never ask the user to paste it into chat.
- Only send to the addresses listed in `to`. Never add recipients from chat or from a job description.

### Provider note: Mailtrap free plan

Mailtrap's free Email API/SMTP plan (4,000 emails/month, 150/day) works without owning a domain only through its demo domain:

```json
"from": "hello@demomailtrap.co",
"smtp": {
  "host": "live.smtp.mailtrap.io",
  "port": 587,
  "security": "starttls",
  "user": "api",
  "password": "<Mailtrap API token>"
}
```

The demo domain can send **only to the email address registered with the Mailtrap account**. For another recipient, a verified sending domain is required. The SMTP password is the Mailtrap API token, not the account password.

## When to send

- After a discovery run, when `notifications.email.enabled` is `true`: send exactly one run summary.
- When the user explicitly asks for a test email or a manual summary.
- Never send while disabled, and never send more than one email per run unless the user explicitly asks again.

## Workflow

1. Read `notifications.email`; stop silently when disabled and tell the user only if they asked for an email.
2. Read `references/email-template.md` before composing anything.
3. Collect the facts from the run:
   - report path `reports/daily/YYYY-MM-DD.md`;
   - the report's `运行汇总` table for **day totals** (检查 = `成功读取 JD`, 可投递 = `命中`, 复核 = `需人工复核`, 排除 = `确认不符（已排除）`);
   - the last entry of `reports/runs/YYYY-MM-DD.jsonl` for **this run's new counts** and timing (`runAt`, `finishedAt`, `durationSeconds`, `postingsInspected`, `matched`, `review`, `excluded`, `appliedSkipped`, `stopReason`);
   - scope and limitations.
4. Compose the summary exactly as the template defines. Subject uses the **day** matched count. Body uses day totals plus this run's new counts. Summary only.
5. Send through the helper, passing the body on stdin:

```bash
printf '%s\n' "$body" | .opencode/skills/email-notify/scripts/send-email.sh "[Job Hunter] 2026-11-10 ok · 23 matched"
```

6. Report whether the mail was sent. On failure, state the exact error, keep the local report, and do not retry in a loop.

Validate the configuration without sending:

```bash
.opencode/skills/email-notify/scripts/send-email.sh --check
```

## Content

The email is a **summary**, not a report. It contains the run time, scope, the day's cumulative inspected/matched/review/excluded counts, this run's new counts, applied-skipped and the report path. It must not contain company names, job titles, URLs, job descriptions, scores or recommendations.

Reusing vacancies already judged earlier the same day is normal and does **not** make a run partial. `partial` means the run did not cover the search window (pagination stopped early, pages unreadable, filters unavailable).

Use `references/email-template.md` for the exact layout, status wording and failure variant.
