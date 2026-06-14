#!/bin/bash
# vault-sync skill installer (Mac/Linux)
# Supports: Claude Code, Gemini CLI, Codex

TOOLS="${1:-claude gemini codex}"
BASE="https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main"

CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

# Config is project-local: `vault-sync enable` generates a .vault-sync.toml in each
# project root (the single source of truth for vault_path, enabled, and mappings).
# No global state file is installed.

for tool in $TOOLS; do
    case "$tool" in
        claude)
            mkdir -p "$CLAUDE_DIR/commands"
            curl -fsSL "$BASE/claude/vault-sync.md" -o "$CLAUDE_DIR/commands/vault-sync.md"
            echo "  [claude] vault-sync.md -> $CLAUDE_DIR/commands/vault-sync.md"
            echo "  Usage: /vault-sync enable"
            ;;

        gemini)
            GEMINI_DIR="$HOME/.gemini"
            mkdir -p "$GEMINI_DIR"
            GEMINI_MD="$GEMINI_DIR/GEMINI.md"
            SECTION=$(curl -fsSL "$BASE/gemini/vault-sync.md")
            if [ -f "$GEMINI_MD" ]; then
                if ! grep -q "vault-sync" "$GEMINI_MD"; then
                    printf "\n\n%s" "$SECTION" >> "$GEMINI_MD"
                    echo "  [gemini] vault-sync section appended -> $GEMINI_MD"
                else
                    echo "  [gemini] already installed, skipped"
                fi
            else
                echo "$SECTION" > "$GEMINI_MD"
                echo "  [gemini] GEMINI.md created -> $GEMINI_MD"
            fi
            echo "  Usage: vault-sync enable"
            ;;

        codex)
            CODEX_DIR="$HOME/.codex"
            mkdir -p "$CODEX_DIR"
            AGENTS_MD="$CODEX_DIR/instructions.md"
            SECTION=$(curl -fsSL "$BASE/codex/vault-sync.md")
            if [ -f "$AGENTS_MD" ]; then
                if ! grep -q "vault-sync" "$AGENTS_MD"; then
                    printf "\n\n%s" "$SECTION" >> "$AGENTS_MD"
                    echo "  [codex] vault-sync section appended -> $AGENTS_MD"
                else
                    echo "  [codex] already installed, skipped"
                fi
            else
                echo "$SECTION" > "$AGENTS_MD"
                echo "  [codex] instructions.md created -> $AGENTS_MD"
            fi
            echo "  Usage: vault-sync enable"
            ;;
    esac
done

echo ""
echo "Done! Run 'vault-sync enable' to set up your Obsidian vault."
