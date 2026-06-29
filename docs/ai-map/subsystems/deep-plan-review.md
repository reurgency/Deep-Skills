<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-plan-review

> **Load when:** reviewing or critiquing a finished plan (`/deep-plan-review`, "review a plan") · **~tokens:** ~480 est

## Purpose

Independently review a finished plan with fresh agents to surface misalignment with user preferences, codebase patterns, duplicate behavior, and internal conflicts — never implements. — `plugins/deep-skills/skills/deep-plan-review/SKILL.md:6 (DeepPlanReview)`

## Entry points

- `/deep-plan-review [<path>]`; NL "review/critique a plan"; defaults to most recent plan.md — `plugins/deep-skills/skills/deep-plan-review/SKILL.md:3 (Independently review a finished plan with fresh)`
- Single-agent (default) vs multi-agent mode (`--multi-agent`/`/multi-agent`) — `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:1 (Multi-agent review)`

## Key components

- Review-only never-edit-source contract — `plugins/deep-skills/skills/deep-plan-review/SKILL.md:6 (DeepPlanReview)`
- Two-lens review dimensions (A user-alignment, B codebase-alignment) — `plugins/deep-skills/skills/deep-plan-review/references/review-dimensions.md:1 (Review dimensions)`
- Findings format + severity (Blocker/Major/Minor/Nit) — `plugins/deep-skills/skills/deep-plan-review/references/findings-format.md:7 (Severity)`
- Card loader script — `plugins/deep-skills/skills/deep-plan-review/scripts/load-active-cards.sh:2 (load-active-cards.sh)`

## Invariants

- Review-only, never edit source (may edit the plan doc) — `plugins/deep-skills/skills/deep-plan-review/SKILL.md:6 (DeepPlanReview)`
- Fresh agents get no planning transcript (independence) — `plugins/deep-skills/skills/deep-plan-review/SKILL.md:22 (Core principle: independence through fresh agents)`
- Directive-card dispatch is a hard requirement — `plugins/deep-skills/skills/deep-plan-review/SKILL.md:12 (Directive cards (Deep-Learn))`
- Byte-identical artifact-structure (shared copy) — `plugins/deep-skills/skills/deep-plan-review/references/artifact-structure.md:3 (All copies must stay byte-identical)`

## Data-flow summary

- Consumes plan + user prefs + codebase + cards → produces `.deep-skills/<effort>/02-Plan-Review/review.md` + Review Findings summary in plan + manifest update; hands off to /deep-implement — `plugins/deep-skills/skills/deep-plan-review/references/artifact-structure.md:3 (All copies must stay byte-identical)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| command + NL triggers | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:3 (Independently review a finished plan with fresh)` |
| review-only never-implement contract | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:6 (DeepPlanReview)` |
| card dispatch hard requirement | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:12 (Directive cards (Deep-Learn))` |
| no planning transcript | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:22 (Core principle: independence through fresh agents)` |
| two-lens model | `plugins/deep-skills/skills/deep-plan-review/references/review-dimensions.md:1 (Review dimensions)` |
| severity scale | `plugins/deep-skills/skills/deep-plan-review/references/findings-format.md:7 (Severity)` |
| parallel fan-out + synthesis | `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:1 (Multi-agent review)` |
| shared-copy invariant | `plugins/deep-skills/skills/deep-plan-review/references/artifact-structure.md:3 (All copies must stay byte-identical)` |
| card loader | `plugins/deep-skills/skills/deep-plan-review/scripts/load-active-cards.sh:2 (load-active-cards.sh)` |
