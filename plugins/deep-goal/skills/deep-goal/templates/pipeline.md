<!-- deep-goal pipeline state — written to `.deep-skills/<effort>/00-Manifest/pipeline.md` at launch
     and updated by the CONDUCTOR ONLY, at every stage boundary (contract row #3). Core skills treat
     this file as opaque (artifact-structure.md § Add-on extensions). It is the resume source: a
     re-invocation reads prior state from here (references/resume-and-report.md § 1), the
     one-stage-in-flight guard reads the
     Dispatch records, and the final run report is assembled from it.
     Header fields are resolved ONCE at launch and never re-derived mid-run; the Artifact baseline
     is likewise recorded once at launch and re-read on resume, never re-snapshot (sole exception:
     on --worktree runs the docs/ai-map row is re-recorded from the fresh worktree when the
     worktree is created — references/loop-and-budget.md § 5). Dates in absolute
     form (YYYY-MM-DD HH:MM). Review-loop rounds append additional dispatch records ("code-review
     (round N)" etc.) plus one Review loop row per round (pre-dispatch snapshot + round accounting
     — references/loop-and-budget.md § 1); --budget runs log boundary events under Budget events
     (§ 2); resume reads this file and continues updating records through the normal loop
     (a "fresh" restart archives it first, as pipeline-archived-<n>.md). -->

# Pipeline — <effort-name>

> **Goal:** <one-line goal as invoked>
> **Rigor:** `<level>` (source: <shipped templates/rigor-map.json | repo override .deep-skills/rigor-map.json>)
> **deep-skills:** `<resolved plugin.json path>` · version <x.y.z — handshake pass | unverified (no semver version field — warning logged, capabilities assumed)>
> **Gates:** <none | before <stage>[, …]> · **Budget:** <none | ~<band> tokens> · **Worktree:** <none | pending (created after planning) | <path> (branch deep-goal/<effort>)>

## Stage list (resolved at launch)

The resolved level's stages in dispatch order, with the invocation each renders to (`references/conductor.md` § Stage → invocation table). A `code-review` stage with a `triage` option expands to two dispatches.

| # | Stage | Dispatch | Invocation |
|---|---|---|---|
| 1 | plan | <inline (interactive) *or* subagent (autonomous)> | `deep-plan <…flags per the map>` |
| 2 | <stage> | subagent | `<skill> <…flags>` |

## Artifact baseline (recorded at launch)

What already existed at each canonical path when THIS run launched — advance tests judge each stage's work against this, never against absolute existence (`references/conductor.md` § 4), so a prior run's surviving artifacts (a fresh restart archives only pipeline state) or a pre-run manual skill can neither pass a stage that did not run nor fail one that did. Recorded once at launch; a resume **re-reads it, never re-snapshots** (re-recording would misread this run's own pre-crash work as pre-existing). All rows `absent` on a virgin effort. **Sole exception — the `docs/ai-map/ (code tree)` row on `--worktree` runs:** the docs advance test reads `docs/ai-map/` in the worktree, where checkout gives every file an mtime after launch, so this one row is **re-recorded from the fresh worktree at worktree creation** (and again if a vanished worktree is recreated on resume) — `references/loop-and-budget.md` § 5.

| Canonical artifact | At launch | Baseline detail |
|---|---|---|
| 01-Plan/plan.md | <absent \| present> | <— \| mtime> |
| 02-Plan-Review/review.md | <absent \| present> | <— \| mtime> |
| 03-Implementation/summary.md | <absent \| present> | <— \| mtime> |
| 04-Code-Review/findings.json | <absent \| present> | <— \| max CR id · count · `reviewed` · findings/cert mtimes> |
| 06-Bug-Fix/round-*/ | <none \| present> | <— \| highest round-K> |
| docs/ai-map/ (code tree) | <absent \| present> | <— \| index.json mtime — on --worktree runs, re-recorded from the worktree at worktree creation (loop-and-budget.md § 5)> |
| Manifest stage statuses | — | <e.g. all pending \| 01–06 complete (prior run)> |

## Dispatch records

One record per dispatch, in order. **Status:** `pending` → `in-flight` → `complete` | `halted` (a loop dispatch skipped by the empty-set short-circuit, `references/loop-and-budget.md` § 1.5, goes straight `pending` → `complete`). **Exactly one record may be `in-flight` at a time** (the double-dispatch guard: mark `in-flight` *before* launching). `halted` means the *stage* stopped without passing its advance test; whether the *run* stopped is the matching Blockers row's Policy. Resume (`references/resume-and-report.md` § 1.3) re-enters at the first record that is not `complete`.

| # | Stage | Status | Started | Finished | Advance test | Spend (est) | Notes |
|---|---|---|---|---|---|---|---|
| 1 | plan | pending | — | — | — | — | — |
| 2 | <stage> | pending | — | — | — | — | — |

- **Advance test** — the conductor's own verification result, e.g. `pass — 01-Plan/plan.md exists`, `pass — summary.md + manifest "03 Implementation: complete"`, `fail — findings.json has open statuses`, `skipped — zero accepted-and-unfixed findings, nothing to fix` (empty-set short-circuit, `references/loop-and-budget.md` § 1.5). Per-stage checks: `references/conductor.md` § 4.
- **Spend (est)** — heuristic band per `references/rigor-levels.md` § Cost bands (refined by observed usage where the host surfaces it); always an estimate, never presented as measured.
- **Notes** — short facts a resume or report needs: assumption-row count, phases committed, blocked clusters, blocker-report path, re-dispatch note.

## Blockers

Every blocker any stage reported, HALT and CONTINUE alike, each with its report path (the run report reproduces this table).

| Stage | Policy | Report | Note |
|---|---|---|---|
| — | — | — | — |

## Review loop

*Only when the level runs a code review (`references/loop-and-budget.md` § 1). One row per review round.* The **Snapshot** is written when the round's re-review record goes `in-flight` — **before** the subagent launches — so a crash mid-round is detectable (round-aware advance test, § 1.2); round 1 uses the plain advance test (no snapshot) when the Artifact baseline shows no pre-existing `findings.json` — over a pre-existing one, round 1 is judged round-aware with the launch baseline as its snapshot (§ 1.2; `references/conductor.md` § 4). **Non-`fixed`** = findings in `findings.json` with status ≠ `fixed`, counted right after the round's review/re-review passes its advance test.

| Round | Snapshot (max CR id · count · `reviewed` · findings/cert mtimes) | Fresh CR ids | Non-`fixed` | Certificate | Decision |
|---|---|---|---|---|---|
| 1 | — | CR-001..CR-NNN | N | <PASS \| FAIL> | <triage → bugfix> |

- **Decision** values: `triage → bugfix` (round 1, per the map) · `re-review (round N+1)` · `exit → docs` · `loop done (cap 0)` · `HALT — unresolved Blockers` · `HALT — convergence failure (cap <re_review_cap> reached)`. When the empty-set short-circuit fires (`references/loop-and-budget.md` § 1.5), the skip prefixes the exit in the same cell, e.g. `bugfix skipped (empty set) → exit → docs` or `triage + bugfix skipped (empty set) → loop done (cap 0)`.

## Spend

Running total: <~N tokens est> — sum of completed records' estimates; uncalibrated heuristic (`references/rigor-levels.md` § Cost bands).

**Budget events** *(only on `--budget` runs — boundary checks that changed the run; `references/loop-and-budget.md` § 2)*

| Boundary (before stage) | Running total | Ceiling | Action |
|---|---|---|---|
| — | — | — | — |

- **Action** values: `paused — notified, waiting` · `resumed` · `ceiling raised to ~<band>` · `ceiling removed` (resume actions: `references/resume-and-report.md` § 1.3).
