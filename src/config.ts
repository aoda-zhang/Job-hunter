import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { z } from "zod";
import type { SearchConfig } from "./types.js";

const searchConfigSchema = z.object({
  search: z.object({
    countries: z.array(z.string().min(2)).min(1),
    roles: z.array(z.string().min(2)).min(1),
    locations: z.array(z.string()).optional(),
    workModes: z.array(z.enum(["remote", "hybrid", "onsite", "flexible"])).optional(),
    lookbackHours: z.number().int().positive(),
    maxResultsPerSource: z.number().int().positive(),
    sources: z.array(z.string().min(2)).min(1),
    excludeKeywords: z.array(z.string()).optional()
  }).strict()
}).strict();

export function loadSearchConfig(
  configPath = resolve(process.cwd(), "config/config.json")
): SearchConfig {
  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(configPath, "utf8"));
  } catch (error) {
    throw new Error(`Unable to read search config at ${configPath}: ${error instanceof Error ? error.message : String(error)}`);
  }

  const parsed = searchConfigSchema.safeParse(raw);
  if (!parsed.success) {
    throw new Error(`Invalid search config:\n${z.prettifyError(parsed.error)}`);
  }
  return parsed.data;
}
