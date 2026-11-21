# Job Hunter

**告诉 OpenCode 你想找什么工作。它用你自己已登录的浏览器搜索你配置的招聘平台——LinkedIn 以及任何你浏览器里能打开的站点——逐个打开候选职位页面，按你的配置筛选，并生成一份每日 Markdown 职位清单。**

[English](README.md) · **简体中文** · [Deutsch](README.de.md)

## 1. 它能做什么

Job Hunter 由三部分组成：一份 OpenCode Agent 说明、六个 Skill 说明，以及一个属于你自己的配置文件。项目里没有应用代码——不需要后端、数据库、CLI、CI，也不需要任何 API Key。

一次运行只做四件事：

1. **搜索**：按 `sources` 的顺序逐个平台检索，每个平台用它自己的查询配置（LinkedIn 一句话 prompt，Indeed 短关键词）。
2. **收窄范围**：在各平台自己的筛选栏中应用你配置的条件——发布时间、雇佣类型、工作模式、职级、地点。
3. **逐个打开**：进入每一个剩余职位的真实页面（而不只是搜索结果卡片），跳过已关闭或不再接受申请的职位。
4. **分类并写报告**：把每个职位判定为「命中 / 待复核 / 不符」，保存到 `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md`（每次运行一个独立文件，文件名精确到分钟，不跨轮合并）。

它不会替你投递、不会私信招聘方、不会修改你的账号设置，只使用你已经登录的浏览器会话。

## 2. 工作流程

```mermaid
flowchart TD
    A[job-hunter.config.json] --> B[Job Hunter Agent]
    B --> C[配置的平台<br/>sources：LinkedIn、Indeed 等]
    C --> D[各平台搜索<br/>LinkedIn prompt、Indeed 短词]
    D --> E[各平台自己的筛选<br/>日期、类型、模式、职级]
    D --> E[逐个打开职位页面]
    E --> F{职位仍有效}
    F -->|已关闭| X[跳过并计数]
    F -->|有效| G[核对标题、发布方、JD 语言、<br/>关键词、模式、类型、职级]
    G --> H[命中 / 待复核 / 不符]
    H --> I[reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md]
```

判断按固定顺序进行，遇到第一个「确认不符」就停止。页面信息不足以证明符合或不符合时，职位会进入**待复核**，而不是被直接排除。

## 3. 你需要准备什么

| 需要 | 说明 |
|---|---|
| OpenCode | 已安装，并在本仓库目录中打开 |
| 浏览器工具 | 在 OpenCode 中已启用的浏览器集成；仓库本身不安装、也不配置浏览器 |
| 招聘平台 | `sources` 里列出的每个平台，都已在该浏览器中登录 |
| 其它 | 无——不需要 Node.js、npm、数据库或 CI |

## 4. 快速开始

```bash
cp job-hunter.config.example.json job-hunter.config.json
```

然后编辑 `job-hunter.config.json`（它已被 Git 忽略，偏好只留在本地）：

1. **`common.jobSearchPrompt`**：一句自然语言，写清地点、职位、技术栈和时间范围（LinkedIn 使用）。
2. **`common.countries` / `common.locations`**：搜索范围。`locations` 为空表示搜索整个国家。
3. **`common.jobTitles.include`**：你接受的职位名称，用于匹配，也是 Indeed 默认查询的来源。
4. **`common.jdLanguages.include`** 和 **`common.technicalKeywords`**：你能接受的语言和技术栈。
5. 可选：`common.workModes`、`common.employmentTypes`、`common.seniority`、`common.thirdPartyPostings`（默认 `separate`）。
6. 保持 `sources` 的顺序：`["LinkedIn","Indeed"]` 表示先跑 LinkedIn。

接着：

1. 在 OpenCode 中打开本仓库目录。
2. 选择 **Job Hunter** Primary Agent（按 `Tab` 切换 Agent）。
3. 直接用自然语言说，例如「帮我找今天的职位」「刷新报告，只要远程」。
4. Agent 操作浏览器搜索并筛选，最后写出 `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md`（HHMM 为该轮开始时间），打开看表格即可。

