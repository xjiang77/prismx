---
name: refactor
description: Safe refactoring with test guardrails. Use when the user says "/refactor", "refactor this", "clean up this code", or wants to restructure code without changing behavior. Runs tests before and after to ensure safety.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Refactor

安全重构：测试基线 → 重构 → 验证绿灯 → 展示 diff。

## Workflow

### 1. Understand Scope

Clarify with the user:
- What to refactor (file, function, module)
- What kind of refactoring (extract, rename, simplify, reorganize)
- What NOT to change

### 2. Baseline Tests

Run the test suite BEFORE any changes:

```bash
[test command]
```

All tests must pass. If they don't, fix tests first (or ask user) before refactoring.

Record the baseline: N tests, all passing.

### 3. Read the Code

Read the target code thoroughly. Understand:
- Current structure and responsibilities
- Dependencies (who calls this, what does it call)
- Edge cases handled

### 4. Plan the Refactoring

Describe what you'll change and why. Common refactoring types:

| Type | When |
|------|------|
| Extract function | 函数太长或有重复逻辑 |
| Rename | 命名不清晰 |
| Simplify conditionals | 嵌套过深或逻辑复杂 |
| Move/reorganize | 职责错位 |
| Remove dead code | 未使用的代码 |
| Reduce duplication | DRY 原则 |

### 5. Execute

Apply changes incrementally:
- One refactoring step at a time
- Run tests after each step
- If tests break, revert and retry differently

### 6. Verify

Run the full test suite:

```bash
[test command]
```

All baseline tests must still pass. Show the output.

### 7. Show Diff

```bash
git diff
```

Present the diff so the user can review the changes.

## Rules

- 不改变行为——所有现有测试必须通过
- 不添加功能——重构和 feature 分开做
- 不一次改太多——小步快跑，每步验证
- 如果没有测试覆盖，先建议添加测试再重构
