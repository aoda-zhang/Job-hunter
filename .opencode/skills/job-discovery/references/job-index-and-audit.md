# 职位索引、去重与运行审计

本文档定义 Job Hunter 的本地记忆层。`job-discovery` skill 每次运行都必须遵守；日报结构仍以 `daily-report-format.md` 为准。

## 1. 文件

| 文件 | 作用 | 是否提交 |
|---|---|---|
| `reports/job-index.json` | 跨日职位索引与投递记录 | 否，Git 忽略，只留本地 |
| `reports/runs/YYYY-MM-DD.jsonl` | 每次运行的审计日志，一个运行一行 | 否，Git 忽略，只留本地 |

不要把这两个文件推送到 `reportRepo`。`reportRepo` 只接收当天日报。

## 2. 职位索引 schema

```json
{
  "version": 1,
  "updatedAt": "2026-11-10",
  "jobs": {
    "4487182341": {
      "jobId": "4487182341",
      "url": "https://www.linkedin.com/jobs/view/4487182341/",
      "company": "immobilien.de",
      "title": "Senior Software Engineer",
      "city": "柏林",
      "firstSeen": "2026-11-08",
      "lastSeen": "2026-11-10",
      "firstReportedOn": "2026-11-08",
      "status": "matched",
      "appliedOn": null,
      "note": ""
    }
  }
}
```

字段规则：

- 键必须是 LinkedIn job ID（canonical URL 里的数字）。拿不到 job ID 时，才退回 canonical URL 作为键。
- `status`：`matched` / `review` / `excluded` / `expired`，记录**最近一次**判定。
- `firstSeen`：第一次打开该职位的日期。
- `lastSeen`：最近一次打开或重新确认的日期。
- `firstReportedOn`：第一次进入**命中表或复核表**的日期；从未进入过为 `null`。被排除的日期不算。
- `appliedOn`：用户确认已投递的日期；未投递为 `null`。
- `note`：可选，只写页面上可核实的事实，不写评价。
- 更新时只改相关字段，保留未知字段；不要整体重写对象，不要改变其它条目。

索引不存在时创建；无法解析时先备份为 `reports/job-index.json.bak`，再重建空索引，并在本次运行的对话里说明。

## 3. 读取顺序

1. 优先读 `reports/job-index.json`，它覆盖全部历史。
2. 索引不存在时，读 `reports/daily/` 下此前 7 个本地日期的报告作为一次性 bootstrap，只恢复 URL、状态和首次出现日期。
3. 两者都没有时，从空索引开始。

## 4. 去重与复用规则

**硬去重**：job ID 或 canonical URL 相同，视为同一职位。

- 索引里 `appliedOn` 非空 → **不打开、不判定、不进入任何职位表**，只在运行汇总里计入「已投递（跳过）」。
- 已存在且最近状态为 `matched` / `review` → 今天仍重新打开并判定（职位可能已关闭或要求变化），备注追加 `[已报 MM-DD]`，日期取 `firstReportedOn`。
- 已存在但最近状态为 `excluded` / `expired` → 今天照常重新评估，不加 `[已报]`；若今天命中，把 `firstReportedOn` 设为今天。

**软去重（疑似同岗不同 ID）**：同一岗位在 LinkedIn 上常有多个 job ID、多城市版本或双语版本。

- 比较键：`归一化公司名 + 归一化职位名 + 城市`。
- 归一化：转小写；去掉标点、多余空格、`(m/w/d)`、`(f/m/d)`、`(all genders)` 一类性别标记；去掉公司法律后缀（GmbH、AG、SE、Inc、Ltd、LLC、GmbH & Co. KG）。
- 不要删除 Senior / Junior / Lead 等职级词，也不要合并不同城市。
- 命中软去重且 job ID 不同 → 在备注写 `⚠️ 疑似重复`；若对方 `appliedOn` 非空，写 `⚠️ 疑似已投 MM-DD`。
- 只标注，不删除、不改判、不合并计数。

## 5. 投递登记

触发：用户说「我投了 X」「这几个标记为已投递」，或明确给出已投递的职位。

1. 定位职位：优先当天日报，其次历史报告，最后用 URL 或「公司 + 职位」匹配索引。
2. 设置 `appliedOn` 为今天，保持 `status` 不变。
3. 若该职位已出现在今天的日报里，在备注追加 `[已投 MM-DD]`；否则只更新索引。
4. 无法唯一定位时只问一个澄清问题，不猜测、不批量标记。
5. 不改变日报的计数与判定。

## 6. 运行审计 schema

路径：`reports/runs/YYYY-MM-DD.jsonl`（按本地日期分文件，一天多次运行就多行，只追加不覆盖）。

```json
{
  "runAt": "2026-11-10T09:30:00+01:00",
  "finishedAt": "2026-11-10T10:02:00+01:00",
  "durationSeconds": 1920,
  "scope": { "countries": ["Germany"], "locations": [] },
  "uiFilters": {
    "datePosted": "Past 24 hours",
    "employmentTypes": ["Full-time"],
    "workModes": ["Remote", "Hybrid", "On-site"],
    "seniority": null
  },
  "prompt": "…jobSearchPrompt 原文…",
  "linkedinResultCount": 300,
  "resultPagesOpened": 5,
  "cardsSkipped": 0,
  "postingsInspected": 120,
  "expired": 0,
  "appliedSkipped": 4,
  "matched": 23,
  "review": 12,
  "excluded": 85,
  "crossDayRepeats": 10,
  "possibleDuplicates": 2,
  "stopReason": "results older than lookbackHours",
  "limitations": []
}
```

规则：

- `runAt` 是**开始搜索**的时间，不是写报告的时间；`finishedAt` 是写完报告、索引和审计的时间；`durationSeconds` 是两者的整数秒差。
- 三者都使用本地时区并带 UTC 偏移（如 `+08:00`）。无法确认时写 `null`，不估算。
- 只记录浏览器会话能支撑的数字；无法确认写 `null`，不估算。
- `linkedinResultCount` 取结果页显示的总数；页面不显示时写 `null`。
- `stopReason` 用一句短语说明为什么停止翻页，例如 `results older than lookbackHours`、`no more pages`、`login required`、`cap reached`。
- `limitations` 只写实际发生的限制（验证码、限流、筛选无法应用等），正常运行为空数组。
- 同一天多次运行追加多行，不合并成一行。
- 审计里的 `postingsInspected` / `matched` / `review` / `excluded` 都是**本次运行**的计数；日报「运行汇总」表是**当日累计**。发摘要邮件时两者都要用，不能混为一谈。

## 7. 保留与清理

- 不要自动删除索引条目或审计日志。
- 用户要求导出、清理或重建时再操作，并先确认范围。
