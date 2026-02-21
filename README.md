# Prismx

Personal Claude Code config repository. Single source of truth for `~/.claude/`.

## Quick Start

```bash
git clone <repo-url> ~/Workspace/prismx
cd ~/Workspace/prismx

# Preview changes
./install.sh --dry-run

# Install
./install.sh
```

## Usage

```bash
./install.sh              # Preview diff + confirm install
./install.sh --dry-run    # Preview only
./install.sh --force      # Skip confirmation
./install.sh --only hooks # Install only hooks

./uninstall.sh            # Remove managed files
./uninstall.sh --restore ~/.claude/backups/<timestamp>  # Restore from backup
```

## Structure

```
prismx/
├── install.sh              # Main installer (diff, backup, deploy)
├── uninstall.sh            # Uninstall / rollback
│
└── claude/                 # Maps 1:1 to ~/.claude/
    ├── CLAUDE.md           # Global instructions
    ├── settings.json       # Permissions, hooks, plugins (__HOME__ placeholder)
    ├── statusline-command.sh
    ├── Makefile
    │
    ├── hooks/
    │   ├── notify.sh           # iTerm2 notification bell
    │   ├── protect-sensitive.sh # Block edits to .env/.pem/.key
    │   ├── auto-format.sh      # PostToolUse: prettier/ruff/gofmt
    │   ├── auto-test.sh        # PostToolUse: opt-in via PRISMX_AUTO_TEST=1
    │   └── save-session.sh     # PreCompact: save session context
    │
    ├── skills/
    │   ├── commit/         # Conventional commit workflow
    │   ├── code-review/    # Structured code review
    │   ├── plan/           # Architecture planning
    │   ├── tdd/            # Test-driven development
    │   ├── test/           # Smart test runner
    │   ├── debug/          # Systematic debugging
    │   ├── pr/             # PR create & review
    │   ├── refactor/       # Safe refactoring
    │   ├── find-skills/    # Skill discovery
    │   ├── skill-auditor/  # Audit skill collection
    │   ├── skill-creator/  # Create & improve skills
    │   ├── skill-packager/ # Package skills as plugins
    │   └── skill-reviewer/ # Review individual skills
    │
    ├── templates/
    │   ├── typescript-CLAUDE.md  # TS project template
    │   ├── python-CLAUDE.md      # Python project template
    │   ├── go-CLAUDE.md          # Go project template
    │   ├── CLAUDE.md.tpl         # Generic project CLAUDE.md
    │   ├── AGENTS.md.tpl         # Codex AGENTS.md
    │   └── settings.local.json.tpl
    │
    ├── scripts/
    │   ├── doctor.sh       # Diagnose issues
    │   ├── audit.sh        # Best practices check
    │   ├── init-project.sh # Initialize project config
    │   └── sync-agents.sh  # Sync to Codex/CodeBuddy
    │
    └── agents/
        └── .gitkeep
```

## How It Works

`prismx/claude/X` maps to `~/.claude/X`. The installer:

1. Diffs every file against the installed version
2. Shows new/changed/unchanged files with color
3. Backs up changed files to `~/.claude/backups/`
4. Copies files, replacing `__HOME__` with actual `$HOME` in settings.json
5. Makes `.sh` files executable
6. Writes a manifest to `~/.claude/.prismx-manifest`

Files that are never overwritten: `plugins/`, `projects/`, `plans/`, `tasks/`, `todos/`, `settings.local.json`, and other runtime data.

## After Install

```bash
# Use Makefile commands from anywhere
alias cc-make='make -C ~/.claude'
cc-make doctor    # Diagnose issues
cc-make audit     # Check best practices
cc-make list      # List installed components
cc-make init-project P=~/my-project  # Init project config
```
