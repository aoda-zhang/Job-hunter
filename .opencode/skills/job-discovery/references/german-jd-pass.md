# German-JD deferral and the both-lan pass

A run has two independent parts:

| Part | Owner | Output | Priority |
|---|---|---|---|
| **1 — normal pass** | `job-discovery`, then `job-apply` for its matched rows | `report.md`, `job-audit.md` | the main result; always finishes and publishes first |
| **2 — both-lan pass** | `job-apply` in `both-lan` mode, after Part 1 is published | `german-jd-audit.md` (from Part 1), `both-lan.md`, queue updates | bonus; never delays, blocks or rewrites Part 1 |

`common.jdLanguages` still decides the Part 1 verdict: a German JD is not a match, however good the role is. Part 1 only **defers** those postings instead of dropping them, and Part 2 works the deferred list on its own schedule.

## 1. Part 1 — deferral audit

Active only when `germanJdPass.enabled` is `true`. In step 3, check 3 (JD language):
a German JD whose title gate already passed is not judged, not matched and not excluded. Record it and stop that row.

Write `<run>/german-jd-audit.md`; never put these rows in `report.md` or in the excluded table. In the main `job-audit.md` merged list the row keeps the status `deferred (German JD)`, so the next run's previous-run dedupe still skips it.

```markdown
# German-JD audit — 2026-11-24-1500

Deferred from Part 1: 7 postings whose title passed and whose JD is German. Part 1 published separately; Part 2 reads this file.

| # | Company | Title | Link | City | Mode | Posted | English evidence | German level | Stack | Poster | Easy Apply |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Example GmbH | Senior Frontend Engineer | [Open](https://…) | Berlin | Hybrid | 2h ago | `Deutsch und Englisch` | C1 | React, TypeScript | direct | No |
| 2 | Another AG | Fullstack Developer | [Open](https://…) | Remote | Remote | 5h ago | not stated | B1 | React, Node.js | third_party | Yes |

This run: 65 JDs read · 7 deferred (German JD) · 0 forms opened for them
```

- One row per deferred posting, in discovery order. Column values are page facts; `not stated` when the JD is silent.
- `English evidence`: the verbatim phrase showing English is used at work, or `not stated`. Accept only wording on the JD itself (§2.1); never infer it from an international team, the company name or an English title.
- `German level`: the CEFR level the JD states, mapped exactly as in `step-3-jd-review.md` check 4; `not stated` when absent. It is recorded, never used as a drop reason here.
- `Stack`: configured `technicalKeywords.include` terms actually present in the JD.
- `Poster`: `direct` / `third_party` / `unknown` from check 2.
- No form is opened and no cover letter is drafted for a deferred row in Part 1. One visit per posting: read the JD facts and, when needed, the Apply button label.
- When `germanJdPass.enabled` is `false`, write no audit and keep the old behaviour: a German JD is `not_matched`.

## 2. Part 2 — the both-lan pass

Runs only when `germanJdPass.enabled` is `true`, `applications.enabled` is `true`, and Part 1 of the same run has finished and been published.
It works the local queue (section 3) and this run's deferred rows **to the end**, in the same rhythm as Part 1: open one posting, decide, apply or record the filter reason, close the tab, next. There is no per-run cap; `applications.maxPerRun` applies to Part 1 only and does not limit this pass.

### 2.1 Eligibility, in order — stop at the first failure

1. **Validity** — 404, closed or "no longer accepting applications" → queue `closed`.
2. **German-only requirement** — with `germanJdPass.excludeGermanOnly` (default `true`), skip the posting **only** when the JD explicitly requires German and never names English:
   - a stated German level or fluency: `Deutschkenntnisse`, `Deutsch in Wort und Schrift`, `fließend` / `verhandlungssicher` / `sicher` / `sehr gute Deutschkenntnisse`, `Deutsch (B2/C1/C2)`, `Deutsch als Arbeitssprache`, `nur Deutsch`, `ausschließlich Deutsch`;
   - and no English counterpart anywhere in the JD (`Englisch`, `English`, `Englischkenntnisse`).

   A JD that says **nothing** about languages passes this gate — silence is not a requirement. `Deutsch von Vorteil` / `Plus` / `wünschenswert` / `nice to have` is not a requirement and does not trigger the skip. Never infer a requirement from the German ad itself, the company name, the location or an "international team". With `excludeGermanOnly: false`, even a German-only JD is accepted.
