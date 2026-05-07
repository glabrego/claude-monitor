# Working with AI agents

This document describes how to use Claude Code (or another AI agent) effectively when contributing to this project.

## Context to provide

When starting a session on this codebase, give the agent this context up front:

- **Three standalone Python scripts** — no build system, no virtual env, no external dependencies
- **No tests** — verify correctness by running the TUI directly and observing behavior
- **Data files live in `~/.claude/`** — not in the repo; don't reference them as if they're committed
- **Symlinks in `~/.local/bin/`** point to the repo scripts — edits take effect immediately

## Useful prompts

**Understanding a behavior:**
> "Read ARCHITECTURE.md and the relevant ADR, then explain why [X] works the way it does."

**Adding a feature:**
> "Read ARCHITECTURE.md first. Then implement [feature]. Don't add external dependencies."

**Debugging:**
> "The [column/behavior] is wrong. Read ADR 003 on pane detection before suggesting a fix."

**Syntax check before committing:**
> "Run `python3 -m py_compile claude-monitor claude-monitor-hook claude-monitor-setup` and fix any errors."

## What agents should NOT do

- Install external Python packages — the zero-dependency constraint is intentional (see ADR 001)
- Modify `~/.claude/settings.json` directly — use `claude-monitor-setup` or add to its `MONITOR_HOOKS` dict
- Write to `~/.claude/monitor-*.json` or `~/.claude/monitor-events.jsonl` — these are runtime data files, not config
- Add a build step, Makefile, or requirements.txt unless there is a compelling reason

## Architecture decisions

Before making a significant change, read the relevant ADR in [`docs/decisions/`](decisions/). These document why things are the way they are and what tradeoffs were consciously accepted. Key ones:

| Change area | Read first |
|-------------|-----------|
| Language / framework | [ADR 001](decisions/001-python-over-compiled-languages.md) |
| Event collection | [ADR 002](decisions/002-hook-based-event-collection.md) |
| Pane detection | [ADR 003](decisions/003-pane-detection-strategy.md) |
| Persistence | [ADR 004](decisions/004-session-registry-as-flat-json.md) |

## Testing changes

There is no test suite. Verify changes by:

1. Running `claude-monitor` in a tmux pane alongside other Claude sessions
2. Checking that the column in question shows the correct value
3. Pressing the relevant key binding and observing the expected behavior
4. Running `python3 -m py_compile` to catch syntax errors

For hook changes, test manually:
```bash
echo '{"session_id":"test-sid","message":"test message"}' | claude-monitor-hook <event-name>
```
