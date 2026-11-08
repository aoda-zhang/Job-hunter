# Job Hunter – Konfigurationshandbuch

Job Hunter verwendet **genau eine zentrale Konfigurationsdatei** im Projektstamm: `job-hunter.config.json`. Suchumfang, Bewerberprofil und Bewertungsregeln werden gemeinsam in dieser Datei gepflegt. Durch Änderungen an dieser Datei können Länder, Stellenprofile und Zielmärkte ohne Änderungen am Anwendungscode gewechselt werden.

## 1. Aufbau der Konfiguration

Die Datei enthält drei Bereiche auf oberster Ebene:

| Bereich | Zweck |
|---|---|
| `search` | Zielländer, Stellentitel, Standorte, Arbeitsmodelle und Suchquellen |
| `candidate` | Berufserfahrung, Kenntnisse, Sprachen, Gehaltsvorstellung und Arbeitserlaubnis-Kontext |
| `matching` | Gewichtung der Bewertung, Schwellenwerte und Analyse-Regeln |

## 2. Vollständiges Beispiel

```json
{
  "search": {
    "countries": ["Germany", "Netherlands"],
    "roles": ["Senior Frontend Engineer", "React Developer"],
    "locations": ["Berlin", "Amsterdam", "Remote"],
    "workModes": ["remote", "hybrid"],
    "lookbackHours": 72,
    "maxResultsPerSource": 50,
    "sources": ["company-career-pages", "LinkedIn", "Indeed"],
    "excludeKeywords": ["intern", "junior"]
  },
  "candidate": {
    "headline": "Senior Frontend Engineer",
    "experienceYears": 9,
    "currentCountry": "China",
    "workAuthorization": {
      "status": "Assess separately for each target country",
      "note": "Verify eligibility and sponsorship requirements for each vacancy."
    },
    "languages": {
      "preferred": ["English"],
      "additional": [
        {"language": "German", "level": "B1", "note": "Currently learning"}
      ]
    },
    "salary": {
      "preferredMinimum": 65000,
      "currency": "EUR",
      "note": "Reference expectation; evaluate against local market."
    },
    "coreSkills": ["React", "TypeScript", "JavaScript"],
    "secondarySkills": ["Node.js", "NestJS"],
    "architectureSkills": ["Microfrontend", "Design Systems"],
    "experienceEvidence": ["Built enterprise frontend platforms with React and TypeScript."]
  },
  "matching": {
    "weights": {
      "roleTitle": 20,
      "coreSkills": 25,
      "architecture": 15,
      "seniority": 10,
      "domainExperience": 10,
      "locationAndWorkMode": 8,
      "language": 7,
      "salary": 5
    },
    "thresholds": {
      "strongMatch": 85,
      "goodMatch": 70,
      "possibleMatch": 55
    },
    "rules": [
      "Score evidence in the job description, not keyword frequency alone.",
      "Mark unstated requirements as unknown."
    ]
  }
}
```

## 3. search – Suchumfang

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---:|---|
| `countries` | string[] | Ja | Ein oder mehrere Zielländer, z. B. `["Germany", "Japan", "United States"]`. Verwenden Sie möglichst einheitliche, allgemein anerkannte englische Ländernamen. |
| `roles` | string[] | Ja | Gesuchte Stellenbezeichnungen und Varianten, z. B. `["React Developer", "Frontend Engineer"]`. Verwenden Sie Titel, die im jeweiligen Arbeitsmarkt üblich sind. |
| `locations` | string[] | Nein | Städte, Regionen oder `Remote`, z. B. `["Munich", "Tokyo", "Remote"]`. Wenn das Feld fehlt oder leer ist, wird kein zusätzlicher Standortfilter angewendet. Grenzüberschreitende Remote-Arbeit muss je Stelle geprüft werden. |
| `workModes` | enum[] | Nein | Arbeitsmodell: `remote`, `hybrid`, `onsite` oder `flexible`. |
| `lookbackHours` | integer | Ja | Zeitraum in Stunden, innerhalb dessen Stellen veröffentlicht worden sein sollen. `72` bedeutet die letzten drei Tage. Muss größer als null sein. |
| `maxResultsPerSource` | integer | Ja | Maximale Anzahl der Ergebnisse je Quelle. Muss größer als null sein. |
| `sources` | string[] | Ja | Kennungen der Suchquellen, z. B. `company-career-pages`, `LinkedIn`, `StepStone`, `Indeed`. Eine Quelle wird nur genutzt, wenn ein zulässiger Adapter implementiert ist. |
| `excludeKeywords` | string[] | Nein | Begriffe, die aus Stellentiteln oder Beschreibungen ausgeschlossen werden sollen, z. B. `["intern", "working student", "junior"]`. Die konkrete Filterlogik wird im Discovery-Modul umgesetzt. |

**Suchkombinationen:** Der geplante Suchplan kombiniert Länder, Stellenprofile und Standorte zu einzelnen Suchaufgaben. Zwei Länder × drei Rollen ergeben mindestens sechs Kombinationen aus Land und Rolle. Die tatsächliche Suche hängt von den verfügbaren Quellenadaptern ab.