你始终只需要和 Job Hunter Agent 交互。它会自行加载 `job-discovery`，不需要你手动选 Skill。

> **查询是按平台配置的。** LinkedIn 原样收到 `common.jobSearchPrompt`；Indeed 收到 `platforms.Indeed.search.queries` 里的短词（或每个职位名一条）。两者都来自配置，运行时不会临时编造。`jobTitles` 和 `technicalKeywords` 用于**匹配结果**，不用于搜索。
>
> **筛选来自配置，不来自 prompt。** 在 prompt 里写「最近 24 小时」并不可靠；Agent 会按配置的时间窗口设置平台的「发布日期」筛选，并在读取结果前确认筛选已生效。在 Indeed 上还会把 JD 语言、雇佣类型和远程偏好映射成对应筛选。

## 5. 配置说明

配置分三层：`sources`（运行顺序）、`common`（跨平台共用偏好）、`platforms`（平台专属设置）。`applicant`、`applications`、`notifications` 是共用运行时配置，`schedules` 放 launchd 定时任务。

| 字段 | 必填 | 作用 |
|---|---|---|
| `sources` | 是 | 要搜索的平台，**按此顺序执行**。`["LinkedIn","Indeed"]` 表示先 LinkedIn、后 Indeed。每个平台都要有对应的 `platforms.<name>` 块。内置 `LinkedIn`、`Indeed` 的说明文件；没有说明文件的平台直接跳过，不猜流程。 |
| `common.countries` | 是 | 国家级范围，例如 `["Germany"]`。用于校验和说明搜索范围，不用于拼接查询。 |
| `common.locations` | 否 | 国家内的可选城市。为空或缺失表示整个国家。 |
| `common.lookbackHours` | 是 | 发布时间窗口（小时）。决定各平台的日期筛选，并在打开每个职位时再次核对。 |
| `common.jobSearchPrompt` | 是 | `queryMode: "prompt"` 的平台（LinkedIn）使用的自然语言检索语句，原样提交。 |
| `common.jobTitles.include` | 是 | 接受的职位名称变体，用于匹配、卡片预筛和 `queryMode: "titles"`。 |
| `common.jdLanguages.include` | 是 | 接受的 JD 语言，例如 `["English"]`。Indeed 会映射到它的 `Language` 筛选。 |
| `common.jdLanguages.acceptGermanJdWithEnglishWorkingLanguage` | 否 | 为 `true` 时，德语 JD 只要明确写明英语是工作/团队/公司语言，也算命中。 |
| `common.jdLanguages.maxRequiredLevel` | 否 | 可选的语言等级上限，例如 `{"German": "A2", "English": "C1"}`。JD 明确要求高于该等级时，按 `language requirement` 排除。只写“German required”按 B1 计算；“nice to have/plus/optional”不算要求。 |
| `common.technicalKeywords.include` | 是 | 要在 JD 中查找的技术关键词。 |
| `common.technicalKeywords.matchMode` | 是 | `any`：命中任意一个即可；`all`：必须全部命中。 |
| `common.workModes` / `common.employmentTypes` / `common.seniority.include` | 否 | 可选匹配维度。全列或为空 = 不筛选。 |
| `common.thirdPartyPostings` | 否 | `separate`（默认）：确认是替第三方客户招聘的猎头/中介岗位，通过其他检查后放进独立的 `代招岗位` 表；`include`：与普通命中混排；`exclude`：排除。证据不足的进复核。 |
| `common.skipPreviousReport` | 否 | 默认 `true`。上一次日报里出现过的职位直接跳过。 |
| `common.dedupe.crossSource` | 否 | 默认 `true`。公司 + 职位 + 城市（规范化后）相同即视为同一职位，第二个平台的行加注记而不重复列出。 |
| `common.dedupe.skipApplied` | 否 | 默认 `true`。某个职位在一个平台投递过，其他平台就跳过，永不重复投递。 |
| `common.report.splitBySource` | 否 | 默认 `true`。日报按平台分节，顺序同 `sources`，每节再分 Easy Apply / No Easy Apply。 |
| `common.isNeededCover` | 否 | 为 `true` 时，留在报告里的命中/复核岗位若 JD 要求求职信，就生成一封。可用 `cover-letter` skill 渲染 PDF。默认 `false`。 |
| `common.reportRepo` | 否 | 可选 Git 地址。配置后每次运行会把当天日报提交并推送到该仓库。 |
| `common.sortBy` / `common.sortDirection` | 否 | 各部分（Easy Apply、No Easy Apply）内、Premium 提示行之后的排序方式；已提交的行按全局「已提交」一节排序。`companySize` 配合 `asc` / `desc`；不填则按发现顺序。 |
| `common.preferredReportLanguage` | 否 | 日报和摘要邮件正文的语言，例如 `English`、`German`、`Chinese`，默认 `English`。 |
| `applicant` | 否 | 用于填第三方申请表的身份信息：`firstName`、`lastName`、`phone`、`email`、`currentCity`、`linkedinUrl`、`portfolioUrl`、`cvPath`、`availableInGermanyFrom`、`governmentEmployee`。身份必填项缺失会停止投递；筛选问题缺失只会阻塞对应岗位。 |
| `applications` | 否 | 投递策略：`enabled`；`externalApply` = `true`（自动填写并提交）/ `false`（只检查字段）；旧值 `off` / `inspect` / `fill`（填好停在 Submit 前）/ `submit` 仍然兼容；`scope`（`matched` 默认 / `review` / `all`）；`excludeThirdParty`（默认 `true`）；`requireNoAccount`（默认 `true`）；`requireExternalRedirect`（默认 `true`）；`maxPerRun`（数字或 `null`）；`coverLetterMode`（`never` / `required-only` / `always`）；`screening` 存放申请表答案。平台一键投递（LinkedIn Easy Apply、Indeed Apply）没有配置项，永远手动。 |
| `platforms.LinkedIn.enabled` / `.premium` | 否 | `premium: true` 时，带 `You'd be a top applicant` 提示的命中岗位在所属部分内优先排序；`enabled: false` 跳过该平台。 |
| `platforms.LinkedIn.search.queryMode` | 否 | `prompt`（默认，原样使用 `common.jobSearchPrompt`）、`titles` 或 `custom`。 |
| `platforms.LinkedIn.feedReview` | 否 | Feed 任务设置：`lookbackHours`、`maxPosts`、`excludeTopics`、`replyLanguage`。 |
| `platforms.LinkedIn.feedJobs` | 否 | 招聘帖搜索：`enabled`、`lookbackHours`（feed 帖时间窗，缺省继承 `common.lookbackHours`）、`searchKeywords`、`maxQueries`、`maxPagesPerQuery`、`maxScreens`、`locationTerms`、`includeRecentFeed`。 |
| `platforms.Indeed.enabled` | 否 | `false` 时跳过 Indeed，但仍保留在 `sources` 里。 |
| `platforms.Indeed.domain` | 否 | 例如 `de.indeed.com`，要和 `common.countries` 一致。 |
| `platforms.Indeed.search.queryMode` | 否 | `custom`（Indeed 默认，使用 `search.queries`）、`titles`（每个 `common.jobTitles.include` 一条）或 `prompt`。 |
| `platforms.Indeed.search.queries` | 否 | 短关键词，例如 `["Frontend Developer","React Developer"]`。Indeed 对短词的效果远好于长段落。 |
| `platforms.Indeed.search.maxQueries` / `.maxPagesPerQuery` | 否 | 该平台的查询条数和翻页上限。 |
| `platforms.Indeed.search.lookbackHours` | 否 | 只覆盖 Indeed 的时间窗口——当前是 `168`（7 天），LinkedIn 保持 24 小时。 |
| `platforms.Indeed.search.filters` | 否 | 绑定哪些 Indeed 筛选器：`date`（始终开）、`employmentType`（开——按 `common.employmentTypes` 选 `Full-time`）、`language`（关——读 JD 判断）、`remote`（关）、`quickApply`（关——会隐藏外部 ATS 岗位）。开关为 `false` 的维度一律从职位页判断。 |
| `notifications.email` | 否 | 可选 SMTP 配置，用于发送运行摘要邮件；默认关闭。`enabled` 为 `true` 时每次运行后发送一封摘要。 |
| `schedules.jobSearch` | 否 | 每日 job search 的 launchd 定时任务。`times` 是 `HH:MM` 字符串数组；`weekdays` 是可选的 launchd 星期数组（`0`–`7`，`1` 为周一，`5` 为周五，空数组表示每天）；空 `times` 表示不启动。`timezone` 必须和系统时区一致。 |
| `schedules.linkedinFeedReview` | 否 | Feed 任务的 launchd 定时：`times`、`weekdays`、`timezone`。空 `times` 表示不启动独立的 feed 任务。 |

