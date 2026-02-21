## Project: {{PROJECT_NAME}}

[简要描述]

## Development

```bash
# Install
pnpm install   # or: bun install

# Dev
pnpm dev

# Build
pnpm build

# Test
pnpm test      # vitest
pnpm test:watch

# Lint
pnpm lint      # eslint
pnpm format    # prettier
```

## Architecture

[关键目录结构]

## Conventions

- Strict TypeScript: no `any`, no `as` casts unless justified with comment
- Tests colocated: `foo.ts` → `foo.test.ts`
- Prefer vitest; fallback jest
- Use named exports over default exports
- Errors: throw typed errors, catch at boundaries
