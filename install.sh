#!/bin/bash

set -euo pipefail

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INSTALL_PREFIX="${CHROME_GEMINI_PREFIX:-$HOME/.local}"
BIN_DIR="$INSTALL_PREFIX/bin"
SHARE_DIR="$INSTALL_PREFIX/share/chrome-gemini"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/chrome-gemini"
APP_DIR="${CHROME_GEMINI_APP_DIR:-$HOME/Applications}"
APP_PATH="$APP_DIR/Chrome Gemini Launcher.app"
CONFIGURE_ARGS=()

print_help() {
    cat <<'EOF'
Usage:
  ./install.sh [OPTIONS]

Options:
  --proxy-server URL    Use an explicit HTTP/HTTPS/SOCKS proxy
  --system-proxy        Use the macOS system proxy (default)
  --region CC           Set the two-letter region override (default: us)
  --proxy-check MODE    warn, strict, or off
  --help                Show this help

Examples:
  ./install.sh --proxy-server http://127.0.0.1:7897
  ./install.sh --proxy-server http://127.0.0.1:7890
  ./install.sh --proxy-server socks5://127.0.0.1:1080
  ./install.sh --system-proxy
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --proxy-server|--region|--proxy-check)
            if [ "$#" -lt 2 ]; then
                printf 'Option %s requires a value.\n' "$1" >&2
                exit 64
            fi
            CONFIGURE_ARGS+=("$1" "$2")
            shift 2
            ;;
        --system-proxy)
            CONFIGURE_ARGS+=("--system-proxy")
            shift
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            printf 'Unknown installer option: %s\n\n' "$1" >&2
            print_help >&2
            exit 64
            ;;
    esac
done

for required in \
    "$PROJECT_DIR/bin/chrome-gemini" \
    "$PROJECT_DIR/scripts/patch-local-state.js" \
    "$PROJECT_DIR/scripts/launcher.applescript" \
    "$PROJECT_DIR/config.example"; do
    if [ ! -f "$required" ]; then
        printf 'Missing project file: %s\n' "$required" >&2
        exit 66
    fi
done

if [ "$(uname -s)" != "Darwin" ]; then
    printf 'This installer supports macOS only.\n' >&2
    exit 69
fi

mkdir -p "$BIN_DIR" "$SHARE_DIR" "$CONFIG_DIR" "$APP_DIR"
/usr/bin/install -m 0755 "$PROJECT_DIR/bin/chrome-gemini" "$BIN_DIR/chrome-gemini"
/usr/bin/install -m 0644 "$PROJECT_DIR/scripts/patch-local-state.js" "$SHARE_DIR/patch-local-state.js"

if [ ! -f "$CONFIG_DIR/config" ]; then
    /usr/bin/install -m 0600 "$PROJECT_DIR/config.example" "$CONFIG_DIR/config"
    printf 'Created config: %s\n' "$CONFIG_DIR/config"
else
    printf 'Kept existing config: %s\n' "$CONFIG_DIR/config"
fi

if [ "${#CONFIGURE_ARGS[@]}" -gt 0 ]; then
    CHROME_GEMINI_CONFIG="$CONFIG_DIR/config" \
        CHROME_GEMINI_SKIP_CONFIG_BACKUP=1 \
        "$BIN_DIR/chrome-gemini" configure "${CONFIGURE_ARGS[@]}"
fi

timestamp=$(date +%Y%m%d_%H%M%S)
if [ -d "$APP_PATH" ]; then
    backup_app="$APP_PATH.backup.$timestamp"
    mv "$APP_PATH" "$backup_app"
    printf 'Previous launcher moved to: %s\n' "$backup_app"
fi

temp_script=$(mktemp "${TMPDIR:-/tmp}/chrome-gemini-launcher.XXXXXX.applescript")
trap 'rm -f "$temp_script"' EXIT

case "$BIN_DIR/chrome-gemini" in
    *[\"\\]*)
        printf 'Install path cannot contain a double quote or backslash.\n' >&2
        exit 64
        ;;
esac
escaped_cli=$(printf '%s' "$BIN_DIR/chrome-gemini" | sed 's/[&/]/\\&/g')
sed "s/__CLI_COMMAND__/$escaped_cli/" "$PROJECT_DIR/scripts/launcher.applescript" > "$temp_script"
/usr/bin/osacompile -o "$APP_PATH" "$temp_script"
if [ ! -f "$APP_PATH/Contents/Resources/Scripts/main.scpt" ]; then
    printf 'Failed to compile the launcher app.\n' >&2
    exit 1
fi
/usr/bin/plutil -replace CFBundleIdentifier -string "io.github.chrome-gemini-launcher" "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleDisplayName -string "Chrome Gemini Launcher" "$APP_PATH/Contents/Info.plist"
/usr/bin/codesign --force --deep --sign - "$APP_PATH" >/dev/null

printf '\nInstalled successfully.\n'
printf 'CLI: %s\n' "$BIN_DIR/chrome-gemini"
printf 'Launcher: %s\n' "$APP_PATH"
printf 'Config: %s\n\n' "$CONFIG_DIR/config"
printf 'Next steps:\n'
printf '  1. Start the configured proxy, or confirm the macOS system proxy.\n'
printf '  2. Quit Chrome completely with Cmd+Q.\n'
printf '  3. Run: %s doctor\n' "$BIN_DIR/chrome-gemini"
printf '  4. Drag Chrome Gemini Launcher.app to the Dock.\n'