补充说明：

- `common.lookbackHours` 填数字。它会被映射到该平台能提供的、能完整覆盖该窗口的最近一档日期筛选（LinkedIn：≤24 → 过去 24 小时，≤168 → 过去一周，≤720 → 过去一个月；Indeed：24 小时 / 3 / 7 / 14 天），并在每个职位页面上单独核对。
- 只有你主动收窄时，某个维度才生效。三种工作模式全列、所有雇佣类型全列、或 `common.seniority.include` 为空，都等于「不筛选」。
- `platforms.LinkedIn.feedReview.excludeTopics` 是唯一的排除列表，话题和内容类型都在这里。Skill 里没有隐藏的内置排除列表；空数组表示不做这些排除（时间窗口仍然生效）。
- 「范围」和「筛选」是两件事：国家、城市、发布时间决定**搜哪里、搜多新**；只有上表中的匹配维度决定一个职位**算不算命中**。
- 跨平台顺序：按 `sources` 顺序运行。在 LinkedIn 投递过的职位，到 Indeed 不再打开、不再列出、也不会重复投递（`common.dedupe.skipApplied`）。
- 当前检索形态：LinkedIn 用 **24 小时**窗口（`common.lookbackHours: 24`），Indeed 用 **7 天**（`platforms.Indeed.search.lookbackHours: 168`）。两者都是自己读 JD 判断：Indeed 用短关键词，套 `Date` 和 `Full-time` 两个筛选，JD 语言、工作模式和关键词仍从职位页判断（`filters.language: false`、`filters.remote: false`）。

