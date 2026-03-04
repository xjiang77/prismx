# Prismx

Personal Claude Code config manager — `~/.claude/` 的 single source of truth。

兼具两个定位：管理 prismx 配置部署，同时也是一份 Claude Code 最佳实践指南。

## Quick Start

```bash
git clone <repo-url> ~/Workspace/prismx
cd ~/Workspace/prismx
make upstream-init          # 初始化 vendor/ submodules
make diff                   # 预览将要安装的文件
make apply                  # 部署到 ~/.claude/（会提示确认）
```

验证：

```bash
make doctor                 # 所有检查项 ✓
make list                   # 查看已安装的 hooks, commands, skills, plugins
```

---

## Skills & Commands

按使用场景分组。所有 `/command` 在 Claude Code session 中直接输入即可。

### 编码中


| Command              | 来源                       | 说明                           |
| -------------------- | ------------------------ | ---------------------------- |
| `/simplify`          | code-simplifier plugin   | 写完代码后精简打磨，也会被 Claude 自动调用    |
| `/security-reviewer` | security-guidance plugin | 涉及 auth/API/敏感数据时自动检测（9 种模式） |


### 提 PR 前


| Command           | 来源                       | 说明                               |
| ----------------- | ------------------------ | -------------------------------- |
| `/review-pr`      | pr-review-toolkit plugin | 6 维度深度审查（见下方 sub-agent 表）        |
| `/commit`         | commit-commands plugin   | 自动生成 conventional commit message |
| `/commit-push-pr` | commit-commands plugin   | 一键 commit + push + 创建 PR         |


`/review-pr` 的 6 个 sub-agent：


| Agent                   | 审查维度                       |
| ----------------------- | -------------------------- |
| `code-reviewer`         | CLAUDE.md 合规 + style + bug |
| `silent-failure-hunter` | catch block、fallback、静默失败  |
| `comment-analyzer`      | 注释准确性、comment rot          |
| `pr-test-analyzer`      | 测试覆盖质量、edge case           |
| `type-design-analyzer`  | 类型设计、encapsulation 评分      |
| `code-simplifier`       | Review 时精简（区别于独立 plugin）   |


### Session 交接


| Command           | 说明                                                                          |
| ----------------- | --------------------------------------------------------------------------- |
| `/handoff-create` | 生成完整 HANDOFF.md（goal / completed / failed approaches / resume instructions） |
| `/handoff-quick`  | 精简版（goal / done / next / warning）                                           |
| `/handoff-resume` | 读取 HANDOFF.md，检测 git drift，继续工作                                             |


配套 skill `handoff` 会自动检测 HANDOFF.md 存在和 trigger phrases。

### 项目维护


| Command                          | 来源                          | 说明                                      |
| -------------------------------- | --------------------------- | --------------------------------------- |
| `/context-optimize`              | context-optimize skill      | Context 配置审查，检查 plugin 分布合理性            |
| `/security-scan`                 | security-scan skill         | 扫描 `.claude/` 安全配置                      |
| `/revise-claude-md`              | claude-md-management plugin | Session 结束时将 learnings 写入 CLAUDE.md     |
| `/claude-automation-recommender` | claude-code-setup plugin    | 分析 codebase 推荐 hooks/skills/plugins/MCP |
| `/claude-md-improver`            | claude-md-management plugin | CLAUDE.md 质量审计和评分                       |


### 日常清理


| Command         | 来源                     | 说明                         |
| --------------- | ---------------------- | -------------------------- |
| `/clean_gone`   | commit-commands plugin | 删除已合入的本地 branch + worktree |
| `/hookify`      | hookify plugin         | 从对话分析问题行为，自动创建 hook        |
| `/hookify:list` | hookify plugin         | 查看已配置规则                    |


---

## Review 工具对比

三个 review 相关工具容易混淆：


| 维度     | `pr-review-toolkit` | `code-review`         | `code-simplifier` |
| ------ | ------------------- | --------------------- | ----------------- |
| **定位** | 专家会诊（6 维度深度审查）      | CI 自动审查（发 PR comment） | 写完代码后精简打磨         |
| **触发** | `/review-pr`        | `/code-review`        | `/simplify` 或自动   |
| **输出** | 分维度分析报告             | GitHub PR comment     | **直接修改代码**        |
| **安装** | 已装（user-level）      | 未装（推荐 project-level）  | 已装（user-level）    |


推荐工作流：

```
编码中 → 编码完成 → 提 PR 前 → PR 合入
         code-simplifier   pr-review-toolkit   code-review (CI)
         (自动精简)        (手动深度 review)   (自动发 comment)
```

