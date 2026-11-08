import "dotenv/config";
import { initializeDatabase, db } from "./db/index.js";
import { loadConfig } from "./config.js";
import { generateDailyReport } from "./reports/index.js";

const command = process.argv[2];

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
    default:
      console.log("Usage: npm run dev -- <config:check|db:init|discover|report>");
  }
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
