---
name: debug
description: Systematic debugging workflow. Use when the user says "debug this", "/debug", reports a bug, shares an error/stacktrace, or says "why is this broken". Follows a structured reproduce → trace → hypothesize → fix → verify cycle.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Debug

系统化调试：复现 → 追踪 → 假设 → 修复 → 验证。

## Workflow

### 1. Reproduce

First, make the bug visible:

- If the user gave a command that fails → run it, capture output
- If the user gave a stacktrace → read it carefully
- If the user described a behavior → write a minimal reproduction

The bug is NOT understood until you can reproduce it. Don't guess.

### 2. Read the Stacktrace

Parse the error:
- **Error type**: what category (TypeError, 404, panic, etc.)
- **Location**: file:line where it originates
- **Call chain**: how execution got there
- **Data**: what values caused the error

Read the source file at the error location. Read surrounding context (±20 lines).

### 3. Trace the Code Path

Follow the execution path backwards from the error:
- What function called this?
- What data was passed in?
- Where did that data come from?

Use Grep to find callers. Read each file in the chain.

### 4. Hypothesize

Based on the trace, form a hypothesis:
- "X is null because Y didn't initialize it"
- "The API returns Z format but code expects W"
- State it clearly before attempting a fix.

### 5. Fix

Apply the minimal fix that addresses the root cause:
- Don't refactor surrounding code
- Don't add unrelated improvements
- Fix the specific issue

### 6. Verify

Run the original reproduction:
- The error must be gone
- Run the related tests to confirm no regression

```bash
# Run the failing command again
[original command]

# Run related tests
[test command]
```

Show the output. The fix is NOT done until verification passes.

## Anti-patterns

- 不要猜——先复现
- 不要一次改多处——每次只改一个地方，验证后再改下一个
- 不要添加 workaround 而不理解 root cause
- 不要说 "should work now" 而不运行验证命令