---

## Built-in Agents

Claude Code 内置 agent，不需要安装。Prismx 通过 plugin 配置增强这些 agent 的效果。


| Agent               | 用途            | 触发方式                  |
| ------------------- | ------------- | --------------------- |
| `architect`         | 系统架构设计、可扩展性分析 | 自动或手动 spawn           |
| `doc-updater`       | 代码变更后文档同步更新   | 代码变更后自动               |
| `e2e-runner`        | E2E 测试生成和运行   | Playwright 相关任务时      |
| `security-reviewer` | 安全漏洞检测和修复     | 写安全相关代码时自动            |
| `Plan`              | 架构和实现规划       | `EnterPlanMode` 或复杂任务 |
| `Explore`           | 快速代码搜索和探索     | 搜索/浏览任务时              |
| `general-purpose`   | 复杂多步任务自主执行    | 自动                    |
| `code-simplifier`   | 代码精简打磨        | 编码完成后                 |


---

## Plugins

### User-Level（9 个，所有项目共享）

常驻加载，每个 session 自动生效：


| Plugin                 | 类型          | 用途                               |
| ---------------------- | ----------- | -------------------------------- |
| `commit-commands`      | Skill       | git commit 工作流                   |
| `pr-review-toolkit`    | Skill+Agent | PR 深度 review（6 维度）               |
| `code-simplifier`      | Skill+Agent | 编码后代码精简                          |
| `claude-md-management` | Skill       | CLAUDE.md 维护和审计                  |
| `security-guidance`    | Skill       | 安全检测（9 种模式）                      |
| `hookify`              | Skill       | Hook 创建和管理                       |
| `claude-code-setup`    | Skill       | 新项目配置推荐                          |
| `github`               | MCP         | GitHub 全功能集成（~30 deferred tools） |
| `context7`             | MCP         | 查询任意库最新文档（~4 deferred tools）     |


### Project-Level（按需启用）

在项目 `.claude/settings.local.json` 中启用。从 claude-plugins-official 56 个 plugin 中精选 ~30 个：


| 分类          | 数量  | 示例                                                                           |
| ----------- | --- | ---------------------------------------------------------------------------- |
| **LSP**     | 11  | `typescript-lsp`, `pyright-lsp`, `gopls-lsp`, `rust-analyzer-lsp` + 7 others |
| **开发工作流**   | 5   | `feature-dev`（7 阶段 feature 流程）, `code-review`（CI 自动 PR 审查）                   |
| **前端 & 设计** | 3   | `frontend-design`, `playground`, `figma`                                     |
| **测试 & 安全** | 3   | `playwright`, `semgrep`, `coderabbit`                                        |
| **外部服务**    | 6   | `slack`, `atlassian`, `notion`, `linear`, `sentry`, `vercel`                 |
| **输出风格**    | 2   | `explanatory-output-style`, `learning-output-style`                          |
| **其他**      | 4   | `superpowers`, `ralph-loop`, `qodo-skills`, `document-skills`                |


详细推荐和启用方法见 [docs/plugins.md](docs/plugins.md)。

---

## Hooks

### 已安装（7 个）


| Hook                      | Event        | Matcher      | 功能                         |
| ------------------------- | ------------ | ------------ | -------------------------- |
| `notify.sh`               | Notification | `*`          | iTerm2 通知铃声                |
| `protect-sensitive.sh`    | PreToolUse   | `Edit|Write` | 阻止编辑 .env/.pem/.key        |
| `auto-format.sh`          | PostToolUse  | `Edit|Write` | prettier/ruff/gofmt 自动格式化  |
| `ts-type-check.sh`        | PostToolUse  | `Edit|Write` | tsc --noEmit 类型检查          |
| `check-debug-code.sh`     | Stop         | `*`          | 检查 console.log/debugger 遗留 |
| `pre-compact-handoff.sh`  | PreCompact   | —            | Compact 前保存 transcript 上下文 |
| `post-compact-handoff.sh` | SessionStart | compact      | Compact 后注入 handoff 提示     |


### Hook 开发速查

Event types 和 exit codes：


