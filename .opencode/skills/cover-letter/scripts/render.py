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

PAGE_W, PAGE_H = 595.276, 841.89  # DIN A4
# DIN 5008 on A4: left 2.5 cm, right 2.0 cm, top 4.5 cm, bottom 2.5 cm
CM = 28.3465
LEFT = 2.5 * CM          # 70.87 pt
RIGHT = PAGE_W - 2.0 * CM  # 538.58 pt
WIDTH = RIGHT - LEFT
TOP = 4.5 * CM           # 127.56 pt (first main-text line)
BOTTOM = PAGE_H - 2.5 * CM  # 771.02 pt

BODY_SIZE = 11.0
LINE_H = 13.9
LINEH_FACTOR = 1.2
PARA_GAP = 13.9
FIRST_BASELINE_OFFSET = 11.57
GRAY = (0.102, 0.106, 0.122)

SUBJECT_Y = 280.0
SALUTATION_Y = 310.0
BODY_Y = 338.0
COMPANY_Y = 190.0
STREET_Y = 204.0
CITY_Y = 218.0
DATE_Y = 250.0
SENDER_Y = 127.6
CLOSING_GAP = 13.9
SIGNATURE_GAP = 41.7
ENCLOSURES_GAP = 13.9

P1 = (
    "My name is {first_name} {last_name}. I'm a {job_title} with over {years_experience} years "
    "of experience building and maintaining complex enterprise software, and I'd like to own "
    "your {backend_scope} and contribute to your {product}."
)
P2_FULLSTACK = (
    "{tech_points} have been my core stack for years. At {current_company}, I {achievement}. "
    "The platform serves 3.6 million investors and over 5,000 advisors.",
    "I'm particularly proud of {achievement_design_tokens}. I also {achievement_2}.",
)
P2_BACKEND = (
    "{tech_points} have been my core stack for years. At {current_company}, I {achievement}. "
    "The platform serves 3.6 million investors and over 5,000 advisors. The work most relevant "
    "to this role is that I {achievement_2}.",
)
P2_AI = (
    "{ai_delivery}. The platform serves 3.6 million investors and over 5,000 advisors. "
    "On the product side, I am particularly proud of {achievement_design_tokens}. "
    "I also {achievement_2}. {tech_points} are the tools I use daily, and I work end-to-end "
    "from API design through testing and code review.",
)
P3_PARTS = (
    "{company_fact} {jd_match}",
    "My German is at A2 and improving, and my working language is English. I can provide my own "
    "visa/work permit for Germany within five to eight weeks and do not require visa sponsorship. "
    "I am ready to relocate to {relocation_city}, and my notice period is 30 days. "
    "I'd welcome the opportunity to contribute to {company}'s engineering team. "
    "You can reach me via WhatsApp using the number in my CV header or by email. "
    "Thank you for your time and consideration.",
)

REQUIRED_FIELDS = (
    "company", "role", "company_city", "backend_scope", "product",
    "tech_points", "company_fact", "jd_match",
)
BANNED_PHRASES = (
    "hiermit bewerbe ich mich", "mein name ist", "years old", "with great interest",
    "immediately drawn", "take care of your",
    "sustainable success of your", "i led",
    "teamfähig", "belastbar", "flexibel", "onboard remotely",
    "you write that", "before that i was",
)

# {tech_points} is only ever a list of named technologies (language, framework,
# library, runtime, database, cloud service). Categories and work areas are not
# technologies and must never be listed there.
NON_TECH_TERMS = (
    "component libraries", "component library", "libraries", "library",
    "frameworks", "framework", "technologies", "technology", "tech stack",
    "tooling", "tools", "frontend", "front-end", "backend", "back-end",
    "fullstack", "full-stack", "web development", "software development",
    "design system", "design systems", "ui", "ux",
)
MIN_WORDS, MAX_WORDS = 200, 320

