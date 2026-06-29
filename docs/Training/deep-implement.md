# Training: `/deep-implement`

> Part of the [Deep Skills Training Program](README.md). Skill 3 of 5 — **execute**.
> Source: [`plugins/deep-skills/skills/deep-implement/SKILL.md`](../../plugins/deep-skills/skills/deep-implement/SKILL.md)

`/deep-implement` executes a finished, reviewed plan **phase by phase**:
implement → validate → fix → commit → hand-off — in collaborative or autonomous mode. It is
the **only** deep-\* skill that writes source code.

---

## Learning objectives

By the end you can:

1. Act as an **orchestrator**: spawn a fresh sub-agent per phase rather than coding yourself.
2. Choose **collaborative vs autonomous** mode and use the `--worktree` / `--parallel` flags
   correctly (and know when *not* to).
3. Run the per-phase loop with a **bounded fix loop** and correct **validation gating**.
4. Maintain the durable record: **Phase Summaries**, per-phase **commits**, hand-offs, and the
   **Deferreds** reconciliation.
5. Recognize the boundary: stop and surface gaps instead of silently re-planning.

## Prerequisites

[`/deep-plan`](deep-plan.md) and [`/deep-plan-review`](deep-plan-review.md) — you consume their
output. Comfort with git branching and your project's test runner.

---

## Mental model

**You are the orchestrator, not the author.** By default you do **not** write the code — you
spawn a fresh sub-agent per phase, validate its work, drive the fix loop, commit checkpoints,
and hand off. You reuse existing machinery (test runner, worktrees, hand-off/resume) rather
than reinventing it. The plan is the contract; you execute exactly what it specifies.

This is a *lightweight, plan-driven* orchestrator — deliberately not a heavy DB-backed
pipeline. Keep it slim.

---

## Curriculum

### Module 1 — Inputs & flags
- **plan:** explicit path → plan in context → most recent `01-Plan/plan.md`. Read it **fully**,
  including the **Phase Summaries** appendix and **Deferreds** ledger.
- `--autonomous` / `--collaborative` — execution mode. If omitted on a multi-phase plan,
  **ask**. (`references/execution-modes.md`)
- `--worktree` — isolate work in a git worktree via `/create_worktree`. Default: **work in the
  current branch.**
- `--parallel` — opt-in parallel phase execution, **only** when phases are provably
  independent. Never parallelize without this flag.

### Module 2 — Load & assess
Identify: single- vs multi-phase, which phases are already done (read the Phase Summaries),
the Deferreds ledger, and each phase's acceptance/validation criteria. Resolve mode and flags.
**If resuming, start at the first unfinished phase** — this is where fresh-agent resumability
pays off.

### Module 3 — Worktree / branch setup
With `--worktree`, create the isolated worktree. Otherwise **branch-first if on
`main`/`develop`.** Code changes go in the worktree; **plan/summary updates go to the source
branch root.**

### Module 4 — Execute phases
Per `references/phase-execution.md`:
- **Default (sequential):** for each phase, spawn **one fresh sub-agent** briefed with the
  plan + that phase + prior Phase Summaries. It implements **only that phase**.
- **`--parallel` (guarded):** only for phases verified independent — no shared files, no
  ordering dependency, contract pre-defined. Otherwise fall back to sequential and say why.

For each phase, run the loop: **implement → validate → fix → (commit) → summarize → hand-off.**

### Module 5 — Validate each phase
Per `references/validation.md`: typecheck (e.g. `bunx tsc` **from the app dir — never `npx`
from root**), run relevant tests via the `test-runner` skill, and run the prompt-assembly
snapshot test if the phase touched the relevant pipeline stages. **Block only on *new*
failures in changed files / their imports** — pre-existing unrelated failures don't gate you.

### Module 6 — The bounded fix loop
If validation fails, the phase agent fixes and re-validates. **Cap: 2 attempts.** If still
failing → **stop**, write a blocker report (`templates/blocker-report.md`), **notify**, and in
autonomous mode **do not commit broken code.** The cap is what keeps a stuck phase from
burning the run.

### Module 7 — Commit / gate (mode-dependent)
- **Collaborative:** present diff + validation result + phase summary; await
  approve / request-fix. Commit only if the user wants.
- **Autonomous:** on green validation, **commit a per-phase checkpoint** (conventional message
  + `Co-Authored-By` trailer), append the summary, write the next-phase hand-off, continue.

### Module 8 — Summarize & hand off
After each phase: append a summary to the plan's **Phase Summaries** appendix and write a slim
next-phase hand-off (`templates/phase-handoff.md`). Phase Summaries live **in the plan
document** — `03-Implementation/summary.md` does not replace them.

### Module 9 — Finish
Write/update `.deep-skills/<effort>/03-Implementation/summary.md` — check off the plan's
acceptance/validation criteria there; create the manifest if absent and update the
Implementation stage status. **Reconcile the Deferreds ledger** (addressed vs still open) and
report it. In autonomous mode, **notify** on full-run completion. The plan doc stays the
durable record. Hand off to [`/deep-code-review`](deep-code-review.md).

---

## Directive cards

Run `scripts/load-active-cards.sh deep-implement` at the start; treat each printed directive as
a hard requirement. `DLC-001` gives this skill a **validate** role: each "runtime" Data-Flow
Contract row's reader must be wired in code, plus a **contract probe** (write → execute →
assert read) — the net that typecheck + unit tests miss for cross-layer bugs.

---

## Hands-on exercises

1. **Orchestrator drill:** for a 3-phase plan, write the briefing you'd give the phase-1
   sub-agent (plan + phase + prior summaries) without doing the coding yourself.
2. **Mode call:** decide collaborative vs autonomous for (a) a risky migration and (b) a
   mechanical rename, and justify it.
3. **Gating:** given a test run with 1 new failure in a changed file and 3 pre-existing
   unrelated failures, decide whether the phase is blocked.
4. **Fix-loop limit:** simulate two failed fix attempts; produce the blocker report instead of
   a third attempt.
5. **Resume:** given a plan with phases 1–2 summarized, identify where execution restarts.

---

## Common mistakes

- **Writing the code yourself** instead of orchestrating sub-agents (the default is fresh
  agent per phase).
- **Committing on `main`/`develop`** — always branch first. **Never commit failing code.**
- **Parallelizing without `--parallel`** or without proving independence.
- **Blocking on pre-existing failures** instead of only *new* failures in changed files.
- **A third fix attempt** — the cap is 2; then stop and report.
- **Silently re-planning** when you hit a gap. Stop and surface it — re-planning is
  `/deep-plan`'s job.
- **Over-notifying** — notify on blockers and autonomous completion only, not routine progress.

## Mastery checklist

- [ ] Orchestrated phases via fresh sub-agents; you did not hand-author the code by default.
- [ ] Chose mode deliberately; branched before any commit; never committed broken code.
- [ ] Gated only on new failures in changed files/imports; honored the 2-attempt fix cap.
- [ ] Appended Phase Summaries to the plan and wrote each next-phase hand-off.
- [ ] Finished with `03-Implementation/summary.md`, manifest update, and a reconciled Deferreds ledger.

## Quick reference

| | |
|---|---|
| Input | A finished (ideally reviewed) `01-Plan/plan.md` |
| Output | Source code + `03-Implementation/summary.md` + Phase Summaries in the plan |
| Fix cap | 2 attempts, then a blocker report |
| Hard rules | Only build what the plan specifies; never commit on main/develop; never commit failing code |
| Hand-off to | [`/deep-code-review`](deep-code-review.md) |

➡ **Next:** [Training: `/deep-code-review`](deep-code-review.md)
