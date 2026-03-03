# Prismx

Personal Claude Code config repository. Single source of truth for `~/.claude/`.

## Workflows

### 流程总览

```
首次安装          日常开发              项目配置            上游管理              维护            回滚
─────────    ─────────────────    ────────────────    ──────────────    ──────────    ──────────
clone repo   编辑 claude/ 文件    init-project        upstream-update   doctor       restore
    ↓              ↓                   ↓                   ↓             audit        uninstall
upstream-init  make diff           AI 推荐配置         upstream-diff     list
    ↓           (预览变更)         (plugins/hooks)     (review 变更)
 make diff         ↓                   ↓                   ↓
    ↓          make apply          写入 settings       cherry-pick
 make apply    (部署到 ~/.claude)   .local.json        到 claude/
                                                           ↓
                                                       make diff → apply
```

### 1. 首次安装

**运行**:
```bash
git clone <repo-url> ~/Workspace/prismx
cd ~/Workspace/prismx
make upstream-init          # 初始化 vendor/ submodules
make diff                   # 预览将要安装的文件
make apply                  # 部署（会提示确认）
```

**期望输出**:
```
Prismx Installer
Source: /Users/.../prismx/claude
Target: /Users/.../.claude

  + CLAUDE.md (new)
  + hooks/notify.sh (new)
  + settings.json (new)
  ...

Summary: 25 new, 0 changed, 0 unchanged

Install? [y/N] y

Backup saved to: ~/.claude/backups/20250304-143022
  ✓ CLAUDE.md
  ✓ hooks/notify.sh
  ...
Install complete. (25 new, 0 updated)
```

**验证**:
```bash
make doctor                 # 期望：所有检查项 ✓，无 ⚠ 或 ✗
make list                   # 期望：列出 hooks, commands, skills, plugins
```

---

### 2. 日常开发

编辑 `claude/` 目录中的文件后，预览并部署到 `~/.claude/`。

**运行**:
```bash
# 编辑配置文件，例如：
vim claude/CLAUDE.md

# 预览变更（不修改任何文件）
make diff

# 确认后部署
make apply

# 或只部署某个组件
make apply-only C=hooks     # 可选值: hooks|skills|agents|commands|core|templates|scripts
```

**期望输出** (`make diff`):
```
  ~ CLAUDE.md (changed)
3a4
> New line added here

  hooks/notify.sh (up to date)
  ...

Summary: 0 new, 1 changed, 24 unchanged
Dry run — no changes made.
```

**期望输出** (`make apply`):
```
Summary: 0 new, 1 changed, 24 unchanged
Install? [y/N] y
Backup saved to: ~/.claude/backups/20250304-150000
  ✓ CLAUDE.md
Install complete. (0 new, 1 updated)
```

**验证**:
```bash
diff claude/CLAUDE.md ~/.claude/CLAUDE.md    # 期望：无差异（settings.json 除外，有 __HOME__ 替换）
make diff                                     # 期望：Everything up to date.
```

---

### 3. 项目配置

为目标项目初始化 Claude Code 配置，再用 AI 驱动的 skill 按项目特性优化。

**Step 1: 脚手架**:
```bash
# 从终端（prismx 或任意目录）
make -C ~/.claude init-project P=~/my-project
```

**期望输出**:
```
Initializing coding agent config for: my-project
Path: /Users/.../my-project

  ✓ Created CLAUDE.md
  ✓ Created AGENTS.md
  ✓ Created .claude/settings.local.json
```

生成的文件：
- `CLAUDE.md` — 项目说明骨架（需手动填写 build/test/lint 命令）
- `AGENTS.md` — Codex 用（同 CLAUDE.md 内容）
- `.claude/settings.local.json` — 空的 plugin/permission 配置

**Step 2: AI 推荐配置**（在目标项目的 Claude Code session 中）:
```
# 打开目标项目
cd ~/my-project && claude

# 方式 1：让 AI 分析 codebase 推荐 automations
# （会检测语言、框架、项目结构，推荐 hooks/skills/plugins/MCP）
> 用 claude-automation-recommender 分析这个项目

# 方式 2：检查 plugin 分布是否合理
> /context-optimize
```

