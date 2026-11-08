export type ReviewStatus = "pending" | "apply" | "skip" | "saved";
export type WorkMode = "remote" | "hybrid" | "onsite" | "flexible";

export interface JobHunterConfig {
  search: {
    countries: string[];
    roles: string[];
    locations?: string[];
    workModes?: WorkMode[];
    lookbackHours: number;
    maxResultsPerSource: number;
    sources: string[];
    excludeKeywords?: string[];
  };
  candidate: {
    headline: string;
    experienceYears: number;
    currentCountry: string;
    workAuthorization: { status: string; note: string };
    languages: {
      preferred: string[];
      additional: Array<{ language: string; level: string; note?: string }>;
    };
    salary: { preferredMinimum: number; currency: string; note: string };
    coreSkills: string[];
    secondarySkills: string[];
    experienceEvidence: string[];
  };
  matching: {
    weights: {
      roleTitle: number;
      coreSkills: number;
      seniority: number;
      domainExperience: number;
      locationAndWorkMode: number;
      language: number;
      salary: number;
    };
    thresholds: { strongMatch: number; goodMatch: number; possibleMatch: number };
    rules: string[];
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
