---
description: Create a minimal handoff - just the essentials
---

Create a minimal `HANDOFF.md` with only the essentials. Use this for simple tasks or quick context transfers.

Output this exact format (fill in the brackets):

```markdown
# Handoff: [task in 5 words or less]

**Goal**: [one sentence]

**Done**: [comma-separated list of completed items, or "Nothing yet"]

**Next**: [the single most important next step]

**Watch out**: [one key warning, or "Nothing special"]
```

That's it. No extras.

Save location:
- Create `.claude/handoffs/` directory if it doesn't exist
- Filename: `HANDOFF-{branch}-{YYYYMMDD-HHMMSS}.md` (branch from `git branch --show-current`, `/` → `-`)
- If `$ARGUMENTS` specifies a path, use that instead

If `.claude/handoffs/.pre-compact-context.md` exists, read it for extra context, then delete it.

After saving, if `.gitignore` doesn't contain `.claude/handoffs/`, append it (create `.gitignore` if needed).
