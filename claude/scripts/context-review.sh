#!/bin/bash
# Review Claude Code context configuration across user and project levels
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PROJECT_DIR=""

if [ -d ".claude" ]; then
  PROJECT_DIR="$(pwd)/.claude"
elif [ -d "${PWD}/.claude" ]; then
  PROJECT_DIR="${PWD}/.claude"
fi

echo "=== Context Configuration Review ==="
echo ""

# --- User-level plugins ---
echo "--- Plugins [USER] ($CLAUDE_DIR/settings.json) ---"
user_plugins=0
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  user_plugins=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' "$CLAUDE_DIR/settings.json")
  jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | "  [USER] ✓ " + .key' "$CLAUDE_DIR/settings.json"
else
  echo "  (not found)"
fi
echo "  Total: $user_plugins plugins"
echo ""

# --- Project-level plugins ---
echo "--- Plugins [PROJECT] (.claude/settings.local.json) ---"
project_plugins=0
if [ -n "$PROJECT_DIR" ] && [ -f "$PROJECT_DIR/settings.local.json" ]; then
  project_plugins=$(jq '[.enabledPlugins // {} | to_entries[] | select(.value == true)] | length' "$PROJECT_DIR/settings.local.json")
  jq -r '.enabledPlugins // {} | to_entries[] | select(.value == true) | "  [PROJECT] ✓ " + .key' "$PROJECT_DIR/settings.local.json"
else
  echo "  (none)"
fi
echo "  Total: $project_plugins plugins"
echo ""

# --- MCP Servers ---
echo "--- MCP Servers ---"
if [ -f "$CLAUDE_DIR/mcp.json" ]; then
  echo "  User-level ($CLAUDE_DIR/mcp.json):"
  jq -r '.mcpServers // {} | keys[] | "    [USER] " + .' "$CLAUDE_DIR/mcp.json" 2>/dev/null || echo "    (none)"
fi
if [ -f ".mcp.json" ]; then
  echo "  Project-level (.mcp.json):"
  jq -r '.mcpServers // {} | keys[] | "    [PROJECT] " + .' ".mcp.json" 2>/dev/null || echo "    (none)"
fi
echo ""

# --- Skills ---
echo "--- Skills ---"
skill_count=0
if [ -d "$CLAUDE_DIR/skills" ]; then
  skill_count=$(find "$CLAUDE_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  find "$CLAUDE_DIR/skills" -name "SKILL.md" -exec dirname {} \; 2>/dev/null | xargs -I{} basename {} | sort | sed 's/^/  /'
fi
echo "  Total: $skill_count skills"
echo ""

# --- Agents ---
echo "--- Agents ---"
agent_count=0
if [ -d "$CLAUDE_DIR/agents" ]; then
  agent_count=$(find "$CLAUDE_DIR/agents" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  find "$CLAUDE_DIR/agents" -name "*.md" -exec basename {} .md \; 2>/dev/null | sort | sed 's/^/  /'
fi
echo "  Total: $agent_count agents"
echo ""

# --- Hooks ---
echo "--- Hooks ---"
hook_count=0
if [ -d "$CLAUDE_DIR/hooks" ]; then
  hook_count=$(find "$CLAUDE_DIR/hooks" -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
  find "$CLAUDE_DIR/hooks" -name "*.sh" -exec basename {} \; 2>/dev/null | sort | sed 's/^/  /'
fi
echo "  Total: $hook_count hooks"
echo ""

# --- Summary ---
total_plugins=$((user_plugins + project_plugins))
echo "=== Summary ==="
echo "  Plugins:  $total_plugins ($user_plugins user + $project_plugins project)"
echo "  Skills:   $skill_count"
echo "  Agents:   $agent_count"
echo "  Hooks:    $hook_count"
echo ""

# --- Recommendations ---
if [ "$user_plugins" -gt 12 ]; then
  echo "⚠ User-level has $user_plugins plugins (recommend ≤12)"
  echo "  Run: context-optimize.sh push — to move excess plugins to project-level"
fi
