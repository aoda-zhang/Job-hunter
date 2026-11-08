import test from "node:test";
import assert from "node:assert/strict";
import { evaluateJob } from "../src/filters/index.js";
import type { JobHunterConfig, JobPosting } from "../src/types.js";

const config: JobHunterConfig = {
  search: {
    countries: ["Germany"], lookbackHours: 72, maxResultsPerSource: 50, sources: ["careers"],
    jobTitles: { include: ["Senior Frontend Engineer", "Senior Full-Stack Engineer"] },
    jdLanguages: { include: ["English", "German"] },
    technicalKeywords: { include: ["React", "TypeScript", "Node.js"], matchMode: "any" }
  }
};

const englishJD = `We are looking for an experienced engineer to join our team. You will develop and build modern web applications with React and TypeScript. The role includes working with product managers and designers, improving user experience, writing maintainable code, reviewing changes, and collaborating with our engineering team. You should have strong communication skills and experience delivering software in a professional environment.`;
const germanJD = `Wir suchen eine erfahrene Entwicklerin oder einen erfahrenen Entwickler für unser Team. Sie werden moderne Webanwendungen entwickeln und gemeinsam mit Produktmanagement und Design arbeiten. Zu Ihren Aufgaben gehören die Entwicklung neuer Funktionen, die Verbesserung der Benutzererfahrung, das Schreiben wartbarer Software und die Zusammenarbeit mit unserem Team. Sie bringen Erfahrung in der Softwareentwicklung und gute Kenntnisse moderner Webtechnologien mit.`;

function posting(overrides: Partial<JobPosting> = {}): JobPosting {
  return { source: "fixture", url: "https://example.test/job", title: "Senior Frontend Developer", company: "Example", description: englishJD, discoveredAt: "2026-11-08T00:00:00Z", ...overrides };
}

test("matches equivalent frontend title, supported JD language and any technical keyword", () => {
  const result = evaluateJob(posting(), config);
  assert.equal(result.status, "matched");
  assert.equal(result.checks.jobTitle.status, "match");
  assert.equal(result.checks.jdLanguage.status, "match");
  assert.deepEqual(result.checks.technicalKeywords.matchedKeywords, ["React", "TypeScript"]);
});

test("detects German JD language without inferring from country", () => {
  const result = evaluateJob(posting({ description: germanJD }), config);
  assert.equal(result.checks.jdLanguage.status, "match");
  assert.equal(result.checks.jdLanguage.detectedLanguage, "German");
});

test("keeps short or missing JD in review instead of rejecting it", () => {
  const result = evaluateJob(posting({ description: "React developer needed." }), config);
  assert.equal(result.status, "review");
  assert.equal(result.checks.jdLanguage.status, "unknown");
  assert.equal(result.checks.technicalKeywords.status, "unknown");
});

test("returns review for a missing title when other dimensions match", () => {
  const result = evaluateJob(posting({ title: "" }), config);
  assert.equal(result.status, "review");
  assert.equal(result.checks.jobTitle.status, "unknown");
});

test("marks a confirmed title mismatch as not matched", () => {
  const result = evaluateJob(posting({ title: "Finance Director" }), config);
  assert.equal(result.status, "not_matched");
  assert.equal(result.checks.jobTitle.status, "no_match");
});

test("supports all keyword mode and common JS/TS aliases", () => {
  const allConfig = structuredClone(config);
  allConfig.search.technicalKeywords = { include: ["JavaScript", "TypeScript"], matchMode: "all" };
  const result = evaluateJob(posting({ description: englishJD.replace("React and TypeScript", "JS and TS") }), allConfig);
  assert.equal(result.checks.technicalKeywords.status, "match");
  assert.deepEqual(result.checks.technicalKeywords.matchedKeywords, ["JavaScript", "TypeScript"]);
});

test("does not match partial keyword substrings", () => {
  const result = evaluateJob(posting({ description: englishJD.replace("React", "Reactivate") }), config);
  assert.equal(result.checks.technicalKeywords.matchedKeywords.includes("React"), false);
});
