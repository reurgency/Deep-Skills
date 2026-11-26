<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# packaging

> **Load when:** changing install/marketplace manifests, plugin versions, host support, or the shared-file sweep · **~tokens:** ~1.4k est

## Purpose

Ships one skill set to Claude Code, Codex, Cursor and Copilot via thin per-host manifests; skill bodies are never forked per host. - `plugins/deep-skills/HOSTS.md:3 (# Hosts & distribution)`

## Entry points

- Catalog listing both plugins (`./plugins/deep-skills`, `./plugins/deep-goal`) - `.claude-plugin/marketplace.json:16 ("source": "./plugins/deep-skills",)`, `.claude-plugin/marketplace.json:24 ("source": "./plugins/deep-goal",)`
- Per-host manifests, each with `"skills": "./skills/"` - `plugins/deep-skills/.codex-plugin/plugin.json:11 ("skills")`, `plugins/deep-skills/.cursor-plugin/plugin.json:12 ("skills")`; Claude manifest has no `skills` key - `plugins/deep-skills/.claude-plugin/plugin.json:5 ("version")`
- Install: Claude `/plugin marketplace add reurgency/marketplace` then `/plugin install deep-skills@reurgency` - `plugins/deep-skills/HOSTS.md:48 (/plugin marketplace add)`
- Codex `codex plugin marketplace add ...` then `/plugins` (RE-VERIFY) - `plugins/deep-skills/HOSTS.md:56 (codex plugin marketplace add)`
- Cursor `/add-plugin deep-skills` (RE-VERIFY) - `plugins/deep-skills/HOSTS.md:69 (/add-plugin deep-skills)`
- Copilot CLI reuses the Claude marketplace - `plugins/deep-skills/HOSTS.md:76 (### GitHub Copilot - CLI (reuses the Claude marketplace))`; VS Code is file-based via `chat.agentSkillsLocations`, no marketplace - `plugins/deep-skills/HOSTS.md:86 (### GitHub Copilot - VS Code editor)`
- Update: `/plugin update deep-skills@reurgency`, update deep-skills before deep-goal; Copilot needs manual `copilot plugin update` - `plugins/deep-skills/HOSTS.md:92 (## Updating)`, `plugins/deep-skills/HOSTS.md:102 (### GitHub Copilot - CLI)`
- Maintainer sweep `scripts/check-shared.sh [--shared|--sync|--stale|--all]` - `scripts/check-shared.sh:9 (# Usage)`

## Key types

- Version 0.3.0 appears in 9 places (marketplace metadata + 2 plugin entries, and 3 manifests per plugin) - `.claude-plugin/marketplace.json:7 ("version")`, `.claude-plugin/marketplace.json:17 ("version")`, `plugins/deep-goal/.codex-plugin/plugin.json:3 ("version")`, `plugins/deep-goal/.cursor-plugin/plugin.json:4 ("version")`
- Capability matrix (skills, fan-out, per-agent model, effort, invocation, questions) - `plugins/deep-skills/HOSTS.md:29 (## Capability matrix)`; Copilot/VS Code fan-out is sequential only, fleets fall back to single agent - `plugins/deep-skills/HOSTS.md:34 (Parallel subagent fan-out)`
- deep-goal matrix: stage dispatch is inline sequential on Codex/Cursor/Copilot; Claude Code is the verified floor - `plugins/deep-goal/HOSTS.md:16 (Per-stage fresh-subagent dispatch)`
- Installed-plugin discovery for the version handshake - `plugins/deep-goal/HOSTS.md:20 (deep-skills discovery for the version handshake)`

## Invariants

- deep-goal requires deep-skills >= 0.3.0; coupling is one-directional - `.claude-plugin/marketplace.json:26 ("description")`, `plugins/deep-goal/README.md:5 (Requires)`
- `skills/` and `directives/` stay siblings under the plugin root so the self-locating loader resolves - `plugins/deep-skills/HOSTS.md:11 (## The vendoring invariant)`
- Five shared files, each byte-identical in 7 copies (6 skills + deep-goal), edited in the deep-code-review canonical - `plugins/deep-skills/HOSTS.md:117 (## Maintainer rules (the standalone / single-source contract))`, `scripts/check-shared.sh:25 (SKILL_DIRS)`, `scripts/check-shared.sh:34 (SHARED_FILES)`
- Never fork skill bodies per host; no Claude-only affordance at a call site; do not touch frontmatter casually - `plugins/deep-skills/HOSTS.md:117 (## Maintainer rules (the standalone / single-source contract))`, `plugins/deep-skills/HOSTS.md:117 (## Maintainer rules (the standalone / single-source contract))`
- A new host is not committed until the M3 gate (install, real cycle, fan-out, model binding) passes - `plugins/deep-skills/HOSTS.md:117 (## Maintainer rules (the standalone / single-source contract))`
- check-shared.sh is maintainers only and unshipped - `scripts/check-shared.sh:2 (# check-shared.sh)`

## Data-flow summary

- Sync flow: edit canonical copy, `--sync` copies to all 7, `--shared` verifies and validates model-map.json, `--stale` greps old tier words - `scripts/check-shared.sh:228 (do_sync)` → `scripts/check-shared.sh:48 (check_shared)` → `scripts/check-shared.sh:75 (validate_model_map)` → `scripts/check-shared.sh:271 (check_stale)`
- Install flow: marketplace.json source path → plugin dir → host manifest `skills` → `skills/` plus sibling `directives/` - `.claude-plugin/marketplace.json:16 ("source": "./plugins/deep-skills",)` → `plugins/deep-skills/.cursor-plugin/plugin.json:12 ("skills")`
- Gotcha: marketplace `"name"` is `deep-skills` while install strings use `reurgency` - `.claude-plugin/marketplace.json:3 ("name")`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| All anchors | inline above; none omitted |
