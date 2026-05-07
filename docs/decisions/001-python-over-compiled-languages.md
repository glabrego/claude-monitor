# ADR 001 — Python over Go/Rust

## Status
Accepted

## Context

The monitor needs to display a live TUI, read files, spawn subprocesses, and handle concurrent I/O. Go (with bubbletea) and Rust (with ratatui) were evaluated as alternatives to Python curses.

## Decision

Use Python with the stdlib `curses` module. No external dependencies.

## Rationale

The bottlenecks are entirely I/O-bound:
- Subprocess latency (`ps eww`, `tmux display-message`, `tmux list-panes`)
- File tail reads (JSONL logs, session JSON files)

Neither Go nor Rust improves I/O-bound latency — the OS is the bottleneck, not the language runtime. The GIL is also irrelevant here because threads block on I/O, not CPU.

The only genuine benefit of Go would be the **bubbletea** TUI framework, which offers mouse support and a cleaner reactive component model compared to curses. This is a developer-experience improvement, not a correctness or performance one.

Python wins on:
- Zero install friction (ships with macOS, no `go install` or `cargo build`)
- Single-file scripts, symlink-friendly
- `concurrent.futures.ThreadPoolExecutor` is sufficient for the parallelism needed
- Fast iteration without a compile step

## Consequences

- Stuck with `curses` limitations (no mouse support, limited styling)
- If the TUI ever needs richer interactivity (clickable rows, scrollable panels), migrating to Go + bubbletea is the natural next step
