<!-- deep-goal final run report — a FILL-IN template, written by the CONDUCTOR ONLY to
     `.deep-skills/<effort>/00-Manifest/run-report.md` at run completion, and delivered whole as the
     closing message (references/resume-and-report.md § 2 — the completion sequence and the
     per-section sources of truth). Assemble from artifacts only: pipeline.md, plan.md § Assumptions,
     findings.json, and the code tree — never from subagent narratives. Core skills treat this file
     as opaque (artifact-structure.md § Add-on extensions). Dates in absolute form (YYYY-MM-DD).
     Sections marked "omit when…" are dropped, not left as empty shells. -->

# Run report — <effort-name>

> **Goal:** <one-line goal as invoked>
> **Rigor:** `<level>` (source: <shipped templates/rigor-map.json | repo override .deep-skills/rigor-map.json>) · **Outcome:** <complete — N/N dispatches | complete with CONTINUE blockers — N/N dispatches>
> **State:** [pipeline.md](pipeline.md) · [manifest.md](manifest.md)

## Stages run

One row per dispatch record, in run order (loop rounds included). Commits are read from the code tree — branch `<branch>`<, in worktree `<path>` on `--worktree` runs> — and attributed per stage from the stage's own artifacts; `—` = the stage commits nothing.

| # | Stage | Status | Artifact | Commits | Spend (est) |
|---|---|---|---|---|---|
| 1 | plan | complete | [plan.md](../01-Plan/plan.md) | — | ~<N>k |
| 2 | <stage> | <status> | [<artifact>](<canonical path>) | <shas \| —> | ~<N>k |

## Assumptions (from the plan — verbatim)

Every decision the autonomous planner made **alone**, reproduced verbatim from [`01-Plan/plan.md` § Assumptions](../01-Plan/plan.md) — the unattended run's audit trail (this report is the ledger's canonical reader). Read each row: this is what nobody was asked.

<!-- interactive-planning runs replace the table with: "None — planning was interactive at this
     rigor; these calls were the user's." -->

| # | Question | Chosen answer | Why |
|---|---|---|---|
| 1 | <verbatim from the plan> | <verbatim> | <verbatim> |

## Findings not fixed

**Auto-deferred** — every finding auto-triage deferred below this run's threshold (`--auto-accept-min=<N>`). Source of truth: `findings.json` `status: deferred` (the plan's Deferreds ledger is display-only). Deferred is *not* rejected — each awaits a human call.

| Finding | Severity | Summary |
|---|---|---|
| CR-<NNN> | <n> (<tier>) | <one line> |

**Still open — never triaged** — findings the run ended with in status `open` (e.g. a final re-review's fresh findings at re-review-cap 1). <None. | table below>

| Finding | Severity | Summary |
|---|---|---|
| CR-<NNN> | <n> (<tier>) | <one line> |

## Blockers

Every blocker any stage reported — HALT and CONTINUE alike — reproduced from pipeline.md, each with its report path. <None.>

| Stage | Policy | Report | Note |
|---|---|---|---|
| <stage> | <HALT \| CONTINUE> | <report path> | <one line> |

## Review loop  <!-- omit when the level ran no code review -->

The loop's ledger, from pipeline.md (snapshots stay there — plumbing, not outcome).

| Round | Fresh CR ids | Non-`fixed` | Certificate | Decision |
|---|---|---|---|---|
| 1 | CR-001..CR-<NNN> | <N> | <PASS \| FAIL> | <decision> |

## Spend — uncalibrated estimates

Heuristic bands per `rigor-levels.md` § Cost bands, refined by observed usage where the host surfaced it — **estimates, never measurements**.

| Stage | Spend (est) |
|---|---|
| <stage> | ~<N>k |
| **Total** | **~<N>k tokens** |

<!-- --budget runs append: ceiling ~<band>; Budget events reproduced from pipeline.md. -->

## Worktree  <!-- omit when no --worktree; REQUIRED whenever one was created -->

All code work for this run lives in **`<absolute path>`** on branch **`deep-goal/<effort>`** — nothing has touched your checkout. To land it:

1. Review: `git log <base-branch>..deep-goal/<effort>` (and diff at leisure).
2. Merge: `git merge deep-goal/<effort>` from `<base-branch>` — or push the branch and open a PR.
3. Clean up: `git worktree remove <absolute path>` (the conductor never deletes it for you).
