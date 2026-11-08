# Job Hunter – Konfigurationshandbuch

Job Hunter besteht aus zwei unabhängigen Phasen:

- **Phase 1 – Stellensuche und Bewerbungen:** Stellen ausschließlich anhand von Stellentitel, Sprache der Stellenbeschreibung (JD) und technischen Schlüsselwörtern suchen und filtern. Täglichen Markdown-Bericht erstellen.
- **Phase 2 – Interviewvorbereitung:** Nach einer Intervieweinladung das ausgewählte Unternehmen und die konkrete Stelle mit einem separaten Skill recherchieren.

## 1. Eine zentrale Konfigurationsdatei

Alle Sucheinstellungen befinden sich in `job-hunter.config.json`. Land, Standort, Veröffentlichungszeitraum und Quelle bestimmen nur den Suchumfang und sind keine Bewertungskriterien. Der Lebenslauf hilft bei der Definition von Zielrollen und technischen Schlüsselwörtern, führt aber nicht zu zusätzlichen automatischen Ausschlussregeln.

## 2. Konfigurationsbeispiel

```json
{
  "search": {
    "countries": ["Germany"],
    "locations": ["Munich", "Berlin", "Hamburg", "Remote"],
    "lookbackHours": 72,
    "maxResultsPerSource": 50,
    "sources": ["company-career-pages", "LinkedIn", "StepStone"],
    "jobTitles": {
      "include": ["Senior Frontend Engineer", "Senior Frontend Developer", "Frontend Platform Engineer", "Senior React Engineer", "Senior Full-Stack Engineer"]
    },
    "jdLanguages": { "include": ["English", "German"] },
    "technicalKeywords": {
      "include": ["React", "TypeScript", "JavaScript", "HTML", "CSS", "Next.js", "Node.js", "NestJS", "Express", "Redux"],
      "matchMode": "any"
    }
  }
}
```

## 3. Phase 1 – Stellensuche und Bewerbungen

Mit `npm run report` wird der Tagesbericht unter `reports/daily/YYYY-MM-DD.md` erstellt.

Jede Stelle enthält ihre Datenbank-Job-ID, Stellentitel, Unternehmen, Land/Standort, Arbeitsmodell, JD-Sprache, gefundene technische Schlüsselwörter, Filterstatus und Belege, Veröffentlichungs- und Entdeckungsdatum, Quelle, Stellenlink und JD-Zusammenfassung. Bestätigte Treffer und Fälle zur manuellen Prüfung werden angezeigt; eindeutige Nicht-Treffer bleiben im Datenbank-Audit, erscheinen aber nicht im Bericht.

**In Phase 1 gibt es keine Unternehmensrecherche und keine Interviewantworten.** Berufsjahre, Gehalt, Visum, Seniorität, Branche und Architekturkenntnisse sind keine zusätzlichen Filter.

## 4. Phase 2 – Interviewvorbereitung

Nach einer Intervieweinladung den Recherchekontext für eine gespeicherte Stelle erstellen:

```bash
npm run interview:prepare -- --job-id 123
```

Alternativ kann ein exakter Unternehmensname verwendet werden:

```bash
npm run interview:prepare -- --company "Exact Company Name"
```

Wenn mehrere Stellen dieses Unternehmens gespeichert sind, zeigt der Befehl die Job-IDs an und verlangt die Auswahl einer konkreten Stelle. Er liest die gespeicherten Stellendaten und die JD und erstellt `research-input.md` unter `reports/interviews/<company-slug>/roles/job-<id>/`.

Anschließend das unabhängige Skill `.opencode/skills/company-research/SKILL.md` mit dieser Eingabe manuell aufrufen. Das Skill recherchiert Kerngeschäft und Markt des Unternehmens, analysiert die ausgewählte Stelle und erstellt individuelle Interviewantworten wie „Why do you want to join our company?“.

Die Unternehmensrecherche wird auf Unternehmensebene gespeichert. Stellenanalyse und Interviewvorbereitung werden getrennt nach Job-ID gespeichert. Der CLI-Befehl erstellt nur den Recherchekontext; er recherchiert nicht selbst im Web und generiert keine Antworten. Phase 2 wird niemals automatisch während der Stellensuche gestartet.

## 5. Die drei Filter

| Kriterium | Konfigurationsfeld | Verhalten |
|---|---|---|
| Stellentitel | `jobTitles.include` | Übliche Titelvarianten erkennen |
| JD-Sprache | `jdLanguages.include` | Tatsächliche Hauptsprache erkennen |
| Technische Schlüsselwörter | `technicalKeywords.include` | Konfigurierte Technologien in der JD suchen |

Mit `matchMode: "any"` genügt ein Treffer (empfohlen); `all` verlangt alle konfigurierten Begriffe. Unklare oder unvollständige Fälle bleiben zur manuellen Prüfung erhalten.

## 6. Aktueller Implementierungsstand

Der Generator für tägliche Markdown-Berichte und der Phase-2-Kontextgenerator für ausgewählte Stellen sind implementiert. Jobbörsen-Adapter, vollständige Stellensammlung und deterministische Filterausführung anhand der drei Kriterien müssen noch entwickelt werden. Das Unternehmensrecherche-Skill ist spezifiziert; automatisierte Webrecherche, Interviewantworten und Speicherung der fertigen Recherche stehen noch aus.

Das Projekt versendet keine Bewerbungen und kontaktiert keine Arbeitgeber automatisch.
