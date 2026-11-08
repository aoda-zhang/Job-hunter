export type ReviewStatus = "pending" | "apply" | "skip" | "saved";

export interface JobHunterConfig {
  search: {
    countries: string[];
    locations?: string[];
    lookbackHours: number;
    maxResultsPerSource: number;
    sources: string[];
    jobTitles: { include: string[] };
    jdLanguages: { include: string[] };
    technicalKeywords: {
      include: string[];
      matchMode: "any" | "all";
    };
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

export type FilterDimensionStatus = "match" | "no_match" | "unknown";

export interface JobFilterResult {
  status: "matched" | "review" | "not_matched";
  checks: {
    jobTitle: { status: FilterDimensionStatus; matchedTitle?: string; reason: string };
    jdLanguage: { status: FilterDimensionStatus; detectedLanguage?: string; reason: string };
    technicalKeywords: { status: FilterDimensionStatus; matchedKeywords: string[]; reason: string };
  };
}