每日任务现在是**两个独立的 OpenCode 会话、固定顺序**：先 LinkedIn（检索 + 外部投递 + Feed 招聘帖），再 Indeed。这样每个会话只持有一个平台，避免一起跑时卡顿。`JOB_HUNTER_PHASES=linkedin zsh .opencode/scripts/daily-run.sh` 可以只跑单个阶段，默认是 `linkedin,indeed`。两个阶段写入同一份日报和索引，Indeed 会跳过 LinkedIn 已投递的职位。

**定时任务。** 只改配置里的 `schedules.jobSearch` 不会自动改变 launchd。改完 `times`、`weekdays` 或 `timezone` 后，运行 `.opencode/scripts/apply-schedule.sh`（或直接让 Agent 改时间）。launchd 使用 Mac 的本地时间，所以 `timezone` 必须和系统时区一致。`times` 为空数组会卸载并删除 job search 定时任务；填入时间会重新创建。

LinkedIn feed 有独立的定时器。把 `schedules.linkedinFeedReview.times` 设成 `HH:MM` 数组，可用 `.weekdays` 限定星期（`[1,2,3,4,5]` 表示周一到周五），再运行同一个脚本；空数组表示不启动这个任务。每次运行只看 Recent feed，不检查关注列表：只回复作者岗位匹配 `common.jobTitles.include`、且作者地点确认在 `common.countries`/`common.locations` 内的帖子，没有每日最低数量（0 条也是正常结果），把匹配的招聘帖追加到本轮自己的 `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md`，在启用邮件通知时把回复草稿和招聘帖一起发送，并在配置了 `common.reportRepo` 时推送 `reports/linkedin-feed/YYYY-MM-DD.md` 和更新后的日报。

