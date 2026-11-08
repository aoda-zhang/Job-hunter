# Job Hunter 配置指南（简体中文）

Job Hunter 是一个通用、多国家、多职位的职位发现工具，工作流分为两个独立阶段：

- **第一阶段：职位搜索与简历投递。** 根据目标职位搜索岗位，只通过职位名称、JD 语言和技术关键词三个维度筛选，并生成每日 Markdown 报告。
- **第二阶段：面试准备。** 收到面试邀请后，针对具体公司和岗位，手动调用独立的公司调研 Skill。

## 1. 单一根配置文件

所有搜索配置只放在根目录的 `job-hunter.config.json` 中。

国家、地点、发布时间和招聘来源仅用于确定搜索范围，不参与候选人匹配评分。你的简历和技术背景用于帮助确定目标职位和技术关键词，不会额外引入候选人评分或其他自动淘汰条件。

## 2. 完整配置示例

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

## 3. 第一阶段：职位搜索与投递

运行 `npm run report`（或 `npm run dev -- report`）生成或覆盖当天报告：

`reports/daily/YYYY-MM-DD.md`

报告按公司名称分组，仅为阅读方便，不代表系统会在此阶段调研公司。每个职位展示：

- Job Title、Company Name
- Country、Location、Work Mode
- JD Language
- Technical Keywords（在 JD 中找到的配置关键词）
- Filter Status 和 Filter Evidence
- Posted Date、Discovered Date
- 招聘来源和职位链接
- JD 摘要及原始 JD（如有）

报告包含确认匹配的岗位和需要人工复核的岗位；明确不匹配的岗位不进入日报主体，但保留在数据库审计记录中。未知或信息不足的字段必须标记为 Unknown / Review，不允许静默丢弃。

**第一阶段不执行公司深度调研，也不生成 “Why do you want to join our company?” 等面试答案。** 这一阶段的目标是帮助你快速发现、判断和投递职位。

## 4. 第二阶段：独立公司调研与面试准备 Skill

当你拿到面试邀请后，针对具体公司和岗位手动调用：

`.opencode/skills/company-research/SKILL.md`

该 Skill 独立完成：

1. **公司调研：** 公司主要业务、核心产品/服务、客户群体、商业模式、总部和主要市场。
2. **市场背景：** 行业定位、竞争对手及近期重要业务动态（以可靠来源为准）。
3. **岗位分析：** 岗位职责、技术栈、业务关联，以及你的真实项目经历与岗位要求之间的联系。
4. **面试准备：** Why do you want to join our company?、Why this position?、What can you bring?，以及针对岗位的技术和行为面试问题。

调研结果独立保存在：

`reports/interviews/<company-slug>/`

建议包含 `company-research.md`、`role-analysis.md` 和 `interview-preparation.md`。同一家公司的公司背景可以复用，但不同岗位的分析和答案需要分别定制。

该 Skill 不会在日常职位搜索时自动运行，也不会调研日报中的所有公司。

## 5. 三个职位筛选维度

| 维度 | 配置字段 | 规则 |
|---|---|---|
| Job Title | `jobTitles.include` | 支持常见职位名称变体和语义近似匹配 |
| JD Language | `jdLanguages.include` | 识别 JD 的实际主要语言，不根据国家推断 |
| Technical Keywords | `technicalKeywords.include` | 在 JD 中查找目标技术关键词 |

`technicalKeywords.matchMode`：
- `any`：任意一个关键词命中即可，推荐使用，降低漏掉潜在岗位的风险。
- `all`：必须命中所有配置关键词。

只有三个维度都确认匹配，才标记为 Matched。任一维度明确不匹配才可标记为 Not matched；无法判断时标记为 Review 并保留。

## 6. 明确不作为筛选条件的内容

工作年限、职级、薪资、签证/工作许可、候选人的语言熟练程度、行业背景、架构经验等不参与自动筛选。系统不计算综合匹配分数，也不设置分数淘汰线。

## 7. 校验与当前边界

运行 `npm run config:check` 校验配置，Zod schema 位于 `src/config.ts`。

目前每日 Markdown 报告生成器已实现；招聘网站适配器、完整职位采集和确定性三维筛选执行器仍待开发。第二阶段的独立 Skill 规范和数据库持久化表已定义，但自动公司调研、面试答案生成和面试材料持久化流程仍待开发。

本项目不会自动投递简历或联系雇主；必须遵守招聘网站条款、访问限制和频率要求。
