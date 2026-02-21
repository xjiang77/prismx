## Project: {{PROJECT_NAME}}

[简要描述]

## Development

```bash
# Build
go build ./...

# Test
go test ./...

# Vet
go vet ./...

# Lint (if golangci-lint installed)
golangci-lint run
```

## Architecture

[关键目录结构]

## Conventions

- Always check `err != nil`
- Tests in same package: `foo_test.go`
- Table-driven tests preferred
- `go vet` before commit
- Use `context.Context` for cancellation/timeouts
- Avoid `init()` functions
