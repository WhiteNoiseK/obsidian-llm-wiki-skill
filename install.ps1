# vault-sync skill installer (Windows)

$claudeDir = "$env:USERPROFILE\.claude"
$commandsDir = "$claudeDir\commands"

if (-not (Test-Path $commandsDir)) {
    New-Item -ItemType Directory -Force $commandsDir | Out-Null
}

$base = "https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main"

Write-Host "Installing vault-sync skill..."

Invoke-WebRequest "$base/vault-sync.md" -OutFile "$commandsDir\vault-sync.md"

$stateFile = "$claudeDir\vault-sync-state.json"
if (-not (Test-Path $stateFile)) {
    Invoke-WebRequest "$base/vault-sync-state.json" -OutFile $stateFile
}

Write-Host ""
Write-Host "Done! Run /vault-sync enable inside Claude Code to get started."
