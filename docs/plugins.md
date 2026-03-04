# Plugin 推荐指南

Prismx 采用两层 plugin 体系：User-level 常驻加载，Project-level 按需启用。

---

## User-Level Plugins（9 个）

所有项目共享，每个 session 自动生效：

| Plugin | 类型 | 用途 | 选择理由 |
|---|---|---|---|
| `commit-commands` | Skill | git commit 工作流（/commit, /commit-push-pr, /clean_gone） | 每个项目都需要 commit |
| `pr-review-toolkit` | Skill+Agent | PR 深度 review（6 维度，6 个 sub-agent） | 每个项目都做 PR |
| `code-simplifier` | Skill+Agent | 编码后代码精简（/simplify） | 通用代码质量工具 |
| `claude-md-management` | Skill | CLAUDE.md 维护和审计（/revise-claude-md） | 每个项目都有 CLAUDE.md |
| `security-guidance` | Skill | 安全检测（9 种模式，SessionStart 自动触发） | 写代码时通用 |
| `hookify` | Skill | Hook 创建和管理（/hookify） | 管理 prismx hooks |
| `claude-code-setup` | Skill | 新项目配置推荐（claude-automation-recommender） | 新项目初始化用 |
| `github` | MCP | GitHub 全功能集成（~30 deferred tools） | 几乎所有项目用 GitHub |
| `context7` | MCP | 查询任意库最新文档（~4 deferred tools） | 通用，overhead 极小 |

---

## Project-Level Plugins 精选推荐

从 claude-plugins-official 56 个 plugin 中精选 ~30 个与多语言开发工作流相关的。在项目 `.claude/settings.local.json` 中按需启用。

### LSP（语言服务器）

核心 4 个，按项目语言启用：

| Plugin | 适用场景 |
|---|---|
| `typescript-lsp` | TypeScript / JavaScript 项目 |
| `pyright-lsp` | Python 项目 |
| `gopls-lsp` | Go 项目 |
| `rust-analyzer-lsp` | Rust 项目 |

其他 7 个按需启用：

| Plugin | 适用场景 |
|---|---|
| `clangd-lsp` | C / C++ |
| `csharp-lsp` | C# |
| `jdtls-lsp` | Java |
| `kotlin-lsp` | Kotlin |
| `lua-lsp` | Lua |
| `php-lsp` | PHP |
| `swift-lsp` | Swift |

### 开发工作流

| Plugin | 用途 |
|---|---|
| `feature-dev` | 7 阶段 feature 开发流程（Discovery → Explore → Questions → Architecture → Implement → Review → Summary） |
| `code-review` | CI 自动 PR 审查（4 agent + confidence scoring，自动发 GitHub PR comment） |
| `plugin-dev` | Plugin 开发工具包 |
| `skill-creator` | Skill 创建 / 改进 / 评估 |
| `agent-sdk-dev` | Claude Agent SDK 开发 |

### 前端 & 设计

| Plugin | 用途 |
|---|---|
| `frontend-design` | 前端 UI 设计辅助 |
| `playground` | 交互式 HTML playground |
| `figma` | Figma 设计稿集成 |

### 测试 & 安全

| Plugin | 用途 |
|---|---|
| `playwright` | E2E 测试（Microsoft） |
| `semgrep` | 实时安全漏洞检测 |
| `coderabbit` | 40+ 静态分析器 |

### 外部服务集成

| Plugin | 用途 |
|---|---|
| `slack` | Slack 消息读写 |
| `atlassian` | Jira / Confluence 集成 |
| `notion` | Notion 文档集成 |
| `linear` | Linear 项目管理 |
| `sentry` | Sentry 错误追踪 |
| `vercel` | Vercel 部署管理 |

### 输出风格

| Plugin | 用途 | 注意 |
|---|---|---|
| `explanatory-output-style` | 教育性注释输出 | 额外 token 开销 |
| `learning-output-style` | 交互式学习模式 | 额外 token 开销 |

### 其他

| Plugin | 用途 |
|---|---|
| `superpowers` | TDD / brainstorming / debugging 教学 |
| `ralph-loop` | 循环验证 agent |
| `qodo-skills` | 测试生成 |
| `document-skills` | 文档生成（PDF/PPTX/DOCX，来自 anthropic-agent-skills） |

---

## 启用方法

在目标项目的 `.claude/settings.local.json` 中添加：

```json
{
  "plugins": {
    "typescript-lsp@claude-plugins-official": true,
    "playwright@claude-plugins-official": true
  }
}
```

或使用 AI 推荐：

```bash
cd ~/my-project && claude
> 用 claude-automation-recommender 分析这个项目
> /context-optimize
```

AI 会根据项目 codebase（语言、框架、测试、部署）给出定制建议。

---

## Marketplace 管理

```bash
# 在 Claude Code 中浏览 marketplace
/plugin → Discover

# 安装 plugin
/plugin install {name}@claude-plugins-official

# anthropic-agent-skills marketplace
/plugin install document-skills@anthropic-agent-skills
```

---

## Review 三件套详细对比

| 维度 | `pr-review-toolkit` | `code-review` | `code-simplifier` |
|---|---|---|---|
| **定位** | 专家会诊（6 维度深度审查） | CI 自动审查（一键发 PR comment） | 写完代码后精简打磨 |
| **触发** | `/review-pr` 或单独调某个 agent | `/code-review`（PR branch 上） | `/simplify` 或 Claude 自动调用 |
| **Agent** | 6 个专项 | 4 个通用（2×CLAUDE.md 合规 + bug + git blame） | 1 个 |
| **输出** | 分维度分析报告 | 自动发 GitHub PR comment | **直接修改代码** |
| **何时用** | 提 PR 前自己深度 review | 团队 CI 自动化审查 | 编码完成后打磨 |
| **安装** | 已装（user-level） | 未装（推荐 project-level） | 已装（user-level） |

> **注意**：`pr-review-toolkit` 内部有一个 `code-simplifier` sub-agent，与独立的 `code-simplifier` plugin 同名但用途不同——前者在 review 时用，后者在编码后主动精简。
