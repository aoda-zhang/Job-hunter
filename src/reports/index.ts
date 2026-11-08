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

function companyKey(name: string): string {
  return name.trim().toLocaleLowerCase().replace(/\s+/g, " ");
}

function getCheck(checks: Record<string, unknown> | null, aliases: string[]): unknown {
  if (!checks) return undefined;
  const wanted = new Set(aliases.map((name) => name.toLowerCase().replace(/[^a-z]/g, "")));
  const entry = Object.entries(checks).find(([name]) =>
    wanted.has(name.toLowerCase().replace(/[^a-z]/g, ""))
  );
  return entry?.[1];
}

function formatEvidence(value: unknown): string {
  if (value === undefined || value === null) return "Not available — manual review may be required.";
  return typeof value === "string" ? value : JSON.stringify(value);
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

  const lines: string[] = [
    `# Job Discovery Daily Report — ${dateKey}`,
    "",
    `Generated: ${date.toLocaleString()}`,
    `Vacancies included: ${visibleJobs.length} | Companies: ${companies.size}`,
    "",
    "> Phase 1 report: vacancy discovery and the three configured filters only. Company research and interview preparation are handled separately in Phase 2.",
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
    void key;
    const companyName = companyJobs[0].company;
    lines.push(`## ${companyName}`, "");

    for (const job of companyJobs) {
      const status = resultStatus(job.analysis_json);
      const analysis = parseJson(job.analysis_json);
      const checks = analysis?.checks && typeof analysis.checks === "object"
        ? analysis.checks as Record<string, unknown> : null;

      lines.push(`### ${job.title}`, "");
      lines.push(`- Filter status: **${status === "matched" ? "Matched" : "Review"}**`);
      lines.push(`- Country: ${escapeCell(job.country)}`);
      lines.push(`- Location: ${escapeCell(job.location)}`);
      lines.push(`- Work mode: ${escapeCell(job.work_mode)}`);
      lines.push(`- JD language: ${escapeCell(formatEvidence(getCheck(checks, ["jdLanguage", "language", "jd_language"])))}`);
      lines.push(`- Technical keywords: ${escapeCell(formatEvidence(getCheck(checks, ["technicalKeywords", "keywords", "technical_keywords"])))}`);
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

      if (job.description) {
        const summary = job.description.replace(/\s+/g, " ").trim().slice(0, 500);
        lines.push("", "**JD summary**", "", summary + (job.description.length > 500 ? "…" : ""));
        lines.push("", "<details>", "<summary>Full job description</summary>", "", job.description, "", "</details>", "");
      }
      lines.push("");
    }
  }

  lines.push(
    "## Review checklist",
    "",
    "- [ ] Check vacancies marked Review and confirm missing or ambiguous filter evidence.",
    "- [ ] Open the original JD and verify the role details before applying.",
    "- [ ] Save interview-stage company research for roles that result in an interview invitation.",
    ""
  );

  mkdirSync(dirname(outputPath), { recursive: true });
  writeFileSync(outputPath, lines.join("\n"), "utf8");
  return outputPath;
}
