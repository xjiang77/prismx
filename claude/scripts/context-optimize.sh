#!/bin/bash
# Optimize Claude Code context by managing user vs project-level plugins
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
PRISMX_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
PRISMX_SETTINGS="$PRISMX_DIR/claude/settings.json"

# User-level plugins (should stay in ~/.claude/settings.json)
USER_PLUGINS=(
  "commit-commands@claude-plugins-official"
  "pr-review-toolkit@claude-plugins-official"
  "claude-md-management@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "security-guidance@claude-plugins-official"
  "hookify@claude-plugins-official"
  "claude-code-setup@claude-plugins-official"
  "github@claude-plugins-official"
  "context7@claude-plugins-official"
)

is_user_plugin() {
  local plugin="$1"
  for up in "${USER_PLUGINS[@]}"; do
    [ "$up" = "$plugin" ] && return 0
  done
  return 1
}

cmd_push() {
  echo "=== Push: Move non-user plugins to project .claude/settings.local.json ==="

  if [ ! -f "$SETTINGS" ]; then
    echo "Error: $SETTINGS not found"
    exit 1
  fi

  local project_settings=".claude/settings.local.json"
  mkdir -p .claude

  # Get all enabled plugins from user settings
  local all_plugins
  all_plugins=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | .key' "$SETTINGS")

  local pushed=()
  for plugin in $all_plugins; do
    if ! is_user_plugin "$plugin"; then
      pushed+=("$plugin")
    fi
  done

  if [ ${#pushed[@]} -eq 0 ]; then
    echo "  No plugins to push — user-level is already clean"
    return
  fi

  # Build project settings.local.json
  local existing_plugins="{}"
  if [ -f "$project_settings" ]; then
    existing_plugins=$(jq '.enabledPlugins // {}' "$project_settings")
  fi

  local new_plugins="$existing_plugins"
  for plugin in "${pushed[@]}"; do
    new_plugins=$(echo "$new_plugins" | jq --arg k "$plugin" '. + {($k): true}')
    echo "  → $plugin"
  done

  if [ -f "$project_settings" ]; then
    jq --argjson plugins "$new_plugins" '.enabledPlugins = $plugins' "$project_settings" > "${project_settings}.tmp"
    mv "${project_settings}.tmp" "$project_settings"
  else
    echo "{\"enabledPlugins\": $new_plugins}" | jq '.' > "$project_settings"
  fi

  echo ""
  echo "  Pushed ${#pushed[@]} plugins to $project_settings"
}

cmd_sync() {
  echo "=== Sync: Apply prismx user-level config ==="

  if [ ! -f "$PRISMX_SETTINGS" ]; then
    echo "Error: prismx source not found at $PRISMX_SETTINGS"
    exit 1
  fi

  # Backup current
  local backup_dir="$CLAUDE_DIR/backups/$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$backup_dir"
  cp "$SETTINGS" "$backup_dir/settings.json"
  echo "  Backup: $backup_dir/settings.json"

  # Read prismx source enabledPlugins
  local prismx_plugins
  prismx_plugins=$(jq '.enabledPlugins' "$PRISMX_SETTINGS")

  # Update only enabledPlugins in installed settings, preserve env without tokens
  local current_env
  current_env=$(jq '.env // {}' "$SETTINGS")

  # Remove any token keys from env
  local clean_env
  clean_env=$(echo "$current_env" | jq 'with_entries(select(.key | test("TOKEN|SECRET|KEY|PASSWORD"; "i") | not))')

  # Replace enabledPlugins and clean env
  jq --argjson plugins "$prismx_plugins" --argjson env "$clean_env" \
    '.enabledPlugins = $plugins | .env = $env' "$SETTINGS" > "${SETTINGS}.tmp"
  mv "${SETTINGS}.tmp" "$SETTINGS"

  local count
  count=$(echo "$prismx_plugins" | jq 'length')
  echo "  Synced $count plugins from prismx source"
  echo "  Cleaned env (removed token keys)"

  # Replace __HOME__ placeholder
  if grep -q '__HOME__' "$SETTINGS" 2>/dev/null; then
    sed -i '' "s|__HOME__|$HOME|g" "$SETTINGS"
    echo "  Replaced __HOME__ placeholders"
  fi
}

cmd_recommend() {
  local apply=false
  [ "${2:-}" = "--apply" ] && apply=true

  echo "=== Recommend: Scan project and suggest plugins ==="
  echo ""

  local project_root
  project_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  local project_settings="$project_root/.claude/settings.local.json"

  local existing_plugins=""
  if [ -f "$project_settings" ]; then
    existing_plugins=$(jq -r '.enabledPlugins // {} | keys[]' "$project_settings" 2>/dev/null || true)
  fi

  local recommendations=()
  local reasons=()

  recommend_if_missing() {
    local plugin="$1" reason="$2"
    if echo "$existing_plugins" | grep -qx "$plugin"; then
      return
    fi
    # Deduplicate
    for r in "${recommendations[@]+"${recommendations[@]}"}"; do
      [ "$r" = "$plugin" ] && return
    done
    recommendations+=("$plugin")
    reasons+=("$reason")
  }

  # TypeScript
  if [ -f "$project_root/tsconfig.json" ] || find "$project_root" -maxdepth 3 -name '*.ts' -not -path '*/node_modules/*' -print -quit 2>/dev/null | grep -q .; then
    recommend_if_missing "typescript-lsp@anthropic-official" "tsconfig.json or .ts files detected"
  fi

  # Python
  if [ -f "$project_root/pyproject.toml" ] || [ -f "$project_root/setup.py" ] || find "$project_root" -maxdepth 3 -name '*.py' -not -path '*/.venv/*' -print -quit 2>/dev/null | grep -q .; then
    recommend_if_missing "pyright-lsp@anthropic-official" "Python project detected"
  fi

  # Go
  if [ -f "$project_root/go.mod" ]; then
    recommend_if_missing "gopls-lsp@anthropic-official" "go.mod detected"
  fi

  # Rust
  if [ -f "$project_root/Cargo.toml" ]; then
    recommend_if_missing "rust-analyzer-lsp@anthropic-official" "Cargo.toml detected"
  fi

  # Playwright
  if ls "$project_root"/playwright.config.* 1>/dev/null 2>&1 || [ -d "$project_root/tests/e2e" ]; then
    recommend_if_missing "playwright@anthropic-official" "Playwright config or e2e tests detected"
  fi

  # Figma
  if [ -f "$project_root/.figmarc" ] || ([ -f "$project_root/package.json" ] && grep -q '"figma"' "$project_root/package.json" 2>/dev/null); then
    recommend_if_missing "figma@anthropic-official" ".figmarc or figma dependency detected"
  fi

  # Frontend design
  if [ -d "$project_root/src/components" ] || ([ -f "$project_root/package.json" ] && grep -qE '"(react|vue|svelte|next|nuxt|@angular/core)"' "$project_root/package.json" 2>/dev/null); then
    recommend_if_missing "frontend-design@claude-plugins-official" "Frontend framework or components detected"
  fi

  # Semgrep
  if ls "$project_root"/.semgrep* 1>/dev/null 2>&1; then
    recommend_if_missing "semgrep@anthropic-official" ".semgrep config detected"
  fi

  # Gongfeng MCP (git.woa.com projects)
  local git_remote
  git_remote=$(git -C "$project_root" remote get-url origin 2>/dev/null || true)
  if echo "$git_remote" | grep -q 'git\.woa\.com'; then
    local has_gongfeng=false
    if [ -f "$project_root/.mcp.json" ] && jq -e '.mcpServers.gongfengStreamable' "$project_root/.mcp.json" >/dev/null 2>&1; then
      has_gongfeng=true
    fi
    if ! $has_gongfeng; then
      recommendations+=("mcp:gongfengStreamable")
      reasons+=("git.woa.com remote detected")
    fi
  fi

  # Document skills
  if [ -d "$project_root/docs" ] || [ "$(find "$project_root" -maxdepth 2 -name '*.md' -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')" -gt 5 ]; then
    recommend_if_missing "document-skills@claude-plugins-official" "docs/ directory or 5+ markdown files"
  fi

  if [ ${#recommendations[@]} -eq 0 ]; then
    echo "  No additional plugins recommended for this project."
    return
  fi

  printf "  %-45s %s\n" "RECOMMENDATION" "REASON"
  printf "  %-45s %s\n" "--------------" "------"
  for i in "${!recommendations[@]}"; do
    printf "  %-45s %s\n" "${recommendations[$i]}" "${reasons[$i]}"
  done
  echo ""
  echo "  Total: ${#recommendations[@]} recommendation(s)"

  if $apply; then
    echo ""

    # Separate plugins vs MCP servers
    local plugin_list=()
    local mcp_list=()
    for rec in "${recommendations[@]}"; do
      case "$rec" in
        mcp:*) mcp_list+=("${rec#mcp:}") ;;
        *)     plugin_list+=("$rec") ;;
      esac
    done

    # Apply plugins to .claude/settings.local.json
    if [ ${#plugin_list[@]} -gt 0 ]; then
      mkdir -p "$project_root/.claude"
      local existing="{}"
      if [ -f "$project_settings" ]; then
        existing=$(cat "$project_settings")
      fi

      local plugins_obj
      plugins_obj=$(echo "$existing" | jq '.enabledPlugins // {}')
      for plugin in "${plugin_list[@]}"; do
        plugins_obj=$(echo "$plugins_obj" | jq --arg k "$plugin" '. + {($k): true}')
      done

      echo "$existing" | jq --argjson plugins "$plugins_obj" '.enabledPlugins = $plugins' > "${project_settings}.tmp"
      mv "${project_settings}.tmp" "$project_settings"
      echo "  Applied ${#plugin_list[@]} plugin(s) to $project_settings"
    fi

    # Apply MCP servers to .mcp.json (copy from user-level)
    if [ ${#mcp_list[@]} -gt 0 ]; then
      local user_mcp="$CLAUDE_DIR/mcp.json"
      local project_mcp="$project_root/.mcp.json"
      local mcp_existing="{}"
      if [ -f "$project_mcp" ]; then
        mcp_existing=$(cat "$project_mcp")
      fi

      for server in "${mcp_list[@]}"; do
        local server_config
        server_config=$(jq --arg s "$server" '.mcpServers[$s] // empty' "$user_mcp" 2>/dev/null)
        if [ -n "$server_config" ]; then
          mcp_existing=$(echo "$mcp_existing" | jq --arg s "$server" --argjson c "$server_config" '.mcpServers[$s] = $c')
          echo "  Copied MCP server '$server' from user-level to $project_mcp"
        else
          echo "  Warning: MCP server '$server' not found in $user_mcp, skipping"
        fi
      done

      echo "$mcp_existing" | jq '.' > "${project_mcp}.tmp"
      mv "${project_mcp}.tmp" "$project_mcp"
      echo ""
      echo "  ⚠ Remember to:"
      echo "    1. Add .mcp.json to .gitignore (contains tokens)"
      echo "    2. Remove '$server' from ~/.claude/mcp.json if you want project-only scope"
    fi
  else
    echo ""
    echo "  Run with --apply to write to project config"
  fi
}

cmd_auto() {
  echo "=== Auto: push → sync → verify ==="
  echo ""
  cmd_push
  echo ""
  cmd_sync
  echo ""
  "$PRISMX_DIR/claude/scripts/context-verify.sh"
}

usage() {
  echo "Usage: $(basename "$0") <command>"
  echo ""
  echo "Commands:"
  echo "  push        Move excess user-level plugins to project .claude/settings.local.json"
  echo "  sync        Sync user-level config from prismx source (backup → replace)"
  echo "  recommend   Scan project and suggest plugins [--apply to write]"
  echo "  auto        Run push → sync → verify"
}

case "${1:-}" in
  push)      cmd_push ;;
  sync)      cmd_sync ;;
  recommend) cmd_recommend "$@" ;;
  auto)      cmd_auto ;;
  *)         usage; exit 1 ;;
esac
