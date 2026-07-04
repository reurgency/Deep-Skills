# Hosts & distribution — installing deep-skills across assistants

The deep-* skills are **one set of skills** (the `skills/<name>/SKILL.md` + `references/` + `scripts/` + `templates/` layout every modern agent host reads). This repo adds **thin per-host manifests** so each assistant installs the *same* skills natively. **Skill bodies are never forked per host** — the only per-host files are the manifest directories below.

> **Status — schema/capability gates are DEFERRED.** The manifests here were authored against each host's official marketplace docs (mid-2026) but the **empirical capability-verification gate (M3)** — install on the host, run a full `deep-plan → deep-code-review` cycle, and confirm (a) load + NL/slash invocation, (b) parallel fan-out actually runs, (c) per-agent model selection binds to `model-map.md` — has **not** been run. Run it per host before treating that host as committed. Items marked **RE-VERIFY** are schema/command details that move fast and must be re-checked against current docs at install time.

## The vendoring invariant (why directives live next to skills)

The Deep-Learn directive loader (`skills/<name>/scripts/load-active-cards.sh`) is **self-locating**: it resolves the shared registry **relative to its own file**, three levels up — `skills/<name>/scripts/ → ../../../directives/cards/active`. For that to resolve on any host, the installed unit must keep `skills/` and `directives/` as **siblings** under one plugin root.

That is exactly why every per-host manifest lives **inside `plugins/deep-skills/`** (alongside `.claude-plugin/`) and points `"skills": "./skills/"`: the vendored package is the plugin root, so `directives/` rides along as a sibling and the relative path keeps working **unchanged** on every host. This is the **primary** §C fix — no edit to the byte-identical `load-active-cards.sh`.

