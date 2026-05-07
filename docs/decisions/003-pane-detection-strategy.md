# ADR 003 — tmux pane detection strategy

## Status
Accepted

## Context

The PANE column needs to show which tmux window a Claude session is running in. Several approaches were tried before arriving at the current solution.

**What we want to display**: the tmux **window index** (the number shown in the status bar, e.g. `5`), not the internal global pane ID (e.g. `%8`). These are different — a session started as the 6th window ever created has pane ID `%8` but window index `5`.

## Decision

Three-layer priority chain, first match wins:

1. **Hook event** (`$TMUX_PANE` from `SessionStart`) — captured when the session starts, 100% accurate, stored in `monitor-events.jsonl`
2. **Live proc env** (`ps eww -p <pid>`) — reads `TMUX_PANE=...` from the running process's environment, accurate for sessions started before hook installation
3. **BFS from tmux shell PIDs** — fallback for ended sessions or when neither of the above is available

For display, the raw pane ID (`%8`) is converted to window index via `tmux display-message -t %8 -p "#{window_index}"`.

## Rationale

**Why not BFS alone?** Process tree ancestry does not reliably map to tmux pane ownership. A process can be a descendant of a shell in a different pane than where it's visually running (e.g. when panes are opened via scripts, or with nested shells). BFS was the initial approach and consistently produced wrong values.

**Why proc env before BFS?** `$TMUX_PANE` is set by tmux in the shell's environment and inherited by all child processes. It is authoritative. `ps eww` reads it directly from the live process — no inference needed.

**Why hook events first?** Once a session-start event is recorded, the pane is known permanently without any subprocess call. This is the most efficient path and eliminates the `ps eww` call entirely for new sessions.

**Why window index instead of pane ID?** Users refer to windows by the number in the tmux status bar. The internal `%N` global pane ID is an implementation detail that increases monotonically and bears no relation to the user-visible number.

## Consequences

- Pane data for sessions started before hook installation requires `ps eww` — one subprocess call per session, cached permanently for the session's lifetime
- Ended sessions only have pane data if a `SessionStart` hook event was recorded for them
- The BFS `tmux_pane_map()` refresh (every 5s) runs two subprocesses in parallel (`tmux list-panes` + `ps -eo pid=,ppid=`) — negligible cost but worth knowing
