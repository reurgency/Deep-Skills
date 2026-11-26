<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# directives

> **Load when:** adding, toggling, or debugging Deep-Learn directive cards, the card registries, or the category taxonomy · **~tokens:** ~1.3k est

## Purpose

A card registry: each learned improvement is structured card data, never a prose edit to a SKILL.md, giving on/off, provenance and telemetry. - `plugins/deep-skills/directives/README.md:3 (# Directives Registry (Deep-Learn))`. deep-goal has its own separate registry, shipped empty in v1. - `plugins/deep-goal/directives/README.md:5 (# Directives Registry (Deep-Learn) - deep-goal)`

## Entry points

- `./toggle.sh <ID> on|off` moves a card between `cards/active/` and `cards/disabled/` and rewrites `status:`; no args lists all cards by state. - `plugins/deep-skills/directives/toggle.sh:36 (if [ "$action" = "off" ]; then)`, `plugins/deep-skills/directives/toggle.sh:18 (if [ "$#" -eq 0 ]; then)`
- Skills run `scripts/load-active-cards.sh <phase>` (loader documented elsewhere); deep-plan, deep-plan-review, deep-implement, deep-bugfix, deep-code-review, deep-docs and deep-goal each do. - `plugins/deep-skills/skills/deep-plan/SKILL.md:18 (scripts/load-active-cards.sh deep-plan)`, `plugins/deep-goal/skills/deep-goal/SKILL.md:18 (scripts/load-active-cards.sh deep-goal)`
- The loader self-locates the registry relative to its own path (so `skills/` and `directives/` must stay siblings), avoiding uninterpolated `${CLAUDE_PLUGIN_ROOT}` in SKILL.md prose. - `plugins/deep-goal/directives/README.md:25 (## How the skill loads active cards)`, `plugins/deep-skills/directives/README.md:54 (## How skills load active cards)`

## Key types

- Card: Markdown with YAML frontmatter (`id`, `category`, `owner_phases`, `title`, `trigger`, `status`, `provenance`, `promotion`, `outcome`) plus a body with one section per owner phase. - `plugins/deep-skills/directives/README.md:22 (## Card format)`
- `DLC-001` State / Data-Flow Contract, the only card, active, category `write-no-reader`, phases deep-plan, deep-plan-review, deep-implement, deep-bugfix. - `plugins/deep-skills/directives/cards/active/DLC-001.md:4 (owner_phases)`
- Taxonomy: five class slugs (`write-no-reader`, `deletion-parity`, `claim-vs-evidence`, `test-hygiene`, `reuse-dup`); only DLC-001 is written. - `plugins/deep-skills/directives/taxonomy.md:11 (## Categories)`
- Lifecycle dirs `active/ shadow/ candidate/ disabled/`. - `plugins/deep-skills/directives/README.md:7 (## Layout - file-per-card, directory-as-lifecycle-state)`

## Invariants

- The card's directory is the source of truth for state; `status:` mirrors it, so never hand-move files. - `plugins/deep-skills/directives/README.md:7 (## Layout - file-per-card, directory-as-lifecycle-state)`
- No card reaches `active/` without human approval (`promotion.human_approved_by`); removal is first-class and disabled cards are never deleted. - `plugins/deep-skills/directives/README.md:28 (## Lifecycle (the gates))`
- The taxonomy is the authoritative slug list; cards must not invent categories; a class is added only if high severity or seen in 2+ reviews. - `plugins/deep-skills/directives/taxonomy.md:18 (## Rules for this file)`
- The loader matches `owner_phases` by exact token, so core cards cannot target `deep-goal` today and deep-goal reads only its own registry. - `plugins/deep-goal/directives/README.md:5 (v1: this registry ships EMPTY)`, `plugins/deep-goal/directives/taxonomy.md:1 (# Deep-Learn taxonomy - pointer)`
- deep-goal's `toggle.sh` is byte-identical to the core copy, as is the loader (vendoring invariant). - `plugins/deep-goal/directives/README.md:13 (toggle.sh)`, `plugins/deep-goal/directives/README.md:25 (## How the skill loads active cards)`
- deep-goal does not fork the taxonomy; it points to the core one. - `plugins/deep-goal/directives/taxonomy.md:3 (# Deep-Learn taxonomy - pointer)`
- `toggle.sh` uses `git mv` only for tracked cards, else `mv`; it exits 1 if the source card is absent. - `plugins/deep-skills/directives/toggle.sh:50 (if git -C "$here" ls-files --error-unmatch "$src")`, `plugins/deep-skills/directives/toggle.sh:42 (card not found)`

## Data-flow summary

- Toggle: `toggle.sh <ID> off` -> move `cards/active/<ID>.md` to `cards/disabled/` -> `sed` rewrites `status:` - `plugins/deep-skills/directives/toggle.sh:37 (src="$cards/active/$id.md";   dst="$cards/disabled)` -> `plugins/deep-skills/directives/toggle.sh:57 (sed -i.bak -E "s/^status:[[:space:]].*/status: $ne)`
- Load: skill start -> loader with its phase -> active cards whose `owner_phases` match are applied; none prints "no active directive cards for phase: <phase>". - `plugins/deep-skills/skills/deep-plan/SKILL.md:18 (scripts/load-active-cards.sh deep-plan)` -> `plugins/deep-goal/directives/README.md:25 (## How the skill loads active cards)`
- Phase 1 only: the Distiller (`/deep-learn`) and Effectiveness Monitor are not built, so candidate/shadow stay empty. - `plugins/deep-skills/directives/README.md:5 (Phase 1 (current))`

## Anchors

| Claim | Anchor |
|---|---|
| Anchors are inline above; this table lists the non-obvious one | `plugins/deep-skills/directives/README.md:5 (Phase 1 (current))` |