- **Non-shell hosts** (or installs where the sibling layout isn't preserved — e.g. copying only `skills/` into a VS Code editor folder): apply directive cards by hand instead — read `directives/cards/active/` and apply each card whose `owner_phases` lists the phase as an exact token. See any skill's `references/host-affordances.md` § *Directive-card loading without a reliable shell*.

## Model-tier routing is portable, and required

Every host below supports **per-agent model selection** in its subagent/agent definition. The fleets (`deep-code-review`, `deep-plan-review`, `deep-bugfix`) **must** bind each agent's model from that skill's `references/model-map.md` before fan-out — a correctness guarantee, not an affordance (see `references/host-affordances.md`). The map is **host-agnostic**: one `model-map.md` per fleet, keyed by the **orchestrator's own model** (which determines both the family — Anthropic / OpenAI / … — and the ceiling), so the same file resolves on every host; no per-host copies. All three tiers (main/mid/cheap) are **reasoning** tiers — `cheap` is the cheapest *reasoning* model, never a small/utility one (Haiku, GPT-mini/nano), which are never required in this series. The ceiling is the user's selected model, so a restricted shop whose best model is normally a mid grade (Sonnet 4.6, GPT-5.4) runs `main` = `mid` = `cheap` at that ceiling. **A host that cannot bind per-agent models routes its fleets to a single-agent fallback for that host only** (see the matrix).

## Capability matrix (from official docs; ✓ = documented, ⚠ = degrade, gate = verify empirically)

| Capability | Claude Code | Codex | Cursor | Copilot / VS Code |
|---|---|---|---|---|
| `SKILL.md` skills | ✓ | ✓ GA | ✓ GA | ✓ GA (VS Code 1.108+, stable Jan 2026) |
| Parallel subagent fan-out | ✓ | ✓ (`[features] multi_agent=true`) | ✓ (`/multitask`, Task fan-out) | ⚠ **sequential `handoffs` only — no documented parallel fan-out** |
| Per-agent model selection | ✓ | ✓ (`.codex/agents/*.toml` `model`) | ✓ (`.cursor/agents/*.md` `model:`) | ✓ (`*.agent.md` `model:`) |
| Per-agent reasoning effort | ✓ | ✓ (`model_reasoning_effort`) | ✗ | ✗ (not documented) |
| NL + slash/selector invocation | ✓ `/x` | ✓ `/skills` + NL | ✓ `/x`, `@`, NL | ✓ `/x` + NL |
| Structured-question UI | ✓ `AskUserQuestion` | chat fallback | chat fallback | chat fallback |
| Artifact writes (`.deep-skills/**`) | ✓ | ✓ | ✓ | ✓ |

**Copilot/VS Code degradation (gate-b risk).** VS Code Copilot's custom-agents docs describe **sequential** handoffs, not concurrent fan-out. If the M3 gate confirms no parallel fan-out: the **single-agent** skills (`deep-plan`, `deep-implement`, `deep-docs`) run fully; the **fleet** skills (`deep-code-review`, `deep-plan-review`, and `deep-bugfix` — per-cluster diagnose+fix fan-out plus fresh proof agents) route to their sequential single-agent fallback on this host only. Re-verify against current docs — VS Code agent features move fast.

## Per-host install

### Claude Code (reference host — shipped)
Add the marketplace, install the plugin:
```
/plugin marketplace add <owner>/<repo>
/plugin install deep-skills@deep-skills-by-reu
```
Manifests: `.claude-plugin/marketplace.json` (repo root) + `plugins/deep-skills/.claude-plugin/plugin.json`.

### Codex (manifest authored — gate pending)
Codex reads `SKILL.md` natively and has a plugin marketplace.
```
codex plugin marketplace add <owner>/<repo>     # RE-VERIFY exact subcommand/flags
# then in Codex: /plugins → search "deep-skills" → Install
```
Manifest: `plugins/deep-skills/.codex-plugin/plugin.json` (`"skills": "./skills/"`). Codex also accepts `.claude-plugin/marketplace.json` as a legacy/compat marketplace source. For the fleets, enable fan-out (`[features] multi_agent = true` in `~/.codex/config.toml`) and ship `.codex/agents/*.toml` with per-agent `model` resolved from `model-map.md`.
**RE-VERIFY:** the official Codex marketplace path is `.agents/plugins/marketplace.json` (add one if the legacy `.claude-plugin` source isn't honored on the target version); exact `codex plugin marketplace add` flags; per-skill `agents/openai.yaml` metadata.

### Cursor (manifest authored — gate pending)
Cursor reads `SKILL.md` natively and has a plugin marketplace.
```
# In Cursor Agent chat:
/add-plugin deep-skills          # RE-VERIFY — used in the wild, not on an official docs page
# or: Customize panel → Marketplace → install
# Local dev/test: copy plugins/deep-skills/ into ~/.cursor/plugins/local/deep-skills/ → Reload Window
```
Manifest: `plugins/deep-skills/.cursor-plugin/plugin.json` (`"skills": "./skills/"`). Fleets use `.cursor/agents/*.md` with `model:` from `model-map.md`; `/multitask` and Task fan-out provide concurrency.
**RE-VERIFY:** `/add-plugin` command; SKILL.md frontmatter beyond `name`/`description`/`paths`; how to surface `directives/` (no native Cursor slot — the vendoring invariant + shell loader cover it; the no-shell fallback covers the rest).

### GitHub Copilot — CLI (reuses the Claude marketplace)
Copilot CLI consumes `.claude-plugin/marketplace.json` directly:
```
copilot plugin marketplace add <owner>/<repo>
copilot plugin install deep-skills@deep-skills-by-reu
/skills list                     # verify
```

### GitHub Copilot — VS Code editor (file-based; no marketplace)
The VS Code editor has **no skills marketplace** — point it at this repo's skills:
- Set `chat.agentSkillsLocations` to the repo's `plugins/deep-skills/skills` (preferred — no duplication), **or** copy/symlink the skill dirs into `.github/skills/` (VS Code also reads `.claude/skills/` natively).
- Map `directives/` to always-on context via `.github/instructions/*.instructions.md`, or rely on the no-shell directive fallback.
- **Fleet caveat:** see the degradation note above.

## Maintainer rules (the standalone / single-source contract)

1. **One source of truth.** Skill bodies are shared across all hosts. Never fork a `SKILL.md` or `references/*` per host — fix it once, it ships everywhere. The only per-host files are the manifest dirs (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`). `model-map.md` is **not** forked per host — it is one host-agnostic file keyed by the orchestrator's model.
2. **Byte-identical shared files (standalone rule).** Any edit to a shared file is applied **identically** across every skill that carries it, then the consistency sweep re-run (`cmp` each copy pairwise against the canonical):
   - `scripts/load-active-cards.sh` — the **6** loader-bearing skills (`deep-plan`, `deep-plan-review`, `deep-implement`, `deep-code-review`, `deep-bugfix`, `deep-docs`).
   - `references/artifact-structure.md` — all **6** skills.
   - `references/host-affordances.md` — all **6** skills.
   - `references/model-map.md` — the **3** fleet skills. `deep-code-review` and `deep-plan-review` share one byte-identical review map; `deep-bugfix` carries its own third fleet map (same tier conventions, its own agent roles: diagnose+fix / proof / containment). Each is one host-agnostic file keyed by the orchestrator's model.
3. **Every change must work on all hosts.** No edit may assume a Claude-only affordance at a call site — route optional affordances through `host-affordances.md`; keep model routing bound through `model-map.md`.
4. **Never touch frontmatter casually.** `name:`/`description:` drive auto-load/discovery on every host. Changing them changes invocation everywhere.
5. **Run the M3 gate before committing a new host.** Manifest authored ≠ host supported. Install, run a real cycle, confirm fan-out + model binding + directive-registry load, then update the matrix above.
