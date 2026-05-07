# ADR 004 — Session registry as flat JSON file

## Status
Accepted

## Context

Claude Code deletes `~/.claude/sessions/<pid>.json` when a session ends. To keep ended sessions visible (so their IDs remain copyable for `claude --resume`), the monitor needs its own persistence layer.

Options considered:
1. Flat JSON file (`~/.claude/monitor-registry.json`)
2. SQLite database
3. Append-only JSONL (same format as event log)

## Decision

Flat JSON file. The registry is a single dict keyed by session UUID, loaded in full on startup and written atomically on change.

## Rationale

**SQLite** is the natural choice for queryable persistent state, but the access patterns here are trivial: full scan on every render, upsert on session change, delete on expiry or user action. There are never more than ~50 sessions in the registry (7-day window). SQLite's overhead — schema, connection management, WAL files — is pure cost with no benefit at this scale.

**Append-only JSONL** would avoid full rewrites but complicates reads (need to replay to get current state) and makes deletion (user presses `dd`) awkward.

**Flat JSON** is the simplest structure that works. The file is small (<50KB in practice), reads and writes are instant, and the whole thing is human-readable and trivially inspectable.

Writes are guarded by a dirty flag — the file is only written when the registry actually changes (session status update, new session, expiry, or user deletion). In steady state this is at most once per second.

## Consequences

- Not safe for concurrent writes from multiple TUI instances (last-write-wins). Acceptable because running two instances of `claude-monitor` simultaneously is not a supported use case
- 7-day retention is hardcoded. Changing it requires editing `REGISTRY_MAX_DAYS` in the source
