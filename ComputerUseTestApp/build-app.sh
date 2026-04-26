#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Computer Use Test App"
EXECUTABLE_NAME="ComputerUseTestApp"
CONFIGURATION="${1:-debug}"
INSTALL_DIR="${2:-}"

swift build -c "$CONFIGURATION"

BUILD_DIR=".build/arm64-apple-macosx/$CONFIGURATION"
APP_PATH=".build/$APP_NAME.app"
CONTENTS_PATH="$APP_PATH/Contents"
MACOS_PATH="$CONTENTS_PATH/MacOS"
RESOURCES_PATH="$CONTENTS_PATH/Resources"

rm -rf "$APP_PATH"
mkdir -p "$MACOS_PATH" "$RESOURCES_PATH"

cp "AppBundle/Info.plist" "$CONTENTS_PATH/Info.plist"
cp "$BUILD_DIR/$EXECUTABLE_NAME" "$MACOS_PATH/$EXECUTABLE_NAME"
chmod +x "$MACOS_PATH/$EXECUTABLE_NAME"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --sign - "$APP_PATH" >/dev/null
fi

if [ -n "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    rsync -a --delete "$APP_PATH/" "$INSTALL_DIR/$APP_NAME.app/"
    if command -v codesign >/dev/null 2>&1; then
        codesign --force --sign - "$INSTALL_DIR/$APP_NAME.app" >/dev/null
    fi
    echo "$INSTALL_DIR/$APP_NAME.app"
    exit 0
fi

echo "$APP_PATH"
