.DEFAULT_GOAL := help
ROOT_DIR := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)
CLAUDE_HOME := $(HOME)/.claude

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_.-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

diff: ## Compare prismx config with ~/.claude (dry run only)
	@$(ROOT_DIR)/install.sh --dry-run

preview: diff ## Alias of diff

apply: ## Install with confirmation prompt
	@$(ROOT_DIR)/install.sh

install: apply ## Alias of apply

apply-force: ## Install without confirmation prompt
	@$(ROOT_DIR)/install.sh --force

install-force: apply-force ## Alias of apply-force

apply-only: ## Install one component only. Usage: make apply-only C=hooks
	@test -n "$(C)" || (echo "Usage: make apply-only C=hooks|skills|agents|core|templates|scripts"; exit 1)
	@$(ROOT_DIR)/install.sh --only "$(C)"

install-only: apply-only ## Alias of apply-only

apply-only-force: ## Install one component only without confirmation. Usage: make apply-only-force C=hooks
	@test -n "$(C)" || (echo "Usage: make apply-only-force C=hooks|skills|agents|core|templates|scripts"; exit 1)
	@$(ROOT_DIR)/install.sh --force --only "$(C)"

install-only-force: apply-only-force ## Alias of apply-only-force

uninstall: ## Remove Prismx-managed files from ~/.claude
	@$(ROOT_DIR)/uninstall.sh

restore: ## Restore from backup. Usage: make restore B=~/.claude/backups/<timestamp>
	@test -n "$(B)" || (echo "Usage: make restore B=~/.claude/backups/<timestamp>"; exit 1)
	@$(ROOT_DIR)/uninstall.sh --restore "$(B)"

doctor: ## Run diagnostics from installed ~/.claude
	@make -C "$(CLAUDE_HOME)" doctor

audit: ## Run config audit from installed ~/.claude
	@make -C "$(CLAUDE_HOME)" audit

list: ## List installed hooks/skills/plugins/permissions from ~/.claude
	@make -C "$(CLAUDE_HOME)" list

sync: ## Sync CLAUDE.md to Codex + CodeBuddy from installed ~/.claude
	@make -C "$(CLAUDE_HOME)" sync

.PHONY: help diff preview apply install apply-force install-force apply-only install-only apply-only-force install-only-force uninstall restore doctor audit list sync
