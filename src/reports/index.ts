import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { db } from "../db/index.js";

interface JobRow {
  id: number;
  source: string;
  url: string;
  title: string;
  company: string;
  country: string | null;
  location: string | null;
  work_mode: string | null;
  description: string | null;
  posted_at: string | null;
  discovered_at: string;
  analysis_json: string | null;
}

interface CompanyResearchRow {
  company: string;
  website: string | null;
  main_business: string | null;
  products_services: string | null;
  customer_groups: string | null;
  business_model: string | null;
  role_relevance: string | null;
  sources_json: string | null;
  researched_at: string | null;
}

interface InterviewPrepRow {
  job_id: number;
  language: string | null;
  answer: string;
  sources_json: string | null;
  updated_at: string;
}

function escapeCell(value: unknown): string {
  return String(value ?? "Not available").replace(/\|/g, "\\|").replace(/\r?\n/g, " ");
}

function parseJson(value: string | null): Record<string, unknown> | null {
  if (!value) return null;
  try {
    const parsed: unknown = JSON.parse(value);
    return parsed && typeof parsed === "object" && !Array.isArray(parsed)
      ? parsed as Record<string, unknown>
      : null;
  } catch {
    return null;
  }
}

function resultStatus(analysisJson: string | null): "matched" | "review" | "not_matched" {
  const parsed = parseJson(analysisJson);
  const status = parsed?.status;
  if (status === "matched" || status === "review" || status === "not_matched") return status;
  // Existing records without filter evidence are retained for human review, never silently discarded.
  return "review";
}

function sourceList(value: string | null): string[] {
  if (!value) return [];
  try {
    const parsed: unknown = JSON.parse(value);
    if (Array.isArray(parsed)) return parsed.filter((item): item is string => typeof item === "string");
  } catch { /* malformed optional research metadata */ }
  return [];
}

function whyJoinDraft(company: string, title: string, language: string | null): string {
  if (language && !/^en(?:glish)?$/i.test(language)) {
    return "Interview answer not generated: the configured interview language is " +
      language + ". Add verified company research and candidate-specific evidence before drafting.";
  }
  return `Draft — personalize before using:

“I’m interested in joining ${company} because I’d like to contribute to the products and services behind its core business. The ${title} role particularly interests me because it offers an opportunity to apply my relevant engineering experience to real product and customer needs. I’d like to learn more about the team’s current priorities and how this role can help improve the product. I believe the strongest reason for joining is the connection between the company’s business, the challenges of this position, and the experience I can bring.”

Personalize this answer with verified company products/business facts and one concrete, truthful example from your own experience. Do not use this generic draft unchanged.`;
}

function companyKey(name: string): string {
  return name.trim().toLocaleLowerCase().replace(/\s+/g, " ");
}

function renderSources(sources: string[]): string {
  if (!sources.length) return "Research sources: not added yet.";
  return sources.map((url) => `- ${url}`).join("\n");
}

