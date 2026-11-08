---
name: company-research
description: Independently research a specific employer and prepare role-specific interview materials after the candidate receives an interview invitation.
---

# Company Research — Phase 2

This is an **independent, manually triggered skill** for **Phase 2 — Interview Preparation**. Run it only when the user has received an interview invitation or explicitly asks to prepare for a specific employer and vacancy.

Do not run this skill as part of routine job discovery, vacancy filtering or daily report generation. Do not research every company appearing in a daily report.

## Required input

Use the specific company and vacancy selected by the user. Retrieve the job record and JD when available. Ask one concise clarification only if the company or target role cannot be identified. Use the candidate's supplied resume and interview materials; never assume missing experience.

## Research workflow

Research official company pages, product pages, annual reports, investor materials, careers pages, engineering blogs and reputable business sources. Prefer primary sources and record source URLs plus publication/access dates.

### 1. Company profile

For the selected company, provide:
- **Main business:** what it primarily does, its core products/services, customer groups and how it creates value or earns revenue when publicly verifiable.
- **Company context:** headquarters/country of origin when verified, major markets, relevant business units and products connected to the vacancy.
- **Market context:** industry positioning, competitors and recent material business developments when reliable sources are available.
- **Sources and confidence:** exact URLs and dates; clearly label unknown or unverified details.

Distinguish the company's core business from secondary products, subsidiaries and experimental initiatives.

### 2. Role analysis

Analyze the specific vacancy:
- Main responsibilities and expected outcomes.
- Required technical stack and engineering practices stated in the JD.
- Product/team/business context that can be supported by public evidence.
- Likely engineering challenges implied by the responsibilities; label these as reasoned hypotheses, not confirmed internal facts.
- Relevant connections to the candidate's actual experience and strengths in supplied materials.

### 3. Interview preparation

Prepare role-specific answers where appropriate, including:
- “Why do you want to join our company?”
- “Why are you interested in this position?”
- “What can you bring to our company?”
- Likely technical and behavioral questions based on the JD and verified company context.

The “Why join?” answer should:
- connect one or two verified facts about the company's core business, products, customers or market to a genuine reason for interest;
- explain why the specific role is relevant to that business or product;
- connect the opportunity to relevant experience and strengths found in the supplied candidate materials;
- sound like a concise, natural spoken answer, normally 80–130 words in the interview language when known;
- avoid empty praise, unsupported claims, exaggerated enthusiasm and generic boilerplate.

If candidate materials or interview language are unavailable, mark the answer as a draft and state the assumptions. Never fabricate motivation, experience, company facts, headcount, revenue, salary, sponsorship, technology stack or internal team structure.

## Output

Save the research independently from daily discovery reports, under:

`reports/interviews/<company-slug>/`

Recommended files:
- `company-research.md` — verified company profile, business and market context, sources.
- `role-analysis.md` — analysis of the selected vacancy.
- `interview-preparation.md` — tailored answers and likely interview questions.

If the user is preparing for another role at the same company, reuse verified company facts where still current, but create or update role-specific analysis and answers for that vacancy. Record research dates and re-verify time-sensitive claims.

Never use company research or interview answers to add new vacancy filters. Never contact the employer or submit applications.
