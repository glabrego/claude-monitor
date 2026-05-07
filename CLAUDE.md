# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## What this is

A terminal dashboard for monitoring Claude Code sessions. Three standalone Python scripts — no build system, no package manager, no external dependencies.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for a full overview of how the system works.

## Working with agents

See [docs/AGENTS.md](docs/AGENTS.md) for guidance on how to use AI agents effectively when contributing to this project.

## Key files

| File | Purpose |
|------|---------|
| `claude-monitor` | Main TUI — Python curses, ~600 lines |
| `claude-monitor-hook` | Hook receiver — appends events to `~/.claude/monitor-events.jsonl` |
| `claude-monitor-setup` | Idempotent hook installer for `~/.claude/settings.json` |

## Development workflow

Since these are plain scripts with no build step, edit and run directly:

```bash
# run the TUI
claude-monitor

# test the hook manually
echo '{"session_id":"test","message":"hello"}' | claude-monitor-hook notification

# reinstall hooks after modifying claude-monitor-setup
claude-monitor-setup
```

Syntax check before committing:
```bash
python3 -m py_compile claude-monitor claude-monitor-hook claude-monitor-setup
```

## Architecture decisions

Non-obvious design choices are documented in [`docs/decisions/`](docs/decisions/). Read these before making significant changes to avoid re-litigating settled tradeoffs.
