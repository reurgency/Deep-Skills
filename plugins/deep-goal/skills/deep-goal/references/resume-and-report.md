# Resume & final run report

The conductor's two bookends: **re-entry** (§ 1 — crash-safe resume from `00-Manifest/pipeline.md`, contract rows #3 and #8) and the **final run report** (§ 2 — the completion artifact that surfaces everything autonomous mode decided alone, contract row #6). `references/conductor.md` § 7 is the summary; this file is the spec. Everything here reads the state Phases 4–5 already persist — `pipeline.md` (`templates/pipeline.md`), `findings.json`, the plan's Assumptions section — and **never re-derives what the header recorded**.

## 1. Re-entry protocol

### 1.1 Detection — the FIRST launch check

Before anything else in the launch sequence (`references/conductor.md` § 1 — before rigor resolution, before the handshake), check for prior state:

- **Invocation targets an effort** (an `--effort`/named effort, or a goal whose derived slug matches an existing effort dir) **whose `00-Manifest/pipeline.md` exists** → re-entry (§ 1.2).
- **Bare resume invocation** ("resume deep-goal", "continue the run", re-invoking after a pause notification) → scan `.deep-skills/*/00-Manifest/pipeline.md` for **open runs**: any dispatch record not `complete`, or all records `complete` with a HALT Blockers row or no `run-report.md` yet. Exactly one open run → target it. Several → the re-entry question carries one resume option per open run (previews per § 1.2). None → say so; nothing to resume.
- **No prior pipeline.md** for the targeted effort → not a re-entry; the normal launch sequence continues.
- **`--dry-run` never re-enters** — it prints the preview and stops, touching nothing, prior state or not.

A run that already completed cleanly (all records `complete`, `run-report.md` written, no HALT row) is not resumed and not archived unprompted: announce it is done, point at `00-Manifest/run-report.md`, and ask nothing further unless the user asks for a fresh run.

### 1.2 The re-entry question — one, self-contained

Announce prior state and offer **resume / fresh** as **one structured question** (host-affordances: native structured-question tool, numbered-list chat fallback). It is **self-contained**: each option's description/preview (**≤ 15 lines** — hosts truncate beyond that) carries the prior-state summary a decision needs, never between-tool-call prose — rigor + source, records complete/total, the resume point (first non-`complete` record, its status, and what resuming does to it per § 1.3), any Blockers rows, budget state (ceiling · running total · paused boundary), unfired gates, worktree path, spend so far. Trim the completed-stages list first when squeezing under 15 lines.

