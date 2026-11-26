<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-implement

> **Load when:** editing or invoking /deep-implement (phase loop, validation, commit/hand-off, modes) · **~tokens:** ~1.8k est
> **Deep ref:** [references/deep-implement.md](../references/deep-implement.md)

## Purpose

Orchestrator skill that executes a finished plan phase by phase with a fresh sub-agent per phase; it does not write code itself. - `plugins/deep-skills/skills/deep-implement/SKILL.md:11 (# DeepImplement)`

## Entry points

- `/deep-implement [plan path] --autonomous --worktree --max=<smartest|smarter|smart>` (frontmatter) - `plugins/deep-skills/skills/deep-implement/SKILL.md:4 (argument-hint)`
- Plan resolution: explicit path, then context, then latest `.deep-skills/*/01-Plan/plan.md` - `plugins/deep-skills/skills/deep-implement/SKILL.md:38 (plan)`
- Mode: autonomous or collaborative; asked if omitted on multi-phase plans - `plugins/deep-skills/skills/deep-implement/SKILL.md:39 (Run autonomously)`
- `--parallel` is opt-in only - `plugins/deep-skills/skills/deep-implement/SKILL.md:41 (Run independent phases in parallel)`
- Directive cards loaded first and treated as hard requirements - `plugins/deep-skills/skills/deep-implement/SKILL.md:21 (Treat every directive)`

## Key types

- Phase Summaries appendix in the plan: the durable record and only state - `plugins/deep-skills/skills/deep-implement/SKILL.md:44 (Reuse, don't reinvent)`, `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:54 (Next-phase hand-off)`
- Blocker report template - `plugins/deep-skills/skills/deep-implement/templates/blocker-report.md:3 (Blocker)`
- Phase hand-off template - `plugins/deep-skills/skills/deep-implement/templates/phase-handoff.md:3 (Hand-off)`
- `03-Implementation/summary.md` with `Base · Max · Models` header - `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:45 (Implementation summary)`

## Invariants

- Build only what the plan specifies; gaps are surfaced, not re-planned - `plugins/deep-skills/skills/deep-implement/SKILL.md:85 (Guardrails)`
- Never commit on main/develop; never commit failing code - `plugins/deep-skills/skills/deep-implement/SKILL.md:86 (Guardrails)`
- Fix loop capped at 2 attempts, then blocker report and notify - `plugins/deep-skills/skills/deep-implement/SKILL.md:72 (5. Fix loop)`
- Every phase agent runs on the `implement` stage tier, set explicitly per launch - `plugins/deep-skills/skills/deep-implement/SKILL.md:88 (Guardrails)`
- Parallel only if no shared files, no ordering dependency, contract pre-defined - `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:18 (--parallel)`
- Never read .env during command discovery; no hardcoded check commands - `plugins/deep-skills/skills/deep-implement/references/validation.md:5 (Host-command discovery)`
- Block only on new failures in changed files - `plugins/deep-skills/skills/deep-implement/references/validation.md:3 (Validation)`
- Never push or force-push unless asked - `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:22 (Commits)`
- In a worktree, code stays there; plan/summary updates go to the source branch root - `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:9 (Worktree mode)`
- Notify only on blocker and autonomous completion - `plugins/deep-skills/skills/deep-implement/references/notifications.md:3 (Notifications)`

## Data-flow summary

- Per phase: brief fresh agent (plan + phase + summaries + hand-off + MODEL line) - `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:5 (Default)` → validate incl. combined suite run - `plugins/deep-skills/skills/deep-implement/references/validation.md:26 (Per-phase checks)` → commit (autonomous) or gate (collaborative) - `plugins/deep-skills/skills/deep-implement/SKILL.md:76 (6. Commit / gate)` → append summary and hand-off - `plugins/deep-skills/skills/deep-implement/SKILL.md:79 (7. Summarize)`
- Resume: first phase not marked done in Phase Summaries - `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:58 (Resume)`

## Anchors

| Claim | Anchor |
|---|---|
| purpose | `plugins/deep-skills/skills/deep-implement/SKILL.md:11 (# DeepImplement)` |
| entry: flags | `plugins/deep-skills/skills/deep-implement/SKILL.md:4 (argument-hint)` |
| entry: plan | `plugins/deep-skills/skills/deep-implement/SKILL.md:38 (plan)` |
| entry: mode | `plugins/deep-skills/skills/deep-implement/SKILL.md:39 (Run autonomously)` |
| entry: parallel | `plugins/deep-skills/skills/deep-implement/SKILL.md:41 (Run independent phases in parallel)` |
| entry: directives | `plugins/deep-skills/skills/deep-implement/SKILL.md:21 (Treat every directive)` |
| type: Phase Summaries | `plugins/deep-skills/skills/deep-implement/SKILL.md:44 (Reuse, don't reinvent)` |
| type: Phase Summaries | `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:54 (Next-phase hand-off)` |
| type: blocker | `plugins/deep-skills/skills/deep-implement/templates/blocker-report.md:3 (Blocker)` |
| type: hand-off | `plugins/deep-skills/skills/deep-implement/templates/phase-handoff.md:3 (Hand-off)` |
| type: summary.md | `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:45 (Implementation summary)` |
| inv: scope | `plugins/deep-skills/skills/deep-implement/SKILL.md:85 (Guardrails)` |
| inv: no bad commits | `plugins/deep-skills/skills/deep-implement/SKILL.md:86 (Guardrails)` |
| inv: fix cap | `plugins/deep-skills/skills/deep-implement/SKILL.md:72 (5. Fix loop)` |
| inv: model tier | `plugins/deep-skills/skills/deep-implement/SKILL.md:88 (Guardrails)` |
| inv: parallel | `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:18 (--parallel)` |
| inv: no .env | `plugins/deep-skills/skills/deep-implement/references/validation.md:5 (Host-command discovery)` |
| inv: new failures | `plugins/deep-skills/skills/deep-implement/references/validation.md:3 (Validation)` |
| inv: no push | `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:22 (Commits)` |
| inv: worktree docs | `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:9 (Worktree mode)` |
| inv: notify | `plugins/deep-skills/skills/deep-implement/references/notifications.md:3 (Notifications)` |
| flow: brief | `plugins/deep-skills/skills/deep-implement/references/phase-execution.md:5 (Default)` |
| flow: validate | `plugins/deep-skills/skills/deep-implement/references/validation.md:26 (Per-phase checks)` |
| flow: commit/gate | `plugins/deep-skills/skills/deep-implement/SKILL.md:76 (6. Commit / gate)` |
| flow: summarize | `plugins/deep-skills/skills/deep-implement/SKILL.md:79 (7. Summarize)` |
| flow: resume | `plugins/deep-skills/skills/deep-implement/references/commit-and-handoff.md:58 (Resume)` |
