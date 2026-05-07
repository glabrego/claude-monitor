#!/usr/bin/env bash
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"

mkdir -p "$BIN"

for script in claude-monitor claude-monitor-hook claude-monitor-setup; do
    ln -sf "$REPO/$script" "$BIN/$script"
    chmod +x "$REPO/$script"
    echo "  linked $BIN/$script"
done

echo ""
echo "Installing Claude Code hooks..."
"$BIN/claude-monitor-setup"

echo ""
echo "Done. Run: claude-monitor"
