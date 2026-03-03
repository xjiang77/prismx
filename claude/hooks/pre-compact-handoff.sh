#!/bin/bash
set -u
# PreCompact hook: set flag + extract transcript essence before compaction

INPUT=$(cat)

# Single jq call to parse all fields
eval "$(echo "$INPUT" | jq -r '
  @sh "SESSION_ID=\(.session_id // "")",
  @sh "TRANSCRIPT=\(.transcript_path // "")",
  @sh "CWD=\(.cwd // "")"
' 2>/dev/null)" || { SESSION_ID=""; TRANSCRIPT=""; CWD=""; }

[ -z "$SESSION_ID" ] && exit 0

# Set flag for post-compact hook
touch "/tmp/claude-needs-handoff-${SESSION_ID}"

# Extract transcript essence
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] && [ -n "$CWD" ]; then
  HANDOFF_DIR="$CWD/.claude/handoffs"
  mkdir -p "$HANDOFF_DIR"
  EXTRACT="$HANDOFF_DIR/.pre-compact-context.md"

  # Cache last 30 lines to avoid double read on jq failure
  TAIL_CACHE=$(tail -30 "$TRANSCRIPT")

  {
    echo "# Pre-Compact Context Snapshot"
    echo ""
    echo "Captured at: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Last 30 conversation entries (covers recent working context)
    echo "## Recent Conversation (last 30 entries)"
    echo '```'
    echo "$TAIL_CACHE" | jq -R 'try fromjson' | jq -r '
      if .type == "human" then "USER: " + (.text // "[media]")
      elif .type == "assistant" then "ASSISTANT: " + (.text // "[tool use]")[0:500]
      elif .type == "tool_result" then "TOOL_RESULT: " + (.content // "")[0:300]
      else empty
      end
    ' 2>/dev/null || echo "$TAIL_CACHE"
    echo '```'
    echo ""

    # Errors and failures from last 200 lines (bounded search)
    echo "## Errors & Failures"
    echo '```'
    ERRORS=$(tail -200 "$TRANSCRIPT" | \
      grep '"error"\|"is_error":true\|"failed"' | \
      jq -r '.content // .text // empty' 2>/dev/null | \
      tail -20)
    if [ -n "$ERRORS" ]; then
      echo "$ERRORS"
    else
      echo "(none detected)"
    fi
    echo '```'
  } > "$EXTRACT"
fi

exit 0