## 6. 职位如何被筛选

检查按以下顺序进行，遇到第一个确认不符即停止：

1. 职位有效性——404、跳转离开职位页、「不再接受申请」。
2. 职位名称——与 `common.jobTitles.include` 属于同一岗位族。
3. 发布方类型——记录为直招、代招或不明；确认代招的岗位照常通过其余检查，并放进独立「代招岗位」表（配置为 `exclude` 时排除）。
4. JD 语言——以 JD 实际使用的语言为准。
4b. 语言等级要求——配置了 `jdLanguages.maxRequiredLevel` 时，JD 明确要求高于你的等级即判定不符（`language requirement`）。
5. 技术关键词——按 `matchMode` 判断。
6. 工作模式——仅当 `workModes` 是真正的子集时启用。
7. 雇佣类型——仅当 `employmentTypes` 是真正的子集时启用。
8. 职级——仅当 `seniority.include` 是真正的子集时启用。

| 结果 | 含义 | 出现在哪 |
|---|---|---|
| `matched`（命中） | 所有生效维度都能在页面上确认符合 | 主表；确认代招的岗位进「代招岗位」表 |
| `review`（待复核） | 页面不足以证明符合或不符合（过短、缺失、截断、中英混排） | 复核表 |
| `not_matched`（不符） | 至少一个生效维度明确不符合 | 排除表，并写明原因 |

在打开页面之前，Agent 会先做一次卡片预筛：标题明显是其它职能（销售、市场、财务、HR、设计、SAP 运维等），或明显不在配置的国家/城市范围内，才会跳过，并且只计数不列出。标题模糊、被截断或包含多个岗位的，仍然会打开。

Agent 必须**严格串行**：一次只搜一个查询、一次只开一个职位、一次只用一个标签页。打开 → 读 JD → 判断 → 投递或检查 → 记录 → 关掉标签页，再处理下一个。禁止批量打开职位卡片或职位链接，禁止在一次工具调用里循环多个职位 ID，禁止并行执行浏览器动作。慢一点是正确行为。

没有打分，不按「候选人匹配度」排名，也不按薪资、工作年限、签证或行业额外过滤。命中岗位表分成 **Easy Apply**（你本人手动投递）和 **No Easy Apply**（第三方页面，由 agent 填写；`externalApply: true` 时也会自动提交）两部分；已提交的岗位单独放到排除岗位前的「已提交」一节，不会和「已检查」混在一起。开启 `platforms.LinkedIn.premium` 后，带 **`You'd be a top applicant`** 提示的命中岗位在所属部分内优先排序；检查不符仍然排除。这个拆分不改变岗位是否命中。每张岗位表在 `#` 之后先放公司名、备注、申请表单状态和链接，招聘平台列放在最后。没能自动提交的外部岗位，备注末尾必须写明 `无法自动提交：<原因>`。

## 7. 报告

| 产出 | 路径 |
|---|---|
| 每轮职位发现 | `reports/daily/YYYY-MM-DD/YYYY-MM-DD-HHMM/report.md` |
| LinkedIn feed 回复机会 | `reports/linkedin-feed/YYYY-MM-DD.md` |
| 面试准备 | `reports/interviews/<company-slug>/` |

日报按 `sources` 顺序按平台分节（先 LinkedIn、后 Indeed）。每一节内的命中岗位再分为 **Easy Apply** 和 **No Easy Apply** 两部分（部分内 Premium 提示行优先，再按公司规模排序），已提交的行移到排除岗位前的 **已提交** 一节；运行汇总表每个平台一列，最后加总计列。之后是确认代招岗位通过同样检查后单独列出的「代招岗位」表、需要时的待复核表，以及最后写明具体原因的排除岗位。No Easy Apply 部分由 agent 打开第三方页面并填写表单，`externalApply: true` 时直接提交，`fill` 时保留标签页由你点 Submit。每张表都有 `Source` 列，跨平台时也能看清。日报格式由 `.opencode/skills/job-discovery/references/daily-report-format.md` 统一规定，语言由 `common.preferredReportLanguage` 指定（默认 `English`）。格式文档只固定结构，翻译的只是可读文字。

