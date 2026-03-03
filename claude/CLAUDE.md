## Core Rules

1. **Prove It Works**: Never say "verified" or "already implemented" without running the actual command and showing its output. Reading a file is NOT verification. Run the code, paste the terminal output. If a command fails, fix and retry — don't claim partial success.

2. **No False Completions**: If you haven't run the verification command, the task is NOT complete. Period.

3. **Action Over Planning**: Do NOT enter plan mode for simple/medium tasks. If the user provides a plan or clear instruction, execute it immediately. Only use plan mode for genuinely complex architectural decisions or tasks spanning 5+ steps across multiple systems. When in doubt, act.

4. **Pick and Act**: When fixing something, pick the most reasonable approach and do it. Do NOT present multiple options and ask the user to choose unless the decision is truly ambiguous and high-stakes.

5. **Review Scope**: When reviewing code or a PR, scope to ALL changes on the current branch vs main unless told otherwise. Do NOT limit to the last commit.

## Writing

- 中英文混合：technical terms in English, explanations in Chinese.

## Language Detection

进入项目时检测语言 (package.json / go.mod / pyproject.toml)：
- **TypeScript**: 有 bun.lockb 用 bun，否则 pnpm；测试优先 vitest，fallback jest
- **Python**: 有 [tool.uv] 用 uv，否则 pip；测试用 pytest -xvs
- **Go**: go test ./...，提交前 go vet

## Debugging

调试时：先 reproduce（不要猜），trace code path，形成 hypothesis，apply minimal fix，运行原始失败命令验证。

## TDD

RED-GREEN-REFACTOR：先写一个 failing test（必须 fail，pass 说明 test 有问题），
最小实现让它 pass，再 refactor。每步跑 test 并 show output。

## PR Format

- Title: `type(scope): 中文简述`（≤70 chars）
- Body: ## Summary (2-3 bullets), ## Changes, ## Test Plan

## Research Workflows

- **Extract pattern**: 用 DeepWiki MCP 理解库架构 + GitHub MCP/CLI 读源码 → 实现 self-contained 版本 + equivalence test。注意检查源 license。