DEFAULTS = {
    "closing": "Kind regards",
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
        fields.setdefault("sender_city", applicant.get("currentCity", ""))
        fields.setdefault("place", applicant.get("currentCity", "").split(",")[0].strip())
        fields.setdefault("date", dt.date.today().strftime("%d. %B %Y"))
        fields["company"] = clean(fields.get("company"))
        fields.setdefault("relocation_city", (clean(fields.get("company_city")).split(",")[0] or "").strip())
        fields["role"] = clean(fields.get("role"))
        if not fields["company"] or not fields["role"]:
            raise ValueError("company and role are required")
        missing = [k for k in REQUIRED_FIELDS if not clean(fields.get(k))]
        if missing:
            raise ValueError("missing template fields: " + ", ".join(missing))
        self.f = {k: clean(v) for k, v in fields.items()}
        tech = self.f.get("tech_points", "").lower()
        for term in NON_TECH_TERMS:
            if re.search(rf"(?<![a-z0-9]){re.escape(term)}(?![a-z0-9])", tech):
                raise ValueError(
                    "tech_points must list named technologies only "
                    f"(language, framework, library, runtime, database, cloud service); "
                    f"{term!r} is a category, not a technology: {self.f['tech_points']!r}"
                )
        self.reg = fitz.Font(fontfile=str(FONT_REG))
        self.bold = fitz.Font(fontfile=str(FONT_BOLD))
        self.fill_header = bool(data.get("fill_header", True))
        self.highlight_fields = list(data.get("highlight_fields", []))
        self.doc = fitz.open()
        self.page = None
        self.page_no = 0
        self.y = BODY_Y

        # One generic file name for every letter:
        # <First>_<Last>_Cover_Letter.pdf, next to the JSON. A JD that dictates
        # a file name overrides it through "filename".
        base_name = f"{fields['first_name']}_{fields['last_name']}_Cover_Letter"
        name = data.get("filename") or re.sub(r"[^A-Za-z0-9]+", "_", base_name).strip("_")
        out_dir = Path(data.get("__input_dir") or Path.cwd())
        default = out_dir / f"{name}.pdf"
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
            self.text((LEFT, self.y), line, self.reg, BODY_SIZE)
            self.y += LINE_H

    def render(self) -> Path:
        self.new_page(first=True)

        # Recipient block and date. The uploaded template does not highlight
        # these lines, but they are placeholders; fill_header: false keeps them
        # literally as Company / Street / City / Place, dd.mm.2021.
        if self.fill_header:
            # Sender block, top right (DIN 5008)
            sender_lines = [
                f"{self.f['first_name']} {self.f['last_name']}",
                self.f.get("sender_address") or self.f.get("sender_city") or self.f.get("place", ""),
                self.f.get("email", ""),
                self.f.get("phone", ""),
            ]
            if self.f.get("linkedin"):
                sender_lines.append(self.f["linkedin"])
            sender_lines = [line for line in sender_lines if line]
            sy = SENDER_Y
            for idx, line in enumerate(sender_lines[:5]):
                font = self.bold if idx == 0 else self.reg
                self.right_text(sy, line, font, 9.5, GRAY)
                sy += 12.5

            # Recipient block, left (DIN 5008)
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

        # Subject line: bold, no "Betreff", no final period (DIN 5008)
        self.text((LEFT, SUBJECT_Y), f"Application as {self.f['role']}", self.bold, BODY_SIZE)
        salutation = self.f.get("salutation") or "Dear Hiring Manager,"
        self.text((LEFT, SALUTATION_Y), salutation, self.reg, BODY_SIZE)

        # Fixed template body; only the placeholder fields change.
        self.y = BODY_Y
        focus = (self.f.get("manulife_focus") or "fullstack").lower()
        if focus == "ai":
            p2 = P2_AI
        elif focus == "backend":
            p2 = P2_BACKEND
        else:
            p2 = P2_FULLSTACK
        body_texts = []
        for template in (P1, *p2, *P3_PARTS):
            text = template.format(**self.f)
            body_texts.append(text)
            self.paragraph(text)
            self.y += PARA_GAP

        body = " ".join(body_texts)
        low = body.lower()
        for phrase in BANNED_PHRASES:
            if phrase in low:
                raise ValueError(f"banned phrase in letter: {phrase!r}")
        words = len(body.split())
        if not MIN_WORDS <= words <= MAX_WORDS:
            raise ValueError(f"body has {words} words; expected {MIN_WORDS}-{MAX_WORDS}")

        # Closing and signature
        self.y += CLOSING_GAP
        self.text((LEFT, self.y), self.f.get("closing", "Kind regards"), self.reg, BODY_SIZE, GRAY)

        sig_path = None
        if self.f.get("signature"):
            candidate = Path(self.f["signature"]).expanduser()
            if not candidate.is_absolute():
                candidate = REPO_ROOT / candidate
            if not candidate.exists():
                raise ValueError(f"signature image not found: {candidate}")
            sig_path = candidate

        name_y = self.y + SIGNATURE_GAP
        if sig_path is not None:
            pix = fitz.Pixmap(str(sig_path))
            width_pt = 72.0
            height_pt = width_pt * pix.height / pix.width
            top = self.y + 3 + (SIGNATURE_GAP - 13 - height_pt) / 2
            rect = fitz.Rect(LEFT, top, LEFT + width_pt, top + height_pt)
            self.page.insert_image(rect, filename=str(sig_path), keep_proportion=True)
            name_y = self.y + SIGNATURE_GAP

        signature = f"{self.f['first_name']} {self.f['last_name']}" if self.fill_header else "Firstname Lastname"
        self.text((LEFT, name_y), signature, self.bold, BODY_SIZE, GRAY)

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

        if self.doc.page_count != 1:
            raise ValueError(f"cover letter is {self.doc.page_count} pages; expected 1")
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
        payload.setdefault("__input_dir", str(path.resolve().parent))
    payload.setdefault("__input_stem", stem)
    output = Letter(payload, load_config()).render()
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