同一职位在 LinkedIn 投递过，就不会在 Indeed 再次出现或再次投递；未投递的重复职位只加注记，不合并。

`job-hunter.config.json` 和 `reports/daily/` 都被 Git 忽略。如果配置了 `common.reportRepo`，每次运行后只会把当天日报提交并推送到你指定的仓库。

**本地记忆。** 另外两个文件只留在你的机器上，永远不会被推送：

| 文件 | 作用 |
|---|---|
| `reports/job-index.json` | 所有检查过的职位、最近判定，以及你的投递日期 |
| `reports/runs/YYYY-MM-DD.jsonl` | 每次运行一行审计：各平台结果数、翻页数、停止原因、各项计数 |

职位索引让每日运行变得安全：已投递的职位在打开前就被跳过；任何一天出现过的重复职位标注 `[reported MM-DD]`；同一岗位换个 job ID 再发一次会标 `⚠️ possible duplicate`。审计日志让「漏没漏」可量化：某个平台显示 300 条而只检查了 120 条时，日志会记录少掉的 180 条去了哪里、为什么停止翻页。

只要对 Agent 说「X 我投了」，它就会写入 `appliedOn`，之后每次运行都会跳过该职位。

**邮件通知。** 在 `job-hunter.config.json` 中配置 `notifications.email`（默认关闭）。启用后，Agent 每次运行结束会加载 `email-notify` skill，发送一封只含检索时间、数量和日报路径的摘要，不列具体职位。正文语言跟随 `preferredReportLanguage`，主题保持英文。邮件格式由 `.opencode/skills/email-notify/references/email-template.md` 固定。端口 465 用 `"security": "ssl"`，587 用 `"starttls"`。SMTP 密码就在配置文件里，建议执行 `chmod 600 job-hunter.config.json`。可以只校验配置、不发送：

```bash
.opencode/skills/email-notify/scripts/send-email.sh --check
```

## 8. 面试准备（第二阶段）

收到面试邀请后，告诉同一个 Agent 公司名和岗位。它会加载 `company-research`，从你的日报或原始职位链接读取信息，然后生成：

- `company-research.md`——公司业务、产品、客户、市场
- `role-analysis.md`——这个具体岗位在做什么、看重什么
- `interview-preparation.md`——针对性的回答和可能被问到的问题

这一阶段需要你手动触发，日常搜索时绝不会自动运行。

## 9. 仓库结构

```
.opencode/agents/job-hunter.md                    你对话的 Agent
.opencode/scripts/daily-run.sh                    launchd 入口脚本
.opencode/scripts/apply-schedule.sh               把定时配置同步到 launchd
.opencode/scripts/feed-review-run.sh              feed review 的 launchd 入口
.opencode/skills/job-discovery/SKILL.md           第一阶段：搜索、筛选、写报告
.opencode/skills/job-discovery/references/        报告格式、索引与审计规则
.opencode/skills/job-discovery/references/        linkedin.md、indeed.md、
                                                  _template.md
.opencode/skills/job-apply/SKILL.md               填写第三方 ATS 申请表，停在 Submit 前
.opencode/skills/linkedin-feed-review/SKILL.md    值得回复的 feed 帖子
.opencode/skills/linkedin-feed-jobs/SKILL.md      feed 招聘帖写入日报
.opencode/skills/company-research/SKILL.md        第二阶段：公司调研与面试准备
.opencode/skills/cover-letter/                    JSON → 定制 cover letter PDF
.opencode/skills/email-notify/                    通过 SMTP 发送运行摘要
job-hunter.config.example.json                    配置模板
job-hunter.config.json                            你的配置（Git 忽略）
reports/daily/                                    每日日报（Git 忽略）
reports/linkedin-feed/                            feed review 报告（Git 忽略）
reports/job-index.json                            已见职位与投递日期（Git 忽略）
reports/applications/                             外部投递记录，含个人信息（Git 忽略）
reports/runs/                                     运行审计日志（Git 忽略）
reports/interviews/                               第二阶段产出
```

