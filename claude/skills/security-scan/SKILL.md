---
name: security-scan
description: Scan Claude Code configuration (.claude/) for security vulnerabilities. Use when the user says "/security-scan", "audit my config", "check security", or before committing .claude/ changes. Runs a bash script that checks for hardcoded secrets, permission misconfigs, hook injection risks, and MCP issues.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Security Scan

审计 `.claude/` 配置的安全性：secrets、permissions、hooks、MCP、agents。

## Usage

Run the scan script against a target directory:

```bash
~/.claude/skills/security-scan/scan.sh [path-to-claude-dir]
```

If no path is given, it scans the current project's `.claude/` directory, falling back to `~/.claude/`.

## What It Checks

| Category | Checks |
|----------|--------|
| **Secrets** | API keys, tokens, passwords hardcoded in CLAUDE.md, settings.json, mcp.json |
| **Permissions** | `Bash(*)` wildcard, missing deny lists, dangerous commands in allow list |
| **Hooks** | Command injection via `${var}` interpolation, data exfil (curl/wget), silent error suppression |
| **MCP** | Hardcoded env secrets, `npx -y` auto-install, shell-running servers |
| **Agents** | Unrestricted Bash access, missing model spec, prompt injection surface |

## Severity Levels

- **CRITICAL** — Fix immediately: hardcoded secrets, `Bash(*)` allow
- **HIGH** — Fix before production: injection in hooks, missing deny lists
- **MEDIUM** — Recommended: silent error suppression, `npx -y` in MCP
- **INFO** — Awareness: missing descriptions, style suggestions

## Grading

| Grade | Score | Meaning |
|-------|-------|---------|
| A | 90-100 | Secure configuration |
| B | 75-89 | Minor issues |
| C | 60-74 | Needs attention |
| D | 40-59 | Significant risks |
| F | 0-39 | Critical vulnerabilities |

## Workflow

1. Run `scan.sh` — get the report with findings and grade
2. Review each finding — the script shows file, line, severity, and fix suggestion
3. Apply fixes — edit the flagged files
4. Re-run `scan.sh` — confirm grade improved

## After the Scan

Based on findings, suggest concrete fixes:
- Replace hardcoded secrets with env var references (`$ENV_NAME`)
- Scope wildcard permissions (`Bash(*)` → specific commands)
- Quote variables in hooks to prevent injection
- Add deny lists for dangerous commands
- Remove `npx -y` from MCP configs
