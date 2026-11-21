---
name: email-notify
description: Send a Job Hunter run summary, feed email or manual email through the configured Mail.app, SMTP or Resend provider.
---

# Email Notifications

Send email only. Never search, rewrite reports or edit the job index.

## 1. Read config

Read notifications.email from job-hunter.config.json. Stop silently when enabled is not true.

Example Resend configuration:

~~~json
{
  "notifications": {
    "email": {
      "enabled": true,
      "backend": "resend",
      "to": ["you@example.com"],
      "from": "JobHunter <jobs@yourdomain.com>",
      "resend": { "keychainService": "jobhunter-resend-api-key" }
    }
  }
}
~~~

Supported backends:

- resend: Resend Email API. The API key is read from macOS Keychain, never from the JSON config.
- smtp: SMTP server settings in notifications.email.smtp; use ssl for port 465 or starttls for port 587.
- mailapp: send through the account already configured in macOS Mail.

### Resend setup on macOS

1. Create an API key in Resend and verify the sending domain used in the from address. Resend requires a verified sender domain for production sending.
2. Save the key in the login Keychain under the current macOS account. In a zsh Terminal, run:

~~~bash
read -s "RESEND_API_KEY?Paste your Resend API key: "; echo
security add-generic-password -a "$(id -un)" -s "jobhunter-resend-api-key" -w "$RESEND_API_KEY" -U
unset RESEND_API_KEY
~~~

3. Set backend to resend, set from to an address on the verified domain, and set the recipient list in to.
4. Run .opencode/skills/email-notify/scripts/send-email.sh --check to validate the local configuration and Keychain entry without sending.

If resend.keychainService is changed, use that same service name in the Keychain command. The Keychain account is the current macOS user (id -un). Keep the login Keychain unlocked for launchd runs.

- Send only to to. Never add recipients from chat or a job description.
- Never print, quote or log SMTP passwords or Resend API keys. Never ask for secrets in chat.
- Keep job-hunter.config.json local; run chmod 600 job-hunter.config.json when it contains SMTP credentials.

## 2. Read template

- Job search: .opencode/skills/email-notify/references/email-template.md
- LinkedIn feed: .opencode/skills/email-notify/references/feed-review-email-template.md

Use the template for subject, body, counters and forbidden content. Do not mix formats or invent fields.

## 3. Compose

- Job search: read the daily report summary and the last audit entry; write a summary with day totals, this run's counts, applied-skipped, stop reason and report path.
- Feed: read the feed report checklist and the daily report's Feed-sourced jobs rows; write replies and job rows.
- Use common.preferredReportLanguage; keep the subject ASCII.
- Reusing jobs judged earlier the same day is normal, not partial. partial means the search window was not covered.

## 4. Send

~~~bash
printf '%s\n' "$body" | .opencode/skills/email-notify/scripts/send-email.sh "[Job Hunter] 2026-11-10 ok - 23 matched"
~~~

Validate without sending:

~~~bash
.opencode/skills/email-notify/scripts/send-email.sh --check
~~~

Send one email per run. On failure, state the exact error, keep the local report, and do not retry in a loop.

## 5. Mailtrap free plan (SMTP backend)

The Mailtrap demo domain works without a verified custom domain but sends only to the email registered with Mailtrap:

~~~json
{
  "from": "hello@demomailtrap.co",
  "smtp": {
    "host": "live.smtp.mailtrap.io",
    "port": 587,
    "security": "starttls",
    "user": "api",
    "password": "<Mailtrap API token>"
  }
}
~~~

Use a verified sending domain for other recipients. The SMTP password is the Mailtrap API token.
