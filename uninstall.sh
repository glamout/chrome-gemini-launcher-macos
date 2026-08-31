#!/bin/bash

set -euo pipefail

INSTALL_PREFIX="${CHROME_GEMINI_PREFIX:-$HOME/.local}"
BIN_PATH="$INSTALL_PREFIX/bin/chrome-gemini"
SHARE_DIR="$INSTALL_PREFIX/share/chrome-gemini"
APP_DIR="${CHROME_GEMINI_APP_DIR:-$HOME/Applications}"
APP_PATH="$APP_DIR/Chrome Gemini Launcher.app"

rm -f "$BIN_PATH"
rm -f "$SHARE_DIR/patch-local-state.js"
rmdir "$SHARE_DIR" 2>/dev/null || true

if [ -d "$APP_PATH" ]; then
    rm -rf "$APP_PATH"
fi

printf 'Removed the CLI and launcher.\n'
printf 'Configuration and Local State backups were kept.\n'
printf 'Config: %s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/chrome-gemini/config"

