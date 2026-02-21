#!/bin/bash
# PreCompact hook: save session context before compaction
INPUT=$(cat)

MEMORY_DIR="$HOME/.claude/memory"
mkdir -p "$MEMORY_DIR"

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

cat > "$MEMORY_DIR/session-${TIMESTAMP}.md" <<EOF
# Session: ${SESSION_ID}
- **Time**: ${TIMESTAMP}
- **CWD**: ${CWD}
- **Event**: PreCompact
EOF

exit 0
