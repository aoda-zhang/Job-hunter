# Job Hunter 配置指南（简体中文）

本项目只使用一个根配置文件：`job-hunter.config.json`。搜索范围、候选人资料和匹配规则全部集中在这里。修改配置即可切换国家、职位和目标市场，无须修改代码。

## 1. 配置结构

根配置包含三个顶层对象：

| 对象 | 用途 |
|---|---|
| `search` | 要搜索哪些国家、职位、地点和招聘来源 |
| `candidate` | 候选人的经验、技能、语言、薪资和工作许可背景 |
| `matching` | 职位匹配评分权重、分数阈值和分析规则 |

## 2. 完整示例

```json
{
  "search": {
    "countries": ["Germany", "Netherlands"],
    "roles": ["Senior Frontend Engineer", "React Developer"],
    "locations": ["Berlin", "Amsterdam", "Remote"],
    "workModes": ["remote", "hybrid"],
    "lookbackHours": 72,
    "maxResultsPerSource": 50,
    "sources": ["company-career-pages", "LinkedIn", "Indeed"],
    "excludeKeywords": ["intern", "junior"]
  },
  "candidate": {
    "headline": "Senior Frontend Engineer",
    "experienceYears": 9,
    "currentCountry": "China",
    "workAuthorization": {
      "status": "Assess separately for each target country",
      "note": "Verify eligibility and sponsorship requirements for each vacancy."
    },
    "languages": {
      "preferred": ["English"],
      "additional": [
        {"language": "German", "level": "B1", "note": "Currently learning"}
      ]
    },
    "salary": {
      "preferredMinimum": 65000,
      "currency": "EUR",
      "note": "Reference expectation; evaluate against local market."
    },
    "coreSkills": ["React", "TypeScript", "JavaScript"],
    "secondarySkills": ["Node.js", "NestJS"],
    "architectureSkills": ["Microfrontend", "Design Systems"],
    "experienceEvidence": ["Built enterprise frontend platforms with React and TypeScript."]
  },
  "matching": {
    "weights": {
      "roleTitle": 20,
      "coreSkills": 25,
      "architecture": 15,
      "seniority": 10,
      "domainExperience": 10,
      "locationAndWorkMode": 8,
      "language": 7,
      "salary": 5
    },
    "thresholds": {
      "strongMatch": 85,
      "goodMatch": 70,
      "possibleMatch": 55
    },
    "rules": [
      "Score evidence in the job description, not keyword frequency alone.",
      "Mark unstated requirements as unknown."
    ]
  }
}
```

## 3. search：搜索范围

| 字段 | 类型 | 必填 | 说明与配置方式 |
|---|---|---:|---|
| `countries` | string[] | 是 | 国家列表。可填一个或多个国家名称，例如 `["Germany", "Japan", "United States"]`。建议使用英文标准国名。 |
| `roles` | string[] | 是 | 职位名称列表。每个职位会作为独立搜索目标，例如 `["React Developer", "Frontend Engineer"]`。职位名称应使用招聘市场常见写法。 |
| `locations` | string[] | 否 | 城市、地区或 Remote，例如 `["Munich", "Tokyo", "Remote"]`。留空或删除该字段表示不额外限定地点；Remote 是否跨境可行需由职位信息确认。 |
| `workModes` | enum[] | 否 | 工作方式，可选 `remote`、`hybrid`、`onsite`、`flexible`。 |
| `lookbackHours` | integer | 是 | 搜索最近多少小时发布的职位。72 表示最近三天；必须大于 0。 |
| `maxResultsPerSource` | integer | 是 | 每个招聘来源最多收集多少条结果，必须大于 0。 |
| `sources` | string[] | 是 | 搜索来源标识，例如 `company-career-pages`、`LinkedIn`、`StepStone`、`Indeed`。只有已实现且允许访问的适配器才会真正执行。 |
| `excludeKeywords` | string[] | 否 | 排除职位标题或描述中出现的关键词，例如 `["intern", "working student", "junior"]`。具体匹配方式由发现引擎实现。 |

**搜索组合：** 设计上会将国家、职位和地点组合成搜索任务。比如 2 个国家 × 3 个职位，就是至少 6 组国家/职位搜索条件；实际抓取范围还取决于来源适配器。

## 4. candidate：候选人资料

