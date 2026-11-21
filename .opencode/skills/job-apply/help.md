# Job Apply — blocked fields

One row per blocker. `job-apply` appends a row every time an automatic submission is blocked, so the user can answer the field once and the next run fills it automatically.

| # | Date | Company | Role | Field | Why blocked | Status | Answer / next step |
|---|---|---|---|---|---|---|---|
| 1 | 2026-11-20 | ABOUT YOU | Senior Frontend Engineer - Checkout | `city` | 表单拒绝配置值 “Chengdu, China”（只接受德国城市） | answered | Munich |
| 2 | 2026-11-20 | ABOUT YOU | Senior Frontend Engineer (all genders) | `country_code` | 电话区号被预填为 +49，无法改为 +86 | answered | 如果必须填写德国电话，那么就放弃投递，但是必须先尝试能否填入中国的+86 |
| 3 | 2026-11-20 | NiCE | Senior AI Software Engineer | 是否有亲属就职于 NICE / 是否曾就职于 NICE | 必填是/否问题，配置无对应项 | answered | 我完全没有在任何德国公司工作过，下次遇到这种问我或者我的家属有没有说投递的公司工作过，直接填写No或者选择No |
| 4 | 2026-11-20 | Kärcher | Senior Software Engineer - Kärcher Connected Cleaning (m/w/d) | — | 需登录/创建账号才能继续 | answered | 如果要注册，就直接放弃投递 |
| 5 | 2026-11-20 | EMIL Group | Senior/Leading Software Engineer (f/m/d/x) | — | Cloudflare Turnstile 人机校验拦截 | answered | 暂时放弃投递，我自己手动投递 |
| 6 | 2026-11-20 | Kombo / Almedia / TeleClinic / Air Apps | — | — | 浏览器中继中断，表单未完成 | answered | 基础设施问题，下一轮自动重试 |

## How this file is used

- **On every blocked submission**, append one row: date, company, role, the exact field label, the concrete blocker, `open`, and `—`.
- **When the user answers**, fill the `Answer / next step` cell and set `Status` to `answered`.
- **When the answer is in `job-hunter.config.json` or the rule is fixed**, set `Status` to `fixed`; the next run fills it without asking again.
- One row per company + role + field. Never duplicate an open row; update it instead.
- CAPTCHA, login walls and browser failures are recorded too, but marked as not answerable through config.
- This file is local working state, not a report: never publish it, never put candidate values in it.
