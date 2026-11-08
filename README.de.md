# Job Hunter – Konfigurationshandbuch

Job Hunter verwendet eine zentrale Datei im Projektstamm: `job-hunter.config.json`. Das System unterstützt mehrere Länder und Stellenprofile. **Stellen werden ausschließlich anhand von drei Kriterien gefiltert: Stellentitel, Sprache der Stellenbeschreibung (JD) und technische Schlüsselwörter in der JD.**

Land, Standort, Veröffentlichungszeitraum und Quelle bestimmen nur den Suchumfang. Sie sind keine Kriterien für eine Bewerberbewertung.

## 1. Vollständiges Konfigurationsbeispiel

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

## 2. Feldreferenz

### Suchumfang (keine Matching-Kriterien)

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---:|---|
| `countries` | string[] | Ja | Zielländer, z. B. `["Germany", "Japan", "United States"]`. Mehrere Länder sind möglich. |
| `locations` | string[] | Nein | Städte, Regionen oder Remote. Ohne Angabe wird kein zusätzlicher Standortfilter angewendet. |
| `lookbackHours` | integer | Ja | Rückblick in Stunden; 72 bedeutet die letzten drei Tage. |
| `maxResultsPerSource` | integer | Ja | Maximale Anzahl gesammelter Stellen pro Quelle. |
| `sources` | string[] | Ja | Kennungen der Quellen. Eine Quelle funktioniert nur, wenn ein zulässiger Adapter implementiert ist. |

### Die drei Stellenfilter

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---:|---|
| `jobTitles.include` | string[] | Ja | Akzeptierte Stellentitel und übliche Varianten. Semantischer Abgleich statt exakter Zeichenkettenübereinstimmung. |
| `jdLanguages.include` | string[] | Ja | Akzeptierte Sprachen der Stellenbeschreibung, z. B. Englisch, Deutsch oder Japanisch. Die tatsächliche Hauptsprache der JD erkennen und nicht aus dem Land ableiten. |
| `technicalKeywords.include` | string[] | Ja | Technologien, nach denen in der JD gesucht wird. Kerntechnologien und sinnvolle Schreibvarianten eintragen. |
| `technicalKeywords.matchMode` | enum | Ja | `any` bedeutet, dass ein Treffer genügt; `all` verlangt alle konfigurierten Begriffe. `any` wird empfohlen, um passende Stellen nicht unnötig zu übersehen. |

## 3. Filterlogik

1. **Stellentitel:** Groß-/Kleinschreibung ignorieren und semantische Varianten berücksichtigen; keine exakte Übereinstimmung verlangen.
2. **JD-Sprache:** Die Hauptsprache der Stellenbeschreibung erkennen und nur konfigurierte Sprachen akzeptieren.
3. **Technische Schlüsselwörter:** Die gesamte JD durchsuchen. Im empfohlenen Modus `any` reicht bereits ein passender Begriff.

Eine Stelle erhält den Status Matched nur, wenn alle drei Kriterien bestätigt erfüllt sind.

Fehlt der Titel oder die JD, ist der Text zu kurz oder bleibt die Erkennung unklar, erhält die Stelle den Status Review und bleibt für eine manuelle Prüfung erhalten. Not matched darf nur bei einem eindeutig belegten Nichttreffer vergeben werden.

## 4. Ausdrücklich keine Filterkriterien

Nicht nach Berufsjahren, Seniorität, Gehalt, Visum/Arbeitserlaubnis, Sprachkenntnissen des Bewerbers, Branche, Architekturkenntnissen oder anderen persönlichen Profilmerkmalen filtern. Es gibt weder einen allgemeinen Bewerber-Matching-Score noch eine automatische Ablehnung anhand eines Scores.

## 5. Validierung und aktuelle Grenzen

Mit `npm run config:check` wird die Konfiguration geprüft. Das Zod-Schema befindet sich in `src/config.ts`.

Konfiguration und Filterregeln sind definiert; echte Jobbörsen-Adapter, Stellensammlung und die deterministische Filterausführung müssen noch implementiert werden. Ein Eintrag in der Quellenliste bedeutet nicht, dass der Adapter bereits verfügbar ist. Nutzungsbedingungen, Zugriffsbeschränkungen und Abruflimits der jeweiligen Quelle sind einzuhalten. Das Projekt versendet keine Bewerbungen und kontaktiert keine Arbeitgeber automatisch.

## 6. Tägliche Ergebnisdateien und Interviewvorbereitung

Das Ziel ist eine Markdown-Datei pro Kalendertag: `reports/daily/YYYY-MM-DD.md`. Die bestätigten Treffer und manuell zu prüfenden Stellen des Tages werden nach Unternehmen gruppiert. Für jedes Unternehmen werden **Kerngeschäft, Hauptprodukte/-dienstleistungen und Kundengruppen** mit zuverlässigen Quellen beschrieben. Für jede wesentlich andere Stelle wird außerdem eine individuelle, natürlich gesprochene Antwort auf **„Why do you want to join our company?“** in der bekannten Interviewsprache erstellt. Weitere Durchläufe am selben Tag aktualisieren dieselbe Datei, statt Duplikate anzulegen.

Aktueller Stand: Die Anforderungen für Company Research und Daily Reports sind definiert. Automatische Stellensuche, strukturierte Unternehmensrecherche und die Markdown-Berichtserstellung sind jedoch noch nicht implementiert. Dies beschreibt das Zielformat und keine bereits verfügbare CLI-Funktion.