- **Resume** (recommended default) — continue per § 1.3. On a **budget-paused** run the resume options also cover the ceiling: keep it (warn: still crossed → it pauses again immediately), raise it, or remove it — either as option variants or honoring a ceiling stated in the invocation itself ("resume with a 1m budget"); any change is logged as a Budget events row (`ceiling raised to ~<band>` / `ceiling removed`) before the boundary re-check.
- **Start fresh** — archive `00-Manifest/pipeline.md` to **`00-Manifest/pipeline-archived-<n>.md`**, where `<n>` = 1 + the highest existing archive number (`pipeline-archived-1.md` first; no timestamps), then fall through to the normal launch sequence from the top (rigor re-resolved, handshake re-run, a new pipeline.md written). Fresh archives **only the pipeline state** — the manifest, plan, and stage artifacts remain, and the new run re-plans and re-runs stages over them per each skill's own semantics (re-reviews append findings; bugfix appends round dirs) — the fresh option's preview must say so.
- **Loop-halt runs** (all records `complete` but the run halted via a HALT Blockers row from the convergence machinery — cap-1 certificate FAIL, or cap-≥2 convergence failure): the resume choice splits into two options — **one more round** (triage → bugfix → re-review at the level's own entry; the human's explicit choice overrides the cap **once per re-invocation**, recorded in the new records' Notes as `resume: user authorized round N past cap/halt`) or **exit to docs** (proceed to the remaining map stages, all non-`fixed` findings reported as residuals). Both stay inside the same question.

### 1.3 The resume walk

**Honor persisted state — re-read, never re-derive.** The pipeline.md header and Stage list table are authoritative: rigor + the resolved stage list (never re-resolve the map), the deep-skills plugin location and version outcome (never re-discover), gates, budget ceiling, worktree path. Exception — a persisted **path that no longer exists on disk**: the deep-skills location gone → re-run discovery (`conductor.md` § 1a) and update the header; the worktree path gone → recreate the same tree from its recorded branch (`git worktree add <recorded-path> deep-goal/<effort>` — the commits live in the branch, not the tree), still never a *second* worktree.

**Resume point = the first dispatch record that is not `complete`** (`pending`, `in-flight`, or `halted` — inline stages have records too, so a crash during mvp/prod planning resumes correctly). Action by what is found:

| Found | Meaning | Resume action |
|---|---|---|
| `pending` record | stopped at a boundary — crash, budget pause, or gate stop before dispatch | **Re-enter AT that boundary**, running its checks in the Phase-5 order (`loop-and-budget.md` § 6): budget check first, against the current — possibly just-raised — ceiling (still crossed → pause again, notify with a raise hint); then the gate check — a gate set before this stage **re-fires** unless the record's Notes already show `gate: approved`; then mark `in-flight` and dispatch normally. |
| `in-flight`, artifacts **complete** (advance test passes) | the stage finished; the crash hit between finish and record update | **The idempotency rule:** mark the record `complete` (advance-test result; Notes `resume: found complete, not re-dispatched`) and advance to the next boundary. Never re-dispatch. |
| `in-flight`, artifacts **incomplete** | the stage died mid-flight | **Re-dispatch the same stage once** (same briefing, re-rendered from the persisted header + map entry), leaning on the skill's internal resume (table below). Fails its advance test again → HALT-class blocker per `conductor.md` § 4. |
| `halted` record | the stage failed its advance test / hit a blocker; the human has since intervened (their re-invocation says so) | Re-dispatch that stage; its internal resume picks up from what stands (e.g. deep-implement re-entering at the blocked phase after the human unblocked it). The Blockers row stays as history; the new outcome writes a fresh record completion. |
| all `complete` + HALT Blockers row (loop halt) | the *run* halted at the loop exit, not a stage | Per the re-entry question's loop-halt options (§ 1.2): one more round, or exit to docs. |
| all `complete`, no HALT row, **no `run-report.md`** | crash between the last stage and the report | Run the completion sequence (§ 2.1) — resume's cheapest case. |

**Round-aware, always:** when the record in question is a review round ≥ 2, "artifacts complete" is **never bare artifact existence** (vacuously true from round 2) — it is the **round-aware test** against the snapshot in that round's Review loop row (`loop-and-budget.md` § 1.2): fresh CR ids or status changes AND an updated `reviewed` date / mtimes. A crash mid-re-review therefore re-dispatches; it never marks an un-run round complete.

**What each core skill's internal resume gives you** (why one re-dispatch is safe):

| Re-dispatched stage | Internal resume mechanism |
|---|---|
| `plan` (autonomous) | none needed — `plan.md` is the only output; the planner re-runs clean, nothing partial to reconcile |
| `plan` (interactive, mvp/prod) | not a dispatch: **re-open the inline planning window** — the user re-invoking *is* the interactivity; run deep-plan inline with `--effort=<slug>` from the header (the name was already settled — no re-confirmation) and the map's `--rounds`/columbo |
| `plan-review` | re-runs whole (single review artifact; rewrite is safe) |
| `implement` | plan.md § Phase Summaries — completed phases stand; it re-enters at the first unfinished phase, no duplicate commits |
| `code-review` (review) | re-runs the round; report/certificate are rewritten for the round, findings append per the round contract |
| `code-review (triage)` | naturally idempotent — only `open` findings get flipped; prior statuses are preserved by contract |
| `bugfix` | `06-Bug-Fix/round-N/scope.json` — the round's scope is fixed at intake; re-entry resumes the round's remaining clusters |
| `docs` | deep-docs `--refresh` semantics — incremental over the existing `docs/ai-map/` |

**Double-dispatch guard, re-entry edition:** within a live session, `conductor.md` § 3's guard *announces* an in-flight stage rather than dispatching beside it. On re-entry the human's re-invocation is the evidence the prior conductor died — so the question announces the in-flight record (and whether its artifacts check out), and choosing Resume either completes it (idempotency row) or re-dispatches it (died mid-flight row). Exactly one re-dispatch per resume per stage; a stage is never dispatched while another record is `in-flight`.

**What resume never does:** re-ask rigor · re-derive the header · archive anything (that is fresh's job) · rewrite a `complete` record · re-fire an approved gate · create a second worktree or effort dir · dispatch past a boundary whose checks fail.

## 2. The final run report

The report is the run's accountability artifact: at yolo/poc **nobody was watching** — every decision the pipeline made alone (assumptions, auto-deferrals, blocker continuations) must surface here, loudly, or it never surfaces at all.

### 2.1 When and how — the completion sequence

The run **completes** when the last record of the resolved walk is `complete` (docs at mvp/prod; the loop's last stage at poc; implement at yolo — including a resumed run reaching that point, or a loop-halt resume exiting to docs). Then, in order:

1. **Write `00-Manifest/run-report.md`** from `templates/run-report.md`, assembled per § 2.2 — from artifacts only (pipeline.md, plan.md, findings.json, the code tree), never from subagent narratives.
2. **Update the manifest effort summary paragraph** in `00-Manifest/manifest.md` — **the conductor's ONLY manifest write, ever**: replace/write the one-paragraph effort summary (outcome, rigor, what shipped, residual counts, pointer to `run-report.md`). Stage lines stay untouched, as always.
3. **Completion notification** — the fourth and final trigger of `loop-and-budget.md` § 4, its mechanics and example line.
4. **Deliver the report as the closing message** — the full rendered report, not a pointer, as the final message of the turn (final messages are the one channel every host reliably renders; between-tool-call prose is not).

**HALTed runs get no report** — the halted `pipeline.md` is the state, and the HALT notification already carried the actionable fact; the report is written once, at completion (a resumed run writes it when it *reaches* completion). A re-invocation of a run that already completed announces it and points at the existing report (§ 1.1) — it never rewrites it.

### 2.2 Contents — section by section, each with its source of truth

| Section | Source of truth | Rules |
|---|---|---|
| **Header** | pipeline.md header + records | goal, rigor + source, outcome (`complete — N/N dispatches` or `complete with CONTINUE blockers`), links to pipeline.md + manifest.md. |
| **Stages run** | dispatch records + the artifact tree + the code tree | one row per dispatch record: stage · status · artifact link (canonical path, `references/artifact-structure.md`) · commits · spend. Commits are read from the code tree (`git log` on the run's branch — the worktree branch on `--worktree` runs) and attributed per stage via the stage's own artifacts (implement's `summary.md` per-phase commits; bugfix's `fix-summary.md`); `—` for stages that commit nothing. |
| **Assumptions** | `01-Plan/plan.md` § Assumptions | reproduced **VERBATIM — every row, unchanged, same columns** (`# · Question · Chosen answer · Why`, the plan-template shape). **The run report is this ledger's canonical reader** (contract row #6): an autonomous plan's self-answered questions surface here or nowhere. Interactive planning (no Assumptions section in the plan) → state `None — planning was interactive at this rigor; these calls were the user's.` |
| **Auto-deferred findings** | `findings.json` entries with `status: deferred` — **the source of truth**; the plan's Deferreds ledger is display-only derived state | **every** deferred finding, each with its **numeric severity** (+ tier as presentation): id · severity · one-line summary. Deferred ≠ rejected — nothing is ever auto-rejected. If findings.json and the plan's ledger disagree, report findings.json and note the drift. |
| **Residual open findings** | `findings.json` entries still `open` at completion | e.g. an mvp final re-review's fresh findings — never triaged **by design** (`loop-and-budget.md` § 1.4, cap 1); listed with severity and marked `open — never triaged`. Empty at clean convergence. |
| **Blockers** | pipeline.md Blockers table | reproduced whole: stage · **policy** (HALT/CONTINUE) · **report path** · note — every blocker, both classes, each with its report path. `None` when empty. |
| **Review loop** | pipeline.md Review loop table | the loop ledger reproduced — round · fresh CR ids · non-`fixed` count · certificate · decision (the Snapshot column stays in pipeline.md; it is plumbing, not outcome). Omit the section when the level ran no code review. |
| **Spend** | dispatch records' Spend (est) + the Spend running total | per-stage + total, **always with the uncalibrated caveat** (heuristic bands per `rigor-levels.md` § Cost bands — estimates, never measurements). On `--budget` runs, the ceiling and the Budget events log ride along. |
| **Worktree** | pipeline.md header Worktree slot | **required whenever set** (`loop-and-budget.md` § 5): absolute path, branch, and merge instructions — review the branch, merge or PR it, then `git worktree remove <path>`; the conductor never deletes it. Omit the section when no worktree. |

The template (`templates/run-report.md`) carries this structure as fill-in slots; every value above is assembled at completion time — the template itself has no time-variant content.
