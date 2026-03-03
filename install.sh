#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/claude"
TARGET_DIR="$HOME/.claude"
MANIFEST_FILE="$TARGET_DIR/.prismx-manifest"

# Load previous manifest for orphan detection
OLD_MANIFEST_FILES=()
if [ -f "$MANIFEST_FILE" ]; then
  while IFS= read -r line; do
    [[ "$line" == \#* ]] && continue
    [[ -z "$line" ]] && continue
    OLD_MANIFEST_FILES+=("$line")
  done < "$MANIFEST_FILE"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Parse args
DRY_RUN=false
FORCE=false
ONLY=""

# Resolve GH_TOKEN once (used for settings.json placeholder replacement)
GH_TOKEN="${GITHUB_PERSONAL_ACCESS_TOKEN:-$(gh auth token 2>/dev/null || echo "")}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true; shift ;;
    --only)    ONLY="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: ./install.sh [--dry-run] [--force] [--only <component>]"
      echo ""
      echo "Options:"
      echo "  --dry-run          Preview changes without installing"
      echo "  --force            Skip confirmation prompt"
      echo "  --only <component> Install only: hooks, skills, agents, commands, core, templates, scripts"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Exclusion list — never overwrite these
EXCLUDE_PATTERNS=(
  "plugins/"
  "projects/"
  "plans/"
  "tasks/"
  "todos/"
  ".git/"
  "settings.local.json"
  "mcp-needs-auth-cache.json"
  "debug/"
  "file-history/"
  "history.jsonl"
  "cache/"
  "paste-cache/"
  "session-env/"
  "shell-snapshots/"
  "stats-cache.json"
  "statsig/"
  "telemetry/"
  "logs/"
  "ide/"
  "backups/"
  "config/"
  "usage-data/"
  "memory/"
)

is_excluded() {
  local rel_path="$1"
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    if [[ "$rel_path" == *"$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

should_include() {
  local rel_path="$1"
  [ -z "$ONLY" ] && return 0
  case "$ONLY" in
    hooks)     [[ "$rel_path" == hooks/* ]] ;;
    skills)    [[ "$rel_path" == skills/* ]] ;;
    agents)    [[ "$rel_path" == agents/* ]] ;;
    core)      [[ "$rel_path" == CLAUDE.md || "$rel_path" == settings.json || "$rel_path" == statusline-command.sh || "$rel_path" == Makefile ]] ;;
    templates) [[ "$rel_path" == templates/* ]] ;;
    scripts)   [[ "$rel_path" == scripts/* ]] ;;
    commands)  [[ "$rel_path" == commands/* ]] ;;
    *) echo "Unknown component: $ONLY (use: hooks, skills, agents, commands, core, templates, scripts)"; exit 1 ;;
  esac
}

# Collect files to process
NEW_FILES=()
CHANGED_FILES=()
UNCHANGED_FILES=()
ALL_FILES=()

echo -e "${BOLD}Prismx Installer${NC}"
echo -e "${DIM}Source: $SOURCE_DIR${NC}"
echo -e "${DIM}Target: $TARGET_DIR${NC}"
echo ""

while IFS= read -r -d '' file; do
  rel_path="${file#$SOURCE_DIR/}"

  # Skip .gitkeep
  [[ "$(basename "$file")" == ".gitkeep" ]] && continue

  is_excluded "$rel_path" && continue
  should_include "$rel_path" || continue

  ALL_FILES+=("$rel_path")
  target_file="$TARGET_DIR/$rel_path"

  if [ ! -f "$target_file" ]; then
    NEW_FILES+=("$rel_path")
    echo -e "  ${GREEN}+ $rel_path${NC} (new)"
  elif ! diff -q "$file" "$target_file" &>/dev/null; then
    # For settings.json, compare after __HOME__ replacement
    if [[ "$rel_path" == "settings.json" ]]; then
      temp_file=$(mktemp)
      sed -e "s|__HOME__|$HOME|g" -e "s|__GH_TOKEN__|$GH_TOKEN|g" "$file" > "$temp_file"
      if ! diff -q "$temp_file" "$target_file" &>/dev/null; then
        CHANGED_FILES+=("$rel_path")
        echo -e "  ${YELLOW}~ $rel_path${NC} (changed)"
        if $DRY_RUN; then
          diff --color=always "$target_file" "$temp_file" || true
        fi
      else
        UNCHANGED_FILES+=("$rel_path")
        echo -e "  ${DIM}  $rel_path (up to date)${NC}"
      fi
      rm "$temp_file"
    else
      CHANGED_FILES+=("$rel_path")
      echo -e "  ${YELLOW}~ $rel_path${NC} (changed)"
      if $DRY_RUN; then
        diff --color=always "$target_file" "$file" || true
      fi
    fi
  else
    UNCHANGED_FILES+=("$rel_path")
    echo -e "  ${DIM}  $rel_path (up to date)${NC}"
  fi
done < <(find "$SOURCE_DIR" -type f -print0 | sort -z)

# Detect orphaned files (in old manifest but not in new file list)
ORPHAN_FILES=()
if [ -z "$ONLY" ]; then
  for old_file in ${OLD_MANIFEST_FILES[@]+"${OLD_MANIFEST_FILES[@]}"}; do
    found=false
    for new_file in ${ALL_FILES[@]+"${ALL_FILES[@]}"}; do
      if [ "$old_file" = "$new_file" ]; then
        found=true
        break
      fi
    done
    if ! $found && [ -f "$TARGET_DIR/$old_file" ]; then
      ORPHAN_FILES+=("$old_file")
      echo -e "  ${RED}- $old_file${NC} (orphaned)"
    fi
  done
fi

echo ""
echo -e "${BOLD}Summary:${NC} ${GREEN}${#NEW_FILES[@]} new${NC}, ${YELLOW}${#CHANGED_FILES[@]} changed${NC}, ${DIM}${#UNCHANGED_FILES[@]} unchanged${NC}, ${RED}${#ORPHAN_FILES[@]} orphaned${NC}"

# Nothing to do?
if [ ${#NEW_FILES[@]} -eq 0 ] && [ ${#CHANGED_FILES[@]} -eq 0 ] && [ ${#ORPHAN_FILES[@]} -eq 0 ]; then
  echo -e "\n${GREEN}Everything up to date.${NC}"
  exit 0
fi

# Dry run stops here
if $DRY_RUN; then
  echo -e "\n${DIM}Dry run — no changes made.${NC}"
  exit 0
fi

# Confirm
if ! $FORCE; then
  echo ""
  read -rp "Install? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# Backup
BACKUP_DIR="$TARGET_DIR/backups/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
for rel_path in ${CHANGED_FILES[@]+"${CHANGED_FILES[@]}"}; do
  target_file="$TARGET_DIR/$rel_path"
  if [ -f "$target_file" ]; then
    backup_file="$BACKUP_DIR/$rel_path"
    mkdir -p "$(dirname "$backup_file")"
    cp "$target_file" "$backup_file"
  fi
done
echo -e "\n${DIM}Backup saved to: $BACKUP_DIR${NC}"

# Install
echo ""
for rel_path in ${NEW_FILES[@]+"${NEW_FILES[@]}"} ${CHANGED_FILES[@]+"${CHANGED_FILES[@]}"}; do
  source_file="$SOURCE_DIR/$rel_path"
  target_file="$TARGET_DIR/$rel_path"
  mkdir -p "$(dirname "$target_file")"

  if [[ "$rel_path" == "settings.json" ]]; then
    sed -e "s|__HOME__|$HOME|g" -e "s|__GH_TOKEN__|$GH_TOKEN|g" "$source_file" > "$target_file"
  else
    cp "$source_file" "$target_file"
  fi

  # Make .sh files executable
  if [[ "$rel_path" == *.sh ]]; then
    chmod +x "$target_file"
  fi

  echo -e "  ${GREEN}✓${NC} $rel_path"
done

# Remove orphaned files
for rel_path in ${ORPHAN_FILES[@]+"${ORPHAN_FILES[@]}"}; do
  target_file="$TARGET_DIR/$rel_path"
  if [ -f "$target_file" ]; then
    backup_file="$BACKUP_DIR/$rel_path"
    mkdir -p "$(dirname "$backup_file")"
    cp "$target_file" "$backup_file"
    rm "$target_file"
    # Remove empty parent directories up to TARGET_DIR
    parent_dir="$(dirname "$target_file")"
    while [ "$parent_dir" != "$TARGET_DIR" ] && [ -d "$parent_dir" ]; do
      rmdir "$parent_dir" 2>/dev/null || break
      parent_dir="$(dirname "$parent_dir")"
    done
    echo -e "  ${RED}✗${NC} $rel_path (removed)"
  fi
done

# Write manifest
echo "# Prismx managed files — $(date +%Y-%m-%d)" > "$MANIFEST_FILE"
for rel_path in "${ALL_FILES[@]}"; do
  echo "$rel_path" >> "$MANIFEST_FILE"
done

echo -e "\n${GREEN}${BOLD}Install complete.${NC} (${#NEW_FILES[@]} new, ${#CHANGED_FILES[@]} updated, ${#ORPHAN_FILES[@]} removed)"
