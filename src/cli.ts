import "dotenv/config";
import { initializeDatabase, db } from "./db/index.js";
import { loadConfig } from "./config.js";

const command = process.argv[2];

async function main(): Promise<void> {
  switch (command) {
    case "config:check": {
      const config = loadConfig();
      console.log("Job Hunter configuration is valid.");
      console.log(JSON.stringify({
        countries: config.search.countries,
        roles: config.search.roles,
        candidate: config.candidate.headline,
        matchingWeights: config.matching.weights
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
      console.log(`Job titles: ${config.search.jobTitles.include.join(" | ")}`);\n      console.log(`JD languages: ${config.search.jdLanguages.include.join(", ")}`);\n      console.log(`Technical keywords: ${config.search.technicalKeywords.include.join(", ")}`);
      console.log("Discovery scaffold ready. Implement and configure permitted source adapters to collect postings.");
      break;
    }
    case "report": {
      initializeDatabase();
      const rows = db.prepare(
        "SELECT title, company, country, location, url, review_status, discovered_at FROM jobs ORDER BY discovered_at DESC"
      ).all();
      console.log(JSON.stringify(rows, null, 2));
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
