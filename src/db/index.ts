import Database from "better-sqlite3";
import { mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { schemaSql } from "./schema.js";

const databasePath = resolve(process.env.DATABASE_PATH ?? "./data/jobs.sqlite");
mkdirSync(dirname(databasePath), { recursive: true });

export const db = new Database(databasePath);
db.pragma("journal_mode = WAL");
db.pragma("foreign_keys = ON");

export function initializeDatabase(): void {
  db.exec(schemaSql);

  // Migrate databases created before country-aware search was introduced.
  const columns = db.pragma("table_info(jobs)") as Array<{ name: string }>;
  if (!columns.some((column) => column.name === "country")) {
    db.exec("ALTER TABLE jobs ADD COLUMN country TEXT");
    db.exec("CREATE INDEX IF NOT EXISTS idx_jobs_country ON jobs(country)");
  }
}
