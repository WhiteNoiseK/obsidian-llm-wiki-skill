# obsidian-llm-wiki-skill

> Your project docs are scattered. Your knowledge dies with the repo. LLM Wiki fixes that — auto-classify, sync, and refactor docs into a permanent Obsidian vault as you build.

## What it does

- **classify** — scans project docs and creates permanent knowledge entries in your Obsidian vault (Concepts / Entities / Domains)
- **refactor** — converts source docs from full-content to reference style, replacing generic explanations with vault links
- **full** — both at once, idempotent on repeat runs
- **status** — preview what would change, no writes

On first run (`/vault-sync enable`), it guides you through Obsidian setup and scaffolds the entire vault structure automatically.

## Install

**Windows**
```powershell
irm https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main/install.ps1 | iex
```

**Mac / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/WhiteNoiseK/obsidian-llm-wiki-skill/main/install.sh | bash
```

**Manual**

Copy `vault-sync.md` → `~/.claude/commands/vault-sync.md`  
Copy `vault-sync-state.json` → `~/.claude/vault-sync-state.json` (skip if already exists)

## Usage

```
/vault-sync enable                        # first-time setup wizard
/vault-sync [project_path] status         # preview sync targets
/vault-sync [project_path] classify       # create vault entries
/vault-sync [project_path] refactor       # convert source docs
/vault-sync [project_path] full           # classify + refactor
/vault-sync disable                       # pause without deleting anything
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

## Requirements

- [Claude Code](https://claude.ai/code) (CLI or IDE extension)
- [Obsidian](https://obsidian.md) (free)

## Architecture principle

Wiki and project repos stay physically separate.  
The vault holds **permanent knowledge only** — links point to the source repo, never duplicate content.  
See `vault-sync.md` → `Architecture_Separation_Doctrine` for details.
