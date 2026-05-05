#!/usr/bin/env python3
"""Export translations from xcstrings files to CSV."""

import csv
import json
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
XCSTRINGS_FILES = [
    os.path.join(PROJECT_DIR, "VOCR", "Localizable.xcstrings"),
    os.path.join(PROJECT_DIR, "VOCR", "InfoPlist.xcstrings"),
]
CSV_DIR = os.path.join(SCRIPT_DIR, "csv")
STATE_ORDER = {"new": 0, "needs_review": 1, "translated": 2, "stale": 3}


def load_all_strings():
    """Load and merge strings from all xcstrings files."""
    merged = {}
    for path in XCSTRINGS_FILES:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        merged.update(data["strings"])
    return merged


def get_all_languages(strings):
    """Find all non-English languages across all entries."""
    languages = set()
    for entry in strings.values():
        for lang in entry.get("localizations", {}).keys():
            if lang != "en":
                languages.add(lang)
    return sorted(languages)


def export_language(strings, lang_code):
    """Export a single language to CSV. Returns state counts dict."""
    os.makedirs(CSV_DIR, exist_ok=True)
    csv_path = os.path.join(CSV_DIR, f"{lang_code}.csv")

    rows = []
    for key in strings.keys():
        entry = strings[key]
        comment = entry.get("comment", "")
        localizations = entry.get("localizations", {})

        en_value = ""
        en_loc = localizations.get("en", {})
        if en_loc:
            en_value = en_loc.get("stringUnit", {}).get("value", "")

        translation = ""
        state = "new"
        lang_loc = localizations.get(lang_code, {})
        if lang_loc:
            string_unit = lang_loc.get("stringUnit", {})
            translation = string_unit.get("value", "")
            state = string_unit.get("state", "new")

        rows.append([key, comment, en_value, translation, state])

    rows.sort(key=lambda r: (STATE_ORDER.get(r[4], 99), r[0]))

    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["key", "comment", "en", "translation", "state"])
        writer.writerows(rows)

    counts = {"new": 0, "needs_review": 0, "translated": 0, "stale": 0, "other": 0}
    for row in rows:
        state = row[4]
        if state in counts:
            counts[state] += 1
        else:
            counts["other"] += 1

    return counts


def print_breakdown(breakdown):
    """Print a breakdown table of translation states per language."""
    header = f"{'Language':<12} | {'New':<6} | {'Needs Review':<12} | {'Translated':<10} | {'Stale':<6} | {'Total':<6}"
    print("\n" + header)
    print("-" * len(header))
    for lang, counts in sorted(breakdown.items()):
        total = sum(counts.values())
        print(
            f"{lang:<12} | {counts['new']:<6} | {counts['needs_review']:<12} | "
            f"{counts['translated']:<10} | {counts['stale']:<6} | {total:<6}"
        )


def main():
    strings = load_all_strings()

    if len(sys.argv) > 1:
        lang_code = sys.argv[1]
        counts = export_language(strings, lang_code)
        if lang_code != "template":
            print_breakdown({lang_code: counts})
        else:
            total = len(strings)
            print(f"Exported {total} strings to csv/template.csv")
            print("Copy to csv/<language_code>.csv, fill in translations, then import.")
    else:
        breakdown = {}
        for lang_code in get_all_languages(strings):
            breakdown[lang_code] = export_language(strings, lang_code)
        export_language(strings, "template")
        print(f"Exported csv/template.csv")
        print_breakdown(breakdown)


if __name__ == "__main__":
    main()
