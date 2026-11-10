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

## Build and Test

Never run VOCR from a build or export folder. To test any build, Debug or Release, quit any running VOCR (`osascript -e 'quit app "VOCR"'`), copy the app with `ditto <build folder>/VOCR.app /Applications/VOCR.app`, and launch `/Applications/VOCR.app`. A change of signing identity (Debug vs. Developer ID) or app path can make macOS ask again for Screen Recording or Accessibility permission.

To build a release:

1. Work on `dev`. Bump `MARKETING_VERSION` (e.g. `3.1.1-beta.3`) in both build configurations of `VOCR.xcodeproj/project.pbxproj`, then commit as `v<version>`. Do not bump `CURRENT_PROJECT_VERSION` by hand: the scheme's post-archive action runs `agvtool bump`, so the current value is always the next unused build number.
2. Archive and export with Developer ID signing so the entitlements (camera, Apple Events, background inference) and hardened runtime are kept:
   - `xcodebuild -project VOCR.xcodeproj -scheme VOCR -configuration Release -archivePath /tmp/vocr-release/VOCR.xcarchive -allowProvisioningUpdates archive`
   - `xcodebuild -exportArchive -archivePath /tmp/vocr-release/VOCR.xcarchive -exportOptionsPlist <plist with destination export, method developer-id, teamID <the project's DEVELOPMENT_TEAM>, signingStyle automatic> -exportPath /tmp/vocr-release/export -allowProvisioningUpdates`
   - The `com.apple.developer.background-tasks.continued-processing.inference` entitlement requires a provisioning profile, so keep `-allowProvisioningUpdates`.
   - Confirm the exported app has the expected build number and entitlements (`codesign -d --entitlements :- VOCR.app`).
   - Commit the post-archive build number change as `build bump`.
3. Install the exported app into `/Applications` as described above and check that it launches.

## Distribution

`<repo>` below is the GitHub repository as `owner/name` (`gh repo view --json nameWithOwner -q .nameWithOwner`).

Steps 2 onward push to GitHub and update the public appcast. Do them only when asked.

1. Notarize every build given to anyone else, including betas shared directly. Do not use a notarization script that re-signs the app: re-signing drops the entitlements. Notarize the exported app as is:
   - `ditto -c -k --sequesterRsrc --keepParent VOCR.app VOCR-submission.zip`
   - `xcrun notarytool submit VOCR-submission.zip --keychain-profile "<profile>" --wait`, where `<profile>` was saved with `xcrun notarytool store-credentials`.
   - `xcrun stapler staple VOCR.app`, then `spctl --assess --type execute -v VOCR.app` must report `Notarized Developer ID`.
   - Install the stapled app into `/Applications`, confirm `spctl --assess --type execute -v /Applications/VOCR.app` reports `Notarized Developer ID`, and check that it launches.
2. Copy the stapled app to `archives/VOCR.app`, replacing any older app there, and write the release notes in `archives/changelog.md` (`archives/` is git-ignored).
3. Push `dev`, fast-forward `main` to `dev` (`git checkout main && git merge --ff-only dev`), and push `main`.
4. Temporarily move older `archives/VOCR_v*.zip` files out of `archives/` so `generate_appcast` doesn't rewrite their appcast entries; move them back afterward.
5. On `main`, run `uv run release.py` (uses `gh` and the repository of the current checkout; add `--tag` to override the version from the app). It uses the newest Sparkle `generate_appcast` under Xcode's DerivedData; set `GENERATE_APPCAST` to use another copy. It zips the app, creates the GitHub release (prerelease if the tag contains `beta`), generates and merges the Sparkle appcast into `docs/appcast.xml`, uploads the zip, adds `docs/VOCR_<tag>.html`, and commits the docs as `<tag>`.
6. Update the download link in both `readme.md` (tracked in lowercase) and `docs/README.md` to the new release zip, `https://github.com/<repo>/releases/download/<tag>/VOCR_<tag>.zip`, and commit as `Download link`.
7. Push `main`, fast-forward `dev` to `main`, and push `dev`.
8. Verify:
   - `gh release view <tag> --repo <repo>` shows the zip, and beta tags are marked as prereleases.
   - The new appcast entry points at the uploaded zip, and beta entries have `<sparkle:channel>beta</sparkle:channel>`, so only users with Download Beta Release on are offered them.
   - GitHub Pages builds from `main:/docs`. Wait until `gh api repos/<repo>/pages/builds/latest` shows `built` for the last commit, then confirm the live appcast (`curl -sL <SUFeedURL>`, using `SUFeedURL` from `VOCR/Info.plist`) and the live download link on the GitHub Pages site.
9. To update only the notes of an existing release, edit the changelog and run `uv run release.py --update --tag <tag>`.
