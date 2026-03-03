# Prismx

## Project
- Shell-based config manager for `~/.claude/` — bash scripts, Makefiles, no package manager
- `claude/` directory maps 1:1 to `~/.claude/`
- `install.sh` handles diff/backup/deploy with `__HOME__` placeholder replacement

## Dev Workflow
- `make diff` — preview changes before install
- `make apply` — install to ~/.claude
- Test hooks/skills by installing then running Claude Code in a test project

## Conventions
- Scripts must be POSIX-compatible bash (no bashisms beyond `[[ ]]`)
- All `.sh` files get +x via installer
- `settings.json` uses `__HOME__` placeholder (replaced at install time)
