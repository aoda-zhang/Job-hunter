# Job Hunter – Konfigurationshandbuch

Job Hunter ist ein länder- und rollenübergreifendes Tool zur Stellensuche mit zwei getrennten Phasen:

- **Phase 1 – Stellensuche und Bewerbung:** Stellen anhand der Zielrollen suchen und ausschließlich nach Stellentitel, Sprache der Stellenbeschreibung (JD) und technischen Schlüsselwörtern filtern. Anschließend einen täglichen Markdown-Bericht erstellen.
- **Phase 2 – Interviewvorbereitung:** Nach einer Intervieweinladung ein unabhängiges Skill zur Recherche des ausgewählten Unternehmens und der konkreten Stelle manuell aufrufen.

## 1. Eine zentrale Konfigurationsdatei

Alle Sucheinstellungen befinden sich in `job-hunter.config.json`.

Land, Standort, Veröffentlichungszeitraum und Quelle bestimmen nur den Suchumfang. Sie sind keine Kriterien für eine Bewerberbewertung. Lebenslauf und technischer Hintergrund helfen bei der Definition von Zielrollen und Schlüsselwörtern, führen aber nicht zu zusätzlichen Bewertungspunkten oder automatischen Ausschlussregeln.

## 2. Vollständiges Konfigurationsbeispiel

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
    "jdLanguages": {
      "include": ["English", "German"]
    },
    "technicalKeywords": {
      "include": ["React", "TypeScript", "JavaScript", "HTML", "CSS", "Next.js", "Node.js", "NestJS", "Express", "Redux"],
      "matchMode": "any"
    }
  }
}
```

## 3. Phase 1 – Stellensuche und Bewerbung

Mit `npm run report` (oder `npm run dev -- report`) wird der Tagesbericht erstellt oder überschrieben:

`reports/daily/YYYY-MM-DD.md`

Die Stellen werden nur zur besseren Lesbarkeit nach Unternehmen gruppiert. Jede Stelle enthält:
- Stellentitel und Unternehmen.
- Land, Standort und Arbeitsmodell, sofern bekannt.
- Erkannte Sprache der Stellenbeschreibung.
- In der JD gefundene konfigurierte technische Schlüsselwörter.
- Filterstatus und Belege für die drei Kriterien.
- Veröffentlichungsdatum und Entdeckungsdatum.
- Quelle und Stellenlink.
- Kurze JD-Zusammenfassung und einklappbare Originalbeschreibung, sofern verfügbar.

Der Bericht enthält bestätigte Treffer und Einträge zur manuellen Prüfung. Eindeutig nicht passende Stellen werden aus dem Bericht ausgeschlossen, bleiben aber für die Datenbankprüfung gespeichert. Unbekannte oder unvollständige Angaben werden ausdrücklich gekennzeichnet.

**In Phase 1 gibt es keine ausführliche Unternehmensrecherche und keine Interviewantworten.** Ziel ist es, passende Stellen zu finden, zu prüfen und Bewerbungen vorzubereiten.

## 4. Phase 2 – Unabhängige Unternehmensrecherche und Interviewvorbereitung

Nach einer Intervieweinladung das folgende Skill manuell aufrufen:

`.opencode/skills/company-research/SKILL.md`

Dieses unabhängige Skill umfasst:
1. **Unternehmensprofil:** Kerngeschäft, Produkte/Dienstleistungen, Kundengruppen, Geschäftsmodell, Hauptsitz und wichtige Märkte.
2. **Marktumfeld:** Branchenposition, Wettbewerber und aktuelle wichtige Geschäftsentwicklungen, sofern zuverlässige Quellen verfügbar sind.
3. **Stellenanalyse:** Aufgaben, Technologie-Stack, Geschäftskontext und Bezug zu den tatsächlichen Projekterfahrungen des Bewerbers.
4. **Interviewvorbereitung:** „Why do you want to join our company?“, „Why this position?“, „What can you bring?“ sowie wahrscheinliche technische und verhaltensbezogene Fragen.

Die Ergebnisse werden getrennt gespeichert unter:

`reports/interviews/<company-slug>/`

Empfohlene Dateien: `company-research.md`, `role-analysis.md` und `interview-preparation.md`. Unternehmensinformationen können bei mehreren Stellen desselben Unternehmens wiederverwendet werden; Stellenanalyse und Antworten müssen jedoch auf die jeweilige Rolle zugeschnitten sein.

Das Skill wird nicht während der regulären Stellensuche gestartet und recherchiert nicht automatisch alle Unternehmen im Tagesbericht.

## 5. Die drei Stellenfilter

| Kriterium | Konfigurationsfeld | Verhalten |
|---|---|---|
| Stellentitel | `jobTitles.include` | Übliche Titelvarianten und semantisch ähnliche Bezeichnungen erkennen |
| JD-Sprache | `jdLanguages.include` | Tatsächliche Hauptsprache erkennen, nicht aus dem Land ableiten |
| Technische Schlüsselwörter | `technicalKeywords.include` | Konfigurierte Technologien in der JD suchen |

Für `technicalKeywords.matchMode`:
- `any`: Ein einziger Treffer genügt; empfohlen, um mögliche Stellen nicht unnötig zu übersehen.
- `all`: Alle konfigurierten Begriffe müssen vorkommen.

Eine Stelle wird nur dann als Matched markiert, wenn alle drei Kriterien eindeutig erfüllt sind. Not matched ist nur bei klaren Gegenbelegen zulässig. Unklare oder unvollständige Fälle bleiben als Review erhalten.

## 6. Ausdrücklich keine Filterkriterien

Nicht nach Berufsjahren, Seniorität, Gehalt, Visum/Arbeitserlaubnis, Sprachkenntnissen des Bewerbers, Branche oder Architekturkenntnissen filtern. Es gibt weder einen allgemeinen Bewerber-Matching-Score noch eine automatische Ablehnung anhand eines Scores.

## 7. Validierung und aktuelle Grenzen

Mit `npm run config:check` wird die Konfiguration geprüft. Das Zod-Schema befindet sich in `src/config.ts`.

Der Generator für tägliche Markdown-Berichte ist implementiert. Jobbörsen-Adapter, vollständige Stellensammlung und deterministische Filterausführung anhand der drei Kriterien müssen noch entwickelt werden. Die Spezifikation des unabhängigen Phase-2-Skills und die Datenbanktabellen sind definiert; automatische Unternehmensrecherche, Interviewantworten und Speicherung der Interviewunterlagen stehen noch aus.

Das Projekt versendet keine Bewerbungen und kontaktiert keine Arbeitgeber automatisch. Nutzungsbedingungen, Zugriffsbeschränkungen und Abruflimits der jeweiligen Quelle sind einzuhalten.
