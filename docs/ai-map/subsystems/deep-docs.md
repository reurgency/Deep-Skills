<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-docs

> **Load when:** generating/refreshing the AI map (`/deep-docs`, "map this codebase") · **~tokens:** ~600 est
> **Deep ref:** [references/deep-docs.md](../references/deep-docs.md)

## Purpose

Context-window-aware, machine-readable documentation generator producing a standing, queryable, tier-layered orientation map of what a codebase has built — every claim anchored to file:line (symbol) and adversarially verified by fresh agents. — `plugins/deep-skills/skills/deep-docs/SKILL.md:3 (machine-readable documentation of what a codebase has built)`

## Entry points

- `/deep-docs`; NL "map this codebase / document what's built / generate the AI map / refresh the docs" — `plugins/deep-skills/skills/deep-docs/SKILL.md:3 (Triggers on /deep-docs and on requests to map, document)`
- Default-mode six-stage pipeline: intake/scope → survey → layering → anchor-verify → index → place — `plugins/deep-skills/skills/deep-docs/SKILL.md:45 (Default-mode workflow)`

## Key components

- Intake & scope (three input modes + quarantine) — `plugins/deep-skills/skills/deep-docs/references/intake-and-scope.md:1 (Intake & scope)`
- Survey (directory-primary boundary discovery + fan-out) — `plugins/deep-skills/skills/deep-docs/references/survey.md:1 (Survey)`
- Layering & anchors (three tiers + anchor format) — `plugins/deep-skills/skills/deep-docs/references/layering-and-anchors.md:1 (Layering & anchors)`
- Anchor-verify (always-on per-card verification + verdict) — `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:1 (Anchor-verify)`
- Index & coverage (index.json schema + coverage.md) — `plugins/deep-skills/skills/deep-docs/references/index-and-coverage.md:1 (Index & coverage)`
- Place & report (staging + atomic-mv + crash safety) — `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:1 (Place & report)`

## Invariants

- Documents-never-decides: changes no code in target repo (writes only docs/ai-map/** + manifest line + 07-Docs pointer) — `plugins/deep-skills/skills/deep-docs/SKILL.md:10 (Documents, never decides)`
- Every claim anchored or it's fiction; existing-docs quarantine (external-unverified pointers, never ingested) — `plugins/deep-skills/skills/deep-docs/SKILL.md:19 (Every claim is anchored or it's fiction)`
- Never half-write the map: staging + .in-progress marker + atomic mv; refuse-if-marker — `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:1 (Place & report)`
- Always-on anchor-verify per card; drift blocks publish — `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:1 (Anchor-verify)`

## Data-flow summary

- Consumes host conventions + directive cards + existing human docs (as pointers) → intake → survey fan-out → layering → verify fan-out → index → staging → atomic mv; produces `docs/ai-map/{MAP.md,index.json,subsystems/*,references/*,coverage.md}` + 07-Docs pointer + manifest line — `plugins/deep-skills/skills/deep-docs/references/survey.md:1 (Survey)` → `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:1 (Anchor-verify)` → `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:1 (Place & report)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| purpose: tiered, anchored, verified | `plugins/deep-skills/skills/deep-docs/SKILL.md:3 (machine-readable documentation of what a codebase has built)` |
| changes no code in target repo | `plugins/deep-skills/skills/deep-docs/SKILL.md:10 (Documents, never decides)` |
| anchored-or-fiction + quarantine | `plugins/deep-skills/skills/deep-docs/SKILL.md:19 (Every claim is anchored or it's fiction)` |
| six-stage pipeline | `plugins/deep-skills/skills/deep-docs/SKILL.md:45 (Default-mode workflow)` |
| three input modes + quarantine | `plugins/deep-skills/skills/deep-docs/references/intake-and-scope.md:1 (Intake & scope)` |
| directory-primary boundary discovery + fan-out | `plugins/deep-skills/skills/deep-docs/references/survey.md:1 (Survey)` |
| three tiers + anchor format | `plugins/deep-skills/skills/deep-docs/references/layering-and-anchors.md:1 (Layering & anchors)` |
| always-on per-card verification + verdict | `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:1 (Anchor-verify)` |
| index.json schema + coverage.md | `plugins/deep-skills/skills/deep-docs/references/index-and-coverage.md:1 (Index & coverage)` |
| staging + atomic-mv + crash safety | `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:1 (Place & report)` |
| machine index schema | `plugins/deep-skills/skills/deep-docs/templates/index.json:1` |
