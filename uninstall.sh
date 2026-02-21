#!/bin/bash
set -euo pipefail

TARGET_DIR="$HOME/.claude"
MANIFEST_FILE="$TARGET_DIR/.prismx-manifest"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Parse args
RESTORE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore) RESTORE="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: ./uninstall.sh [--restore <backup-dir>]"
      echo ""
      echo "Options:"
      echo "  --restore <dir>  Restore from a backup directory"
      echo "                   e.g., --restore ~/.claude/backups/20250222-143000"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Restore mode
if [ -n "$RESTORE" ]; then
  if [ ! -d "$RESTORE" ]; then
    echo -e "${RED}Backup directory not found: $RESTORE${NC}"
    echo ""
    echo "Available backups:"
    ls -1d "$TARGET_DIR"/backups/*/ 2>/dev/null || echo "  (none)"
    exit 1
  fi

  echo -e "${BOLD}Restoring from: $RESTORE${NC}"
  count=0
  while IFS= read -r -d '' file; do
    rel_path="${file#$RESTORE/}"
    target_file="$TARGET_DIR/$rel_path"
    mkdir -p "$(dirname "$target_file")"
    cp "$file" "$target_file"
    echo -e "  ${GREEN}✓${NC} $rel_path"
    count=$((count + 1))
  done < <(find "$RESTORE" -type f -print0)

  echo -e "\n${GREEN}Restored $count files.${NC}"
  exit 0
fi

# Uninstall mode
if [ ! -f "$MANIFEST_FILE" ]; then
  echo -e "${RED}No manifest found at $MANIFEST_FILE${NC}"
  echo "Cannot determine which files are managed by Prismx."
  echo "Run install.sh first to create a manifest."
  exit 1
fi

echo -e "${BOLD}Prismx Uninstaller${NC}"
echo -e "${DIM}Reading manifest: $MANIFEST_FILE${NC}"
echo ""

FILES=()
while IFS= read -r line; do
  [[ "$line" == \#* ]] && continue
  [[ -z "$line" ]] && continue
  FILES+=("$line")
done < "$MANIFEST_FILE"

# Show what will be removed
for rel_path in "${FILES[@]}"; do
  target_file="$TARGET_DIR/$rel_path"
  if [ -f "$target_file" ]; then
    echo -e "  ${RED}- $rel_path${NC}"
  else
    echo -e "  ${DIM}  $rel_path (already gone)${NC}"
  fi
done

echo ""
read -rp "Remove ${#FILES[@]} managed files? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

count=0
for rel_path in "${FILES[@]}"; do
  target_file="$TARGET_DIR/$rel_path"
  if [ -f "$target_file" ]; then
    rm "$target_file"
    count=$((count + 1))
  fi
done

rm "$MANIFEST_FILE"

echo -e "\n${GREEN}Removed $count files.${NC}"
echo -e "${DIM}Tip: use './uninstall.sh --restore <backup-dir>' to restore from backup${NC}"
