# Job matching

The scoring engine must return a score with an evidence trail. Keep deterministic criteria separate from LLM-generated interpretation. Missing data is "unknown", never silently treated as a positive match. See `config/scoring-rules.json`.
