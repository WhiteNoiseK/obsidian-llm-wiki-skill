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

> **These 8 tags are FILE-level labels only.** A binding quantitative item *inside* a document (a performance/function target) is **"priority authority"**, NOT a file label — it must be complied with but receives **no `#authority/...` tag of its own** (the host file keeps its own file-level tag, usually `#authority/domain/derived`). **Never tag an in-document item.** The priority-authority concept is owned by the project's `docs/_knowledge-architecture.md §2`; this skill only references it.

## Source Immutability Invariant (Strictly Enforced)
Source repository files are strictly read-only inputs for vault-sync.
vault-sync must NEVER modify, delete, shrink, replace, link-rewrite, normalize, or reformat any
source document in the repository. Only the external Vault snapshot may be created or updated.

## Multi-Engine Scopes
- **Claude**: Orchestrator. Full rights to external Vault writes (`init`, `update`) and `plan` / `eval`.
- **Gemini**: Documentation Writer / Independent Scorer. Restricted to `plan` and `eval`. External Vault writes are FORBIDDEN.
- **Codex**: Read-only reviewer. Restricted to `plan` and `eval`. External Vault writes are FORBIDDEN unless explicitly delegated via a path allowlist.

## Configuration Authority (single source of truth)
The `.vault-sync.toml` in the **project root** is the SINGLE authority for this project's sync
configuration: `vault_path`, `enabled`, and the `[mappings]` table. Because it lives inside the
project workspace, every engine (Claude, Codex, Gemini) can read it under default sandboxing.

**Do NOT read `~/.claude/vault-sync-state.json`** — it is legacy and non-authoritative. Never source
`vault_path` or `enabled` from outside the workspace.

---

## Execution Sequence

### Step 0: Activation & Validation
1. If `mode == "enable"`:
   - If `.vault-sync.toml` does NOT exist in the project root: analyze the project's documentation
     folder structure and generate it, containing `vault_path` (the absolute Obsidian vault path — if
     it cannot be determined, prompt the user; never guess), `enabled = true`, and a `[mappings]`
     table mapping local folders to the Obsidian standard folders (e.g.
     `20_Projects/[Project_Name]/AI_Workflow`, `10_Wiki_Knowledge/Domains`). Set transient or
     operational folders (scores, handoffs, reviews, tasks, harness internals, code) to `IGNORE`.
   - **CRITICAL**: You MUST also inject a document creation rule into the project's governance files (e.g. `.clauderules`, `AGENTS.md`, or `docs/_knowledge-architecture.md`). The rule must explicitly enforce that: "ALL newly created markdown documents within the project MUST include an appropriate 8-level Authority tag (e.g., `#authority/domain/...`) at the very top of the file."
   - If it already exists: set `enabled = true` and exit WITHOUT overwriting existing mappings.
2. Read `.vault-sync.toml`. If it is missing, or `vault_path` / `enabled` is absent or malformed:
   **HALT (fail closed)** and tell the user to run `vault-sync enable` first.
3. If `enabled == false` AND `mode != "disable"`: output the warning
   `"LLM Wiki가 비활성화 상태입니다. vault-sync enable 로 활성화하세요."` and HALT immediately.
4. If `mode == "disable"`: set `enabled = false` in `.vault-sync.toml` and exit.
5. Validate that `--type` is provided (except for `disable` or `plan` modes without options).

### Step 1: Authority Evaluation & Classification (Mode: `eval`)
If `mode == "eval"` OR the `--auth` option is NOT provided:
- **Primary signal — read the source's explicit `#authority/[type]/[level]` tag** (at the top of the source file) and use that level verbatim.
- Fallback only if no tag is present: infer from explicit Single Source of Truth (SSOT) markers / a status table (a fallback only — per `_knowledge-architecture.md §2`, a bare `status:` is no longer a standalone classifier).
- **CRITICAL**: If neither an `#authority/...` tag nor an explicit SSOT marker/status table is present, you must **NEVER** add an arbitrary tag. You must **HALT** the synchronization and notify the user that authority cannot be safely determined.

### Step 2: Synchronization Logic (Modes: `init` / `update` / `plan`)

#### Deterministic Path Mapping Rules
Determine the Vault destination by reading the `[mappings]` table in `.vault-sync.toml` (project root),
then prefixing the matched destination with `vault_path` from the same file.
- Mapping keys are workspace-relative folder paths **without trailing slashes** (e.g. `docs/pm-guide`).
- Use **longest-prefix match**; a more specific path mapped to `IGNORE` overrides a broader parent.
- Do NOT use hardcoded paths.
- If `.vault-sync.toml` is missing, HALT and prompt the user to run `vault-sync enable` first.
- If a folder is mapped to `IGNORE` or is not mapped, do not sync it.

#### Mode: `plan`
- Evaluate the document authority and output a dry-run plan of how it will be synchronized without modifying any files.

#### Mode: `init` (Initial Sync)
- Copy the contents from `[source_path]` into the deterministic Vault location defined above.
- Add the following explicit Non-Authoritative Snapshot warning at the very top:
  `> ⚠️ Non-authoritative snapshot.`
  `> Authority remains: <repo-relative-source-path>`
  `> Do not cite this Vault copy as SSOT. Use the repository source file.`
  `> Synced at: <timestamp>`
- Inject the `#authority/.../...` tag directly below the warning.
- **Project Anchor Link**: Inject `Project: [[Project_Name]]` directly below the authority tag to ensure Graph View clustering.
- **Refactoring Rule**: Replace general conceptual explanations in the **Vault snapshot document** (NOT the original source document) with Obsidian internal WikiLinks (`[[...]]`). Do NOT use `obsidian://` links as they break Foam/portal pipelines and AI sight.

#### Mode: `update` (Incremental Sync)
- If the document already exists in the Vault, merge and update the body text with the Git original safely.
- **CRITICAL**: Do NOT overwrite or destroy the authority tag, the Project Anchor Link, or the existing Obsidian internal link structures at the top.
- If `--engine` is provided, append `Synced by [engine]` at the top or in the changelog.

#### Mode: `relocate` (SSOT Link Healing on Project Move)
- Use this mode when the project folder has been moved and the `file:///` SSOT links in the Vault are broken.
- The AI MUST NOT auto-detect or guess the new absolute path.
- The AI MUST explicitly prompt the user to input the "Old Project Path" and the "New Project Path".
- Once the user provides both paths, scan the Vault and perform a batch replace of the `file:///[Old_Path]` strings with `file:///[New_Path]` in the snapshot headers.
