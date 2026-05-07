# Architecture

## Overview

```
┌─────────────────────────────────────────────────────┐
│                  Claude Code process                 │
│  (one per session, writes ~/.claude/sessions/*.json) │
└──────────────────────┬──────────────────────────────┘
                       │ hooks (async)
                       ▼
┌─────────────────────────────────────────────────────┐
│              claude-monitor-hook                     │
│  reads stdin (hook payload + $TMUX_PANE from env)   │
│  appends to ~/.claude/monitor-events.jsonl          │
│  fires osascript notification on Notification event │
└──────────────────────┬──────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
~/.claude/sessions/*.json   ~/.claude/monitor-events.jsonl
  (written by Claude Code)   (written by hook)
          │                         │
          └────────────┬────────────┘
                       │ read every 1s
                       ▼
┌─────────────────────────────────────────────────────┐
│                  claude-monitor                      │
│  Python curses TUI, refreshes at 1Hz               │
│  maintains ~/.claude/monitor-registry.json (7 days) │
│  maintains ~/.claude/monitor-labels.json            │
└─────────────────────────────────────────────────────┘
```

## Data sources

### `~/.claude/sessions/<pid>.json`
Written and deleted by Claude Code itself. One file per running session. Contains `pid`, `sessionId`, `cwd`, `status` (`busy`/`idle`), `startedAt`, `version`. The file disappears when the session ends.

### `~/.claude/monitor-events.jsonl`
Append-only log written by `claude-monitor-hook`. Each line is a JSON record with `ts`, `event`, `session_id`, `tmux_pane`, and `payload`. Events: `session-start`, `pre-tool-use`, `prompt-submit`, `notification`, `stop`.

### `~/.claude/monitor-registry.json`
Maintained by the TUI. Persists session metadata for 7 days after a session ends. Keyed by session UUID. Written only when the registry changes (dirty flag).

### `~/.claude/monitor-labels.json`
Maintained by the TUI. Stores custom names and colors per session UUID. Bidirectionally synced with tmux window names.

## Render loop

The main loop runs at ~20Hz (50ms sleep) for responsive key input, but all I/O is throttled to once per second:

```
while True:
    key = getch()           # non-blocking, always
    handle_keypress(key)    # uses data from last render

    if time_since_last_render < 1s:
        sleep(50ms)
        continue

    # --- 1Hz data refresh ---
    load_sessions()
    update_registry()       # dirty-flag save
    refresh_hook_panes()    # 30s TTL
    refresh_tmux_pane_map() # 5s TTL, two subprocesses in parallel
    fetch_new_session_data() # pane + model, parallel across new sessions
    sync_tmux_window_names() # 5s TTL per pane
    load_recent_events()    # dynamic window size
    render_frame()
```

## tmux integration

Pane detection uses a three-layer priority chain (see [ADR 003](decisions/003-pane-detection-strategy.md)):

1. `SessionStart` hook captures `$TMUX_PANE` — permanent, no subprocess needed
2. `ps eww -p <pid>` reads it from the live process env — cached for session lifetime
3. BFS from tmux shell PIDs — fallback for ended sessions

The PANE column displays `#{window_index}` (status-bar number), not the internal `%N` pane ID.

Name sync is bidirectional: renaming the tmux window updates the NAME column within 5s; pressing `n` in the TUI calls `tmux rename-window` immediately.

## Parallelism

Two places use `ThreadPoolExecutor`:

1. **`tmux_pane_map()`** — runs `tmux list-panes` and `ps -eo pid=,ppid=` concurrently (2 threads, every 5s)
2. **Per-session first-time fetch** — when new sessions appear, `pane_from_proc_env` and `session_model` are dispatched in parallel (up to 6 threads)

Both are I/O-bound. The GIL is not a concern here.
