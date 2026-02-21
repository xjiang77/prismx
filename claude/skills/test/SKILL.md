---
name: test
description: Intelligent test runner. Use when the user says "test this", "run tests", "/test", or wants to run and analyze test results. Detects framework, runs tests, parses results, and suggests fixes for failures.
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Test

智能测试运行器：检测框架 → 运行测试 → 解析结果 → 报告。

## Workflow

### 1. Detect Framework

Check project root for test configuration:

```bash
ls package.json pyproject.toml go.mod Cargo.toml Makefile 2>/dev/null
```

| Indicator | Framework | Command |
|-----------|-----------|---------|
| vitest.config.* | Vitest | `npx vitest run` |
| jest.config.* / package.json has jest | Jest | `npx jest` |
| pyproject.toml / pytest.ini | Pytest | `pytest -xvs` |
| go.mod | Go test | `go test ./...` |
| Cargo.toml | Cargo test | `cargo test` |

If bun.lockb exists, prefer `bun test` over npx.

### 2. Determine Scope

- No arguments → run full suite
- File path argument → run that file only
- Directory argument → run tests in that dir
- Function/test name → run matching test (`-k` for pytest, `-t` for jest)

### 3. Run Tests

Run the detected command. Capture both stdout and stderr. Show the full output to the user.

### 4. Parse Results

Extract from output:
- Total tests / passed / failed / skipped
- Failed test names and error messages
- Stack traces for failures

### 5. Report

Format:

```
## Test Results: [pass/fail]

✓ N passed | ✗ N failed | ○ N skipped

### Failures
- **test_name**: error message
  → file:line
  → suggested fix
```

### 6. Fix Failures

If tests fail, offer to:
1. Read the failing test and implementation
2. Identify the root cause
3. Fix and re-run to verify

Only fix if the user agrees. Don't auto-fix without asking.
