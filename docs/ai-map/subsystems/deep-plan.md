<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-plan

> **Load when:** running or modifying a feature-planning session (`/deep-plan`, "plan a feature") · **~tokens:** ~520 est

## Purpose

Interactive, steerable feature-planning session that produces a self-contained, fresh-agent-resumable plan artifact — planning only, never implementation. — `plugins/deep-skills/skills/deep-plan/SKILL.md:6 (DeepPlan)`

## Entry points

- `/deep-plan` command; NL "plan a feature / run a planning session" — `plugins/deep-skills/skills/deep-plan/SKILL.md:6 (DeepPlan)`
- In-session commands `/drill /breakout /gaps /risks /constraints /columbo` — `plugins/deep-skills/skills/deep-plan/SKILL.md:30 (In-session commands)`
- 8-stage interruptible state machine (Setup → Frame → Explore → Question rounds → Pre-write nudge → Design & write → Review → Columbo) — `plugins/deep-skills/skills/deep-plan/SKILL.md:45 (Session workflow)`

## Key components

- Directive-card load before session — `plugins/deep-skills/skills/deep-plan/SKILL.md:12 (Directive cards (Deep-Learn))`
- Card loader script — `plugins/deep-skills/skills/deep-plan/scripts/load-active-cards.sh:2 (load-active-cards.sh)`
- Artifact structure (`.deep-skills/` layout + manifest) — `plugins/deep-skills/skills/deep-plan/references/artifact-structure.md:1 (Artifact structure)`
- Plan template (deferreds ledger format) — `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:58 (Deferreds)`

## Invariants

- Plan-only, never implement — `plugins/deep-skills/skills/deep-plan/SKILL.md:6 (DeepPlan)`
- Directive cards are hard requirements; loaded before the session — `plugins/deep-skills/skills/deep-plan/SKILL.md:12 (Directive cards (Deep-Learn))`
- Pre-write nudge mandatory: offer gaps/risks/constraints before writing — `plugins/deep-skills/skills/deep-plan/SKILL.md:62 (5. Pre-write nudge)`
- Deferreds live in a ledger, not prose — nothing forgotten by phase 4 — `plugins/deep-skills/skills/deep-plan/SKILL.md:85 (Deferreds)`
- Phases carry no conversation memory; Phase Summaries empty at planning time — `plugins/deep-skills/skills/deep-plan/references/phase-structuring.md:13 (Resumability rules)`

## Data-flow summary

- Consumes directive cards + user answers → produces `.deep-skills/<effort>/00-Manifest/manifest.md` + `01-Plan/plan.md`; hands off to /deep-plan-review and /deep-implement — `plugins/deep-skills/skills/deep-plan/references/artifact-structure.md:1 (Artifact structure)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| plan-only never-implement boundary | `plugins/deep-skills/skills/deep-plan/SKILL.md:6 (DeepPlan)` |
| mandatory card load before session | `plugins/deep-skills/skills/deep-plan/SKILL.md:12 (Directive cards (Deep-Learn))` |
| in-session command table | `plugins/deep-skills/skills/deep-plan/SKILL.md:30 (In-session commands)` |
| 8 stages | `plugins/deep-skills/skills/deep-plan/SKILL.md:45 (Session workflow)` |
| mandatory pre-write nudge | `plugins/deep-skills/skills/deep-plan/SKILL.md:62 (5. Pre-write nudge)` |
| deferral ledger | `plugins/deep-skills/skills/deep-plan/SKILL.md:85 (Deferreds)` |
| output location + manifest | `plugins/deep-skills/skills/deep-plan/references/artifact-structure.md:1 (Artifact structure)` |
| no-conversation-memory invariant | `plugins/deep-skills/skills/deep-plan/references/phase-structuring.md:13 (Resumability rules)` |
| ledger format | `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:58 (Deferreds)` |
| card loader | `plugins/deep-skills/skills/deep-plan/scripts/load-active-cards.sh:2 (load-active-cards.sh)` |
