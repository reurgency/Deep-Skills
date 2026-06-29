<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-implement

> **Load when:** executing a plan phase-by-phase (`/deep-implement`, "build a phase") · **~tokens:** ~560 est
> **Deep ref:** [references/deep-implement.md](../references/deep-implement.md)

## Purpose

Execute a finished plan phase-by-phase as an orchestrator — spawning fresh sub-agents per phase, validating, bounded fix loops (cap 2), committing checkpoints, handing off — collaborative or autonomous. — `plugins/deep-skills/skills/deep-implement/SKILL.md:6 (DeepImplement)`

## Entry points

- `/deep-implement`; NL "execute a plan / build a phase / continue from phase N"; arg `plan=<path>` or auto-discover — `plugins/deep-skills/skills/deep-implement/SKILL.md:22 (Inputs & flags)`
- Per-phase loop: implement → validate → fix → (commit) → summarize → hand-off — `plugins/deep-skills/skills/deep-implement/SKILL.md:46 (3. Execute phases)`

## Key components

- Orchestrator model (does not write code itself; spawns fresh sub-agents) — `plugins/deep-skills/skills/deep-implement/SKILL.md:6 (DeepImplement)`
- Execution modes: collaborative gate vs autonomous commit-on-green — `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:5 (Collaborative)`
- Validation + DLC-001 contract probe — `plugins/deep-skills/skills/deep-implement/references/validation.md:34 (Green ≠ verified for external shapes)`
- Commit + branch policy, hand-off — `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:3 (Branch policy)`

## Invariants

- Orchestrator spawns a fresh sub-agent per phase — `plugins/deep-skills/skills/deep-implement/SKILL.md:6 (DeepImplement)`
- Directive cards are hard requirements — `plugins/deep-skills/skills/deep-implement/SKILL.md:12 (Directive cards (Deep-Learn))`
- Never commit on main/develop (branch first) — `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:3 (Branch policy)`
- DLC-001: green ≠ verified for external shapes (contract probe) — `plugins/deep-skills/skills/deep-implement/references/validation.md:34 (Green ≠ verified for external shapes)`
- Parallel only with `--parallel` + provable independence — `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:13 (--parallel)`
- Autonomous: commit-on-green, stop-on-blocker — `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:17 (Autonomous)`

## Data-flow summary

- Consumes plan (full, incl Phase Summaries + Deferreds) + cards → per-phase: phase agent → validation → commit → hand-off → next phase; produces Phase Summaries appendix + `03-Implementation/summary.md` + commits + blocker reports + notifications — `plugins/deep-skills/skills/deep-implement/SKILL.md:46 (3. Execute phases)` → `plugins/deep-skills/skills/deep-implement/references/validation.md:34 (Green ≠ verified for external shapes)` → `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:3 (Branch policy)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| orchestrator model, spawns fresh sub-agents | `plugins/deep-skills/skills/deep-implement/SKILL.md:6 (DeepImplement)` |
| cards mandatory | `plugins/deep-skills/skills/deep-implement/SKILL.md:12 (Directive cards (Deep-Learn))` |
| plan resolution + flags | `plugins/deep-skills/skills/deep-implement/SKILL.md:22 (Inputs & flags)` |
| per-phase loop | `plugins/deep-skills/skills/deep-implement/SKILL.md:46 (3. Execute phases)` |
| approval gate | `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:5 (Collaborative)` |
| commit-on-green, stop-on-blocker | `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:17 (Autonomous)` |
| parallel safety conditions | `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:13 (--parallel)` |
| DLC-001 contract probe | `plugins/deep-skills/skills/deep-implement/references/validation.md:34 (Green ≠ verified for external shapes)` |
| never commit on main | `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:3 (Branch policy)` |
| notify sparingly | `plugins/deep-skills/skills/deep-implement/references/notifications.md:1 (Notifications)` |
| next-phase hand-off format | `plugins/deep-skills/skills/deep-implement/templates/phase-handoff.md:1` |
