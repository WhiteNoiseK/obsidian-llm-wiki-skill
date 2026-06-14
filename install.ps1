# vault-sync skill installer (Windows)
# Supports: Claude Code, Gemini CLI, Codex

param(
    [string[]]$Tools = @("claude", "gemini", "codex")
)

$base = "https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main"

# Claude config dir (used for the command file below).
# Config is project-local: `vault-sync enable` generates a .vault-sync.toml in each
# project root (the single source of truth for vault_path, enabled, and mappings).
# No global state file is installed.
$claudeDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Force $claudeDir | Out-Null }

foreach ($tool in $Tools) {
    switch ($tool.ToLower()) {

        "claude" {
            $commandsDir = "$claudeDir\commands"
            if (-not (Test-Path $commandsDir)) { New-Item -ItemType Directory -Force $commandsDir | Out-Null }
            Invoke-WebRequest "$base/claude/vault-sync.md" -OutFile "$commandsDir\vault-sync.md"
            Write-Host "  [claude] vault-sync.md -> $commandsDir\vault-sync.md"
            Write-Host "  Usage: /vault-sync enable"
        }

        "gemini" {
            $geminiDir = "$env:USERPROFILE\.gemini"
            if (-not (Test-Path $geminiDir)) { New-Item -ItemType Directory -Force $geminiDir | Out-Null }
            $geminiMd = "$geminiDir\GEMINI.md"
            $section = (Invoke-WebRequest "$base/gemini/vault-sync.md").Content
            if (Test-Path $geminiMd) {
                if (-not (Select-String -Path $geminiMd -Pattern "vault-sync" -Quiet)) {
                    Add-Content $geminiMd "`n`n$section"
                    Write-Host "  [gemini] vault-sync section appended -> $geminiMd"
                } else {
                    Write-Host "  [gemini] already installed, skipped"
                }
            } else {
                Set-Content $geminiMd $section -Encoding utf8
                Write-Host "  [gemini] GEMINI.md created -> $geminiMd"
            }
            Write-Host "  Usage: vault-sync enable"
        }

        "codex" {
            $codexDir = "$env:USERPROFILE\.codex"
            if (-not (Test-Path $codexDir)) { New-Item -ItemType Directory -Force $codexDir | Out-Null }
            $agentsMd = "$codexDir\instructions.md"
            $section = (Invoke-WebRequest "$base/codex/vault-sync.md").Content
            if (Test-Path $agentsMd) {
                if (-not (Select-String -Path $agentsMd -Pattern "vault-sync" -Quiet)) {
                    Add-Content $agentsMd "`n`n$section"
                    Write-Host "  [codex] vault-sync section appended -> $agentsMd"
                } else {
                    Write-Host "  [codex] already installed, skipped"
                }
            } else {
                Set-Content $agentsMd $section -Encoding utf8
                Write-Host "  [codex] instructions.md created -> $agentsMd"
            }
            Write-Host "  Usage: vault-sync enable"
        }
    }
}

Write-Host ""
Write-Host "Done! Run 'vault-sync enable' to set up your Obsidian vault."
