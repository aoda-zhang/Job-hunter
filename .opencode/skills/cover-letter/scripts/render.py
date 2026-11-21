#!/usr/bin/env python3
"""Fill the fixed cover-letter template from a small JSON file.

Usage:
    python3 .opencode/skills/cover-letter/scripts/render.py letter.json
    cat letter.json | python3 .opencode/skills/cover-letter/scripts/render.py -

Only the template's variable fields are replaced. All other sentences, wording,
punctuation and paragraph order stay exactly as in the uploaded template.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from pathlib import Path

import fitz

SKILL_DIR = Path(__file__).resolve().parent.parent
REPO_ROOT = SKILL_DIR.parents[2]
FONT_REG = SKILL_DIR / "fonts" / "Roboto-Regular.ttf"
FONT_BOLD = SKILL_DIR / "fonts" / "Roboto-Bold.ttf"

PAGE_W, PAGE_H = 612.0, 792.0
LEFT = 72.0
RIGHT = 540.9
WIDTH = RIGHT - LEFT
TOP = 72.0
BOTTOM = 730.0

BODY_SIZE = 11.04
LINE_H = 15.25
LINEH_FACTOR = 1.318
PARA_GAP = 15.25
FIRST_BASELINE_OFFSET = 11.57
GRAY = (0.102, 0.106, 0.122)

SUBJECT_Y = 254.3
SALUTATION_Y = 315.1
BODY_Y = 345.3
COMPANY_Y = 102.3
STREET_Y = 117.7
CITY_Y = 132.8
DATE_Y = 193.6
CLOSING_GAP = 15.25
SIGNATURE_GAP = 30.4

P1 = (
    "My name is {first_name} {last_name}, I’m a {age}-year-old {job_title} "
    "with over {years_experience} years of experience developing and maintaining "
    "complex enterprise software, and I’d like to take care of your {backend_scope} "
    "and contribute to the sustainable success of your {product}."
)
P2 = (
    "{match_reason} {tech_points} have been my strong suit for many years now. "
    "In my current position with {current_company} I have {achievement}. "
    "Before that I was {previous_work}. So, I {strength_1} and of {strength_2}. "
    "I put strong emphasis on {non_tech_1} and {non_tech_2}."
)
P3_PARTS = (
    "You write that {jd_quote}. I was immediately drawn to this opportunity. "
    "I would love to join your team in {team_location} and take the next step in my career.",
    "I am planning my relocation to Germany and do not require visa sponsorship. "
    "I could also onboard remotely starting in {start_date}.",
    "I would be happy to share more about the projects I have worked on and "
    "demonstrate how my experience could contribute to your team. You can reach me "
    "via WhatsApp or email using the contact details in the header. "
    "Thank you for your time and consideration!",
)

DEFAULTS = {
    "match_reason": "I believe we’re a match because",
    "strength_1": "bring a profound understanding of the entire delivery pipeline",
    "strength_2": "scalable products",
    "closing": "Kind regards,",
}

# Personal facts live in a local, Git-ignored file so the tracked skill stays
# generic. Create cover-letter-personal.json at the repo root.
def load_personal() -> dict:
    path = REPO_ROOT / "cover-letter-personal.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}



def load_config() -> dict:
    path = REPO_ROOT / "job-hunter.config.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def slug(value: str) -> str:
    value = value.lower().strip()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "company"


def clean(value) -> str:
    return " ".join(str(value or "").split())


def wrap(text: str, font: fitz.Font, size: float, width: float) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = word if not current else f"{current} {word}"
        if font.text_length(trial, fontsize=size) <= width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [""]


class Letter:
    def __init__(self, data: dict, config: dict):
        applicant = config.get("applicant", {})
        fields = dict(DEFAULTS)
        fields.update(load_personal())
        fields.update({k: v for k, v in data.items() if v is not None})
        fields.setdefault("first_name", applicant.get("firstName", ""))
        fields.setdefault("last_name", applicant.get("lastName", ""))
        fields.setdefault("email", applicant.get("email", ""))
        fields.setdefault("phone", applicant.get("phone", ""))
        fields.setdefault("linkedin", applicant.get("linkedinUrl", ""))
        fields.setdefault("place", applicant.get("currentCity", "").split(",")[0].strip())
        fields.setdefault("date", dt.date.today().strftime("%d.%m.%Y"))
        fields["company"] = clean(fields.get("company"))
        fields["role"] = clean(fields.get("role"))
        if not fields["company"] or not fields["role"]:
            raise ValueError("company and role are required")
        missing = [k for k in ("backend_scope", "product", "tech_points", "non_tech_1", "non_tech_2", "jd_quote", "team_location") if not clean(fields.get(k))]
        if missing:
            raise ValueError("missing template fields: " + ", ".join(missing))
        if not clean(fields.get("age")):
            raise ValueError("age is required by the template; set it in cover-letter-personal.json or the JSON")
        self.f = {k: clean(v) for k, v in fields.items()}
        self.reg = fitz.Font(fontfile=str(FONT_REG))
        self.bold = fitz.Font(fontfile=str(FONT_BOLD))
        self.fill_header = bool(data.get("fill_header", True))
        self.highlight_fields = list(data.get("highlight_fields", []))
        self.doc = fitz.open()
        self.page = None
        self.page_no = 0
        self.y = BODY_Y

        # One file per vacancy. A JSON named after the job id produces <jobId>.pdf;
        # only a role-slug JSON (legacy) falls back to the role name.
        stem = slug(Path(data.get("__input_stem") or "").stem) if data.get("__input_stem") else ""
        name = stem if re.fullmatch(r"[0-9a-f]{6,}", stem) else slug(fields["role"])
        default = REPO_ROOT / "reports" / "cover-letters" / slug(fields["company"]) / f"{name}.pdf"
        self.output = Path(data.get("output") or default).expanduser()
        if not self.output.is_absolute():
            self.output = REPO_ROOT / self.output

    def new_page(self, first: bool = False) -> None:
        self.page = self.doc.new_page(width=PAGE_W, height=PAGE_H)
        self.page_no += 1
        self.y = TOP
        if not first:
            header = f"{self.f['first_name']} {self.f['last_name']} · Application as {self.f['role']}"
            self.text((LEFT, self.y + 12), header, self.reg, 8.5, (0.45, 0.45, 0.45))
            self.page.draw_line(
                fitz.Point(LEFT, self.y + 18),
                fitz.Point(RIGHT, self.y + 18),
                color=(0.82, 0.82, 0.82),
                width=0.6,
            )
            self.y += 34

    def text(self, point, text: str, font: fitz.Font, size: float, color=(0, 0, 0)) -> None:
        self.page.insert_text(
            fitz.Point(point[0], point[1]),
            text,
            fontname="cl-" + ("bold" if font is self.bold else "regular"),
            fontfile=str(FONT_BOLD if font is self.bold else FONT_REG),
            fontsize=size,
            color=color,
        )

    def right_text(self, y: float, text: str, font: fitz.Font, size: float, color=(0, 0, 0)) -> None:
        self.text((RIGHT - font.text_length(text, fontsize=size), y), text, font, size, color)

    def justified(self, line: str, y: float) -> None:
        words = line.split()
        if not words:
            return
        if len(words) == 1:
            self.text((LEFT, y), line, self.reg, BODY_SIZE)
            return
        space = self.reg.text_length(" ", fontsize=BODY_SIZE)
        widths = [self.reg.text_length(w, fontsize=BODY_SIZE) for w in words]
        natural = sum(widths) + space * (len(words) - 1)
        extra = max(0.0, (WIDTH - natural) / (len(words) - 1))
        x = LEFT
        for word, word_width in zip(words, widths):
            self.text((x, y), word, self.reg, BODY_SIZE)
            x += word_width + space + extra

    def paragraph(self, text: str, first: bool = False) -> None:
        lines = wrap(text, self.reg, BODY_SIZE, WIDTH)
        if self.page is None:
            self.new_page(first=first)
        for index, line in enumerate(lines):
            if self.y + LINE_H > BOTTOM:
                self.new_page()
            if index == len(lines) - 1:
                self.text((LEFT, self.y), line, self.reg, BODY_SIZE)
            else:
                self.justified(line, self.y)
            self.y += LINE_H

    def render(self) -> Path:
        self.new_page(first=True)

        # Recipient block and date. The uploaded template does not highlight
        # these lines, but they are placeholders; fill_header: false keeps them
        # literally as Company / Street / City / Place, dd.mm.2021.
        if self.fill_header:
            self.text((LEFT, COMPANY_Y), self.f["company"], self.bold, BODY_SIZE)
            if self.f.get("company_street"):
                self.text((LEFT, STREET_Y), self.f["company_street"], self.reg, BODY_SIZE)
            if self.f.get("company_city"):
                self.text((LEFT, CITY_Y), self.f["company_city"], self.reg, BODY_SIZE)
            date_text = f"{self.f['place']}, {self.f['date']}" if self.f.get("place") else self.f["date"]
            self.right_text(DATE_Y, date_text, self.reg, BODY_SIZE)
        else:
            self.text((LEFT, COMPANY_Y), "Company", self.bold, BODY_SIZE)
            self.text((LEFT, STREET_Y), "Street", self.reg, BODY_SIZE)
            self.text((LEFT, CITY_Y), "City", self.reg, BODY_SIZE)
            self.right_text(DATE_Y, "Place, dd.mm.2021", self.reg, BODY_SIZE)

        # Subject and salutation
        self.text((LEFT, SUBJECT_Y), f"Application as {self.f['role']}", self.bold, BODY_SIZE)
        self.text((LEFT, SALUTATION_Y), f"Dear {self.f['company']} Team,", self.reg, BODY_SIZE)

        # Fixed template body; only the placeholder fields change.
        self.y = BODY_Y
        for template in (P1, P2, *P3_PARTS):
            self.paragraph(template.format(**self.f))
            self.y += PARA_GAP

        # Closing and signature
        self.y += CLOSING_GAP
        self.text((LEFT, self.y), self.f.get("closing", "Kind regards,"), self.reg, BODY_SIZE, GRAY)
        self.y += SIGNATURE_GAP
        signature = f"{self.f['first_name']} {self.f['last_name']}" if self.fill_header else "Firstname Lastname"
        self.text((LEFT, self.y), signature, self.bold, BODY_SIZE, GRAY)

        # Optional yellow highlight for the base template. The final letter has none.
        for field in self.highlight_fields:
            value = self.f.get(field, "")
            if not value:
                continue
            for page in self.doc:
                for rect in page.search_for(value):
                    page.draw_rect(rect + (-1, -2, 1, 2), color=None, fill=(1, 1, 0), overlay=False)

        # Re-add clickable contact data when it appears in the fixed template header.
        for page in self.doc:
            for needle, uri in [
                (self.f.get("email", ""), f"mailto:{self.f.get('email', '')}"),
                (self.f.get("linkedin", ""), self.f.get("linkedin", "")),
            ]:
                if not needle or not uri:
                    continue
                for rect in page.search_for(needle):
                    page.insert_link({"kind": fitz.LINK_URI, "from": rect, "uri": uri})

        self.output.parent.mkdir(parents=True, exist_ok=True)
        try:
            self.doc.subset_fonts()
        except Exception:
            pass
        self.doc.save(self.output, garbage=4, deflate=True)
        self.doc.close()
        return self.output


def main() -> int:
    parser = argparse.ArgumentParser(description="Fill the fixed cover-letter template from JSON.")
    parser.add_argument("json_path", help="Path to the letter JSON file, or - for stdin")
    args = parser.parse_args()
    if args.json_path == "-":
        payload = json.load(sys.stdin)
        stem = ""
    else:
        path = Path(args.json_path)
        payload = json.loads(path.read_text(encoding="utf-8"))
        stem = path.stem
    payload.setdefault("__input_stem", stem)
    output = Letter(payload, load_config()).render()
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