3. **Role fit** — the strict title gate already passed before the deferral (step 3 check 1: a `common.jobTitles.include` phrase, no `excludeWords` word), so any deferred posting is already in your role family. Re-read the title on the reopened page and stop only when it changed to another role or now contains an exclude word.
4. **Stack fit ("basically consistent")** — the JD must show at least `germanJdPass.minStackMatches` (default `2`) terms from `common.technicalKeywords.include`, with aliases `JS`/`JavaScript`, `TS`/`TypeScript`, `NodeJS`/`Node.js`/`Node`, `ReactJS`/`React`. **React is not required**: `TypeScript` + `Node.js` is enough, and so is `JavaScript` + `HTML`/`CSS`. Fewer hits → fail (`技术栈命中不足：<n> 个`).
5. **Primary stack** — the role's main language/framework in `common.jobTitles.stackExclude` with `applications.screening.techYears` = `0` → fail (`primary stack`). A React mention inside a Java/Python role never qualifies.
6. **Work mode, employment type, seniority** — only when configured in `common`; judge from the page. An `unknown` **fails** here (no review queue in Part 2) and the reason is `work mode not stated` etc.
7. **German level** — `common.jdLanguages.maxRequiredLevel.German` does **not** gate this pass; the stated level is already in the audit and goes into the report so the user can judge. The `English` cap still applies.
8. **Dedupe** — skip a candidate already applied to (today's `reports/applications/*.md`, the queue, or the previous run's audit), or already matched in this run's Part 1.
9. **Then apply** — a candidate that passes every gate is handled in §2.2; a failing one is recorded in `both-lan.md` with its reason and in the queue as `skipped: <reason>`. Move on to the next posting.

### 2.2 Applying

Reopen the canonical URL, then use the normal `job-apply` procedure and field mapping:

- **Save** first when `common.saveMatchedJobs` is `true` (one verified click, never toggled off).
- **Cover letter** when `common.isNeededCover` is `true`, saved in `<run>/<Company>-<JobTitle>/`.
- **Easy Apply / Schnellbewerbung** — with `applications.easyApply.enabled` `true`, fill and submit it through `job-apply` one vacancy at a time; otherwise never fill or submit, leave it to the user, and record it in `both-lan.md` and the queue.
- **External** — inspect the form into `fields.json`, fill and submit per `applications.externalApply` (`true` submits, `fill` stops before Submit, `false` inspects only). Third-party postings follow `applications.excludeThirdParty`.
- **Blocked** — `note: "blocked: <reason>"` in `fields.json` plus one `help.json` entry with `"pass": "both-lan"`. Never guess an answer.
- **Queue sync** — the moment a submit succeeds, write the applications-log row and set that queue row to `applied` in the same step, including a `blocked` row that was just retried. A queue row and an applications row must never disagree about the same URL; a stale `blocked` row caused a duplicate submission on 2026-11-27.
- Never create an account, never bypass a CAPTCHA, never apply twice.

## 3. Queue — `reports/runs/both-lan-queue.md`

Local working state, Git-ignored, never published. It records what happened to every German-JD row; it is **not** a to-do list for a later run.

```markdown
| # | First seen | Company | Title | Link | Status | Note |
|---|---|---|---|---|---|---|
| 1 | 2026-11-24 15:00 | Example GmbH | Senior Frontend Engineer | [Open](https://…) | applied | submitted 2026-11-24 15:42 |
| 2 | 2026-11-24 15:00 | Another AG | Fullstack Developer | [Open](https://…) | blocked: b-014 | required field `Node years` |
| 3 | 2026-11-23 20:30 | Third GmbH | React Developer | [Open](https://…) | skipped: 技术栈命中不足：0 个 | — |
```