## 4. candidate – Bewerberprofil

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---:|---|
| `headline` | string | Ja | Ziel-Berufsbezeichnung, z. B. `Senior Frontend Engineer`. |
| `experienceYears` | number | Ja | Gesamte Berufserfahrung in Jahren. Dezimalwerte sind erlaubt; negative Werte nicht. |
| `currentCountry` | string | Ja | Aktuelles Aufenthaltsland. Dient zur Einordnung des Standorts und grenzüberschreitender Beschäftigung. |
| `workAuthorization.status` | string | Ja | Kurze Beschreibung des aktuellen Arbeitserlaubnisstatus. Daraus darf keine Berechtigung für andere Zielländer abgeleitet werden. |
| `workAuthorization.note` | string | Ja | Ergänzende Hinweise. Die Analyse soll Visum, Arbeitserlaubnis und mögliche Arbeitgeberunterstützung für jede Stelle gesondert prüfen. |
| `languages.preferred` | string[] | Ja | Bevorzugte Arbeitssprachen, z. B. `["English"]`. |
| `languages.additional` | object[] | Ja | Weitere Sprachen. Jeder Eintrag benötigt `language` und `level`; `note` ist optional. Wenn möglich, CEFR-Niveaus (A1–C2) verwenden. |
| `salary.preferredMinimum` | number | Ja | Numerische Mindest-Gehaltsvorstellung. Zusammen mit `currency` interpretieren und nicht ungeprüft auf andere Arbeitsmärkte übertragen. |
| `salary.currency` | string | Ja | Dreistelliger Währungscode, z. B. EUR, USD, GBP oder JPY. |
| `salary.note` | string | Ja | Kontext wie Bruttojahresgehalt, Verhandelbarkeit oder unverbindlicher Richtwert. |
| `coreSkills` | string[] | Ja | Zentrale Fachkenntnisse für die angestrebte Position. |
| `secondarySkills` | string[] | Ja | Ergänzende oder sekundäre Kenntnisse. |
| `architectureSkills` | string[] | Ja | Kenntnisse in Architektur, Systemdesign und Engineering-Praktiken. |
| `experienceEvidence` | string[] | Ja | Kurze Nachweise aus Projekten und Berufserfahrung. Möglichst Kontext, Verantwortung, Technologien und Ergebnisse nennen statt nur Schlagwörter. |

## 5. matching – Bewertungsregeln

### weights

Jeder Schlüssel steht für eine Bewertungsdimension. Der Zahlenwert gibt deren relatives Gewicht an.

| Schlüssel | Aktuelles Gewicht | Bedeutung |
|---|---:|---|
| `roleTitle` | 20 | Übereinstimmung zwischen Stellentitel und Zielrolle |
| `coreSkills` | 25 | Übereinstimmung der Kernkompetenzen |
| `architecture` | 15 | Architektur, Systemdesign und Engineering-Praktiken |
| `seniority` | 10 | Erfahrungs- und Senioritätsniveau |
| `domainExperience` | 10 | Branchen- und Domänenerfahrung |
| `locationAndWorkMode` | 8 | Standort und Arbeitsmodell |
| `language` | 7 | Anforderungen an Arbeitssprachen |
| `salary` | 5 | Übereinstimmung der Vergütung |

Die Gewichte sollten normalerweise zusammen 100 ergeben; die aktuellen Werte erfüllen dies. Bei Änderungen sollten sie auf 100 normiert werden, damit der Prozentwert nachvollziehbar bleibt. Die Bewertungslogik soll die Gewichte anwenden und nicht lediglich Schlüsselwörter zählen.

### thresholds

| Schlüssel | Aktueller Wert | Bedeutung |
|---|---:|---|
| `strongMatch` | 85 | Schwelle für eine sehr gute Übereinstimmung |
| `goodMatch` | 70 | Schwelle für eine gute Übereinstimmung |
| `possibleMatch` | 55 | Schwelle für eine Stelle, die weiter geprüft werden sollte |

Stellen unterhalb von `possibleMatch` können als geringe Übereinstimmung markiert werden, dürfen aber nicht allein aufgrund des Scores automatisch ausgeschlossen werden. Es muss gelten: `strongMatch >= goodMatch >= possibleMatch`.

### rules

Ein Array natürlichsprachlicher Anweisungen für die Analyse. Beispiele: Muss-Anforderungen von optionalen Kenntnissen unterscheiden; nicht genannte Gehalts- oder Sponsoringinformationen als unbekannt markieren; wesentliche Bewertungen mit Belegen aus Stellenanzeige und Bewerberprofil begründen. Die Regeln können an die eigenen Bewertungskriterien angepasst werden.

## 6. Typische Anwendungsfälle

- **Zielländer ändern:** `search.countries` bearbeiten.
- **Berufsbilder ändern:** `search.roles` bearbeiten.
- **Städte ergänzen:** `search.locations` bearbeiten.
- **Nur Remote-Stellen:** `workModes` auf `["remote"]` setzen.
- **Kein Filter für das Arbeitsmodell:** `workModes` weglassen.
- **Bewertungsprioritäten ändern:** `matching.weights` und `matching.thresholds` anpassen.
- **Profil aktualisieren:** den Bereich `candidate` bearbeiten; persönliche Kompetenzen gehören nicht in die Suchbegriffe.

## 7. Validierung und Grenzen

Mit `npm run config:check` wird die Konfiguration geprüft. Das Laufzeitschema ist mit Zod in `src/config.ts` definiert.

Eine gültige Konfiguration bedeutet nicht, dass alle Suchquellen bereits implementiert sind. Quellenadapter müssen separat entwickelt werden und die Nutzungsbedingungen, Zugriffsbeschränkungen und Abruflimits der jeweiligen Plattform einhalten. Das Projekt versendet keine Bewerbungen und kontaktiert keine Arbeitgeber automatisch.
