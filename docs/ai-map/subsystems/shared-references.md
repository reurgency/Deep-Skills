<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# shared-references

> **Load when:** editing model-map.json/.md, host-affordances.md, artifact-structure.md, load-active-cards.sh or check-shared.sh, or tracing how an agent's model is resolved · **~tokens:** ~1.9k est
> **Deep ref:** [references/shared-references.md](../references/shared-references.md)

## Purpose

Five series-shared files, canonical in deep-code-review and copied byte-identically into all 7 skill dirs (6 deep-skills + deep-goal), because skills may not cross-reference each other. - `scripts/check-shared.sh:4 (# Enforces the series-shared-file rule: every shar)`

## Entry points

- `scripts/check-shared.sh [--shared|--sync|--stale|--all]` (maintainer-only, not shipped) - `scripts/check-shared.sh:9 (Usage)`; `--sync` copies canonical over all copies - `scripts/check-shared.sh:228 (do_sync)`
- `load-active-cards.sh <phase>` prints active directive cards whose `owner_phases:` has the exact phase token - `plugins/deep-skills/skills/deep-code-review/scripts/load-active-cards.sh:30 (for card in "$active"/*.md; do)`
- Skills read `model-map.json` + `model-map.md` before any launch - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:5 (Required launch input)`
- `host-affordances.md` is the single fallback home (questions, notifications, effort, worktree, trailer) - `plugins/deep-skills/skills/deep-code-review/references/host-affordances.md:7 (How to use this file)`

## Key types

- `model-map.json`: `ladder.<tier>.<claude|gpt>` (current gen first, then previous), `stages.<max>.<stage>`, `_utility_unused` - `plugins/deep-skills/skills/deep-code-review/references/model-map.json:5 ("ladder")`, `:12 ("stages")`, `:11 ("_utility_unused")`
- Repo override `.deep-skills/model-map.json` (sparse; ladder lists replace whole, stage values replace singly) - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:148 (Merge at key granularity)`
- Frozen snapshot `00-Manifest/model-map.resolved.json` (whole merged map, orchestrator-written) - `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:68 (Add-on extensions)`
- `.deep-skills/<effort>/00-Manifest..07-Docs` layout - `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:9 (Directory layout)`

## Invariants

- Tiers are fixed models (smartest > smarter > smart floor); every tier reasons; small models (haiku, mini, nano, `_utility_unused`) are never assigned - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:133 (Binding rules)`
- Model set explicitly on every launch, built-in types included; resolve to full ID, launch value per host (Claude Code = family alias, so a MODEL: report is mandatory) - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:119 (Host binding)`
- Mismatch: discard + relaunch once per candidate, never on alias hosts; missing/unknown report is recorded unverified - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:128 (Binding rules)`
- Binding (schema) errors never advance access fallback - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:124 (Binding errors are not access errors)`
- Override validation: refuse unless valid JSON, only `map_version/ladder/stages`, fixed stage roster, stage tier <= max, small-free, one tier per ID - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:154 (Validate at launch)`
- A stage given a snapshot uses it and never re-reads shipped map/override; missing snapshot is a blocker - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:136 (## Repo override)`
- Core skills never write or read orchestrator files (pipeline.md, rigor-map.json) except the named snapshot - `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:77 (Ownership rule)`
- Any skill creates manifest.md if absent - `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:59 (Manifest creation rule)`

## Data-flow summary

- `--max` (default = base's tier) -> `stages.<max>.<stage>` -> fleet notation -> ladder ID -> access fallback -> launch value -> `MODEL:` report -> classify -> record - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:74 (--max)` -> `:101 (Access fallback)` -> `:126 (Verified-ID classification)`
- Canonical edit -> `check-shared.sh --sync` -> `--all` (byte-compare 7 copies, validate map, stale scan) - `scripts/check-shared.sh:48 (check_shared)` -> `scripts/check-shared.sh:75 (validate_model_map)` -> `scripts/check-shared.sh:271 (check_stale)`

## Anchors

| Claim | Anchor |
|---|---|
| purpose / 7 copies | `scripts/check-shared.sh:4 (# Enforces the series-shared-file rule: every shar)` |
| check-shared usage | `scripts/check-shared.sh:9 (Usage)` |
| sync | `scripts/check-shared.sh:228 (do_sync)` |
| compare | `scripts/check-shared.sh:48 (check_shared)` |
| validate | `scripts/check-shared.sh:75 (validate_model_map)` |
| stale scan | `scripts/check-shared.sh:271 (check_stale)` |
| loader | `plugins/deep-skills/skills/deep-code-review/scripts/load-active-cards.sh:30 (for card in "$active"/*.md; do)` |
| required input | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:5 (Required launch input)` |
| affordances | `plugins/deep-skills/skills/deep-code-review/references/host-affordances.md:7 (How to use this file)` |
| ladder | `plugins/deep-skills/skills/deep-code-review/references/model-map.json:5 ("ladder")` |
| stages | `plugins/deep-skills/skills/deep-code-review/references/model-map.json:12 ("stages")` |
| utility | `plugins/deep-skills/skills/deep-code-review/references/model-map.json:11 ("_utility_unused")` |
| merge | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:148 (Merge at key granularity)` |
| snapshot file | `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:68 (Add-on extensions)` |
| layout | `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:9 (Directory layout)` |
| no small models | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:133 (Binding rules)` |
| host binding | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:119 (Host binding)` |
| relaunch once | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:128 (Binding rules)` |
| binding errors | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:124 (Binding errors are not access errors)` |
| override validation | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:154 (Validate at launch)` |
| snapshot exception | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:136 (## Repo override)` |
| ownership | `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:77 (Ownership rule)` |
| manifest rule | `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:59 (Manifest creation rule)` |
| --max | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:74 (--max)` |
| access fallback | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:101 (Access fallback)` |
| classification | `plugins/deep-skills/skills/deep-code-review/references/model-map.md:126 (Verified-ID classification)` |
