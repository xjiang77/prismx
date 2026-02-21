#!/bin/bash
# PreToolUse hook: suggest /compact at logical breakpoints
# Tracks tool call count and suggests compaction before context pressure builds
INPUT=$(cat)

COUNTER_FILE="/tmp/prismx-tool-counter-$$"

# Initialize or increment counter
if [ -f "$COUNTER_FILE" ]; then
  COUNT=$(cat "$COUNTER_FILE")
  COUNT=$((COUNT + 1))
else
  COUNT=1
fi
echo "$COUNT" > "$COUNTER_FILE"

# Suggest compact every 40 tool calls (logical breakpoint)
if [ $((COUNT % 40)) -eq 0 ]; then
  echo '{"decision":"block","reason":"[prismx] You have made '$COUNT' tool calls this session. Consider running /compact to free up context budget before continuing."}' >&2
  # Don't actually block — just advise
fi

exit 0