- **`pending` does not exist.** A row is written only together with its terminal or blocker state: `applied`, `blocked: b-NNN`, `skipped: <reason>`, `closed`, or `interrupted`.
- **No row may be left "for the next run".** Running out of turns, time or budget is not a status: the pass either finishes the row or the whole run stops (see the primary-platform stop-all rule), which is the only case that writes `interrupted`. A third-party page signal is a `blocked` row, not an `interrupted` run.
- `interrupted` means the run was cut off hard (primary-platform stop-all dialog, browser failure, crash) before the row was handled. Those rows are resumed first by the next run; they are the only rows that carry over.
- Add every deferred row of the current run in one of those states, deduplicated by canonical URL and by normalized `company + title + city`.
- A `blocked: b-NNN` row changes to `applied` / `skipped` once that `help.json` entry is `answered` or `fixed` and the row is retried; until then it stays `blocked` and is reported as blocked, never as "waiting".
- **One state per URL.** A row that was `blocked` and is retried successfully becomes `applied` immediately — a submitted row is never left `blocked`. The queue is the dedupe source for this pass; the fallback is today's applications log, never an older one.
- Evaluate eligibility only for a row being processed; a failed gate marks it `skipped: <reason>` so it never returns.
- Prune `applied`, `skipped` and `closed` rows older than 30 days; never delete a `blocked` or `interrupted` row.
- Process `interrupted` rows first (oldest first), then this run's new deferrals; finish the list unless the run is stopped by the primary-platform stop-all rule.

## 4. `both-lan.md` format

Written in the run folder as `<run>/` + `germanJdPass.reportFile` (default `both-lan.md`), in `common.preferredReportLanguage`. One file per run; never merge runs.

```markdown
# 双语德语 JD 补充投递 — 2026-11-24 15:40

- 运行编号：`2026-11-24-1500`
- 第一部分报告：`report.md`（已发布）
- 德语 JD 审计：`german-jd-audit.md`
- 本次处理：处理 7 · 强匹配 4 · 已提交 3 · 阻塞 1 · 未通过 3
- 队列：`reports/runs/both-lan-queue.md`（本次处理的 7 条均已终态；未处理 0）

## 强匹配候选

| # | 公司 | 职位 | 城市 | 模式 | 技术栈 | 语言证据 | Apply form | Saved | Link | 结果 |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Example GmbH | Senior Frontend Engineer | Berlin | Hybrid | React, TypeScript | `Deutsch und Englisch` | Submitted | Saved | [Open](https://…) | 21:42 已提交 |
| 2 | Another AG | Fullstack Developer | Remote | Remote | React, Node.js | `Englisch als Arbeitssprache` | Blocked | Saved | [Open](https://…) | 阻塞：必填 `Node years`（b-014） |
| 3 | Third GmbH | React Developer | Munich | On-site | React, TypeScript | `Deutsch und Englisch` | Submitted | Saved | [Open](https://…) | 21:44 已提交（Easy Apply） |

## 未通过强匹配

| # | 公司 | 职位 | 原因 |
|---|---|---|---|
| 1 | Example Two | Frontend Developer | JD 明确只要求德语（`fließend Deutsch`） |
| 2 | Example Three | Fullstack Developer | 技术栈命中不足：1 个 |
```

- `Apply form`: `Submitted` / `Blocked` / `Inspected` / `Manual only` (Easy Apply when automation is disabled).
- `结果` names the concrete outcome and the `help.json` id when blocked; never claim a submit without the confirmation page.
- The `未通过强匹配` table uses the exact failing gate (`未写明英语同为工作语言`, `技术栈命中不足：<n> 个`, `主技术栈 <stack>`, `工作模式未标注`, `已投递过`, `职位已关闭`).
- Write the file even when nothing qualified: keep the header and the `本次处理` line, and omit the empty tables.
- No form field tables here — they stay in `<run>/<Company>-<JobTitle>/fields.json`.
- After the file and the applications log are written, publish the run folder again with `report-publish.sh` so the published copy contains `both-lan.md` too. A push failure is reported, never hidden, and never rolls Part 1 back.

## 5. Order and failure isolation

1. Part 1: report → audit → publish → (matched external rows via `job-apply`).
2. Part 2: queue update → candidates → `both-lan.md` → applications log → queue update → publish the run folder again.

Part 2 never edits `report.md`, `job-audit.md` or `german-jd-audit.md`, never changes Part 1 counts. If Part 2 fails or is interrupted, keep what it wrote, record it in its `both-lan.md` header and the queue, and leave Part 1 exactly as published. The primary-platform stop-all rule applies to both parts; a third-party page signal blocks only that posting.
