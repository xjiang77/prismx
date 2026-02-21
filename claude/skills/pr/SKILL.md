---
name: pr
description: PR workflow — create or review pull requests. Use when the user says "/pr", "/pr create", "/pr review", "create a PR", "review PR #N", or wants to work with pull requests. Supports both creating new PRs and reviewing existing ones.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# PR

PR 工作流：创建 PR 或 review 已有 PR。

## Mode Detection

- `/pr` 或 `/pr create` → Create mode
- `/pr review <number>` → Review mode

## Create Mode

### 1. Gather Context

```bash
git status
git log --oneline main..HEAD
git diff main...HEAD --stat
```

### 2. Analyze Changes

Read ALL changed files (not just the diff summary). Understand:
- What was added/changed/removed
- Why (infer from commit messages and code)
- Impact and scope

### 3. Generate PR Content

- **Title**: `type(scope): 中文简述` (≤70 chars)
- **Body**:

```markdown
## Summary
- [变更要点，2-3 bullets]

## Changes
- [具体文件/模块级别的变更说明]

## Test Plan
- [ ] [如何验证这些变更]
```

### 4. Create PR

```bash
gh pr create --title "title" --body "$(cat <<'EOF'
## Summary
...

## Test Plan
...
EOF
)"
```

Show the PR URL when done.

## Review Mode

### 1. Fetch PR

```bash
gh pr view <number> --json title,body,files,additions,deletions
gh pr diff <number>
```

### 2. Review

Read every changed file thoroughly. Analyze across dimensions:

| Dimension | Check |
|-----------|-------|
| Correctness | 逻辑是否正确，边界条件 |
| Security | 注入、权限、secrets |
| Performance | 不必要的计算、N+1 |
| Testing | 是否有对应测试 |

### 3. Output

```markdown
## PR Review: #N — [title]

### Summary
[2-3 句总结]

### Findings

#### Issues
- **file:line** [description] — [suggestion]

#### Suggestions
- **file:line** [description]

#### Positive
- [值得肯定的地方]

### Verdict
[APPROVE / REQUEST_CHANGES / COMMENT]
```

### 4. Submit (Optional)

If user says "submit" or "post":
```bash
gh pr review <number> --approve --body "..."
# or
gh pr review <number> --request-changes --body "..."
```
