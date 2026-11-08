import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { z } from "zod";
import type { JobHunterConfig } from "./types.js";

const configSchema = z.object({
  search: z.object({
    countries: z.array(z.string().min(2)).min(1),
    locations: z.array(z.string().min(1)).optional(),
    lookbackHours: z.number().int().positive(),
    maxResultsPerSource: z.number().int().positive(),
    sources: z.array(z.string().min(2)).min(1),
    jobTitles: z.object({
      include: z.array(z.string().min(2)).min(1)
    }).strict(),
    jdLanguages: z.object({
      include: z.array(z.string().min(2)).min(1)
    }).strict(),
    technicalKeywords: z.object({
      include: z.array(z.string().min(1)).min(1),
      matchMode: z.enum(["any", "all"]).default("any")
    }).strict()
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
