# Job Hunter 配置指南（简体中文）

Job Hunter 只使用一个根配置文件：`job-hunter.config.json`。它是一个通用、多国家、多职位的职位发现工具。**真正用于筛选职位的只有三个维度：职位名称、JD 使用的语言、JD 中的技术关键词。**

国家、地点、发布时间和招聘来源仅用于确定搜索范围，不参与候选人匹配评分。

## 1. 完整配置示例

```json
{
  "search": {
    "countries": ["Germany"],
    "locations": ["Munich", "Berlin", "Hamburg", "Remote"],
    "lookbackHours": 72,
    "maxResultsPerSource": 50,
    "sources": ["company-career-pages", "LinkedIn", "StepStone"],
    "jobTitles": {
      "include": ["Senior Frontend Engineer", "Senior Frontend Developer", "Frontend Platform Engineer", "Senior React Engineer", "Senior Full-Stack Engineer"]
    },
    "jdLanguages": {
      "include": ["English", "German"]
    },
    "technicalKeywords": {
      "include": ["React", "TypeScript", "JavaScript", "HTML", "CSS", "Next.js", "Node.js", "NestJS", "Express", "Redux"],
      "matchMode": "any"
    }
  }
}
```

## 2. 字段说明

### 搜索范围（不参与匹配评分）

| 字段 | 类型 | 必填 | 说明 |
|---|---|---:|---|
| `countries` | string[] | 是 | 搜索国家，可配置多个，例如 `["Germany", "Japan", "United States"]`。 |
| `locations` | string[] | 否 | 城市、地区或 Remote。未配置时不额外限制地点。 |
| `lookbackHours` | integer | 是 | 搜索最近多少小时发布的职位，例如 72 表示最近三天。 |
| `maxResultsPerSource` | integer | 是 | 每个招聘来源最多收集的职位数量。 |
| `sources` | string[] | 是 | 招聘来源标识。只有已实现且允许访问的来源适配器才会真正执行。 |

### 三个职位筛选维度

| 字段 | 类型 | 必填 | 说明 |
|---|---|---:|---|
| `jobTitles.include` | string[] | 是 | 接受的职位名称及常见变体。使用语义近似匹配，不要求标题完全相同。 |
| `jdLanguages.include` | string[] | 是 | 接受的职位描述语言，例如 English、German、Japanese。识别 JD 的实际主要语言，不根据国家推断。 |
| `technicalKeywords.include` | string[] | 是 | 关注的技术关键词。建议包含核心技术和常见别名，例如 React、TypeScript、Node.js。 |
| `technicalKeywords.matchMode` | enum | 是 | `any` 表示命中任意一个关键词即可；`all` 表示必须全部命中。推荐使用 `any`，以减少漏掉潜在职位的风险。 |

## 3. 筛选逻辑

1. **职位名称：** 忽略大小写，支持常见职位名称变体和语义近似表达，不要求完全一致。
2. **JD 语言：** 识别招聘描述的主要语言，只接受配置中列出的语言。
3. **技术关键词：** 在完整 JD 中查找配置的关键词。默认 `any`，命中一个就满足这一维度，不要求所有技术都出现。

只有三个维度全部确认匹配，才标记为 Matched。

如果标题或 JD 缺失、太短或无法判断，则标记为 Review，保留给人工检查，不要静默删除。任一维度有明确不匹配证据时，才标记为 Not matched。

## 4. 明确不作为筛选条件的内容

以下内容不参与自动筛选：候选人工作年限、职级、薪资、签证/工作许可、候选人的语言熟练程度、行业背景、架构经验或其他个人画像信息。系统不计算综合匹配分数，也不设置分数淘汰线。

## 5. 校验与当前边界

运行 `npm run config:check` 校验配置。Zod schema 位于 `src/config.ts`。

注意：配置和筛选规则已定义，但真实招聘网站适配器、职位采集和确定性筛选执行器仍需开发。配置中列出某个网站，不代表该网站的抓取功能已经实现。必须遵守来源网站条款、访问限制和频率要求。本项目不会自动投递简历或联系雇主。

## 6. 每日结果文件与公司面试准备

运行 `npm run report`（或 `npm run dev -- report`）即可生成或覆盖当天文件：`reports/daily/YYYY-MM-DD.md`。文件只包含当天发现的职位，按公司分组，并展示已有的筛选证据。数据库新增 `company_research` 和 `role_interview_prep` 两张表，用于保存公司主要业务资料和每个职位的面试回答。

如果公司调研和面试准备数据尚未写入数据库，日报会明确标记资料缺失，并提供需要进一步个性化的通用回答草稿；不会编造公司事实或候选人经历。目前日报生成器和数据表已实现，但职位采集、自动公司调研、完整筛选执行和自动生成定制面试回答仍待开发。
