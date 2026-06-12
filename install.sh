#!/bin/bash
# vault-sync skill installer (Mac/Linux)

CLAUDE_DIR="$HOME/.claude"
COMMANDS_DIR="$CLAUDE_DIR/commands"
BASE="https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main"

mkdir -p "$COMMANDS_DIR"

echo "Installing vault-sync skill..."

curl -fsSL "$BASE/vault-sync.md" -o "$COMMANDS_DIR/vault-sync.md"

STATE_FILE="$CLAUDE_DIR/vault-sync-state.json"
if [ ! -f "$STATE_FILE" ]; then
    curl -fsSL "$BASE/vault-sync-state.json" -o "$STATE_FILE"
fi

echo ""
echo "Done! Run /vault-sync enable inside Claude Code to get started."
