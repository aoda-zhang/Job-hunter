export const schemaSql = `
CREATE TABLE IF NOT EXISTS jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source TEXT NOT NULL,
  source_id TEXT,
  url TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  company TEXT NOT NULL,
  country TEXT,
  location TEXT,
  work_mode TEXT,
  salary_text TEXT,
  description TEXT,
  posted_at TEXT,
  discovered_at TEXT NOT NULL,
  score INTEGER CHECK (score IS NULL OR (score >= 0 AND score <= 100)),
  analysis_json TEXT,
  review_status TEXT NOT NULL DEFAULT 'pending'
    CHECK (review_status IN ('pending', 'apply', 'skip', 'saved')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_jobs_discovered_at ON jobs(discovered_at);
CREATE INDEX IF NOT EXISTS idx_jobs_score ON jobs(score);
CREATE INDEX IF NOT EXISTS idx_jobs_review_status ON jobs(review_status);
CREATE INDEX IF NOT EXISTS idx_jobs_company ON jobs(company);
CREATE INDEX IF NOT EXISTS idx_jobs_country ON jobs(country);

CREATE TABLE IF NOT EXISTS company_research (
  company TEXT PRIMARY KEY,
  website TEXT,
  main_business TEXT,
  products_services TEXT,
  customer_groups TEXT,
  business_model TEXT,
  role_relevance TEXT,
  sources_json TEXT,
  researched_at TEXT
);

CREATE TABLE IF NOT EXISTS role_interview_prep (
  job_id INTEGER PRIMARY KEY REFERENCES jobs(id) ON DELETE CASCADE,
  language TEXT,
  answer TEXT NOT NULL,
  sources_json TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
`;
