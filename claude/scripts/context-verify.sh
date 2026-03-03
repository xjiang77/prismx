#!/bin/bash
# Verify Claude Code context configuration is correct
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
PRISMX_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PRISMX_SETTINGS="$PRISMX_DIR/claude/settings.json"

PASS=0; FAIL=0
pass() { echo "  ✓ PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== Context Verification ==="
echo ""

# 1. Check installed settings exists
if [ -f "$SETTINGS" ]; then
  pass "settings.json exists"
else
  fail "settings.json not found at $SETTINGS"
  echo ""
  echo "Result: $PASS passed, $FAIL failed"
  exit 1
fi

# 2. Check no plaintext tokens in env
token_count=$(jq -r '.env // {} | keys[]' "$SETTINGS" 2>/dev/null | grep -ciE 'TOKEN|SECRET|KEY|PASSWORD' || true)
if [ "$token_count" -eq 0 ]; then
  pass "No token keys in env"
else
  fail "Found $token_count token-like keys in env (use gh auth or env vars instead)"
fi

# 3. Check user-level plugin count
user_plugins=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' "$SETTINGS")
if [ "$user_plugins" -le 12 ]; then
  pass "User-level plugins: $user_plugins (≤12 recommended)"
else
  fail "User-level plugins: $user_plugins (recommend ≤12, run context-optimize.sh push)"
fi

# 4. Compare enabledPlugins with prismx source
if [ -f "$PRISMX_SETTINGS" ]; then
  installed_plugins=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$SETTINGS" | sort)
  # Process prismx settings: replace __HOME__ is irrelevant for plugins comparison
  source_plugins=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$PRISMX_SETTINGS" | sort)

  if [ "$installed_plugins" = "$source_plugins" ]; then
    pass "Plugins match prismx source"
  else
    fail "Plugins diverge from prismx source"
    echo "    Installed only:"
    comm -23 <(echo "$installed_plugins") <(echo "$source_plugins") | sed 's/^/      /'
    echo "    Source only:"
    comm -13 <(echo "$installed_plugins") <(echo "$source_plugins") | sed 's/^/      /'
  fi
else
  fail "Prismx source not found at $PRISMX_SETTINGS"
fi

# 5. Check __HOME__ placeholders are resolved in installed
if grep -q '__HOME__' "$SETTINGS" 2>/dev/null; then
  fail "__HOME__ placeholders not resolved in installed settings"
else
  pass "No __HOME__ placeholders in installed settings"
fi

# 6. Check hooks are executable
hook_dir="$CLAUDE_DIR/hooks"
if [ -d "$hook_dir" ]; then
  non_exec=$(find "$hook_dir" -name "*.sh" ! -perm -u+x 2>/dev/null | wc -l | tr -d ' ')
  if [ "$non_exec" -eq 0 ]; then
    pass "All hooks are executable"
  else
    fail "$non_exec hooks are not executable"
  fi
fi

echo ""
echo "=== Result: $PASS passed, $FAIL failed ==="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
