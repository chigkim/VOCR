# AGENTS

## Implementation

When implementing or revising a feature:

1. Run `git ls-files` first. Only review or edit tracked files unless explicitly instructed otherwise.
2. Create or update `plan.md` with a detailed step-by-step plan for other agents. Do not `git add` `plan.md`.
3. Use a simple, cohesive design that prioritizes security, readability, consistency, efficiency, maintainability, and modularity.
4. Avoid unnecessary wrappers, translation layers, redundant code paths, duplicate entry points, dead code, and needless complexity.
5. Prefer clear abstractions only when they reduce real complexity or duplication.
6. Preserve unrelated user changes. Do not revert or overwrite changes outside the task scope.
7. Run relevant validation after changes, such as tests, JSON parsing, linting, or builds. Report what was run and any failures.
8. If required new code files are created, `git add` them. Do not add `plan.md`.
9. Summarize completed changes in bullet points.

## Translation

1. Export all translations by running `python translations/export.py`.
2. Git does not track `translations/csv/*.csv`, so do not add them.
3. Update the translation CSV files in `translations/csv/*.csv`, excluding `template.csv`. For each non-template CSV:
  - Only modify rows where `state` is exactly `new`.
  - Fill in the `translation` column for those rows.
  - Change those rows' `state` to `needs_review`.
  - Do not modify any row whose `state` is not `new`.
4. Run: `python translations/breakdown.py` and confirm that the output shows zero rows with `new` state for every language.
