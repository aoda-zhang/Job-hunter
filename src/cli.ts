import "dotenv/config";
import { initializeDatabase } from "./db/index.js";
import { loadConfig } from "./config.js";
import { generateDailyReport } from "./reports/index.js";
import { prepareInterviewResearch } from "./interviews/index.js";

const command = process.argv[2];

function readInterviewSelector(args: string[]): { jobId?: number; company?: string } {
  const jobIdIndex = args.indexOf("--job-id");
  const companyIndex = args.indexOf("--company");
  if (jobIdIndex !== -1 && companyIndex !== -1) {
    throw new Error("Use either --job-id or --company, not both.");
  }
  if (jobIdIndex !== -1) {
    const raw = args[jobIdIndex + 1];
    if (!raw || !/^\d+$/.test(raw)) throw new Error("Usage: npm run interview:prepare -- --job-id <id>");
    return { jobId: Number(raw) };
  }
  if (companyIndex !== -1) {
    const company = args.slice(companyIndex + 1).join(" ").trim();
    if (!company) throw new Error('Usage: npm run interview:prepare -- --company "Exact Company Name"');
    return { company };
  }
  throw new Error('Choose a vacancy with --job-id <id> or --company "Exact Company Name".');
}

async function main(): Promise<void> {
  switch (command) {
    case "config:check": {
      const config = loadConfig();
      console.log("Job Hunter configuration is valid.");
      console.log(JSON.stringify({
        countries: config.search.countries,
        jobTitles: config.search.jobTitles.include,
        jdLanguages: config.search.jdLanguages.include,
        technicalKeywords: config.search.technicalKeywords.include,
        keywordMatchMode: config.search.technicalKeywords.matchMode
      }, null, 2));
      break;
    }
    case "db:init":
      initializeDatabase();
      console.log("Database initialized.");
      break;
    case "discover": {
      const config = loadConfig();
      initializeDatabase();
      console.log("Discovery configuration loaded.");
      console.log(`Countries: ${config.search.countries.join(", ")}`);
      console.log(`Job titles: ${config.search.jobTitles.include.join(" | ")}`);
      console.log(`JD languages: ${config.search.jdLanguages.include.join(", ")}`);
      console.log(`Technical keywords: ${config.search.technicalKeywords.include.join(", ")}`);
      console.log(`Keyword match mode: ${config.search.technicalKeywords.matchMode}`);
      console.log("Discovery scaffold ready. Implement and configure permitted source adapters to collect postings.");
      break;
    }
    case "report": {
      initializeDatabase();
      const outputPath = generateDailyReport();
      console.log(`Daily report generated: ${outputPath}`);
      break;
    }
    case "interview:prepare": {
      initializeDatabase();
      const selector = readInterviewSelector(process.argv.slice(3));
      const outputPath = prepareInterviewResearch(selector);
      console.log(`Interview research input prepared: ${outputPath}`);
      console.log("Next: invoke .opencode/skills/company-research/SKILL.md with this file as the selected vacancy context.");
      console.log("This command prepares the handoff; it does not perform web research or generate interview answers itself.");
      break;
    }
    default:
      console.log("Usage: npm run dev -- <config:check|db:init|discover|report|interview:prepare>");
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