export function generateDailyReport(date = new Date()): string {
  const dateKey = [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0")
  ].join("-");
  const outputPath = resolve(process.cwd(), "reports", "daily", `${dateKey}.md`);

  const jobs = db.prepare(`
    SELECT id, source, url, title, company, country, location, work_mode,
           description, posted_at, discovered_at, analysis_json
    FROM jobs
    WHERE date(discovered_at, 'localtime') = ?
    ORDER BY company COLLATE NOCASE, discovered_at DESC
  `).all(dateKey) as JobRow[];

  const visibleJobs = jobs.filter((job) => resultStatus(job.analysis_json) !== "not_matched");
  const companies = new Map<string, JobRow[]>();
  for (const job of visibleJobs) {
    const key = companyKey(job.company);
    const existing = companies.get(key) ?? [];
    if (!existing.some((item) => item.url === job.url)) existing.push(job);
    companies.set(key, existing);
  }

  const companyRows = db.prepare(`
    SELECT company, website, main_business, products_services, customer_groups,
           business_model, role_relevance, sources_json, researched_at
    FROM company_research
  `).all() as CompanyResearchRow[];
  const researchByCompany = new Map(companyRows.map((row) => [companyKey(row.company), row]));

  const prepRows = db.prepare(`
    SELECT job_id, language, answer, sources_json, updated_at
    FROM role_interview_prep
  `).all() as InterviewPrepRow[];
  const prepByJob = new Map(prepRows.map((row) => [row.job_id, row]));

  const lines: string[] = [
    `# Job Search Daily Report — ${dateKey}`,
    "",
    `Generated: ${date.toLocaleString()}`,
    `Vacancies included: ${visibleJobs.length} | Companies: ${companies.size}`,
    "",
    "> Includes confirmed matches and records requiring manual review. Records without filter evidence are retained as Review. Confirmed non-matches are excluded.",
    "",
    "## Summary",
    "",
    `- Confirmed matches: ${visibleJobs.filter((job) => resultStatus(job.analysis_json) === "matched").length}`,
    `- Needs review: ${visibleJobs.filter((job) => resultStatus(job.analysis_json) === "review").length}`,
    ""
  ];

  if (!visibleJobs.length) {
    lines.push("No eligible vacancies are currently stored in the database.", "");
  }

  for (const [key, companyJobs] of companies) {
    const companyName = companyJobs[0].company;
    const research = researchByCompany.get(key);
    lines.push(`## ${companyName}`, "");
    lines.push(`### Company overview`, "");
    lines.push(`- Website: ${research?.website ?? "Not researched yet"}`);
    lines.push(`- Main business: ${research?.main_business ?? "Research required — add a verified plain-language description of the company's core business."}`);
    lines.push(`- Products / services: ${research?.products_services ?? "Not researched yet"}`);
    lines.push(`- Customer groups: ${research?.customer_groups ?? "Not researched yet"}`);
    lines.push(`- Business model: ${research?.business_model ?? "Not verified / not researched yet"}`);
    lines.push(`- Relevance to these vacancies: ${research?.role_relevance ?? "Explain how the advertised roles connect to the company's products or business unit."}`);
    if (research?.researched_at) lines.push(`- Research updated: ${research.researched_at}`);
    lines.push("", renderSources(sourceList(research?.sources_json ?? null)), "");

    for (const job of companyJobs) {
      const status = resultStatus(job.analysis_json);
      const analysis = parseJson(job.analysis_json);
      const checks = analysis?.checks && typeof analysis.checks === "object"
        ? analysis.checks as Record<string, unknown> : null;
      const prep = prepByJob.get(job.id);
      lines.push(`### ${job.title}`, "");
      lines.push(`- Filter status: **${status === "matched" ? "Matched" : "Review"}**`);
      lines.push(`- Location: ${escapeCell([job.location, job.country].filter(Boolean).join(", "))}`);
      lines.push(`- Work mode: ${escapeCell(job.work_mode)}`);
      lines.push(`- Posted: ${escapeCell(job.posted_at)}`);
      lines.push(`- Discovered: ${escapeCell(job.discovered_at)}`);
      lines.push(`- Source: ${escapeCell(job.source)}`);
      lines.push(`- Job link: ${job.url}`);
      if (checks) {
        lines.push("", "**Filter evidence**", "");
        for (const [dimension, detail] of Object.entries(checks)) {
          lines.push(`- ${dimension}: ${escapeCell(JSON.stringify(detail))}`);
        }
      } else {
        lines.push("- Filter evidence: not available; manual review required.");
      }
      lines.push("", "#### Interview: “Why do you want to join our company?”", "");
      lines.push(prep?.answer ?? whyJoinDraft(companyName, job.title, prep?.language ?? null));
      if (prep?.sources_json) lines.push("", "**Interview-answer sources**", "", renderSources(sourceList(prep.sources_json)));
      lines.push("");
      if (job.description) {
        lines.push("<details>", "<summary>Job description</summary>", "", job.description, "", "</details>", "");
      }
    }
  }

  lines.push("## Research and preparation checklist", "");
  lines.push("- [ ] Verify the company's main business, products and customer groups using official sources.");
  lines.push("- [ ] Add source URLs and publication/access dates for company facts.");
  lines.push("- [ ] Replace generic interview drafts with role-specific answers grounded in verified company facts and your actual experience.");
  lines.push("- [ ] Check uncertain vacancies manually; do not treat Review as a rejection.");
  lines.push("");
  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, lines.join("\n"), "utf8");
  return outputPath;
}
