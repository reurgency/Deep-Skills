<!-- deep-goal stage briefing — a FILL-IN template, rendered by the conductor per dispatch
     (references/conductor.md § 3, which defines every substitution) and passed as the dispatched
     subagent's ENTIRE prompt. Substitutions:
       {skill_name}    — the sibling skill to invoke, BY NAME (e.g. deep-implement)
       {skill_path}    — that skill's SKILL.md under the launch-resolved deep-skills install
                         (a Claude-Code-specific location optimization; the NAME is authoritative)
       {effort_name}   — the effort slug (artifacts home: .deep-skills/{effort_name}/)
       {stage_flags}   — this stage's arguments + flags from the resolved rigor map
                         (conductor.md § Stage → invocation table)
       {worktree_path} — renders "none — work on the current branch per the skill's own defaults"
                         unless the run was launched with --worktree, in which case it is the ONE
                         conductor-created worktree every post-planning stage shares (Phase 5 wires
                         this; until then it always renders the "none" form)
     Keep the rendered briefing MINIMAL — the skill's own SKILL.md carries the job; this briefing
     carries only identity, effort, flags, and the pipeline rules. Never append transcripts,
     plan excerpts, or prior stages' narratives. -->

You are running **one stage** of an autonomous deep-* pipeline (conducted by deep-goal). Your entire job is one skill invocation:

**Invoke the skill `{skill_name}` now**, with exactly these arguments: {stage_flags}

- On Claude Code its SKILL.md is at `{skill_path}` — a location shortcut only; the skill is invoked **by name**, and its own SKILL.md (directive cards, workflow, guardrails, artifacts) defines everything you do. Read and follow it completely.
- **Effort:** `{effort_name}` — all artifacts for this run live under `.deep-skills/{effort_name}/`. If your skill asks which effort/plan/findings to use, it is this one; never propose a different effort name.
- **Working tree:** {worktree_path}

Pipeline rules — these bind you on top of the skill's own guardrails, never instead of them:

1. **Artifacts are the only channel.** Everything you need from earlier stages is already in `.deep-skills/{effort_name}/` (plan, manifest, review artifacts — read what your skill directs); everything you produce must land in your skill's canonical artifacts. You receive no transcripts and pass none forward.
2. **Your final message is not the channel — write the artifacts.** The conductor advances only on artifact evidence: your skill's expected output files at their canonical paths, and your skill's own manifest stage line updated exactly as it prescribes. A closing summary that isn't backed by artifacts counts as not done.
3. **Stay in your stage.** Run `{skill_name}` with the arguments above and stop — do not invoke other deep-* skills (unless your skill's own workflow explicitly does), do not edit `00-Manifest/pipeline.md` or another stage's artifacts, and ask the user nothing: this pipeline is autonomous. If you hit a blocker, do what your skill prescribes (its blocker report / notification), then stop.
