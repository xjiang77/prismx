#!/bin/bash
# PostToolUse hook: run tsc --noEmit after editing .ts/.tsx files
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Only check TypeScript files
case "$FILE_PATH" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

# Find the nearest tsconfig.json
DIR=$(dirname "$FILE_PATH")
TSCONFIG=""
while [ "$DIR" != "/" ]; do
  if [ -f "$DIR/tsconfig.json" ]; then
    TSCONFIG="$DIR/tsconfig.json"
    break
  fi
  DIR=$(dirname "$DIR")
done

[ -z "$TSCONFIG" ] && exit 0

PROJECT_DIR=$(dirname "$TSCONFIG")

# Run type check (suppress stdout, capture stderr for errors)
if command -v npx &>/dev/null; then
  ERRORS=$(cd "$PROJECT_DIR" && npx tsc --noEmit 2>&1 | grep -E "error TS" | head -5)
  if [ -n "$ERRORS" ]; then
    echo "[prismx] TypeScript errors detected:" >&2
    echo "$ERRORS" >&2
  fi
fi

exit 0
