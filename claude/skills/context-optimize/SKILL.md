---
name: context-optimize
description: Review and optimize Claude Code context configuration. Use when context is bloated, to audit plugin distribution, or to sync user/project-level settings.
command: /context-optimize
---

# Context Optimization

You are a Claude Code context optimization assistant. Help the user manage their two-layer configuration (user-level + project-level).

## Available Commands

Run these via the user's Makefile:

1. **Review** — Show current configuration across all layers
   ```bash
   make -C ~/.claude context-review
   ```

2. **Optimize** — Move excess plugins from user-level to project-level
   ```bash
   # Push non-essential plugins to current project's .claude/settings.local.json
   ~/.claude/scripts/context-optimize.sh push

   # Sync user-level from prismx source (backup + replace + clean tokens)
   ~/.claude/scripts/context-optimize.sh sync

   # Full auto: push → sync → verify
   ~/.claude/scripts/context-optimize.sh auto
   ```

4. **Recommend** — Scan project and suggest project-level plugins
   ```bash
   # Show recommendations for current project
   ~/.claude/scripts/context-optimize.sh recommend

   # Apply recommendations to .claude/settings.local.json
   ~/.claude/scripts/context-optimize.sh recommend --apply
   ```

3. **Verify** — Check configuration is correct
   ```bash
   make -C ~/.claude context-verify
   ```

## Two-Layer Architecture

### User-level (`~/.claude/settings.json`) — 9 plugins
Essential plugins loaded for every project:
- `commit-commands` — git commit workflow
- `pr-review-toolkit` — PR review with specialized agents
- `claude-md-management` — CLAUDE.md maintenance
- `code-simplifier` — code quality
- `security-guidance` — security best practices
- `hookify` — hook management
- `claude-code-setup` — project setup recommendations
- `github` — GitHub integration (MCP, deferred)
- `context7` — documentation queries (MCP, deferred)

### Project-level (`.claude/settings.local.json`) — on demand
Heavy or specialized plugins enabled per-project:
- LSPs: `pyright-lsp`, `typescript-lsp`, `gopls-lsp`, `rust-analyzer-lsp`
- Frontend: `figma`, `frontend-design`, `playwright`
- Code review: `greptile`, `coderabbit`
- Development: `feature-dev`, `agent-sdk-dev`, `skill-creator`
- Other: `document-skills`, `playground`, `semgrep`, `ralph-loop`, `superpowers`, `qodo-skills`

## Workflow

1. Run `context-review` to see current state
2. If user-level has too many plugins, run `context-optimize push` to move excess to project
3. Run `context-optimize sync` to align with prismx source
4. Run `context-verify` to confirm everything is correct
