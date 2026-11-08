# Job Hunter 配置指南（简体中文）

Job Hunter 是一个多国家、多职位的职位发现工具，分为两个互相独立的阶段。

- **第一阶段：职位搜索与简历投递。** 只围绕职位名称、JD 语言和技术关键词搜索、筛选，并生成每日 Markdown 报告。
- **第二阶段：面试准备。** 收到面试邀请后，针对选定公司和岗位，手动执行独立的公司调研 Skill。

## 1. 单一根配置文件

所有搜索设置只放在根目录的 `job-hunter.config.json`。国家、地点、发布时间和来源决定搜索范围，不参与候选人匹配评分。简历用于确定目标职位和技术关键词，不引入额外评分或自动淘汰条件。

## 2. 配置示例

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
    "jdLanguages": { "include": ["English", "German"] },
    "technicalKeywords": {
      "include": ["React", "TypeScript", "JavaScript", "HTML", "CSS", "Next.js", "Node.js", "NestJS", "Express", "Redux"],
      "matchMode": "any"
    }
  }
}
```

## 3. 第一阶段：职位搜索与投递

运行 `npm run report` 生成当天报告：`reports/daily/YYYY-MM-DD.md`。

每个岗位展示：
- Job Title、Company Name、Country、Location、Work Mode
- JD Language
- Technical Keywords（在 JD 中找到的配置关键词）
- Filter Status 和 Filter Evidence
- Posted Date、Discovered Date
- 招聘来源、职位链接
- JD 摘要及原始 JD（如有）

报告包含确认匹配和需要人工复核的岗位。明确不匹配的岗位不进入日报主体，但保留在数据库审计记录中。公司名称分组仅用于阅读，不代表公司调研。

**第一阶段不调研公司，也不生成 Why do you want to join our company 等面试答案。** 不按工作年限、薪资、签证、职级、行业或架构经验额外淘汰职位。

## 4. 第二阶段：面试准备

收到面试邀请后，先通过岗位 ID 生成调研输入：

`npm run interview:prepare -- --job-id 123`

也可以使用公司名称：

`npm run interview:prepare -- --company "Exact Company Name"`

如果该公司有多个已保存岗位，命令会列出岗位 ID，要求你明确选择具体岗位。命令会读取数据库中的岗位信息和 JD，并生成：

`reports/interviews/<company-slug>/roles/job-<id>/research-input.md`

随后手动调用独立 Skill：

`.opencode/skills/company-research/SKILL.md`

该 Skill 负责：
1. 公司主要业务、产品/服务、客户群体、商业模式和主要市场。
2. 行业定位、竞争对手及近期重要业务动态（以可靠来源为准）。
3. 具体岗位职责、技术栈、业务背景及与你真实项目经历的关联。
4. Why do you want to join our company?、Why this position?、What can you bring? 以及技术和行为面试准备。

输出目录：
- `reports/interviews/<company-slug>/company-research.md`：同一公司可复用的公司调研。
- `reports/interviews/<company-slug>/roles/job-<id>/role-analysis.md`：岗位专属分析。
- `reports/interviews/<company-slug>/roles/job-<id>/interview-preparation.md`：岗位专属面试准备。

CLI 命令只准备岗位上下文，不会自行联网调研或生成面试答案；实际调研由独立 Skill 完成。第二阶段不会反向改变第一阶段的筛选规则。

## 5. 三个筛选维度

| 维度 | 配置字段 | 规则 |
|---|---|---|
| Job Title | `jobTitles.include` | 支持常见职位名称变体 |
| JD Language | `jdLanguages.include` | 识别 JD 实际主要语言，不根据国家推断 |
| Technical Keywords | `technicalKeywords.include` | 在 JD 中查找配置关键词 |

`matchMode: "any"` 表示任意一个关键词命中即可，推荐使用；`all` 表示所有关键词都必须出现。未知或信息不足的情况标记为 Review 并保留。

## 6. 当前开发状态

每日 Markdown 报告生成器和第二阶段岗位上下文生成器已实现。招聘网站适配器、完整职位采集和确定性三维筛选执行器仍待开发。公司调研 Skill 已定义；自动联网调研、面试答案生成和相关结果持久化流程仍待开发。

项目不会自动投递简历或联系雇主。
