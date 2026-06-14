---
description: "Manage LLM Wiki synchronization. Options: plan, init, update, eval, disable"
globs: "docs/**/*.md, *.md"
---
# Vault-Sync Command (Authority Framework)

You are invoked to execute the `vault-sync` command.
The user will trigger this command using the following format:
`/vault-sync [source_path] [mode] [options...]`

## Options
- `--type=<domain|system>` **(Required)**: The type of knowledge to synchronize.
- `--auth=<level>` **(Optional)**: Force injection of one of the 8-level authority tags.
- `--engine=<name>` **(Optional)**: The synchronization engine (e.g. claude, codex, gemini).

## 8-Level Authority Tags (Strictly Enforced)
Every synchronized document MUST contain one of the following tags at the very top:
- **Domain:** `#authority/domain/supreme`, `#authority/domain/single`, `#authority/domain/derived`, `#authority/domain/deprecated`
- **System:** `#authority/system/absolute`, `#authority/system/active`, `#authority/system/inactive`, `#authority/system/deprecated`

---

## Execution Sequence

### Step 0: Activation & Validation
1. Read `~/.claude/vault-sync-state.json` to check `enabled` and `vault_path`.
2. If `enabled == false` AND `mode != "disable"`: Output a warning notification `"LLM Wiki가 비활성화 상태입니다. vault-sync enable 로 활성화하세요."` and HALT execution immediately.
3. If `mode == "disable"`: Update state file setting `enabled: false` and exit.
4. Validate that `--type` is provided (except for `disable` or `plan` modes without options).

### Step 1: Authority Evaluation & Classification (Mode: `eval`)
If `mode == "eval"` OR the `--auth` option is NOT provided:
- Scan the source document body and its Git original to infer its authority level.
- **CRITICAL**: If the document does not have explicit Single Source of Truth (SSOT) markers or a status table, you must **NEVER** add an arbitrary tag. You must **HALT** the synchronization and notify the user that authority cannot be safely determined.

### Step 2: Synchronization Logic (Modes: `init` / `update` / `plan`)

#### Deterministic Path Mapping Rules
Always place the file in the exact Vault destination based on the source path:
- `docs/engineering/` -> `10_Wiki_Knowledge/Domains/`
- `docs/learning/` -> `10_Wiki_Knowledge/Concepts/`
- `docs/information/` -> `30_Sources/`
- `docs/deploy/` -> `20_Projects/[Project_Name]/Deploy/`
- `docs/experiments/` -> `20_Projects/[Project_Name]/Experiments/`
- `docs/retrospective/` -> `20_Projects/[Project_Name]/Retrospective/`
- `docs/pm-guide/` -> `20_Projects/[Project_Name]/PM_Guide/`
- `docs/` (root) -> `20_Projects/[Project_Name]/`
- `node_modules/`, `assets/`, `api/`, `frontend/import/` -> **SKIP (Do not sync)**

#### Mode: `plan`
- Evaluate the document authority and output a dry-run plan of how it will be synchronized without modifying any files.

#### Mode: `init` (Initial Sync)
- Copy the contents from `[source_path]` into the deterministic Vault location defined above.
- Add the following Non-Authoritative Snapshot warning at the very top:
  `> ⚠️ 비권위 스냅샷 경고문`
- Inject the `#authority/.../...` tag directly below the warning.
- **Project Anchor Link**: Inject `Project: [[Project_Name]]` directly below the authority tag to ensure Graph View clustering.
- **Refactoring Rule**: Replace general conceptual explanations in the original source document with Obsidian internal WikiLinks (`[[...]]`). Do NOT use `obsidian://` links as they break Foam/portal pipelines and AI sight.

#### Mode: `update` (Incremental Sync)
- If the document already exists in the Vault, merge and update the body text with the Git original safely.
- **CRITICAL**: Do NOT overwrite or destroy the authority tag, the Project Anchor Link, or the existing Obsidian internal link structures at the top.
- If `--engine` is provided, append `Synced by [engine]` at the top or in the changelog.

#### Mode: `relocate` (SSOT Link Healing on Project Move)
- Use this mode when the project folder has been moved and the `file:///` SSOT links in the Vault are broken.
- The AI MUST NOT auto-detect or guess the new absolute path.
- The AI MUST explicitly prompt the user to input the "Old Project Path" and the "New Project Path".
- Once the user provides both paths, scan the Vault and perform a batch replace of the `file:///[Old_Path]` strings with `file:///[New_Path]` in the snapshot headers.