AI 会读取 prismx 的 user-level 配置 + 项目 codebase，给出定制建议，例如：
- TypeScript 项目 → 启用 `typescript-lsp` plugin
- 有 Playwright 测试 → 启用 `playwright` plugin
- 前端项目 → 启用 `frontend-design` plugin

**Step 3: 应用推荐**:
```json
// ~/my-project/.claude/settings.local.json
{
  "enabledPlugins": {
    "typescript-lsp@claude-plugins-official": true,
    "playwright@claude-plugins-official": true
  }
}
```

**验证**:
```bash
make -C ~/.claude audit-project P=~/my-project   # 期望：CLAUDE.md ✓, AGENTS.md ✓, .claude/ ✓
# 在目标项目的 Claude Code session 中：
> /context-optimize                                # 期望：plugin 分布合理，无 warning
```

---

### 4. 上游管理

`vendor/` 目录通过 git submodule 跟踪上游 repo，需要的内容 cherry-pick 到 `claude/` 定制使用。

**运行**:
```bash
# 拉取上游最新
make upstream-update

# 查看变更摘要
make upstream-diff

# Cherry-pick 流程（手动）：
# 1. 浏览 vendor/ 中的变更
# 2. 复制感兴趣的文件到 claude/ 对应目录
# 3. Review + 适配（修改路径引用等）
# 4. 部署
make diff && make apply
```

**期望输出** (`make upstream-diff`):
```
=== vendor/claude-handoff/ ===
abc1234 feat: add new template
def5678 fix: path handling
=== vendor/superpowers/ ===
  (no changes)
=== vendor/everything-claude-code/ ===
  (no changes)
```

**验证**:
```bash
git submodule status                          # 期望：3 个 submodule 均有 commit hash，无 `-` 前缀
ls vendor/claude-handoff/                     # 期望：能看到上游文件
```

---

### 5. 维护与诊断

**运行**:
```bash
make doctor                 # 诊断常见问题（权限、路径、缺失文件）
make audit                  # 最佳实践检查
make list                   # 查看已安装组件清单
make sync                   # 同步 CLAUDE.md 到 Codex / CodeBuddy
```

**期望输出** (`make list`):
```
=== Hooks ===
auto-format.sh
notify.sh
...

=== Commands ===
handoff-create.md
handoff-quick.md
handoff-resume.md

=== Skills ===
context-optimize
handoff

=== Plugins ===
  ✓ commit-commands@anthropic
  ✓ pr-review-toolkit@anthropic
  ...

=== Permissions ===
Allow: 15 rules
Deny:  3 rules
```

**验证**: `make doctor` 输出无 `✗` 或 `ERROR`。

---

### 6. 回滚与恢复

**查看可用备份**:
```bash
ls ~/.claude/backups/
# 期望：按时间戳命名的目录列表，如 20250304-143022/
```

**恢复特定备份**:
```bash
make restore B=~/.claude/backups/20250304-143022
```

**期望输出**:
```
Restoring from: ~/.claude/backups/20250304-143022
  ✓ CLAUDE.md
  ✓ settings.json
Restored 2 files.
```

**完全卸载**:
```bash
make uninstall
```

**期望输出**:
```
Files to remove (from manifest):
  - CLAUDE.md
  - hooks/notify.sh
  ...
Remove 25 managed files? [y/N] y
  ✓ Removed CLAUDE.md
  ...
Uninstall complete. 25 files removed.
```

**验证**:
```bash
ls ~/.claude/CLAUDE.md 2>/dev/null; echo $?   # 期望：1（文件不存在）
make apply                                     # 重新安装
make doctor                                    # 确认恢复正常
```

## Configuration Architecture

### Two-Layer Design

Prismx 采用两层配置体系，减少 context 开销：

- **User-level** (`~/.claude/`) — 通用配置，所有项目共享。由 prismx 管理。
- **Project-level** (`.claude/`) — 项目特定配置，按需启用。各项目自行维护。

---

## Plugins

### User-Level（9 个，所有项目共享）

常驻加载，每个 session 自动生效：

