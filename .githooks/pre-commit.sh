#!/bin/sh
set -eu

find_swift_format() {
  if command -v swift-format >/dev/null 2>&1; then
    printf '%s\n' swift-format
    return 0
  fi

  if command -v xcrun >/dev/null 2>&1 && xcrun --find swift-format >/dev/null 2>&1; then
    printf '%s\n' 'xcrun swift-format'
    return 0
  fi

  return 1
}

install_swift_format() {
  if ! command -v brew >/dev/null 2>&1; then
    return 1
  fi

  echo "swift-format not found; installing with Homebrew..." >&2
  brew install swift-format
}

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

swift_format_command=$(find_swift_format || true)
if [ -z "$swift_format_command" ]; then
  install_swift_format || {
    echo "error: swift-format is required for the pre-commit hook." >&2
    echo "Install it with: brew install swift-format" >&2
    exit 1
  }
  swift_format_command=$(find_swift_format || true)
fi

if [ -z "$swift_format_command" ]; then
  echo "error: swift-format installation completed, but swift-format was not found on PATH." >&2
  exit 1
fi

tracked_swift_files=$(mktemp)
staged_swift_files=$(mktemp)
trap 'rm -f "$tracked_swift_files" "$staged_swift_files"' EXIT HUP INT TERM

git ls-files -z -- '*.swift' >"$tracked_swift_files"
git diff --cached --name-only -z --diff-filter=ACMR -- '*.swift' >"$staged_swift_files"

if [ -s "$tracked_swift_files" ]; then
  xargs -0 $swift_format_command -rip <"$tracked_swift_files"
fi

if [ -s "$staged_swift_files" ]; then
  xargs -0 git add -- <"$staged_swift_files"
fi
