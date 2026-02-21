#!/bin/bash
# Security scan for Claude Code configuration
# Usage: scan.sh [path-to-claude-dir]
#
# Checks .claude/ directory for:
# - Hardcoded secrets in config files
# - Overly permissive permissions
# - Hook command injection risks
# - MCP server misconfigurations
# - Agent security issues

set -euo pipefail

# ─── Colors ───
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Find target directory ───
TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    if [ -d ".claude" ]; then
        TARGET=".claude"
    elif [ -d "${HOME}/.claude" ]; then
        TARGET="${HOME}/.claude"
    else
        echo -e "${RED}No .claude/ directory found. Specify path: scan.sh /path/to/.claude${NC}"
        exit 1
    fi
fi

if [ ! -d "$TARGET" ]; then
    echo -e "${RED}Directory not found: $TARGET${NC}"
    exit 1
fi

# ─── State ───
SCORE=100
FINDINGS=0
CRITICALS=0
HIGHS=0
MEDIUMS=0
INFOS=0

finding() {
    local severity="$1"
    local file="$2"
    local message="$3"
    local fix="${4:-}"

    FINDINGS=$((FINDINGS + 1))

    case "$severity" in
        CRITICAL)
            echo -e "  ${RED}${BOLD}[CRITICAL]${NC} ${file}"
            SCORE=$((SCORE - 15))
            CRITICALS=$((CRITICALS + 1))
            ;;
        HIGH)
            echo -e "  ${RED}[HIGH]${NC}     ${file}"
            SCORE=$((SCORE - 8))
            HIGHS=$((HIGHS + 1))
            ;;
        MEDIUM)
            echo -e "  ${YELLOW}[MEDIUM]${NC}   ${file}"
            SCORE=$((SCORE - 3))
            MEDIUMS=$((MEDIUMS + 1))
            ;;
        INFO)
            echo -e "  ${BLUE}[INFO]${NC}     ${file}"
            INFOS=$((INFOS + 1))
            ;;
    esac

    echo -e "             ${message}"
    if [ -n "$fix" ]; then
        echo -e "             ${GREEN}Fix: ${fix}${NC}"
    fi
    echo ""
}

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Claude Code Security Scan${NC}"
echo -e "${BOLD}  Target: ${TARGET}${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""

# ─── 1. Secret Detection ───
echo -e "${BOLD}▸ Checking for hardcoded secrets...${NC}"
echo ""

SECRET_PATTERNS=(
    'sk-[a-zA-Z0-9]{20,}'
    'sk-ant-[a-zA-Z0-9-]{20,}'
    'ghp_[a-zA-Z0-9]{36}'
    'gho_[a-zA-Z0-9]{36}'
    'github_pat_[a-zA-Z0-9_]{20,}'
    'glpat-[a-zA-Z0-9-]{20,}'
    'xoxb-[0-9]+-[a-zA-Z0-9]+'
    'xoxp-[0-9]+-[a-zA-Z0-9]+'
    'AKIA[0-9A-Z]{16}'
    'eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}'
    '["\x27]password["'\'']\s*[:=]\s*["\x27][^"'\'']{4,}'
    'api[_-]?key\s*[:=]\s*["\x27][a-zA-Z0-9]{16,}'
    'secret\s*[:=]\s*["\x27][a-zA-Z0-9]{16,}'
    'token\s*[:=]\s*["\x27][a-zA-Z0-9]{16,}'
)

scan_secrets() {
    local file="$1"
    [ -f "$file" ] || return 0

    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -qEi "$pattern" "$file" 2>/dev/null; then
            local match
            match=$(grep -oEi "$pattern" "$file" 2>/dev/null | head -1)
            # Mask the secret
            local masked="${match:0:8}..."
            finding "CRITICAL" "$file" \
                "Possible hardcoded secret: ${masked}" \
                "Use environment variable reference instead"
        fi
    done
}

# Scan all text files in .claude/
while IFS= read -r -d '' file; do
    scan_secrets "$file"
