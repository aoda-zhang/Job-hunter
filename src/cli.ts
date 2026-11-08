import "dotenv/config";
import { initializeDatabase, db } from "./db/index.js";
import { loadSearchConfig } from "./config.js";

const command = process.argv[2];

async function main(): Promise<void> {
  switch (command) {
    case "config:check": {
      const config = loadSearchConfig();
      console.log("Search configuration is valid.");
      console.log(JSON.stringify(config.search, null, 2));
      break;
    }
    case "db:init":
      initializeDatabase();
      console.log("Database initialized.");
      break;
    case "discover": {
      const config = loadSearchConfig();
      initializeDatabase();
      console.log("Discovery configuration loaded.");
      console.log(`Countries: ${config.search.countries.join(", ")}`);
      console.log(`Roles: ${config.search.roles.join(" | ")}`);
      console.log("Discovery scaffold ready. Implement and configure permitted source adapters to collect postings.");
      break;
    }
    case "report": {
      initializeDatabase();
      const rows = db.prepare(
        "SELECT title, company, location, url, score, review_status FROM jobs ORDER BY score DESC, discovered_at DESC"
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
