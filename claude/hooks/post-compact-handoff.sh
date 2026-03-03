#!/bin/bash
set -u
# SessionStart hook (matcher: compact): inject handoff prompt after auto-compact

INPUT=$(cat)

# Single jq call to parse all fields
eval "$(echo "$INPUT" | jq -r '
  @sh "SESSION_ID=\(.session_id // "")",
  @sh "CWD=\(.cwd // "")"
' 2>/dev/null)" || { SESSION_ID=""; CWD=""; }

[ -z "$SESSION_ID" ] && exit 0
[ -z "$CWD" ] && exit 0

# Atomic flag check: mv succeeds only if file exists, prevents race condition
FLAG="/tmp/claude-needs-handoff-${SESSION_ID}"
CLAIMED="/tmp/claude-handoff-claimed-${SESSION_ID}"
mv "$FLAG" "$CLAIMED" 2>/dev/null || exit 0
rm -f "$CLAIMED"

# Cooldown: skip if a handoff was created within last 5 minutes
HANDOFF_DIR="$CWD/.claude/handoffs"
if [ -d "$HANDOFF_DIR" ]; then
  # Use find -mmin for cross-platform compatibility (works on macOS + Linux)
  RECENT=$(find "$HANDOFF_DIR" -maxdepth 1 -name 'HANDOFF-*.md' -mmin -5 2>/dev/null | head -1)
  [ -n "$RECENT" ] && exit 0
fi

CONTEXT_FILE="$HANDOFF_DIR/.pre-compact-context.md"
if [ -f "$CONTEXT_FILE" ]; then
  cat <<MSG
[Auto-Handoff] Auto-compact just occurred. A pre-compact context snapshot was saved.

1. Read $CONTEXT_FILE for detailed context from before compaction
2. Run /handoff-create to preserve structured context as a handoff file
3. Continue with the original task after handoff is saved
MSG
else
  cat <<'MSG'
[Auto-Handoff] Auto-compact just occurred. Run /handoff-create to preserve structured context before continuing.
MSG
fi

exit 0
