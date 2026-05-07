# ADR 002 — Hook-based event collection

## Status
Accepted

## Context

The TUI needs richer per-session data than what `~/.claude/sessions/<pid>.json` provides: last tool called, last user message, notification state, and the tmux pane the session was started in.

Options considered:
1. Poll the conversation JSONL files directly on every render
2. Use Claude Code's hook system to capture events as they happen
3. Read from cmux's `~/.cmuxterm/workstream.jsonl`

## Decision

Use Claude Code's native hook system. A lightweight hook receiver (`claude-monitor-hook`) is called by Claude Code on each event and appends a JSONL line to `~/.claude/monitor-events.jsonl`.

Hooks installed: `SessionStart`, `PreToolUse`, `UserPromptSubmit`, `Notification`, `Stop`.

All hooks are configured `async: true` so they never block the agent.

## Rationale

**Option 1 (poll conversation JSONL)** would work for the model name but is too expensive for real-time tool tracking — the files grow large and parsing them on every render is wasteful.

**Option 3 (cmux's workstream)** creates a hard dependency on cmux, which was explicitly ruled out. The project goal is to be a standalone tool independent of any terminal multiplexer wrapper.

**Option 2 (hooks)** is the right fit:
- Events are captured exactly when they happen — no polling lag
- `$TMUX_PANE` is available in the hook process environment and captured at `SessionStart`, giving accurate pane attribution for existing sessions
- Hooks are append-only JSONL — simple to tail and parse
- Async hooks add <5ms overhead per event

## Consequences

- Events only appear for sessions started **after** hook installation. Pre-existing sessions fall back to proc-env reading (`ps eww -p <pid>`) for pane detection
- The JSONL grows unboundedly; trimmed to 5000 lines when it exceeds 512KB
- Hook payloads are whatever Claude Code provides — if the payload schema changes, the hook receiver may need updating
