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
    """Export a single language to CSV."""
    os.makedirs(CSV_DIR, exist_ok=True)
    csv_path = os.path.join(CSV_DIR, f"{lang_code}.csv")

    rows = []
    for key in sorted(strings.keys()):
        entry = strings[key]
        comment = entry.get("comment", "")
        localizations = entry.get("localizations", {})

        en_value = ""
        en_loc = localizations.get("en", {})
        if en_loc:
            en_value = en_loc.get("stringUnit", {}).get("value", "")

        translation = ""
        lang_loc = localizations.get(lang_code, {})
        if lang_loc:
            translation = lang_loc.get("stringUnit", {}).get("value", "")

        rows.append([key, comment, en_value, translation])

    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["key", "comment", "en", "translation"])
        writer.writerows(rows)

    print(f"Exported {len(rows)} strings to {csv_path}")
    if lang_code == "template":
        print("Copy to csv/<language_code>.csv, fill in translations, then import.")


def main():
    strings = load_all_strings()

    if len(sys.argv) > 1:
        export_language(strings, sys.argv[1])
    else:
        for lang_code in get_all_languages(strings):
            export_language(strings, lang_code)
        export_language(strings, "template")


if __name__ == "__main__":
    main()
