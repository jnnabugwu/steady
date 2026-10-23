#!/usr/bin/env python3
"""Builds the sample Cal AI export: writes cal_ai_sample_export.html from the
made-up meals below, then prints it to cal_ai_sample_export.pdf with headless
Chrome. Standard library only. See README.md.

Usage: python3 docs/sample/generate.py [--chrome PATH]
"""

import argparse
import html
import pathlib
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
HTML_OUT = HERE / "cal_ai_sample_export.html"
PDF_OUT = HERE / "cal_ai_sample_export.pdf"
DEFAULT_CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

NAME = "Sample"
START, END = "01/06/2025", "01/12/2025"

# (name, kcal, protein g, carbs g, fat g, fiber g, sugar g, sodium mg, time)
# kcal stays within ~5% of 4P + 4C + 9F. A "\n" in a name wraps it onto two
# lines, the way a long name wraps in a real Cal AI export.
DAYS = [
    ("January 6, 2025", [
        ("Greek Yogurt with Berries", 250, 20, 30, 6, 4, 18, 85, "8:15am"),
        ("Turkey Sandwich", 520, 34, 52, 18, 6, 7, 1180, "12:40pm"),
        ("Salmon with Rice and Broccoli", 680, 42, 64, 26, 5, 3, 620, "7:05pm"),
    ]),
    ("January 7, 2025", [
        ("Oatmeal with Banana", 340, 10, 62, 6, 8, 16, 10, "7:50am"),
        ("Chicken Caesar Salad", 470, 38, 18, 27, 4, 3, 980, "12:20pm"),
        ("Apple", 95, 0, 25, 0, 4, 19, 2, "3:30pm"),
        ("Spaghetti Bolognese", 720, 36, 84, 24, 7, 12, 890, "7:30pm"),
    ]),
    ("January 8, 2025", [
        ("Scrambled Eggs on Toast", 390, 22, 28, 20, 3, 3, 560, "8:00am"),
        ("Chicken Burrito Bowl with Black Beans,\nBrown Rice and Salsa",
         760, 48, 82, 24, 14, 5, 1650, "1:10pm"),
        ("Hummus with Carrots", 210, 7, 22, 11, 6, 5, 380, "4:00pm"),
        ("Grilled Chicken with Sweet Potato", 560, 46, 48, 18, 7, 10, 540, "7:45pm"),
    ]),
    # The "partial-looking" day: one snack and nothing else logged.
    ("January 9, 2025", [
        ("Protein Bar", 230, 20, 24, 7, 5, 6, 190, "10:30am"),
    ]),
    ("January 10, 2025", [
        ("Avocado Toast", 330, 9, 32, 19, 9, 3, 410, "8:20am"),
        ("Tuna Poke Bowl", 610, 38, 70, 18, 5, 9, 1240, "12:50pm"),
        ("Margherita Pizza", 560, 22, 66, 22, 4, 6, 1180, "8:10pm"),
    ]),
    ("January 11, 2025", [
        ("Pancakes with Maple Syrup", 520, 10, 92, 12, 2, 38, 780, "9:30am"),
        ("Cheeseburger", 640, 34, 42, 36, 2, 8, 1050, "2:15pm"),
        ("Stir-Fried Tofu with Vegetables", 450, 24, 38, 22, 7, 9, 920, "7:20pm"),
    ]),
    ("January 12, 2025", [
        ("Banana Peanut Butter Smoothie", 380, 14, 52, 14, 6, 30, 160, "9:00am"),
        ("Roast Chicken with Potatoes", 690, 52, 48, 30, 5, 4, 760, "1:30pm"),
    ]),
]

# Days per printed page. The parser resets per page, so a day never splits
# across one (CSS keeps each day's table whole, too).
PAGES = [DAYS[0:3], DAYS[3:6], DAYS[6:7]]

STYLE = """
@page { size: letter; margin: 0.6in; }
body { font-family: Helvetica, Arial, sans-serif; font-size: 10pt; color: #111; margin: 0; }
.page { page-break-after: always; }
.page:last-child { page-break-after: auto; }
h1 { font-size: 18pt; margin: 0 0 4pt; }
.range { color: #555; margin: 0 0 14pt; }
h2 { font-size: 12pt; margin: 14pt 0 6pt; }
table { width: 100%; border-collapse: collapse; page-break-inside: avoid; }
th, td { padding: 3pt 4pt; text-align: right; vertical-align: bottom; border-bottom: 0.5pt solid #ddd; }
th:first-child, td:first-child { text-align: left; width: 34%; }
th { font-weight: bold; border-bottom: 1pt solid #999; }
tr.total td { font-weight: bold; border-bottom: none; text-align: left; }
"""


def check(days):
    for header, foods in days:
        for name, kcal, p, c, f, *_ in foods:
            est = 4 * p + 4 * c + 9 * f
            if abs(est - kcal) > 0.05 * kcal + 5:
                sys.exit(f"{header} / {name}: {kcal} kcal vs {est} from macros")


def day_table(header, foods):
    total = sum(food[1] for food in foods)
    rows = []
    for name, kcal, p, c, f, fiber, sugar, sodium, time in foods:
        name_html = "<br>".join(html.escape(part) for part in name.split("\n"))
        cells = [f"{kcal}", f"{p}g", f"{c}g", f"{f}g", f"{fiber}g", f"{sugar}g",
                 f"{sodium}mg", time]
        rows.append(
            f"<tr><td>{name_html}</td>" + "".join(f"<td>{v}</td>" for v in cells) + "</tr>"
        )
    columns = ["Foods", "Calories", "Protein", "Carbs", "Fat", "Fiber", "Sugar",
               "Sodium", "Time"]
    return (
        f"<h2>{html.escape(header)}</h2>\n<table>\n"
        "<tr>" + "".join(f"<th>{c}</th>" for c in columns) + "</tr>\n"
        + "\n".join(rows)
        + f'\n<tr class="total"><td colspan="9">TOTAL Calories eaten: {total} '
        f"Calories burned: 0 Net (eaten-burned): {total}</td></tr>\n</table>"
    )


def build_html():
    pages = []
    for days in PAGES:
        body = "\n".join(day_table(h, foods) for h, foods in days)
        pages.append(
            f'<div class="page">\n<h1>{NAME}&#39;s Report</h1>\n'
            f'<p class="range">Start: {START} &middot; End: {END}</p>\n{body}\n</div>'
        )
    return (
        "<!doctype html>\n<html><head><meta charset=\"utf-8\">"
        f"<title>{NAME}'s Report</title>\n<style>{STYLE}</style></head><body>\n"
        + "\n".join(pages)
        + "\n</body></html>\n"
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--chrome", default=DEFAULT_CHROME)
    args = parser.parse_args()

    assert [d for page in PAGES for d in page] == DAYS
    check(DAYS)
    HTML_OUT.write_text(build_html(), encoding="utf-8")
    subprocess.run(
        [args.chrome, "--headless", "--disable-gpu", "--no-pdf-header-footer",
         f"--print-to-pdf={PDF_OUT}", HTML_OUT.as_uri()],
        check=True,
    )
    for header, foods in DAYS:
        print(f"{header}: {sum(f[1] for f in foods)} kcal, {len(foods)} entries")


if __name__ == "__main__":
    main()