| Plugin | 类型 | 用途 | 选择理由 |
|---|---|---|---|
| `commit-commands` | Skill | git commit 工作流 | 每个项目都需要 commit |
| `pr-review-toolkit` | Skill+Agent | PR 深度 review（6 维度） | 每个项目都做 PR |
| `code-simplifier` | Skill+Agent | 编码后代码精简 | 通用代码质量工具 |
| `claude-md-management` | Skill | CLAUDE.md 维护和审计 | 每个项目都有 CLAUDE.md |
| `security-guidance` | Skill | 安全检测（9 种模式） | 写代码时通用 |
| `hookify` | Skill | Hook 创建和管理 | 管理 prismx hooks |
| `claude-code-setup` | Skill | 新项目配置推荐 | 新项目初始化用 |
| `github` | MCP (~30 tools, deferred) | GitHub 全功能集成 | 几乎所有项目用 GitHub |
| `context7` | MCP (~4 tools, deferred) | 查询任意库的最新文档 | 通用，overhead 极小 |

### Project-Level 精选推荐

按需在项目 `.claude/settings.local.json` 中启用。以下从 claude-plugins-official 56 个 plugin 中精选 ~30 个与多语言开发工作流相关的。

#### LSP（按需启用，匹配项目语言）

核心 4 个：

| Plugin | 适用场景 |
|---|---|
| `typescript-lsp` | TypeScript / JavaScript 项目 |
| `pyright-lsp` | Python 项目 |
| `gopls-lsp` | Go 项目 |
| `rust-analyzer-lsp` | Rust 项目 |

