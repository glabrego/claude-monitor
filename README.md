# claude-monitor

A terminal dashboard for monitoring all running Claude Code sessions at a glance.

Built on top of Claude Code's native session files and hook system — no external dependencies beyond Python stdlib.

## What it shows

| Column | Source |
|--------|--------|
| PID | Process ID of the Claude process |
| STATUS | `busy` (green) · `waiting` (blue) · `idle` (yellow) · `ended` (dim) |
| SESSION | First 8 chars of the session UUID |
| PANE | tmux window index (status-bar number) |
| NAME | Custom label (synced bidirectionally with the tmux window name) |
| PROJECT | Last segment of the working directory |
| UPTIME | Time since session started |
| TOOL | Last tool called |
| MODEL | Model in use (e.g. `sonnet 4.6`) |
| DETAIL | Last tool summary or notification message |

Sessions persist in a 7-day registry so you can still copy their IDs after they end.

## Requirements

- macOS
- Python 3.9+
- tmux (optional — PANE column and resume-to-pane require it)
- Claude Code CLI

## Installation

```bash
git clone https://github.com/guilherme-labrego/claude-monitor ~/workspace/claude-monitor
cd ~/workspace/claude-monitor
./install.sh
```

`install.sh` symlinks the scripts to `~/.local/bin/` and installs Claude Code hooks into `~/.claude/settings.json`.

## Usage

```bash
claude-monitor
```

### Keyboard controls

| Key | Action |
|-----|--------|
| `↑` / `k` | Move selection up |
| `↓` / `j` | Move selection down |
| `Enter` / `r` | Resume session — switches to its tmux pane, or opens a new window with `claude --resume` |
| `n` | Name the selected session (also renames the tmux window) |
| `c` | Cycle session color: auto → red → green → cyan → magenta → blue → yellow |
| `x` | Clear name and color |
| `y` | Copy full session UUID to clipboard (`pbcopy`) |
| `dd` | Delete session from registry |
| `:q` + Enter | Quit |

### Status states

- **busy** (green) — Claude is actively processing
- **waiting** (blue) — Claude finished and sent a notification
- **idle** (yellow) — Claude is waiting for input, no notification fired
- **ended** (dim) — session has ended, kept for 7 days

## How it works

### Data sources

**`~/.claude/sessions/<pid>.json`** — Written by Claude Code for every running session. Contains `pid`, `sessionId`, `cwd`, `status` (`busy`/`idle`), `startedAt`. This is the primary live source.

**`~/.claude/monitor-events.jsonl`** — Written by `claude-monitor-hook`. Captures tool calls, prompts, notifications, and session-start events (including `$TMUX_PANE`).

**`~/.claude/monitor-registry.json`** — Maintained by the TUI. Persists session metadata for 7 days after a session ends so ended sessions remain copyable.

**`~/.claude/monitor-labels.json`** — Persists custom names and colors per session UUID.

### Hooks

`claude-monitor-setup` installs five async hooks into `~/.claude/settings.json`:

| Hook | Purpose |
|------|---------|
| `SessionStart` | Captures `$TMUX_PANE` for accurate pane detection |
| `PreToolUse` | Records last tool name and description |
| `UserPromptSubmit` | Records last user message |
| `Notification` | Updates status to `waiting` + fires a native macOS notification |
| `Stop` | Records session stop events |

### tmux integration

- **PANE column**: shows the tmux window index (the number in the status bar), not the internal `%N` pane ID
- **Pane detection priority**: hook event (`$TMUX_PANE`) → live process env (`ps eww`) → BFS from shell PIDs
- **Name sync**: renaming the tmux window updates the NAME column; pressing `n` renames the tmux window
- **Resume** (`Enter`/`r`): switches to the session's pane if assigned, otherwise opens a new window

### macOS notifications

When Claude finishes a task and fires a `Notification` hook event, a native macOS notification appears with the session label as the title and the notification message as the body.

## Files

```
~/.local/bin/claude-monitor        # TUI (symlink → repo)
~/.local/bin/claude-monitor-hook   # hook receiver (symlink → repo)
~/.local/bin/claude-monitor-setup  # hook installer (symlink → repo)

~/.claude/settings.json            # Claude Code settings (hooks installed here)
~/.claude/monitor-events.jsonl     # hook event log
~/.claude/monitor-registry.json    # 7-day session history
~/.claude/monitor-labels.json      # session names + colors
```
