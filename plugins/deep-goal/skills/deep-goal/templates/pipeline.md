<!-- deep-goal pipeline state — written to `.deep-skills/<effort>/00-Manifest/pipeline.md` at launch
     and updated by the CONDUCTOR ONLY, at every stage boundary (contract row #3). Core skills treat
     this file as opaque (artifact-structure.md § Add-on extensions). It is the resume source: a
     re-invocation reads prior state from here (Phase 6), the one-stage-in-flight guard reads the
     Dispatch records, and the final run report is assembled from it.
     Header fields are resolved ONCE at launch and never re-derived mid-run. Dates in absolute form
     (YYYY-MM-DD HH:MM). Review-loop rounds append additional dispatch records ("code-review
     (round N)" etc.) plus one Review loop row per round (pre-dispatch snapshot + round accounting
     — references/loop-and-budget.md § 1); --budget runs log boundary events under Budget events
     (§ 2); Phase 6's resume reads this file and continues updating records through the normal
     loop (a "fresh" restart archives it first). -->

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

## Dispatch records

One record per dispatch, in order. **Status:** `pending` → `in-flight` → `complete` | `halted`. **Exactly one record may be `in-flight` at a time** (the double-dispatch guard: mark `in-flight` *before* launching). `halted` means the *stage* stopped without passing its advance test; whether the *run* stopped is the matching Blockers row's Policy. Resume (Phase 6) re-enters at the first record that is not `complete`.

| # | Stage | Status | Started | Finished | Advance test | Spend (est) | Notes |
|---|---|---|---|---|---|---|---|
| 1 | plan | pending | — | — | — | — | — |
| 2 | <stage> | pending | — | — | — | — | — |

- **Advance test** — the conductor's own verification result, e.g. `pass — 01-Plan/plan.md exists`, `pass — summary.md + manifest "03 Implementation: complete"`, `fail — findings.json has open statuses`. Per-stage checks: `references/conductor.md` § 4.
- **Spend (est)** — heuristic band per `references/rigor-levels.md` § Cost bands (refined by observed usage where the host surfaces it); always an estimate, never presented as measured.
- **Notes** — short facts a resume or report needs: assumption-row count, phases committed, blocked clusters, blocker-report path, re-dispatch note.

## Blockers

Every blocker any stage reported, HALT and CONTINUE alike, each with its report path (the run report reproduces this table).

| Stage | Policy | Report | Note |
|---|---|---|---|
| — | — | — | — |

## Review loop

*Only when the level runs a code review (`references/loop-and-budget.md` § 1). One row per review round.* The **Snapshot** is written when the round's re-review record goes `in-flight` — **before** the subagent launches — so a crash mid-round is detectable (round-aware advance test, § 1.2); round 1 uses the plain advance test (no snapshot). **Non-`fixed`** = findings in `findings.json` with status ≠ `fixed`, counted right after the round's review/re-review passes its advance test.

| Round | Snapshot (max CR id · count · `reviewed` · findings/cert mtimes) | Fresh CR ids | Non-`fixed` | Certificate | Decision |
|---|---|---|---|---|---|
| 1 | — | CR-001..CR-NNN | N | <PASS \| FAIL> | <triage → bugfix> |

- **Decision** values: `triage → bugfix` (round 1, per the map) · `re-review (round N+1)` · `exit → docs` · `loop done (cap 0)` · `HALT — unresolved Blockers` · `HALT — convergence failure (cap <re_review_cap> reached)`.

## Spend

Running total: <~N tokens est> — sum of completed records' estimates; uncalibrated heuristic (`references/rigor-levels.md` § Cost bands).

**Budget events** *(only on `--budget` runs — boundary checks that changed the run; `references/loop-and-budget.md` § 2)*

| Boundary (before stage) | Running total | Ceiling | Action |
|---|---|---|---|
| — | — | — | — |

- **Action** values: `paused — notified, waiting` · `resumed` · `ceiling raised to ~<band>` · `ceiling removed` (resume actions are Phase 6's).
