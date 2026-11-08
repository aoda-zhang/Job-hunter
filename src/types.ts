export type ReviewStatus = "pending" | "apply" | "skip" | "saved";

export interface JobPosting {
  source: string;
  sourceId?: string;
  url: string;
  title: string;
  company: string;
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
  languageRequirement: string;
  visaRequirement: string;
  salaryAssessment: string;
  recommendation: string;
}
