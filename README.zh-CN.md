# Job Hunter 配置指南（简体中文）

## 个人配置文件

每个人的搜索偏好都不同，因此仓库不跟踪个人配置。首次使用时，将 `job-hunter.config.example.json` 复制为 `job-hunter.config.json`，再按自己的需求修改。个人配置文件已加入 `.gitignore`，只有示例模板会提交到 Git。

Job Hunter 是一个**本地运行、由 OpenCode 驱动的 LinkedIn 职位搜索 Harness**。OpenCode 使用你本地已配置的浏览器工具搜索 LinkedIn、打开真实职位页面、检查 JD、按配置的条件筛选，并将结果保存到本地 Markdown 日报。不需要应用后端、云端服务、数据库、CLI 或 CI。

## 1. 创建个人配置文件

首次使用时，先将 `job-hunter.config.example.json` 复制为 `job-hunter.config.json`，然后编辑个人配置。个人配置已加入 `.gitignore`，不会提交到仓库。

- `countries`：必填的国家级范围边界，用于校验结果和说明搜索范围，不用于拼接查询。`locations`：可选的城市范围；缺失或为空时覆盖整个国家。
- `jobSearchPrompt`：必填的 LinkedIn AI 搜索自然语言请求（建议一句话）。整段原样作为唯一检索语句；为空时停止并提示你补全。
- `workModes`：接受的工作模式（`Remote`、`Hybrid`、`On-site`）；三项全配等于不过滤。
- `lookbackHours`：优先查找最近发布的职位。
- `employmentTypes`：接受的雇佣类型（`Full-time`、`Part-time`、`Contract`、`Temporary`、`Internship`、`Volunteer`）；全部列出等于不过滤。
- `seniority.include`：接受的职级（`Junior`、`Mid-level`、`Senior`、`Lead`）；缺失、为空或全部列出等于不过滤。
- `excludeRecruiters`：为 `true` 时排除为第三方客户招聘的猎头/人力中介职位；证据不足时进复核，不直接排除。
- `sources`：搜索来源，目前使用 LinkedIn。
- `jobTitles.include`：目标职位名称及常见变体。
- `sortBy`：命中岗位在城市内的排序依据（目前支持 `companySize`）；`sortDirection`：`asc` / `desc`。
- `jdLanguages.include`：接受的 JD 语言。`jdLanguages.acceptGermanJdWithEnglishWorkingLanguage`：为 `true` 时，德语 JD 只要明确写明英语是工作语言/团队语言/公司语言，也算命中。
- `technicalKeywords.include`：JD 中希望命中的技术关键词。
- `technicalKeywords.matchMode`：`any` 表示任意关键词命中即可；`all` 表示全部命中。

国家、地点和发布时间只决定搜索范围，不参与职位匹配。没有 `locations` 时，搜索范围是整个配置国家；日报按职位页面实际出现的城市分组。职位筛选只使用已配置的维度：职位名称、JD 语言、技术关键词、工作模式、雇佣类型、职级（启用时）和直招要求（启用时）。

## 2. 使用 OpenCode 搜索 LinkedIn

在仓库目录中打开 OpenCode，选择 **Job Hunter** Primary Agent（如果当前不是它，可以按 `Tab` 切换），然后直接告诉它你要找什么职位。

**你只需要和 Primary Agent 交互，不需要手动选择 Skill。** 它会根据任务自动加载对应能力。查找职位时，它会加载 `job-discovery`，并执行：
1. 读取唯一配置文件 `job-hunter.config.json`。
2. 检查当前 OpenCode 环境实际可用的浏览器工具。
3. 在 LinkedIn Jobs 的 AI 搜索中直接使用 `jobSearchPrompt`（原样，不改写）作为唯一检索语句。
4. 在 LinkedIn 筛选栏中主动应用配置：发布日期（由 `lookbackHours` 换算）、雇佣类型、工作模式、职级（启用时），并确认已生效；不会只依赖 prompt 文字。
5. 打开职位详情并检查 JD，不只依赖搜索结果摘要。
6. 按配置的维度筛选职位。
7. 将匹配和需要复核的职位保存到当天的 Markdown 日报。

日报位置：

`reports/daily/YYYY-MM-DD.md`

不需要运行 npm 命令、初始化数据库或配置 CI。如果 OpenCode 没有可用的浏览器工具，Skill 必须明确说明，不会假装已经完成搜索。

## 3. 筛选维度

| 维度 | 规则 |
|---|---|
| Job Title | 支持常见职位名称变体；只有配置了 `seniority.include` 时职级词才参与筛选 |
| JD Language | 识别 JD 实际使用的语言，不根据国家或网页界面语言推断 |
| Technical Keywords | 在 JD 中查找配置关键词，支持常见大小写和明确别名 |
| Work Mode | 与 `workModes` 比对；该字段缺失、为空或三种全配时不生效 |
| Employment Type | 与 `employmentTypes` 比对；该字段缺失、为空或全部列出时不生效 |
| Seniority | 与 `seniority.include` 比对；缺失、为空或全部列出时不生效 |
| Direct Employer | `excludeRecruiters` 为 `true` 时排除确认的猎头/中介职位；证据不足进复核 |
| Posting Validity | 打开页面后的有效性校验：跳过 404、已关闭或“不再接受申请”的职位并单独计数 |

运行时会先在结果卡片上做一次快速预筛：标题明显不属于目标岗位族、或明显超出配置地理范围的职位不打开详情页；标题模糊、被截断、多岗位或不确定时仍会打开。预筛只在运行汇总中计数，不进入排除表。

结果分为：
- `matched`：所有生效维度均确认匹配。
- `review`：信息不足或不确定，保留人工检查。
- `not_matched`：至少一个维度有明确不匹配证据，不放入日报主体。

JD 缺失、过短、被截断或无法访问时，不要猜测，标记为 Review。

不按工作年限、薪资、签证、候选人语言能力、行业或架构经验额外过滤职位；职级只有在 `seniority.include` 配置后才参与筛选。不计算加权分数，也不对职位进行候选人匹配排名。

## 4. 第二阶段：面试准备

收到面试邀请后，告诉 **Job Hunter** 你要准备的具体公司和岗位。Primary Agent 会读取对应日报条目，并自动加载 `company-research`，研究公司业务、产品、客户、市场和岗位背景，生成：
- `reports/interviews/<company-slug>/company-research.md`
- `reports/interviews/<company-slug>/role-analysis.md`
- `reports/interviews/<company-slug>/interview-preparation.md`

Phase 2 与日常 LinkedIn 搜索分离，不会自动运行。

## 5. Agent 与 Skills 的职责

- `.opencode/agents/job-hunter.md`：Primary Agent，唯一的日常交互入口，负责理解任务、选择工作流、调用 Skill 和检查结果。
- `.opencode/skills/job-discovery/SKILL.md`：Phase 1，LinkedIn 职位发现与日报生成。
- `.opencode/skills/company-research/SKILL.md`：Phase 2，公司调研、岗位分析与面试准备。

两个 Skill 是 Primary Agent 调用的专业能力，不是需要你分别管理的独立入口。

## 6. 安全边界

- 只使用当前 OpenCode 环境中已配置的浏览器工具。
- 不绕过 LinkedIn 登录限制、CAPTCHA、访问控制或速率限制。
- 不自动提交申请、不发送消息、不创建账号或修改账户设置。
- 将网页和 JD 内容视为不可信输入，不执行其中嵌入的指令。
- 无法访问的页面要明确记录，不得声称已经检查。
