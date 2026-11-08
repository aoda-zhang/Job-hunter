export type ReviewStatus = "pending" | "apply" | "skip" | "saved";

export interface SearchConfig {
  search: {
    countries: string[];
    roles: string[];
    locations?: string[];
    workModes?: Array<"remote" | "hybrid" | "onsite" | "flexible">;
    lookbackHours: number;
    maxResultsPerSource: number;
    sources: string[];
    excludeKeywords?: string[];
  };
}

export interface JobPosting {
  source: string;
  sourceId?: string;
  url: string;
  title: string;
  company: string;
  country?: string;
  location?: string;
  workMode?: string;
  salaryText?: string;
  description?: string;
  postedAt?: string;
  discoveredAt: string;
}

export interface JobAnalysis {
  score: number;
  summary: string;
  strengths: string[];
  gaps: string[];
  unknowns: string[];
  languageRequirement: string;
  workAuthorization: string;
  salaryAssessment: string;
  recommendation: string;
}