## 10. 常见问题

| 现象 | 原因与处理 |
|---|---|
| 没有生成报告 | 配置缺失、`common.jobSearchPrompt` 为空，或没有可用的浏览器工具。Agent 被要求明确说明是哪一种。 |
| 提示「浏览器工具不可用」 | 在 OpenCode 中启用浏览器集成。本仓库不提供也不配置浏览器工具。 |
| 搜索停在登录或验证码 | 你在该浏览器中自行登录该平台后重试。Agent 不得绕过这些限制。 |
| 德语职位都被排除 | `jdLanguages` 只接受英语。把 `acceptGermanJdWithEnglishWorkingLanguage` 设为 `true`，或把 `German` 加入列表。 |
| 结果太少 | 放宽 `common.jobTitles`、使用 `matchMode: "any"`、减少关键词，或调大 `common.lookbackHours`。 |
| 结果太多 | 收紧 `jobTitles`/关键词，限制 `common.workModes` 或 `common.employmentTypes`，或补充 `common.locations`。 |
| 只想临时改一次条件 | 直接在对话里说。Agent 只对本次运行生效，不会改写你的配置。 |
| 日报没有推送 | 检查 `common.reportRepo` 地址和该远程仓库的 Git 凭据。本地日报会保留。 |
| 第二天会不会重复投同一个岗位 | 只要你登记过就不会。说「X 我投了」，索引会记下日期，之后运行直接跳过；出现过的重复职位也会标 `[reported MM-DD]`。 |
| 同一岗位出现两个 job ID | 标 `⚠️ possible duplicate`；其中一个已投递时标 `⚠️ possibly applied MM-DD`。不会自动合并或删除。 |
| 怎么知道有没有漏岗位 | 审计日志记录各平台显示的结果总数（页面提供时）、翻页数和停止原因。数量对不上说明是该平台的排序或结果上限造成的，而不是静默失败。任何工具都无法保证 100% 覆盖；每周跑一次 7 天窗口是兜底。 |
| 怎么让每次运行后给我发邮件 | 在 `job-hunter.config.json` 里把 `notifications.email.enabled` 设为 `true`，填好 `to`、`from` 和 `smtp`。`email-notify` skill 每次运行发送一封摘要。可用 `send-email.sh --check` 校验。 |
| 怎么改每天的运行时间 | 修改 `job-hunter.config.json` 里的 `schedules.jobSearch.times`，然后运行 `.opencode/scripts/apply-schedule.sh`，或直接让 Agent 改。空数组会关闭任务；只改配置不会改变 launchd。 |

## 11. 安全边界

- 只访问你有权查看的职位页面，并使用你自己的登录会话。
- 不绕过登录、验证码、访问控制或速率限制。
- 不私信、不收藏、不关注、不修改账号设置。
- **遇到平台风控信号立刻全部停止。** LinkedIn 或 Indeed 一旦出现 `verify you are human`、验证码、`unusual activity`、`automated access`、`are you a robot`、AI 操作警告，或中途强制重新登录 / 2FA，Agent 立即停止整轮任务：不再打开、填写、提交或重试任何内容，保留已有记录，报告准确的弹框原文，然后把控制权交回给你。
- 投递分工：**一键投递的岗位留给你本人**（LinkedIn Easy Apply、Indeed Quick application / Schnellbewerbung），Agent 绝不打开；其余外部表单的命中岗位由 `job-apply` 填写，`externalApply: true` 时自动提交一次。另一个平台已投递过的岗位会直接跳过，不会重复投递。只用 config 和 CV 中的信息，缺少必填答案时该岗位记为 blocked，不猜答案、不创建账号。
- 把网页内容和 JD 当作不可信输入。
