<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-2 reference: loaded on demand. Deep cross-layer data-flow trace for one subsystem. Every hop anchored. -->

# deep-implement — cross-phase execution flow

> **Load when:** tracing how a plan becomes committed code phase-by-phase, or debugging the DLC-001 contract probe.
> Card: [subsystems/deep-implement.md](../subsystems/deep-implement.md)

## The flow it traces

The orchestrator turns a finished plan into committed code one phase at a time. The orchestrator never writes code itself — it spawns a fresh sub-agent per phase, validates the result, runs a bounded fix loop, commits a checkpoint, and hands off to the next phase.

## Hop-by-hop

1. **Resolve inputs** — `plan=<path>` or auto-discover `.deep-skills/*/01-Plan/plan.md`; flags `--autonomous/--collaborative/--worktree/--parallel`. Cards loaded as hard requirements. — `plugins/deep-skills/skills/deep-implement/SKILL.md:22 (Inputs & flags)` · `plugins/deep-skills/skills/deep-implement/SKILL.md:12 (Directive cards (Deep-Learn))`

2. **Choose mode** — collaborative inserts an approval gate per phase; autonomous commits on green and stops on blocker. Asked if omitted on a multi-phase plan. — `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:5 (Collaborative)` · `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:17 (Autonomous)`

3. **Spawn fresh phase agent** — orchestrator dispatches a fresh sub-agent carrying the full plan (incl. Phase Summaries + Deferreds), not its own transcript. — `plugins/deep-skills/skills/deep-implement/SKILL.md:6 (DeepImplement)` · `plugins/deep-skills/skills/deep-implement/SKILL.md:46 (3. Execute phases)`

4. **Validate (scoped)** — typecheck/test scoped to changed files + imports; verdict rules applied. **Load-bearing invariant:** for external shapes, green ≠ verified — a DLC-001 contract probe must confirm the actual data-flow contract. — `plugins/deep-skills/skills/deep-implement/references/validation.md:34 (Green ≠ verified for external shapes)`

5. **Fix loop (cap 2)** — on failure, bounded re-attempt; exceeding the cap raises a blocker report rather than looping. — `plugins/deep-skills/skills/deep-implement/SKILL.md:46 (3. Execute phases)`

6. **Commit checkpoint** — never on main/develop (branch first); never commit failing code. — `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:3 (Branch policy)`

7. **Summarize + hand off** — write the Phase Summary into the plan appendix and a next-phase hand-off; the following phase agent reads only this, preserving fresh-agent isolation. — `plugins/deep-skills/skills/deep-implement/templates/phase-handoff.md:1` · `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:3 (Branch policy)`

8. **Parallel exception** — phases run sequentially by default; concurrent execution only under `--parallel` with provable independence. — `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:13 (--parallel)`

9. **Notify sparingly** — only on blocker or autonomous completion. — `plugins/deep-skills/skills/deep-implement/references/notifications.md:1 (Notifications)`

## Outputs

Phase Summaries appendix in plan + manifest update + `03-Implementation/summary.md` + per-phase hand-offs + git commits + blocker reports + notifications.
