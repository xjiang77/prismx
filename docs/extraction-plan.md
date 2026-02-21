# Agent-Driven Code Extraction: ECC → Prismx

## Context

Prismx 已经建好了基础设施（13 skills, 5 hooks, install/uninstall），但 **agents/ 目录为空**，且缺少一些高价值的 hooks 和 patterns。

用 Karpathy 提倡的方法：**DeepWiki MCP + GitHub CLI** 从 [everything-claude-code](https://github.com/affaan-m/everything-claude-code)（49k+ stars）中精准提取功能，而不是 fork 或安装整个 plugin。

---

## 方法论（Karpathy 式 Agent-Driven Code Extraction）

### Step 0: 安装 DeepWiki MCP（前置条件）

```bash
claude mcp add -s user -t http deepwiki https://mcp.deepwiki.com/mcp
```

这会在 `~/.claude.json` 中注册 DeepWiki MCP server（免费、无需 API key）。

安装后获得 3 个工具：

- `read_wiki_structure` — 获取 repo 的文档目录结构
- `read_wiki_contents` — 读取特定 topic 的 wiki 内容（代码解析 + 解释）
- `ask_question` — 向 repo 提问（e.g. "how does the architect agent work?"）

### Step 1: DeepWiki 理解实现

```
# 先看整体结构
→ read_wiki_structure("affaan-m/everything-claude-code")

# 再深入具体 topic
→ read_wiki_contents("affaan-m/everything-claude-code", "agents")
→ ask_question("affaan-m/everything-claude-code", "how is the architect agent implemented? what's the system prompt?")
```

**关键**: DeepWiki 不只是读文件，它理解代码含义。可以问 "这个 agent 依赖了什么？核心逻辑是什么？哪些是可以去掉的 boilerplate？"

### Step 2: GitHub CLI 获取源码

```bash
# 获取 repo 文件树
gh api repos/affaan-m/everything-claude-code/git/trees/main?recursive=1

# 获取具体文件（raw 内容）
gh api repos/affaan-m/everything-claude-code/contents/agents/architect.md \
  -H "Accept: application/vnd.github.raw"
```

### Step 3: 分析 + 精简

- 对比 DeepWiki 的解释和原始代码
- 识别核心 prompt/逻辑 vs ECC 特有抽象（Node.js utils, plugin 引用, marketplace hooks）
- 去掉不需要的：跨平台支持、ECC 变量引用、不用的语言 (Java/C++/Swift)

### Step 4: 重写为 self-contained prismx 组件

- Agent → 独立 `.md` 文件，遵循 Claude Code agent 格式
- Hook → 独立 `.sh` 脚本，纯 bash，无外部依赖
- 放入 `prismx/claude/` 对应目录

---

## Gap Analysis

| 能力 | Prismx | ECC | 差距 |
|------|--------|-----|------|
| Agents | 0 | 13 | **最大差距** |
| 高级 Hooks | 5 (基础) | 10+ (智能) | 缺 strategic compact, ts-check, console.log 检测 |
| Rules 系统 | 全塞在 CLAUDE.md | 分类组织 (8 categories) | 结构化不足 |
| 环境优化 | 基础 | thinking tokens, autocompact, subagent model | 缺性能调优 |
| 真实世界模板 | 3 (通用) | 4 (SaaS/微服务/API) | 缺最佳实践模板 |

---

## Phase 1: Agents（最高优先级，prismx 为空）

从 ECC 的 13 个 agents 中提取 **4 个最有价值的**：

### 1a. architect agent

- **来源**: `agents/architect.md`
- **去向**: `prismx/claude/agents/architect.md`
- **价值**: 系统设计 + ADR (Architecture Decision Records)，/plan skill 不覆盖架构层面
- **提取方法**: DeepWiki 查 architect agent 的 system prompt 结构 → gh 获取文件 → 去掉 ECC 特有引用 → 适配 prismx

### 1b. security-reviewer agent

- **来源**: `agents/security-reviewer.md`
- **去向**: `prismx/claude/agents/security-reviewer.md`
- **价值**: OWASP Top 10 审计、密钥检测、依赖漏洞扫描 — prismx 完全没有安全审计能力
- **提取方法**: 同上

### 1c. e2e-runner agent

- **来源**: `agents/e2e-runner.md`
- **去向**: `prismx/claude/agents/e2e-runner.md`
- **价值**: Playwright E2E 测试生成和执行 — 独特能力，/test skill 只覆盖单元测试

### 1d. doc-updater agent

- **来源**: `agents/doc-updater.md`
- **去向**: `prismx/claude/agents/doc-updater.md`
- **价值**: 代码变更后自动同步文档 — 解决 "文档过期" 这个普遍痛点

**执行步骤**:

```bash
# 1. DeepWiki 了解 agent 格式和设计模式
# 2. 用 gh api 获取 4 个 agent 文件
gh api repos/affaan-m/everything-claude-code/contents/agents/architect.md \
  -H "Accept: application/vnd.github.raw" > /tmp/ecc-architect.md
# 3. 分析 → 精简 → 重写为 prismx 风格
# 4. 放入 prismx/claude/agents/
```

---

## Phase 2: 高级 Hooks（日常价值最高）

### 2a. strategic-compact hook

- **来源**: ECC 的 `suggest-compact` 逻辑
- **去向**: `prismx/claude/hooks/suggest-compact.sh`
- **价值**: 在逻辑断点（而非只看 context 压力）建议 `/compact`，节省 context budget
- **注册**: PreToolUse hook

### 2b. ts-type-check hook

- **来源**: ECC 的 TypeScript type checking hook
- **去向**: `prismx/claude/hooks/ts-type-check.sh`
- **价值**: 编辑 `.ts/.tsx` 后自动跑 `npx tsc --noEmit`，在 agent 继续前就抓到类型错误
- **注册**: PostToolUse (Edit|Write), matcher: `*.ts|*.tsx`

### 2c. console-log-check hook

- **来源**: ECC 的 Stop hook
- **去向**: `prismx/claude/hooks/check-debug-code.sh`
- **价值**: session 结束前检查是否遗留 `console.log` / `print()` / `fmt.Println` 等 debug 代码
- **注册**: Stop event

### 2d. 更新 settings.json

- 注册新 hooks 到 settings.json

---

## Phase 3: 环境变量优化

### 3a. settings.json env 新增

在 `prismx/claude/settings.json` 的 `env` 中添加：

```json
{
  "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60",
  "CLAUDE_CODE_SUBAGENT_MODEL": "claude-sonnet-4-6"
}
```

**价值**:

- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60`: 提前 compact（默认 95% 太晚），减少 mid-task 中断
- `CLAUDE_CODE_SUBAGENT_MODEL=haiku`: subagent 用 Haiku 省钱省速度

---

## Phase 4: 真实世界项目模板

### 4a. saas-nextjs-CLAUDE.md

- **来源**: ECC 的 `examples/saas-nextjs-CLAUDE.md`
- **去向**: `prismx/claude/templates/saas-nextjs-CLAUDE.md`
- **价值**: Next.js + Supabase + Stripe 的 SaaS 实战模板，比通用 typescript-CLAUDE.md 更有针对性

### 4b. go-microservice-CLAUDE.md

- **来源**: ECC 的 `examples/go-microservice-CLAUDE.md`
- **去向**: `prismx/claude/templates/go-microservice-CLAUDE.md`
- **价值**: gRPC + PostgreSQL 微服务最佳实践

---

## 实施顺序

| Phase | 内容 | 方法 | 文件数 |
|-------|------|------|--------|
| **1** | 4 Agents | DeepWiki 理解 → gh 获取 → 精简重写 | 4 |
| **2** | 3 Hooks + settings 更新 | DeepWiki 查 hook 模式 → 重写为 bash | 3+1 |
| **3** | 环境变量优化 | 直接修改 settings.json | 1 |
| **4** | 2 实战模板 | gh 获取 → 去 ECC 依赖 → 适配 | 2 |

**总计**: ~11 个文件的变更

---

## Verification

1. `./install.sh --dry-run` — 确认新增文件正确显示
2. `./install.sh --force` — 安装到 `~/.claude/`
3. 新 session 中测试：
   - Agents 可被 Task tool 引用
   - `/compact` 建议在合适时机出现
   - 编辑 `.ts` 文件后 type check 自动触发
   - session 结束前 console.log 检查触发
4. 在实际项目中测试 architect agent
