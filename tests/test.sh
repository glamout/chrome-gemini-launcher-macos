#!/bin/bash

set -euo pipefail

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/chrome-gemini-tests.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT

pass_count=0

pass() {
    pass_count=$((pass_count + 1))
    printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
    printf 'not ok - %s\n' "$1" >&2
    exit 1
}

FAKE_APP="$TEST_ROOT/Google Chrome.app"
CONFIG="$TEST_ROOT/config"
STATE="$TEST_ROOT/Local State"
mkdir -p "$FAKE_APP"

cat > "$CONFIG" <<EOF
REGION=US
PROXY_SERVER=
PROXY_CHECK=off
CHROME_APP=$FAKE_APP
CHROME_PROCESS=ChromeGeminiTestProcessThatDoesNotExist
EOF

cat > "$STATE" <<'EOF'
{"variations_country":"cn","variations_safe_seed_permanent_consistency_country":"cn","variations_safe_seed_session_consistency_country":"cn","variations_permanent_consistency_country":["152.0","cn"],"glic":{"launcher_enabled":false,"use_alt_os_icon":true},"profile":{"info_cache":{"Default":{"is_glic_eligible":false},"Profile 2":{"is_glic_eligible":true}}}}
EOF

dry_run=$(
    CHROME_GEMINI_CONFIG="$CONFIG" \
    CHROME_GEMINI_LOCAL_STATE="$STATE" \
    CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
    "$PROJECT_DIR/bin/chrome-gemini" start --dry-run
)
[[ "$dry_run" == *"--variations-override-country=us"* ]] || fail "dry-run contains region flag"
[[ "$dry_run" != *"--proxy-server"* ]] || fail "dry-run omits an empty proxy"
pass "dry-run builds portable Chrome arguments"

CHROME_GEMINI_CONFIG="$CONFIG" \
CHROME_GEMINI_LOCAL_STATE="$STATE" \
CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
"$PROJECT_DIR/bin/chrome-gemini" configure \
    --proxy-server socks5://127.0.0.1:1080 \
    --region GB \
    --proxy-check off >/dev/null

configured_run=$(
    CHROME_GEMINI_CONFIG="$CONFIG" \
    CHROME_GEMINI_LOCAL_STATE="$STATE" \
    CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
    CHROME_GEMINI_DRY_RUN=1 \
    "$PROJECT_DIR/bin/chrome-gemini" start 2>/dev/null
)
[[ "$configured_run" == *"--variations-override-country=gb"* ]] || fail "configured region is used"
[[ "$configured_run" == *"--proxy-server=socks5://127.0.0.1:1080"* ]] || fail "configured proxy is used"
pass "configure supports arbitrary HTTP or SOCKS proxy endpoints"

CHROME_GEMINI_CONFIG="$CONFIG" \
CHROME_GEMINI_LOCAL_STATE="$STATE" \
CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
"$PROJECT_DIR/bin/chrome-gemini" configure --system-proxy --region us --proxy-check off >/dev/null

system_proxy_run=$(
    CHROME_GEMINI_CONFIG="$CONFIG" \
    CHROME_GEMINI_LOCAL_STATE="$STATE" \
    CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
    "$PROJECT_DIR/bin/chrome-gemini" start --dry-run
)
[[ "$system_proxy_run" != *"--proxy-server"* ]] || fail "system proxy mode omits proxy flag"
pass "system proxy mode works without a hard-coded port"

inspect_before=$(
    CHROME_GEMINI_CONFIG="$CONFIG" \
    CHROME_GEMINI_LOCAL_STATE="$STATE" \
    CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
    "$PROJECT_DIR/bin/chrome-gemini" inspect
)
[[ "$inspect_before" == *'"glic_launcher_enabled" : false'* || "$inspect_before" == *'"glic_launcher_enabled": false'* ]] || fail "inspect reports launcher state"
pass "inspect reads Local State without changing it"

CHROME_GEMINI_CONFIG="$CONFIG" \
CHROME_GEMINI_LOCAL_STATE="$STATE" \
CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
"$PROJECT_DIR/bin/chrome-gemini" repair >/dev/null

inspect_after=$(
    CHROME_GEMINI_CONFIG="$CONFIG" \
    CHROME_GEMINI_LOCAL_STATE="$STATE" \
    CHROME_GEMINI_LIBEXEC="$PROJECT_DIR/scripts/patch-local-state.js" \
    "$PROJECT_DIR/bin/chrome-gemini" inspect
)
[[ "$inspect_after" == *'"variations_country" : "us"'* || "$inspect_after" == *'"variations_country": "us"'* ]] || fail "repair changes country"
[[ "$inspect_after" == *'"glic_launcher_enabled" : true'* || "$inspect_after" == *'"glic_launcher_enabled": true'* ]] || fail "repair enables launcher"
[[ "$inspect_after" != *'false'* ]] || fail "repair enables profile eligibility"
find "$TEST_ROOT" -maxdepth 1 -name 'Local State.chrome-gemini.backup.*' -print -quit | grep -q . || fail "repair creates backup"
pass "repair uses structured JSON and creates a backup"

if grep -E 'curl[[:space:]]|wget[[:space:]]|raw\.githubusercontent\.com' \
    "$PROJECT_DIR/bin/chrome-gemini" \
    "$PROJECT_DIR/install.sh" \
    "$PROJECT_DIR/uninstall.sh" \
    "$PROJECT_DIR/scripts/patch-local-state.js" \
    "$PROJECT_DIR/scripts/launcher.applescript" >/dev/null; then
    fail "runtime files must not download or execute remote code"
fi
pass "runtime and installer contain no remote download or execution"

printf '1..%d\n' "$pass_count"
