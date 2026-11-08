import type { JobFilterResult, JobHunterConfig, JobPosting } from "../types.js";

const TITLE_TOKEN_ALIASES: Record<string, string> = {
  "front-end": "frontend",
  "front end": "frontend",
  "ui": "frontend",
  "user-interface": "frontend",
  "user interface": "frontend",
  "developer": "engineer",
  "programmer": "engineer",
  "fullstack": "full-stack",
  "full stack": "full-stack",
  "software": "software"
};

const KEYWORD_ALIASES: Record<string, string[]> = {
  javascript: ["javascript", "\\bjs\\b", "ecmascript"],
  typescript: ["typescript", "\\bts\\b"],
  "node.js": ["node\\.js", "\\bnodejs\\b"],
  "next.js": ["next\\.js", "\\bnextjs\\b"],
  react: ["react", "\\breactjs\\b"],
  redux: ["redux", "redux toolkit", "\\brtk\\b"],
  express: ["express", "expressjs"],
  nestjs: ["nestjs", "nest\\.js"],
  html: ["html", "html5"],
  css: ["css", "css3", "scss", "sass"]
};

const ENGLISH_MARKERS = [
  "the", "and", "with", "for", "you", "your", "we", "our", "will", "are",
  "experience", "skills", "responsibilities", "requirements", "working", "team",
  "develop", "build", "design", "knowledge", "role", "work"
];
const GERMAN_MARKERS = [
  "und", "der", "die", "das", "mit", "für", "sie", "wir", "unsere", "werden",
  "sind", "erfahrung", "kenntnisse", "anforderungen", "aufgaben", "entwicklung",
  "unternehmen", "team", "du", "deine", "ihre", "verantwortung"
];

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function normalizeTitle(value: string): string {
  let normalized = value.toLowerCase().replace(/[’']/g, "").replace(/[^a-z0-9.+#-]+/g, " ").trim();
  for (const [from, to] of Object.entries(TITLE_TOKEN_ALIASES)) {
    normalized = normalized.replace(new RegExp(escapeRegExp(from), "g"), to);
  }
  return normalized.replace(/\s+/g, " ").trim();
}

function titleMatches(actual: string, configured: string): boolean {
  const a = normalizeTitle(actual);
  const b = normalizeTitle(configured);
  if (a === b) return true;
  const aTokens = new Set(a.split(" ").filter(Boolean));
  const bTokens = new Set(b.split(" ").filter(Boolean));
  if (!aTokens.size || !bTokens.size) return false;
  const overlap = [...bTokens].filter((token) => aTokens.has(token)).length;
  // Require most of the configured role identity; this is intentionally conservative.
  return overlap / bTokens.size >= 0.8 && overlap / aTokens.size >= 0.6;
}

function detectLanguage(description: string): { language?: string; reason: string; uncertain: boolean } {
  const text = description.toLowerCase();
  const words = text.match(/[a-zäöüß]+/g) ?? [];
  if (words.length < 35 || description.trim().length < 160) {
    return { reason: "JD text is missing or too short for reliable language detection.", uncertain: true };
  }
  const english = ENGLISH_MARKERS.reduce((sum, word) => sum + (words.includes(word) ? 1 : 0), 0);
  const german = GERMAN_MARKERS.reduce((sum, word) => sum + (words.includes(word) ? 1 : 0), 0);
  if (english === german || Math.max(english, german) < 3) {
    return { reason: "Language signals are ambiguous; manual review is required.", uncertain: true };
  }
  const language = english > german ? "English" : "German";
  return { language, reason: `Detected primary JD language: ${language} (English markers: ${english}; German markers: ${german}).`, uncertain: false };
}

function keywordPattern(keyword: string): RegExp {
  const key = keyword.toLowerCase().trim();
  const aliases = KEYWORD_ALIASES[key] ?? [escapeRegExp(key)];
  const alternatives = aliases.map((alias) => alias.startsWith("\\b") || alias.includes("\\.")
    ? alias
    : `\\b${alias}\\b`);
  return new RegExp(`(?:${alternatives.join("|")})`, "i");
}

export function evaluateJob(posting: JobPosting, config: JobHunterConfig): JobFilterResult {
  const title = posting.title?.trim() ?? "";
  const description = posting.description?.trim() ?? "";

  const titleMatch = title
    ? config.search.jobTitles.include.find((candidate) => titleMatches(title, candidate))
    : undefined;
  const jobTitle = !title
    ? { status: "unknown" as const, reason: "Job title is missing." }
    : titleMatch
      ? { status: "match" as const, matchedTitle: titleMatch, reason: `Title matches configured role: "${titleMatch}".` }
      : { status: "no_match" as const, reason: "No configured job title has a sufficiently close role-title match." };

  const languageResult: { language?: string; reason: string; uncertain: boolean } = description ? detectLanguage(description) : {
    reason: "Job description is missing.", uncertain: true
  };
  const configuredLanguages = config.search.jdLanguages.include.map((item) => item.toLowerCase());
  const jdLanguage = languageResult.uncertain
    ? { status: "unknown" as const, reason: languageResult.reason }
    : configuredLanguages.includes((languageResult.language ?? "").toLowerCase())
      ? { status: "match" as const, detectedLanguage: languageResult.language, reason: languageResult.reason }
      : { status: "no_match" as const, detectedLanguage: languageResult.language, reason: `Detected language "${languageResult.language}" is not in the configured language list.` };

  const keywordChecks = config.search.technicalKeywords.include.map((keyword) => ({
    keyword,
    matched: description.length >= 80 && keywordPattern(keyword).test(description)
  }));
  const matchedKeywords = keywordChecks.filter((item) => item.matched).map((item) => item.keyword);
  const technicalKeywords = description.length < 80
    ? { status: "unknown" as const, matchedKeywords, reason: "Job description is missing or too short to evaluate technical keywords reliably." }
    : config.search.technicalKeywords.matchMode === "all"
      ? matchedKeywords.length === keywordChecks.length
        ? { status: "match" as const, matchedKeywords, reason: `All configured keywords matched (${matchedKeywords.length}/${keywordChecks.length}).` }
        : { status: "no_match" as const, matchedKeywords, reason: `Only ${matchedKeywords.length}/${keywordChecks.length} configured keywords matched; matchMode is "all".` }
      : matchedKeywords.length > 0
        ? { status: "match" as const, matchedKeywords, reason: `${matchedKeywords.length} configured keyword(s) matched; matchMode is "any".` }
        : { status: "no_match" as const, matchedKeywords, reason: 'No configured technical keyword matched; matchMode is "any".' };

  const checks = { jobTitle, jdLanguage, technicalKeywords };
  const statuses = [jobTitle.status, jdLanguage.status, technicalKeywords.status];
  const status = statuses.includes("no_match")
    ? "not_matched" as const
    : statuses.every((item) => item === "match")
      ? "matched" as const
      : "review" as const;

  return { status, checks };
}
