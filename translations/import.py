#!/usr/bin/env python3
"""Import translations from a CSV file back into xcstrings files."""

import argparse
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


def import_csv(csv_path, file_data, key_to_file):
    """Import a single CSV file. Returns (updated, skipped, warned) counts."""
    lang_code = os.path.splitext(os.path.basename(csv_path))[0]

    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    errors = validate(rows, key_to_file, file_data)
    if errors:
        print(f"Validation errors in {csv_path}:\n", file=sys.stderr)
        for error in errors:
            print(f"  {error}\n", file=sys.stderr)
        print("Skipping this file. Fix the errors above and try again.", file=sys.stderr)
        return 0, 0, 0, set()

    updated = 0
    skipped = 0
    warned = 0
    modified = set()
    for row in rows:
        key = row["key"]
        translation = row.get("translation", "").strip()
        state = row.get("state", "").strip()

        if not translation:
            skipped += 1
            continue

        if state == "stale":
            print(f"Warning: skipping stale key '{key}' — string no longer exists in source code", file=sys.stderr)
            warned += 1
            continue

        if state in ("new", ""):
            state = "needs_review"

        path = key_to_file[key]
        entry = file_data[path]["strings"][key]
        if "localizations" not in entry:
            entry["localizations"] = {}

        entry["localizations"][lang_code] = {
            "stringUnit": {
                "state": state,
                "value": translation,
            }
        }
        modified.add(path)
        updated += 1

    parts = [f"Imported {updated} translations for '{lang_code}'", f"{skipped} skipped"]
    if warned:
        parts.append(f"{warned} stale skipped")
    print(", ".join(parts))

    return updated, skipped, warned, modified


def main():
    parser = argparse.ArgumentParser(
        description="Import translations from a CSV file (or folder of CSVs) into xcstrings files.",
    )
    parser.add_argument(
        "path",
        metavar="csv_file_or_folder",
        help="A single .csv file or a folder containing .csv files. "
             "Each file must be named <language_code>.csv (e.g. fr.csv).",
    )
    args = parser.parse_args()

    path_arg = args.path
    if not os.path.exists(path_arg):
        parser.error(f"Not found: {path_arg}")

    if os.path.isdir(path_arg):
        csv_files = sorted(
            os.path.join(path_arg, f)
            for f in os.listdir(path_arg)
            if f.endswith(".csv")
        )
        if not csv_files:
            parser.error(f"No CSV files found in {path_arg}")
    else:
        csv_files = [path_arg]

    # Load all xcstrings files once and share across imports
    file_data = {}
    key_to_file = {}
    for xcpath in XCSTRINGS_FILES:
        data = load_xcstrings(xcpath)
        file_data[xcpath] = data
        for key in data["strings"]:
            key_to_file[key] = xcpath

    all_modified = set()
    for csv_path in csv_files:
        _, _, _, modified = import_csv(csv_path, file_data, key_to_file)
        all_modified |= modified

    for xcpath in all_modified:
        backup_path = xcpath + ".backup"
        shutil.copy2(xcpath, backup_path)
        print(f"Backup saved to {backup_path}")
        save_xcstrings(xcpath, file_data[xcpath])


if __name__ == "__main__":
    main()
