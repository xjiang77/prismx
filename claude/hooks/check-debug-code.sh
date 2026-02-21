#!/bin/bash
# Stop hook: check for leftover debug code before session ends
INPUT=$(cat)

CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
[ -z "$CWD" ] && exit 0
[ ! -d "$CWD" ] && exit 0

# Only check tracked files (git)
if ! command -v git &>/dev/null || ! git -C "$CWD" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  exit 0
fi

# Check staged + unstaged changes for debug statements
DIFF=$(cd "$CWD" && git diff HEAD --unified=0 2>/dev/null || git diff --unified=0 2>/dev/null)
[ -z "$DIFF" ] && exit 0

ISSUES=""

# JavaScript/TypeScript: console.log, console.debug, debugger
JS_HITS=$(echo "$DIFF" | grep -E '^\+' | grep -v '^\+\+\+' | grep -E 'console\.(log|debug|warn)\(|debugger;' || true)
if [ -n "$JS_HITS" ]; then
  ISSUES="${ISSUES}\n  JS/TS: console.log/debug/debugger found"
fi

# Python: print(), breakpoint(), pdb
PY_HITS=$(echo "$DIFF" | grep -E '^\+' | grep -v '^\+\+\+' | grep -E '^\+\s*(print\(|breakpoint\(\)|import pdb|pdb\.set_trace)' || true)
if [ -n "$PY_HITS" ]; then
  ISSUES="${ISSUES}\n  Python: print()/breakpoint()/pdb found"
fi

# Go: fmt.Println used for debug (in non-main files)
GO_HITS=$(echo "$DIFF" | grep -E '^\+' | grep -v '^\+\+\+' | grep -E 'fmt\.Print(ln|f)?\(' || true)
if [ -n "$GO_HITS" ]; then
  ISSUES="${ISSUES}\n  Go: fmt.Print/Println/Printf found (verify not debug)"
fi

if [ -n "$ISSUES" ]; then
  echo "[prismx] Debug code detected in uncommitted changes:$ISSUES" >&2
  echo "  Review and remove before committing." >&2
fi

exit 0
