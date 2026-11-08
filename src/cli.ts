import "dotenv/config";
import { initializeDatabase, db } from "./db/index.js";

const command = process.argv[2];

async function main(): Promise<void> {
  switch (command) {
    case "db:init":
      initializeDatabase();
      console.log("Database initialized.");
      break;
    case "discover":
      initializeDatabase();
      console.log("Discovery scaffold ready. Configure a permitted source adapter before running collection.");
      break;
    case "report": {
      initializeDatabase();
      const rows = db.prepare(
        "SELECT title, company, location, url, score, review_status FROM jobs ORDER BY score DESC, discovered_at DESC"
      ).all();
      console.log(JSON.stringify(rows, null, 2));
      break;
    }
    default:
      console.log("Usage: npm run dev -- <db:init|discover|report>");
  }
}

main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
