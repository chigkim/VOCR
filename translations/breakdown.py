#!/usr/bin/env python3
"""Show translation state breakdown from CSV files."""

import argparse
import csv
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_DIR = os.path.join(SCRIPT_DIR, "csv")
KNOWN_STATES = ("new", "needs_review", "translated", "stale")


def count_csv(path):
    """Return state counts for a single CSV file."""
    counts = {s: 0 for s in KNOWN_STATES}
    counts["other"] = 0
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            state = row.get("state", "").strip()
            if state in counts:
                counts[state] += 1
            else:
                counts["other"] += 1
    return counts


def collect_breakdown(paths):
    """Build {lang: counts} from a list of CSV paths."""
    breakdown = {}
    for path in sorted(paths):
        lang = os.path.splitext(os.path.basename(path))[0]
        if lang == "template":
            continue
        breakdown[lang] = count_csv(path)
    return breakdown


def print_breakdown(breakdown):
    header = (
        f"{'Language':<12} | {'New':<6} | {'Needs Review':<12} | "
        f"{'Translated':<10} | {'Stale':<6} | {'Total':<6}"
    )
    print("\n" + header)
    print("-" * len(header))
    for lang, counts in sorted(breakdown.items()):
        total = sum(counts.values())
        print(
            f"{lang:<12} | {counts['new']:<6} | {counts['needs_review']:<12} | "
            f"{counts['translated']:<10} | {counts['stale']:<6} | {total:<6}"
        )


def main():
    parser = argparse.ArgumentParser(
        description="Show translation state breakdown from CSV file(s).",
    )
    parser.add_argument(
        "input",
        nargs="?",
        default=CSV_DIR,
        metavar="path",
        help="CSV file or folder of CSV files (default: translations/csv/).",
    )
    args = parser.parse_args()

    target = args.input
    if not os.path.exists(target):
        print(f"Error: '{target}' not found.", file=sys.stderr)
        sys.exit(1)

    if os.path.isfile(target):
        paths = [target]
    else:
        paths = [
            os.path.join(target, f)
            for f in os.listdir(target)
            if f.endswith(".csv")
        ]
        if not paths:
            print(f"No CSV files found in '{target}'.", file=sys.stderr)
            sys.exit(1)

    breakdown = collect_breakdown(paths)
    if not breakdown:
        print("No language CSV files to report (template files are skipped).")
        return
    print_breakdown(breakdown)


if __name__ == "__main__":
    main()