done < <(find "$TARGET" -type f \( -name "*.json" -o -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" \) -print0 2>/dev/null)

# ─── 2. Permission Checks ───
echo -e "${BOLD}▸ Checking permissions configuration...${NC}"
echo ""

SETTINGS_FILE="${TARGET}/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    # Check for Bash(*) wildcard
    if grep -q '"Bash(\*)"' "$SETTINGS_FILE" 2>/dev/null; then
        finding "CRITICAL" "$SETTINGS_FILE" \
            "Bash(*) in allow list — unrestricted shell access" \
            "Scope to specific commands: Bash(git *), Bash(npm *), etc."
    fi

    # Check for Bash(rm -rf *)
    if grep -q 'Bash(rm -rf' "$SETTINGS_FILE" 2>/dev/null; then
        if grep -q '"allow"' "$SETTINGS_FILE" 2>/dev/null && grep -A999 '"allow"' "$SETTINGS_FILE" | grep -q 'Bash(rm -rf'; then
            finding "CRITICAL" "$SETTINGS_FILE" \
                "rm -rf in allow list" \
                "Move to deny list or remove entirely"
        fi
    fi

    # Check for missing deny list
    if ! grep -q '"deny"' "$SETTINGS_FILE" 2>/dev/null; then
        finding "HIGH" "$SETTINGS_FILE" \
            "No deny list configured" \
            "Add deny list for dangerous commands: rm -rf, git push --force, sudo, etc."
    fi

    # Check for --no-verify in allow list
    if grep -q '\-\-no-verify' "$SETTINGS_FILE" 2>/dev/null; then
        finding "MEDIUM" "$SETTINGS_FILE" \
            "--no-verify found in permissions — bypasses git hooks" \
            "Remove --no-verify to enforce pre-commit checks"
    fi

    # Check for sudo in allow list
    if grep -q '"Bash(sudo' "$SETTINGS_FILE" 2>/dev/null; then
        if grep -A999 '"allow"' "$SETTINGS_FILE" | grep -q 'Bash(sudo'; then
            finding "HIGH" "$SETTINGS_FILE" \
                "sudo in allow list" \
                "Remove sudo from allow list; add to deny list"
        fi
    fi

    # Check for curl/wget in allow list
    if grep -q '"Bash(curl\|"Bash(wget' "$SETTINGS_FILE" 2>/dev/null; then
        if grep -A999 '"allow"' "$SETTINGS_FILE" | grep -qE 'Bash\(curl|Bash\(wget'; then
            finding "MEDIUM" "$SETTINGS_FILE" \
                "curl/wget in allow list — potential data exfiltration vector" \
                "Consider moving to deny list or scoping to specific URLs"
        fi
    fi
else
    finding "INFO" "$SETTINGS_FILE" \
        "No settings.json found"
fi

# ─── 3. Hook Security ───
echo -e "${BOLD}▸ Checking hook security...${NC}"
echo ""

while IFS= read -r -d '' hook_file; do
    [ -f "$hook_file" ] || continue

    # Check for unquoted variable interpolation (command injection)
    if grep -qE '\$\{?(file|path|input|output|tool_input)\}?' "$hook_file" 2>/dev/null; then
        if ! grep -qE '"\$\{?(file|path|input|output|tool_input)\}?"' "$hook_file" 2>/dev/null; then
            finding "HIGH" "$hook_file" \
                "Unquoted variable interpolation — command injection risk" \
                "Quote all variables: \"\${file}\" instead of \${file}"
        fi
    fi

    # Check for data exfiltration
    if grep -qE '(curl|wget|nc |netcat)\s' "$hook_file" 2>/dev/null; then
        finding "HIGH" "$hook_file" \
            "Network command in hook — potential data exfiltration" \
            "Remove network calls from hooks or document their purpose"
    fi

    # Check for silent error suppression
    if grep -qE '2>/dev/null.*\|\|.*true$' "$hook_file" 2>/dev/null; then
        finding "MEDIUM" "$hook_file" \
            "Silent error suppression (2>/dev/null || true)" \
            "Log errors instead of suppressing: 2>>\"\$LOG_FILE\""
    fi

    # Check for eval usage
    if grep -qE '\beval\b' "$hook_file" 2>/dev/null; then
        finding "HIGH" "$hook_file" \
            "eval usage in hook — code injection risk" \
            "Replace eval with direct command execution"
    fi

    # Check for base64 (obfuscation)
    if grep -qE 'base64\s+(--decode|-d)' "$hook_file" 2>/dev/null; then
        finding "HIGH" "$hook_file" \
            "base64 decode in hook — possible obfuscated payload" \
            "Review and replace with plain text"
    fi
done < <(find "$TARGET" -path "*/hooks/*" -type f -print0 2>/dev/null)

# ─── 4. MCP Server Checks ───
echo -e "${BOLD}▸ Checking MCP server configuration...${NC}"
echo ""

MCP_FILE="${TARGET}/mcp.json"
if [ -f "$MCP_FILE" ]; then
    # Check for hardcoded secrets in MCP env
    for pattern in "${SECRET_PATTERNS[@]}"; do
        if grep -qEi "$pattern" "$MCP_FILE" 2>/dev/null; then
            finding "CRITICAL" "$MCP_FILE" \
                "Hardcoded secret in MCP server config" \
                "Use environment variable reference"
        fi
    done

    # Check for npx -y (auto-install without confirmation)
    if grep -q 'npx -y\|npx --yes' "$MCP_FILE" 2>/dev/null; then
        finding "MEDIUM" "$MCP_FILE" \
            "npx -y auto-installs packages without confirmation — supply chain risk" \
            "Pin specific versions or install globally first"
    fi

    # Check for shell-type MCP servers
    if grep -q '"type":\s*"command"' "$MCP_FILE" 2>/dev/null; then
        if grep -qE '"command":\s*"(bash|sh|zsh)\b' "$MCP_FILE" 2>/dev/null; then
            finding "HIGH" "$MCP_FILE" \
                "Shell-running MCP server" \
                "Use stdio or HTTP transport instead"
        fi
    fi
fi

# Also check project-level mcp.json
PROJECT_MCP=".mcp.json"
if [ -f "$PROJECT_MCP" ]; then
    if grep -q 'npx -y\|npx --yes' "$PROJECT_MCP" 2>/dev/null; then
        finding "MEDIUM" "$PROJECT_MCP" \
            "npx -y in project MCP config" \
            "Pin specific versions"
    fi
fi

# ─── 5. Agent Checks ───
echo -e "${BOLD}▸ Checking agent definitions...${NC}"
echo ""

while IFS= read -r -d '' agent_file; do
    [ -f "$agent_file" ] || continue

    # Check for unrestricted Bash in agent tools
    agent_content=$(cat "$agent_file")
    if echo "$agent_content" | grep -qiE '^tools:.*Bash' 2>/dev/null; then
        finding "MEDIUM" "$agent_file" \
            "Agent has Bash access — review if necessary" \
            "Restrict to Read, Grep, Glob for research-only agents"
    fi

    # Check for missing model specification
    if ! echo "$agent_content" | grep -qiE '^model:' 2>/dev/null; then
        finding "INFO" "$agent_file" \
            "No model specified — will use default (most expensive)" \
            "Add 'model: haiku' or 'model: sonnet' in frontmatter"
    fi
done < <(find "$TARGET" -path "*/agents/*" -name "*.md" -print0 2>/dev/null)

# ─── 6. CLAUDE.md Checks ───
echo -e "${BOLD}▸ Checking CLAUDE.md files...${NC}"
echo ""

while IFS= read -r -d '' claude_md; do
    [ -f "$claude_md" ] || continue

    # Check for auto-run instructions (prompt injection surface)
    if grep -qiE '(always run|auto.?run|execute immediately|run this command first)' "$claude_md" 2>/dev/null; then
        finding "HIGH" "$claude_md" \
            "Auto-run instruction detected — prompt injection surface" \
            "Use hooks for automatic execution instead of CLAUDE.md instructions"
    fi

    # Check for secrets
    scan_secrets "$claude_md"
done < <(find "$TARGET" -name "CLAUDE.md" -print0 2>/dev/null)

# Also check project root CLAUDE.md
if [ -f "CLAUDE.md" ]; then
    scan_secrets "CLAUDE.md"
fi

# ─── Report ───
echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"

# Clamp score
[ "$SCORE" -lt 0 ] && SCORE=0

# Determine grade
if [ "$SCORE" -ge 90 ]; then
    GRADE="A"
    GRADE_COLOR="$GREEN"
elif [ "$SCORE" -ge 75 ]; then
    GRADE="B"
    GRADE_COLOR="$GREEN"
elif [ "$SCORE" -ge 60 ]; then
    GRADE="C"
    GRADE_COLOR="$YELLOW"
elif [ "$SCORE" -ge 40 ]; then
    GRADE="D"
    GRADE_COLOR="$RED"
else
    GRADE="F"
    GRADE_COLOR="$RED"
fi

echo -e "  ${BOLD}Grade: ${GRADE_COLOR}${GRADE}${NC} (${SCORE}/100)"
echo ""
echo -e "  Findings: ${FINDINGS} total"
[ "$CRITICALS" -gt 0 ] && echo -e "    ${RED}${BOLD}Critical: ${CRITICALS}${NC}"
[ "$HIGHS" -gt 0 ] && echo -e "    ${RED}High:     ${HIGHS}${NC}"
[ "$MEDIUMS" -gt 0 ] && echo -e "    ${YELLOW}Medium:   ${MEDIUMS}${NC}"
[ "$INFOS" -gt 0 ] && echo -e "    ${BLUE}Info:     ${INFOS}${NC}"

if [ "$FINDINGS" -eq 0 ]; then
    echo -e "  ${GREEN}No issues found.${NC}"
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""

# Exit code: non-zero if critical findings
[ "$CRITICALS" -gt 0 ] && exit 1
exit 0
