## Project: {{PROJECT_NAME}}

[简要描述]

## Development

```bash
# Install
uv sync        # or: pip install -e ".[dev]"

# Test
pytest -xvs

# Lint
ruff check .
ruff format .

# Type check
pyright
```

## Architecture

[关键目录结构]

## Conventions

- Type hints on public APIs only (function signatures, class attributes)
- Tests in `tests/`: `test_<module>.py`
- Use pytest fixtures, avoid unittest.TestCase
- f-strings over .format()
- Errors: raise specific exceptions, catch at boundaries