| Event              | 触发时机          | Exit 0 | Exit 2        | Other |
| ------------------ | ------------- | ------ | ------------- | ----- |
| `PreToolUse`       | 工具调用前         | 继续     | 阻止（显示 stderr） | 警告    |
| `PostToolUse`      | 工具调用后         | 继续     | 阻止            | 警告    |
| `UserPromptSubmit` | 用户提交 prompt 后 | 继续     | 阻止            | 警告    |
| `Stop`             | Agent 停止时     | 继续     | 阻止            | 警告    |
| `SubagentStop`     | 子 agent 停止时   | 继续     | 阻止            | 警告    |
| `SessionStart`     | Session 开始    | 继续     | 阻止            | 警告    |
| `SessionEnd`       | Session 结束    | 继续     | 阻止            | 警告    |
| `PreCompact`       | Compact 前     | 继续     | 阻止            | 警告    |
| `Notification`     | 通知事件          | 继续     | 阻止            | 警告    |


**Matcher**: tool name regex，空 = 匹配全部。例：`Edit|Write` 匹配 Edit 和 Write 工具。

**stdin JSON**:

```json
{
  "tool_name": "Edit",
  "tool_input": { "file_path": "...", "old_string": "...", "new_string": "..." },
  "session_id": "..."
}
```

**环境变量**: `CLAUDE_SESSION_ID`（session ID）、`CLAUDE_PROJECT_DIR`（项目路径）

---

## MCP Tools

两个 MCP server 通过 `ToolSearch` 按需加载，不占 session 初始 context：

- **github** (~30 tools): Issues / PRs / Code / Repos 全功能操作
- **context7** (~4 tools): `resolve-library-id → query-docs`，查询任意库最新文档

使用方式：提到 GitHub 操作或需要查文档时，Claude 自动通过 ToolSearch 加载。

---

## Daily Workflow

### 编辑与部署

编辑 `claude/` 目录中的文件后，预览并部署到 `~/.claude/`：

```bash
vim claude/CLAUDE.md        # 编辑配置
make diff                   # 预览变更（不修改任何文件）
make apply                  # 确认后部署
make apply-only C=hooks     # 只部署某组件（hooks|skills|agents|commands|core|templates|scripts）
```

### 项目配置

为目标项目初始化 Claude Code 配置：

```bash
# Step 1: 脚手架
make -C ~/.claude init-project P=~/my-project

# Step 2: AI 推荐（在目标项目的 Claude Code session 中）
cd ~/my-project && claude
> 用 claude-automation-recommender 分析这个项目    # 推荐 hooks/skills/plugins
> /context-optimize                                 # 检查 plugin 分布

# Step 3: 应用推荐到 .claude/settings.local.json
```

### 上游管理

`vendor/` 通过 git submodule 跟踪上游 repo：

```bash
make upstream-update        # 拉取上游最新
make upstream-diff          # 查看变更摘要
# 手动 cherry-pick 感兴趣的内容到 claude/，然后：
make diff && make apply
```

### 维护与回滚


| Command                        | 用途                               |
| ------------------------------ | -------------------------------- |
| `make doctor`                  | 诊断常见问题（权限、路径、缺失文件）               |
| `make audit`                   | 最佳实践检查                           |
| `make list`                    | 查看已安装组件清单                        |
| `make sync`                    | 同步 CLAUDE.md 到 Codex / CodeBuddy |
| `make restore B=<backup-path>` | 从备份恢复                            |
| `make uninstall`               | 完全卸载 prismx 管理的文件                |


备份位置：`~/.claude/backups/<timestamp>/`

---

## Architecture

### Two-Layer Design

- **User-level** (`~/.claude/`) — 通用配置，所有项目共享，由 prismx 管理
- **Project-level** (`.claude/`) — 项目特定配置，各项目自行维护

### Structure

```
prismx/
├── install.sh              # 主安装器（diff/backup/deploy）
├── uninstall.sh            # 卸载/回滚
├── vendor/                 # 上游 submodules（只读参考）
│   ├── claude-handoff/
│   ├── superpowers/
│   └── everything-claude-code/
└── claude/                 # 映射到 ~/.claude/
    ├── CLAUDE.md
    ├── settings.json
    ├── Makefile
    ├── commands/
    ├── hooks/
    ├── skills/
    ├── scripts/
    ├── agents/
    └── templates/
```

### How It Works

`prismx/claude/X` → `~/.claude/X`。安装器会：diff 对比 → 显示变更 → 备份已有文件 → 复制并替换 `__HOME__` 占位符 → 设置 `.sh` 可执行权限 → 写入 manifest。

永远不覆盖：`plugins/`, `projects/`, `plans/`, `tasks/`, `settings.local.json`, `mcp.json` 等运行时数据。

---

## After Install

```bash
alias cc-make='make -C ~/.claude'
cc-make doctor              # 诊断问题
cc-make audit               # 最佳实践检查
cc-make list                # 已安装组件
cc-make init-project P=~/my-project  # 初始化项目配置
```

