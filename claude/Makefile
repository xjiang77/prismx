.DEFAULT_GOAL := help
CLAUDE_DIR := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)
PRISMX_DIR := $(shell cd "$(CLAUDE_DIR)/.." 2>/dev/null && pwd || echo "")

help: ## Show all available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

install: ## First-time setup: chmod, fix paths, sync agents, verify
	@echo "=== Installing ==="
	chmod +x $(CLAUDE_DIR)/hooks/*.sh $(CLAUDE_DIR)/statusline-command.sh $(CLAUDE_DIR)/scripts/*.sh
	mkdir -p $(CLAUDE_DIR)/skills $(CLAUDE_DIR)/agents $(CLAUDE_DIR)/mcp
	@# Fix hardcoded home paths in settings.json
	@if grep -q '/Users/[^/]*/\.claude/' $(CLAUDE_DIR)/settings.json 2>/dev/null; then \
		sed -i '' "s|/Users/[^/]*/\.claude/|$$HOME/.claude/|g" $(CLAUDE_DIR)/settings.json; \
		echo "  ✓ Fixed hardcoded paths in settings.json"; \
	else \
		echo "  - settings.json paths already correct"; \
	fi
	@$(MAKE) --no-print-directory sync
	@$(MAKE) --no-print-directory doctor

update: ## Pull latest from prismx and reinstall
	@if [ -n "$(PRISMX_DIR)" ] && [ -f "$(PRISMX_DIR)/install.sh" ]; then \
		echo "=== Updating from Prismx ==="; \
		git -C "$(PRISMX_DIR)" pull --rebase; \
		"$(PRISMX_DIR)/install.sh" --force; \
	else \
		echo "=== Updating from git ==="; \
		git -C $(CLAUDE_DIR) pull --rebase; \
		$(MAKE) --no-print-directory install; \
	fi

audit: ## Check global config against best practices
	@$(CLAUDE_DIR)/scripts/audit.sh

doctor: ## Diagnose common issues
	@$(CLAUDE_DIR)/scripts/doctor.sh

list: ## List installed skills, hooks, plugins, permissions
	@echo "=== Hooks ==="
	@ls -1 $(CLAUDE_DIR)/hooks/*.sh 2>/dev/null | xargs -I{} basename {} || echo "  (none)"
	@echo ""
	@echo "=== Skills ==="
	@ls -1 $(CLAUDE_DIR)/skills/ 2>/dev/null | grep -v .gitkeep || echo "  (none)"
	@echo ""
	@echo "=== MCP ==="
	@ls -1 $(CLAUDE_DIR)/mcp/ 2>/dev/null | grep -v .gitkeep || echo "  (none)"
	@echo ""
	@echo "=== Plugins ==="
	@if [ -f $(CLAUDE_DIR)/settings.json ]; then \
		jq -r '.enabledPlugins // {} | to_entries[] | "  " + (if .value then "✓" else "✗" end) + " " + .key' $(CLAUDE_DIR)/settings.json; \
	fi
	@echo ""
	@echo "=== Permissions ==="
	@if [ -f $(CLAUDE_DIR)/settings.json ]; then \
		echo "Allow: $$(jq '.permissions.allow | length' $(CLAUDE_DIR)/settings.json) rules"; \
		echo "Deny:  $$(jq '.permissions.deny | length' $(CLAUDE_DIR)/settings.json) rules"; \
	fi

init-project: ## Initialize project config (P=<path>)
	@$(CLAUDE_DIR)/scripts/init-project.sh $(or $(P),$(error Usage: make init-project P=<path>))

audit-project: ## Audit project config (P=<path>)
	@echo "=== Auditing project: $(P) ==="
	@[ -f "$(P)/CLAUDE.md" ] && echo "  ✓ CLAUDE.md exists" || echo "  ⚠ No CLAUDE.md"
	@[ -f "$(P)/AGENTS.md" ] && echo "  ✓ AGENTS.md exists" || echo "  ⚠ No AGENTS.md"
	@[ -d "$(P)/.claude" ] && echo "  ✓ .claude/ exists" || echo "  ⚠ No .claude/"
	@if [ -f "$(P)/CLAUDE.md" ]; then \
		lines=$$(wc -l < "$(P)/CLAUDE.md" | tr -d ' '); \
		echo "  CLAUDE.md: $$lines lines"; \
	fi

install-codex: ## Sync CLAUDE.md → ~/.codex/AGENTS.md
	@$(CLAUDE_DIR)/scripts/sync-agents.sh codex

install-codebuddy: ## Sync CLAUDE.md → ~/.codebuddy/CLAUDE.md
	@$(CLAUDE_DIR)/scripts/sync-agents.sh codebuddy

sync: ## Sync config to all agents (Codex + CodeBuddy)
	@$(CLAUDE_DIR)/scripts/sync-agents.sh all

.PHONY: help install update audit doctor list init-project audit-project install-codex install-codebuddy sync
