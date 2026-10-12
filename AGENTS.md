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

## Release

1. Work on `dev`. Bump `MARKETING_VERSION` (e.g. `3.1.0`) and `CURRENT_PROJECT_VERSION` in both build configurations of `VOCR.xcodeproj/project.pbxproj`, then commit as `v<version>`.
2. Archive and export with Developer ID signing so the entitlements (camera, Apple Events) and hardened runtime are kept:
   - `xcodebuild -project VOCR.xcodeproj -scheme VOCR -configuration Release -archivePath /tmp/vocr-release/VOCR.xcarchive archive`
   - `xcodebuild -exportArchive -archivePath /tmp/vocr-release/VOCR.xcarchive -exportOptionsPlist <plist with method developer-id, teamID 9N598S2535, signingStyle automatic> -exportPath /tmp/vocr-release/export`
   - If the archive bumps the build number, commit it as `build bump`.
3. Notarize. Do not run `../notarize/notarize-app.sh` on VOCR: it re-signs without entitlements. Use its submit/staple steps directly:
   - `ditto -c -k --sequesterRsrc --keepParent VOCR.app VOCR-submission.zip`
   - `xcrun notarytool submit VOCR-submission.zip --keychain-profile "FloTools Installer-notary" --wait`
   - `xcrun stapler staple VOCR.app`, then `spctl --assess --type execute -v VOCR.app` must report `Notarized Developer ID`.
4. Copy the stapled app to `archives/VOCR.app` and write the release notes in `archives/changelog.md` (`archives/` is git-ignored).
5. Push `dev`, fast-forward `main` to `dev` (`git checkout main && git merge --ff-only dev`), and push `main`.
6. Temporarily move older `archives/VOCR_v*.zip` files out of `archives/` so `generate_appcast` doesn't rewrite their appcast entries; move them back afterward.
7. On `main`, run `uv run release.py` (uses `gh`; add `--tag` to override the version from the app). It zips the app, creates the GitHub release (prerelease if the tag contains `beta`), generates and merges the Sparkle appcast into `docs/appcast.xml`, uploads the zip, adds `docs/VOCR_<tag>.html`, and commits the docs as `<tag>`.
8. Push `main`, fast-forward `dev` to `main`, and push `dev`.
9. Verify with `gh release view <tag> --repo chigkim/VOCR` and check that the new appcast entry points at the uploaded zip.
10. To update only the notes of an existing release, edit the changelog and run `uv run release.py --update --tag <tag>`.
