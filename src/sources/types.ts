import type { JobPosting } from "../types.js";

export interface JobSource {
  readonly name: string;
  discover(): Promise<JobPosting[]>;
}
