#!/bin/bash
# PostToolUse hook (opt-in): run related test after Edit|Write
# Enable with: PRISMX_AUTO_TEST=1
INPUT=$(cat)

[ "${PRISMX_AUTO_TEST:-0}" != "1" ] && exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""')
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

DIR=$(dirname "$FILE_PATH")
BASE=$(basename "$FILE_PATH")
NAME="${BASE%.*}"
EXT="${BASE##*.}"

find_test() {
  for pattern in "$@"; do
    local f="$DIR/$pattern"
    [ -f "$f" ] && echo "$f" && return 0
  done
  return 1
}

case "$EXT" in
  ts|tsx|js|jsx)
    TEST_FILE=$(find_test "${NAME}.test.${EXT}" "${NAME}.spec.${EXT}" "__tests__/${NAME}.test.${EXT}")
    if [ -n "$TEST_FILE" ]; then
      if [ -f "$DIR/../../node_modules/.bin/vitest" ] || [ -f "$DIR/../node_modules/.bin/vitest" ]; then
        npx vitest run "$TEST_FILE" &>/dev/null &
      else
        npx jest "$TEST_FILE" --no-coverage &>/dev/null &
      fi
    fi
    ;;
  py)
    TEST_FILE=$(find_test "test_${NAME}.py" "${NAME}_test.py")
    [ -n "$TEST_FILE" ] && pytest "$TEST_FILE" -x --no-header -q &>/dev/null &
    ;;
  go)
    go test "$DIR/..." &>/dev/null &
    ;;
esac

exit 0
