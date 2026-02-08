#!/usr/bin/env python3
"""Import translations from a CSV file back into xcstrings files."""

import csv
import json
import os
import re
import shutil
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)
XCSTRINGS_FILES = [
    os.path.join(PROJECT_DIR, "VOCR", "Localizable.xcstrings"),
    os.path.join(PROJECT_DIR, "VOCR", "InfoPlist.xcstrings"),
]


def load_xcstrings(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_xcstrings(path, data):
    text = json.dumps(data, indent=2, ensure_ascii=False)
    # Xcode uses " : " (spaces around colon) for JSON keys
    text = re.sub(r'": ', '" : ', text)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
        f.write("\n")


def get_format_specifiers(s):
    """Extract format specifiers like %@, %d, %1$@, %% from a string."""
    return re.findall(r'%(?:\d+\$)?[@d]|%%', s)


def validate(rows, key_to_file, file_data):
    """Validate CSV rows. Returns list of error messages."""
    errors = []
    for i, row in enumerate(rows, start=2):  # row 1 is header
        key = row["key"]
        translation = row.get("translation", "").strip()

        if not translation:
            continue

        if key not in key_to_file:
            errors.append(f"Row {i}: Unknown key '{key}'")
            continue

        # Check format specifiers match
        path = key_to_file[key]
        entry = file_data[path]["strings"][key]
        en_loc = entry.get("localizations", {}).get("en", {})
        en_value = en_loc.get("stringUnit", {}).get("value", "") if en_loc else ""

        en_specs = sorted(get_format_specifiers(en_value))
        tr_specs = sorted(get_format_specifiers(translation))
        if en_specs != tr_specs:
            errors.append(
                f"Row {i}: Format specifier mismatch for '{key}'\n"
                f"  English:     {en_value}\n"
                f"  Translation: {translation}\n"
                f"  Expected: {en_specs}  Got: {tr_specs}"
            )

    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 import.py <csv_file>", file=sys.stderr)
        sys.exit(1)

    csv_path = sys.argv[1]
    if not os.path.exists(csv_path):
        print(f"Error: File not found: {csv_path}", file=sys.stderr)
        sys.exit(1)

    lang_code = os.path.splitext(os.path.basename(csv_path))[0]

    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    # Load all xcstrings files and build key-to-file mapping
    file_data = {}
    key_to_file = {}
    for path in XCSTRINGS_FILES:
        data = load_xcstrings(path)
        file_data[path] = data
        for key in data["strings"]:
            key_to_file[key] = path

    # Validate before making any changes
    errors = validate(rows, key_to_file, file_data)
    if errors:
        print("Validation errors found:\n", file=sys.stderr)
        for error in errors:
            print(f"  {error}\n", file=sys.stderr)
        print("Import aborted. Fix the errors above and try again.", file=sys.stderr)
        sys.exit(1)

    # Backup all files
    for path in XCSTRINGS_FILES:
        backup_path = path + ".backup"
        shutil.copy2(path, backup_path)
        print(f"Backup saved to {backup_path}")

    updated = 0
    skipped = 0
    for row in rows:
        key = row["key"]
        translation = row.get("translation", "").strip()

        if not translation:
            skipped += 1
            continue

        path = key_to_file[key]
        entry = file_data[path]["strings"][key]
        if "localizations" not in entry:
            entry["localizations"] = {}

        entry["localizations"][lang_code] = {
            "stringUnit": {
                "state": "translated",
                "value": translation,
            }
        }
        updated += 1

    # Save only modified files
    modified = set()
    for row in rows:
        key = row["key"]
        if key in key_to_file and row.get("translation", "").strip():
            modified.add(key_to_file[key])

    for path in modified:
        save_xcstrings(path, file_data[path])

    print(f"Imported {updated} translations for '{lang_code}' ({skipped} skipped)")


if __name__ == "__main__":
    main()