其他 7 个 LSP 按需启用：`clangd-lsp` (C/C++), `csharp-lsp` (C#), `jdtls-lsp` (Java), `kotlin-lsp`, `lua-lsp`, `php-lsp`, `swift-lsp`

启用方法：
```json
// .claude/settings.local.json
{
  "plugins": {
    "typescript-lsp@claude-plugins-official": true
  }
}
```

#### 开发工作流

| Plugin | 用途 |
|---|---|
| `feature-dev` | 7 阶段 feature 开发流程（Discovery → Explore → Questions → Architecture → Implement → Review → Summary） |
| `code-review` | CI 自动 PR 审查（4 agent + confidence scoring，自动发 GitHub PR comment） |
| `plugin-dev` | Plugin 开发工具包 |
| `skill-creator` | Skill 创建 / 改进 / 评估 |
| `agent-sdk-dev` | Claude Agent SDK 开发 |

#### 前端 & 设计

| Plugin | 用途 |
|---|---|
| `frontend-design` | 前端 UI 设计辅助 |
| `playground` | 交互式 HTML playground |
| `figma` | Figma 设计稿集成 |

#### 测试 & 安全

| Plugin | 用途 |
|---|---|
| `playwright` | E2E 测试（Microsoft） |
| `semgrep` | 实时安全漏洞检测 |
| `coderabbit` | 40+ 静态分析器 |

#### 外部服务集成

| Plugin | 用途 |
|---|---|
| `slack` | Slack 消息读写 |
| `atlassian` | Jira / Confluence 集成 |
| `notion` | Notion 文档集成 |
| `linear` | Linear 项目管理 |
| `sentry` | Sentry 错误追踪 |
| `vercel` | Vercel 部署管理 |

#### 输出风格

| Plugin | 用途 |
|---|---|
| `explanatory-output-style` | 教育性注释输出（注意：额外 token 开销） |
| `learning-output-style` | 交互式学习模式 |

#### 其他

| Plugin | 用途 |
|---|---|
| `superpowers` | TDD / brainstorming / debugging 教学 |
| `ralph-loop` | 循环验证 agent |
| `qodo-skills` | 测试生成 |
| `document-skills` | 文档生成（PDF/PPTX/DOCX，来自 anthropic-agent-skills） |

### Marketplace 管理

```bash
# 在 Claude Code 中浏览 marketplace
/plugin → Discover

# 安装 plugin
/plugin install {name}@claude-plugins-official

# 另有 anthropic-agent-skills marketplace
/plugin install document-skills@anthropic-agent-skills
```

---

## 易混淆 Plugin 对比

### Review 三件套

| 维度 | `pr-review-toolkit` | `code-review` | `code-simplifier` |
|---|---|---|---|
| **定位** | 专家会诊（6 维度深度审查） | CI 自动审查（一键发 PR comment） | 写完代码后精简打磨 |
| **触发** | `/review-pr` 或单独调某个 agent | `/code-review`（PR branch 上） | `/simplify` 或 Claude 自动调用 |
| **Agent** | 6 个专项 | 4 个通用（2×CLAUDE.md 合规 + bug + git blame） | 1 个 |
| **输出** | 分维度分析报告 | 自动发 GitHub PR comment | **直接修改代码** |
| **何时用** | 提 PR 前自己深度 review | 团队 CI 自动化审查 | 编码完成后打磨 |
| **安装** | 已装（user-level） | 未装（推荐 project-level） | 已装（user-level） |

> **注意**：`pr-review-toolkit` 内部有一个 `code-simplifier` sub-agent，与独立的 `code-simplifier` plugin 同名但用途不同——前者在 review 时用，后者在编码后主动精简。

### 推荐工作流

```
编码中 → 编码完成 → 提 PR 前 → PR 合入
         code-simplifier   pr-review-toolkit   code-review (CI)
         (自动精简)        (手动深度 review)   (自动发 comment)
```

---

## Official Skills & Commands

已安装的 9 个 user-level plugin 提供的完整使用指南。

### commit-commands

| Command | 场景 | 说明 |
|---|---|---|
| `/commit` | 日常提交 | 自动生成 conventional commit message |
| `/commit-push-pr` | Feature 完成 | 一键 commit + push + 创建 PR |
| `/clean_gone` | PR 合入后清理 | 删除已合入的本地 branch + worktree |

### pr-review-toolkit

**`/review-pr`** — 提 PR 前深度审查。可选维度：tests / errors / types / code / simplify / comments

6 个子 agent：

| Agent | 用途 |
|---|---|
| `code-reviewer` | 通用 review（CLAUDE.md 合规 + style + bug） |
| `silent-failure-hunter` | 错误处理审查（catch block、fallback、静默失败） |
| `comment-analyzer` | 注释准确性（comment rot、过时注释） |
| `pr-test-analyzer` | 测试覆盖质量（behavioral vs line coverage、edge case） |
| `type-design-analyzer` | 类型设计（encapsulation + invariant 评分 1-10） |
| `code-simplifier` | Review 时精简（区别于独立 code-simplifier plugin） |

### code-simplifier

| Command | 场景 | 说明 |
|---|---|---|
| `/simplify` | 编码完成后打磨 | 也会被 Claude 写完代码后自动调用 |

关注：clarity、redundancy、consistency。**直接修改代码**（不是生成报告）。

### claude-md-management

| Command | 场景 | 说明 |
|---|---|---|
| `/revise-claude-md` | Session 结束时 | 将 learnings 写入 CLAUDE.md |
| `claude-md-improver` | 审计 CLAUDE.md | 质量评分体系 |

### security-guidance

自动 SessionStart hook，9 种检测模式。

触发场景：写代码涉及用户输入、auth、API endpoint、敏感数据时，Claude 自动调用 `security-reviewer` agent。

### hookify

| Command | 场景 | 说明 |
|---|---|---|
| `/hookify` | 从对话中分析问题行为 | 自动创建 hook 防止重犯 |
| `/hookify:list` | 查看已配置规则 | — |
| `/hookify:configure` | 启用/禁用规则 | — |
| `/hookify:writing-rules` | 规则语法指导 | — |

### claude-code-setup

| Command | 场景 | 说明 |
|---|---|---|
| `claude-automation-recommender` | 新项目初始化 | 分析 codebase 推荐 hooks/skills/plugins/MCP |

### github (MCP, ~30 deferred tools)

通过 ToolSearch 按需加载，不占 session 初始 context：

| 类别 | 操作 |
|---|---|
| Issues | create / read / update / search / comment |
| PRs | create / read / review / merge / update |
| Code | search / get-file / create-or-update / push |
| Repos | create / fork / search / branches / tags / releases |

### context7 (MCP, ~4 deferred tools)

```
resolve-library-id → query-docs
```

场景：查询任意库的最新文档和示例代码。触发：提到 "use context7" 或需要查文档时。

---

## Built-in Agents

Claude Code 内置 agent，不需要安装，按需自动 spawn 或手动调用：

| Agent | 用途 | 触发方式 | 说明 |
|---|---|---|---|
| `architect` | 系统架构设计、可扩展性分析 | Claude 自动或手动 spawn | 替代原自建 architect agent |
| `doc-updater` | 代码变更后文档同步更新 | 代码变更后自动 | 替代原自建 doc-updater agent |
| `e2e-runner` | E2E 测试生成和运行（Playwright） | Playwright 相关任务时 | 替代原自建 e2e-runner agent |
| `security-reviewer` | 安全漏洞检测和修复 | 写安全相关代码时自动 | 替代原自建 security-reviewer agent |
| `Plan` | 架构和实现规划 | `EnterPlanMode` 或复杂任务时 | 替代原自建 plan skill |
| `Explore` | 快速代码搜索和探索 | 搜索/浏览任务时 | — |
| `general-purpose` | 复杂多步任务自主执行 | 自动 | — |
| `code-simplifier` | 代码精简打磨 | 编码完成后 | 与同名 plugin 互补 |

---

## Custom Skills & Commands

### /handoff-create, /handoff-quick, /handoff-resume

Session 间 context 交接。来源：`vendor/claude-handoff`（已 review + 定制）。

| Command | 用途 |
|---|---|
| `/handoff-create` | 生成完整 HANDOFF.md（goal, completed, failed approaches, resume instructions） |
| `/handoff-quick` | 精简版，只有 goal/done/next/warning |
| `/handoff-resume` | 读取 HANDOFF.md，检测 git drift，继续工作 |

配套 skill `handoff` 会自动检测 HANDOFF.md 存在和 trigger phrases。

### /context-optimize

Context 配置审查和优化。检查 user-level / project-level plugin 分布是否合理，推荐优化方案。

```
# 在 Claude Code 中
/context-optimize
```

### /security-scan

扫描 `.claude/` 目录安全配置。检查 hardcoded secrets、permission misconfig、hook injection risks、MCP 问题。

```
# 在 Claude Code 中
/security-scan
```

---

## Hooks

### 已安装 Hooks（5 个）

| Hook | Event | Matcher | 功能 |
|---|---|---|---|
| `notify.sh` | Notification | `*` | iTerm2 通知铃声 |
| `protect-sensitive.sh` | PreToolUse | `Edit\|Write` | 阻止编辑 .env/.pem/.key |
| `auto-format.sh` | PostToolUse | `Edit\|Write` | prettier/ruff/gofmt 自动格式化 |
| `ts-type-check.sh` | PostToolUse | `Edit\|Write` | tsc --noEmit 类型检查 |
| `check-debug-code.sh` | Stop | `*` | 检查 console.log/debugger/print 遗留 |

### Hook 开发速查

#### Event Types（9 种）

| Event | 触发时机 | 典型用途 |
|---|---|---|
| `PreToolUse` | 工具调用前 | 拦截危险操作 |
| `PostToolUse` | 工具调用后 | 格式化、检查 |
| `UserPromptSubmit` | 用户提交 prompt 后 | 输入验证 |
| `Stop` | Agent 停止时 | 最终检查 |
| `SubagentStop` | 子 agent 停止时 | 子任务验收 |
| `SessionStart` | Session 开始 | 环境初始化 |
| `SessionEnd` | Session 结束 | 清理 |
| `PreCompact` | Compact 前 | 保存 context |
| `Notification` | 通知事件 | 提醒用户 |

#### Matcher 语法

- Tool name regex，空 = 匹配全部
- 示例：`Edit|Write` 匹配 Edit 和 Write 工具

#### Exit Code 含义

| Code | 含义 |
|---|---|
| `0` | Pass（继续执行） |
| `2` | Block with message（阻止执行，显示 stderr） |
| other | Warning（显示 stderr，继续执行） |

#### stdin JSON 格式

Hook 通过 stdin 接收 JSON：
```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." },
  "session_id": "..."
}
```

#### 环境变量

| 变量 | 说明 |
|---|---|
| `CLAUDE_SESSION_ID` | 当前 session ID |
| `CLAUDE_PROJECT_DIR` | 项目目录路径 |

---

## Upstream Dependencies

`vendor/` 目录通过 git submodule 管理上游参考 repo。只做跟踪和参考，不直接部署——需要的内容 cherry-pick 到 `claude/` 后定制使用。

| Submodule | 用途 |
|---|---|
| `vendor/claude-handoff` | Session handoff（HANDOFF.md 生成/恢复） |
| `vendor/superpowers` | 开发方法论参考（TDD/debugging/review/planning） |
| `vendor/everything-claude-code` | Agent/command/skill 参考库 |

### 上游管理工作流

```bash
make upstream-init     # 首次 clone 后初始化 submodules
make upstream-update   # 拉取上游最新
make upstream-diff     # 查看上游变更

# Cherry-pick 流程：
# 1. make upstream-update 拉取最新
# 2. 查看 vendor/ 中感兴趣的文件
# 3. 复制到 claude/ 对应目录，review + 定制
# 4. make diff 确认，make apply 部署
```

---

## Structure

```
prismx/
├── install.sh              # Main installer (diff, backup, deploy)
├── uninstall.sh            # Uninstall / rollback
│
├── vendor/                 # Upstream submodules (read-only reference)
│   ├── claude-handoff/     # willseltzer/claude-handoff
│   ├── superpowers/        # obra/superpowers
│   └── everything-claude-code/  # affaan-m/everything-claude-code
│
└── claude/                 # Maps 1:1 to ~/.claude/
    ├── CLAUDE.md           # Global instructions
    ├── settings.json       # Permissions, hooks, plugins (__HOME__ placeholder)
    ├── statusline-command.sh
    ├── Makefile
    │
    ├── commands/
    │   ├── handoff-create.md   # Full handoff document generation
    │   ├── handoff-quick.md    # Minimal handoff
    │   └── handoff-resume.md   # Resume from existing handoff
    │
    ├── hooks/
    │   ├── notify.sh           # iTerm2 notification bell
    │   ├── protect-sensitive.sh # Block edits to .env/.pem/.key
    │   ├── auto-format.sh      # PostToolUse: prettier/ruff/gofmt
    │   ├── ts-type-check.sh    # PostToolUse: TypeScript type check
    │   └── check-debug-code.sh # Stop: check for debug code
    │
    ├── skills/
    │   ├── context-optimize/   # Context config review & optimize
    │   ├── handoff/            # Auto-detect HANDOFF.md & trigger phrases
    │   └── security-scan/      # Security scan for .claude/
    │
    ├── scripts/
    │   ├── doctor.sh           # Diagnose issues
    │   ├── audit.sh            # Best practices check
    │   ├── init-project.sh     # Initialize project config
    │   ├── sync-agents.sh      # Sync to Codex/CodeBuddy
    │   ├── context-review.sh   # Review context configuration
    │   ├── context-optimize.sh # Optimize plugin distribution
    │   └── context-verify.sh   # Verify config correctness
    │
    ├── agents/                 # .gitkeep only (using built-in agents)
    │
    └── templates/
        ├── typescript-CLAUDE.md    # TS project template
        ├── python-CLAUDE.md        # Python project template
        ├── go-CLAUDE.md            # Go project template
        ├── go-microservice-CLAUDE.md
        ├── saas-nextjs-CLAUDE.md
        ├── CLAUDE.md.tpl           # Generic project CLAUDE.md
        ├── AGENTS.md.tpl           # Codex AGENTS.md
        └── settings.local.json.tpl
```

## How It Works

`prismx/claude/X` maps to `~/.claude/X`. The installer:

1. Diffs every file against the installed version
2. Shows new/changed/unchanged files with color
3. Backs up changed files to `~/.claude/backups/`
4. Copies files, replacing `__HOME__` with actual `$HOME` in settings.json
5. Makes `.sh` files executable
6. Writes a manifest to `~/.claude/.prismx-manifest`

Files that are never overwritten: `plugins/`, `projects/`, `plans/`, `tasks/`, `todos/`, `settings.local.json`, `mcp.json`, and other runtime data.

## Context Management

```bash
# Review current context configuration
make -C ~/.claude context-review

# Optimize: move excess plugins to project-level
~/.claude/scripts/context-optimize.sh push

# Sync user-level from prismx source
~/.claude/scripts/context-optimize.sh sync

# Full auto: push → sync → verify
~/.claude/scripts/context-optimize.sh auto

# Verify everything is correct
make -C ~/.claude context-verify
```

Or use the skill inside Claude Code:
```
/context-optimize
```

## After Install

```bash
# Use Makefile commands from anywhere
alias cc-make='make -C ~/.claude'
cc-make doctor          # Diagnose issues
cc-make audit           # Check best practices
cc-make list            # List installed components
cc-make context-review  # Review context config
cc-make context-verify  # Verify config correctness
cc-make init-project P=~/my-project  # Init project config
```
