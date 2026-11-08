import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { z } from "zod";
import type { JobHunterConfig } from "./types.js";

const configSchema = z.object({
  search: z.object({
    countries: z.array(z.string().min(2)).min(1),
    roles: z.array(z.string().min(2)).min(1),
    locations: z.array(z.string()).optional(),
    workModes: z.array(z.enum(["remote", "hybrid", "onsite", "flexible"])).optional(),
    lookbackHours: z.number().int().positive(),
    maxResultsPerSource: z.number().int().positive(),
    sources: z.array(z.string().min(2)).min(1),
    excludeKeywords: z.array(z.string()).optional()
  }).strict(),
  candidate: z.object({
    headline: z.string(),
    experienceYears: z.number().nonnegative(),
    currentCountry: z.string(),
    workAuthorization: z.object({ status: z.string(), note: z.string() }),
    languages: z.object({
      preferred: z.array(z.string()),
      additional: z.array(z.object({
        language: z.string(),
        level: z.string(),
        note: z.string().optional()
      }))
    }),
    salary: z.object({
      preferredMinimum: z.number().nonnegative(),
      currency: z.string().length(3),
      note: z.string()
    }),
    coreSkills: z.array(z.string()),
    secondarySkills: z.array(z.string()),
    architectureSkills: z.array(z.string()),
    experienceEvidence: z.array(z.string())
  }).strict(),
  matching: z.object({
    weights: z.record(z.string(), z.number().nonnegative()),
    thresholds: z.object({
      strongMatch: z.number().min(0).max(100),
      goodMatch: z.number().min(0).max(100),
      possibleMatch: z.number().min(0).max(100)
    }),
    rules: z.array(z.string())
  }).strict()
}).strict();

export function loadConfig(
  configPath = resolve(process.cwd(), "job-hunter.config.json")
): JobHunterConfig {
  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(configPath, "utf8"));
  } catch (error) {
    throw new Error(`Unable to read Job Hunter config at ${configPath}: ${error instanceof Error ? error.message : String(error)}`);
  }
  const parsed = configSchema.safeParse(raw);
  if (!parsed.success) {
    throw new Error(`Invalid Job Hunter config:\n${z.prettifyError(parsed.error)}`);
  }
  return parsed.data;
}