| 字段 | 类型 | 必填 | 说明与配置方式 |
|---|---|---:|---|
| `headline` | string | 是 | 目标职业标题，用于候选人概况，例如 `Senior Frontend Engineer`。 |
| `experienceYears` | number | 是 | 总工作年限，可使用小数，例如 8.5；不能为负数。 |
| `currentCountry` | string | 是 | 当前所在国家，用于判断职位地点和跨境工作背景。 |
| `workAuthorization.status` | string | 是 | 当前工作许可状态的简要描述。不要把某个国家的许可结论套用到其他国家。 |
| `workAuthorization.note` | string | 是 | 补充说明。用于提醒分析器逐个职位核实签证、许可和雇主支持要求。 |
| `languages.preferred` | string[] | 是 | 候选人优先使用的工作语言，例如 `["English"]`。 |
| `languages.additional` | object[] | 是 | 其他语言。每项包含 `language`、`level`，以及可选的 `note`。等级建议写 CEFR（A1–C2）或当地常见等级。 |
| `salary.preferredMinimum` | number | 是 | 期望最低薪资数值，不能为负数。必须结合 `currency` 解释；不要把一个国家的数值直接当成另一个国家的市场标准。 |
| `salary.currency` | string | 是 | 三位货币代码，例如 EUR、USD、GBP、JPY。 |
| `salary.note` | string | 是 | 薪资期望的补充说明，例如税前年薪、可协商范围或仅作参考。 |
| `coreSkills` | string[] | 是 | 核心技能，通常是岗位必须具备的技术。 |
| `secondarySkills` | string[] | 是 | 次要或辅助技能。 |
| `architectureSkills` | string[] | 是 | 架构、工程实践和系统设计能力。 |
| `experienceEvidence` | string[] | 是 | 能证明技能和经验的项目/工作成果摘要。尽量写具体项目、职责、技术和结果，不要只堆关键词。 |

## 5. matching：匹配规则

### weights

每个键对应一个评分维度，数值表示该维度的相对权重：

| 字段 | 当前权重 | 说明 |
|---|---:|---|
| `roleTitle` | 20 | 职位名称与目标岗位的相关程度 |
| `coreSkills` | 25 | 核心技能匹配程度 |
| `architecture` | 15 | 架构、系统设计和工程实践 |
| `seniority` | 10 | 职级和经验年限 |
| `domainExperience` | 10 | 行业或业务领域经验 |
| `locationAndWorkMode` | 8 | 地点和工作方式 |
| `language` | 7 | 工作语言要求 |
| `salary` | 5 | 薪资匹配程度 |

权重建议合计为 100。当前配置中的权重合计为 100。调整权重时，建议同步归一化到 100，便于解释最终百分制分数。评分实现应按权重计算，而不是仅统计关键词。

### thresholds

| 字段 | 当前值 | 含义 |
|---|---:|---|
| `strongMatch` | 85 | 强匹配分数线 |
| `goodMatch` | 70 | 良好匹配分数线 |
| `possibleMatch` | 55 | 值得进一步评估的分数线 |

分数低于 `possibleMatch` 可归为低匹配，但不能仅凭分数自动淘汰；阈值应满足 `strongMatch >= goodMatch >= possibleMatch`。

### rules

字符串数组，用自然语言约束分析过程。例如：区分必需技能和加分项；未说明的薪资或签证信息标记为 unknown；每项评分都要给出职位描述和候选人经历证据。可根据你的评估标准增删规则。

## 6. 常见配置场景

- **换国家：** 修改 `search.countries`。
- **换岗位：** 修改 `search.roles`。
- **增加城市：** 修改 `search.locations`。
- **只看远程：** 将 `workModes` 设置为 `["remote"]`。
- **不限制工作方式：** 删除 `workModes`。
- **调整匹配偏好：** 修改 `matching.weights` 和 `matching.thresholds`。
- **更新个人技能：** 修改 `candidate`，不要把个人技能写进搜索关键词字段。

## 7. 校验与边界

运行 `npm run config:check` 校验配置。配置结构由 `src/config.ts` 中的 Zod schema 定义。

配置校验通过不代表职位来源已经实现。来源适配器仍需单独开发，并遵守对应网站的条款、访问限制和频率要求。本项目不会自动投递简历或联系雇主。
