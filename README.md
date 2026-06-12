# obsidian-llm-wiki-skill

> Your project docs are scattered. Your knowledge dies with the repo. LLM Wiki fixes that — auto-classify, sync, and refactor docs into a permanent Obsidian vault as you build.

Works with **Claude Code**, **Gemini CLI**, and **Codex** — one install, all three.

## What it does

- **enable** — guided Obsidian setup + auto-scaffolds the entire vault structure
- **classify** — scans project docs and creates permanent knowledge entries (Concepts / Entities / Domains)
- **refactor** — converts source docs to reference style, replacing generic explanations with vault links
- **full** — classify + refactor at once, idempotent on repeat runs
- **status** — preview what would change, no writes (always available)
- **disable** — pause without deleting anything

## Install

### All tools (Claude + Gemini + Codex)

**Windows**
```powershell
irm https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main/install.ps1 | iex
```

**Mac / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main/install.sh | bash
```

### Specific tools only

**Windows**
```powershell
# Claude only
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main/install.ps1))) -Tools claude

# Gemini only
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main/install.ps1))) -Tools gemini

# Codex only
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main/install.ps1))) -Tools codex
```

**Mac / Linux**
```bash
curl -fsSL .../install.sh | bash -s claude
curl -fsSL .../install.sh | bash -s gemini
curl -fsSL .../install.sh | bash -s codex
```

### Manual

| Tool | File to copy | Destination |
|------|-------------|-------------|
| Claude Code | `claude/vault-sync.md` | `~/.claude/commands/vault-sync.md` |
| Gemini CLI | `gemini/vault-sync.md` | append to `~/.gemini/GEMINI.md` |
| Codex | `codex/vault-sync.md` | append to `~/.codex/instructions.md` |
| All tools | `vault-sync-state.json` | `~/.claude/vault-sync-state.json` |

## Usage

| Tool | Command |
|------|---------|
| Claude Code | `/vault-sync enable` |
| Gemini CLI | `vault-sync enable` |
| Codex | `vault-sync enable` |

```
vault-sync enable                   # first-time setup wizard
vault-sync [project_path] status    # preview sync targets
vault-sync [project_path] classify  # create vault entries
vault-sync [project_path] refactor  # convert source docs
vault-sync [project_path] full      # classify + refactor
vault-sync disable                  # pause
```

## Vault structure created on first enable

```
{vault}/
├── .clauderules
├── 000_Index.md
├── 00_Wiki_Standard_Architecture.md
├── 00_Inbox/
├── 10_Wiki_Knowledge/
│   ├── Concepts/
│   ├── Entities/
│   └── Domains/
├── 20_Projects/
├── 30_Sources/
├── 40_Templates/  (Tpl_Concept, Tpl_Meeting)
└── 99_System_Agent/
```

## Architecture principle

Wiki and project repos stay physically separate.
The vault holds **permanent knowledge only** — links point to source repos, never duplicate content.

## Requirements

- [Obsidian](https://obsidian.md) (free)
- At least one of: Claude Code · Gemini CLI · Codex
