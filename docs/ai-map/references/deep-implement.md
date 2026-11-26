# deep-implement: phase loop trace

<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->

## Flow 1: one phase, autonomous mode

1. Orchestrator spawns a fresh agent briefed with plan, its phase, prior summaries, hand-off, MODEL line - `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:5 (Default)`
2. Agent runs on the stage tier from the model map, explicit per launch - `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:3 (Default)`
3. Agent returns files plus summary and does not commit; orchestrator strips the trailing MODEL line - `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:34 (Briefing a phase agent)`
4. Orchestrator discovers host commands (manifest, CLAUDE.md, tool configs) - `plugins/deep-skills/skills/deep-implement/references/validation.md:7 (Host-command discovery)`
5. Runs targeted and a combined suite run, judged by exit code - `plugins/deep-skills/skills/deep-implement/references/validation.md:26 (Per-phase checks)`, `plugins/deep-skills/skills/deep-implement/references/validation.md:41 (Test output capture)`
6. Verdict names the commands actually run; green is not proof for external shapes - `plugins/deep-skills/skills/deep-implement/references/validation.md:45 (Verdict)`, `plugins/deep-skills/skills/deep-implement/references/validation.md:47 (Verdict)`
7. On failure the agent fixes; cap of 2, then stop, blocker report, notify, no commit - `plugins/deep-skills/skills/deep-implement/SKILL.md:72 (5. Fix loop)`, `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:17 (Autonomous)`
8. On green, checkpoint commit with host-aware trailer - `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:26 (Commits)`
9. Append Phase Summary and write hand-off to the plan - `plugins/deep-skills/skills/deep-implement/SKILL.md:79 (7. Summarize)`, `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:54 (Next-phase hand-off)`
10. Finish: summary.md header records models the agents actually ran on - `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:45 (Implementation summary)`

Collaborative differs only at step 8: present diff and gate; mode switches take effect at the next phase boundary - `plugins/deep-skills/skills/deep-implement/references/execution-modes.md:32 (Switching mid-run)`

## Flow 2: external-shape construction rules

Briefing appends rules when a phase emits a payload an external consumer reads: verify the shape against ground truth, and do not write tautological contract tests - `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:42 (Construction rules)`, `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:43 (Construction rules)`
