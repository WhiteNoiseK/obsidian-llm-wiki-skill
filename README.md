# obsidian-llm-wiki-skill

> Your project docs are scattered. Your knowledge dies with the repo. LLM Wiki fixes that — auto-classify, sync, and refactor docs into a permanent Obsidian vault as you build.

Works with **Claude Code**, **Gemini CLI**, and **Codex** — one install, all three.

## What it does (V2 Authority Framework)

- **enable** — generates the project's `.vault-sync.toml` (the single config source: `vault_path`, `enabled`, and folder mappings) and prepares the vault structure
- **eval** — scans documents for Authority/SSOT tags, halts if missing
- **init** — first-time sync. Copies source to vault with explicit SSOT warning headers and 8-level Authority tags
- **update** — incremental sync. Safely merges text changes while preserving vault link structures
- **plan** — preview what would change, no writes (dry-run)
- **relocate** — explicitly asks for old/new paths to batch-heal broken links after project folder moves
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

> Config is per-project: `vault-sync enable` writes a `.vault-sync.toml` to the project root
> (the single source of truth for `vault_path`, `enabled`, and mappings). No global state file.

## Usage

| Tool | Command |
|------|---------|
| Claude Code | `/vault-sync enable` |
| Gemini CLI | `vault-sync enable` |
| Codex | `vault-sync enable` |

```
vault-sync enable                   # activate sync tracking
vault-sync [project_path] plan      # preview sync targets
vault-sync [project_path] eval      # verify SSOT authority tags
vault-sync [project_path] init      # create vault entries with anchors
vault-sync [project_path] update    # update body text only
vault-sync [project_path] relocate  # heal broken links
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

**Local Project Mapping (TOML)**: To prevent Vault contamination, mapping from legacy/local project paths to Vault standard paths is purely managed by a `.vault-sync.toml` file generated in the root of the active project during `enable`.

## Requirements

- [Obsidian](https://obsidian.md) (free)
- At least one of: Claude Code · Gemini CLI · Codex
