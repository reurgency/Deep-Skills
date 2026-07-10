# Training: `/deep-goal` (optional add-on)

> Part of the [Deep Skills Training Program](README.md). **Not one of the six bundled skills** —
> `/deep-goal` is an **optional, paid add-on plugin** that conducts the six.
> Source: [`plugins/deep-goal/skills/deep-goal/SKILL.md`](../../plugins/deep-goal/skills/deep-goal/SKILL.md)
> · Hosts: [`plugins/deep-goal/HOSTS.md`](../../plugins/deep-goal/HOSTS.md) (Claude Code is the verified floor)

`/deep-goal` runs one effort through the **whole deep-\* relay from a single invocation** —
plan → plan-review → implement → code-review → bugfix → docs — with a **rigor level**
(`yolo` / `poc` / `mvp` / `prod`) selecting, as data, which stages run, how interactive planning
is, what auto-triage accepts, and how many review→fix rounds the loop may take. It is a
**thin conductor**: it sequences and verifies; it never writes plans, source, reviews, or docs
itself. It requires the deep-skills plugin **≥ 0.2.0** (verified at launch); the six core skills
never require it back.

---

## Learning objectives

By the end you can:

1. Choose a **rigor level** deliberately — and read the resolved pipeline with `--dry-run`
   before spending anything.
2. Explain the **conductor mental model**: thin walker, artifacts as the only inter-stage
   channel, and the **advance test** (artifact exists AND manifest line flipped — never a
   subagent's word).
3. Locate the **interactivity boundary** — all human interaction happens in the planning
   window; autonomy starts the moment `plan.md` exists — and know the only things that wait
   after it (your `--gate`s and `--budget` pauses).
4. Predict what the **review→fix loop** does at each rigor: triage thresholds, the re-review
   cap, and convergence vs. halt.
5. Classify a blocker as **spine (HALT)** vs **tail (CONTINUE)** and know what the conductor
   does in each case.
6. **Resume** a killed, paused, or halted run from `pipeline.md`, and read a **run report**
   for everything the pipeline decided alone.

## Prerequisites

All six skill pages — deep-goal dispatches the six skills you already know, unchanged, and its
vocabulary (manifest, findings.json statuses, certificate, Deferreds ledger, fix rounds) is
theirs. Especially: [`/deep-plan`](deep-plan.md)'s `--autonomous` mode and
[`/deep-code-review`](deep-code-review.md)'s `--triage --auto-accept-min` auto-policy — the two
core capabilities the conductor leans on (both free-tier features in their own right).

---

## Mental model

**The conductor is thin on purpose.** It resolves the rigor level to a stage list **from data**
(`templates/rigor-map.json`; a repo can override it at `.deep-skills/rigor-map.json`), then
walks the list: **interactive stages run inline** (planning at mvp/prod — you are present by
definition), **autonomous stages each get one fresh subagent** briefed with a minimal stage
briefing (skill name, effort, flags, worktree). Nothing travels between stages except
**artifacts under `.deep-skills/<effort>/`** — never transcripts (the series invariant).

Two rules make it trustworthy:

- **The advance test.** After every stage the conductor verifies, with its own reads, that the
  expected artifact exists at its canonical path AND the skill flipped its own manifest line.
  A subagent's closing narrative is not evidence. (Re-review rounds use a round-aware variant,
  since review artifacts aren't round-versioned.)
- **The interactivity boundary.** Every question you'll be asked happens in the inline planning
  window. From the moment `01-Plan/plan.md` exists, the run is autonomous: no unsolicited
  questions — the conductor only *notifies* (halts, gates, budget pauses, completion), and only
  *waits* where you asked it to (`--gate`, `--budget`).

State lives in **`00-Manifest/pipeline.md`** — conductor-written, updated at every stage
boundary. Kill the run at any point; re-invoking deep-goal resumes from it.

---

## Curriculum

### Module 1 — The rigor dial (config-as-data)
One flag selects everything that varies between a throwaway spike and a production change.
The four shipped levels (exact stage lists live in `rigor-map.json`, never in prose):

| Rigor | Intent | Planning | Auto-triage accepts | Re-reviews |
|---|---|---|---|---|
| `yolo` | spikes, throwaways | autonomous | n/a (no review) | none |
| `poc` | prototypes you might keep | autonomous + columbo | Blockers only (≥ 9) | 0 |
| `mvp` | **recommended default** | interactive, 1 round | Blocker + Major (≥ 7) | exactly 1 |
| `prod` | changes where wrong is expensive | interactive, 3 rounds; multi-agent reviews | down to Minor (≥ 5) | converge, cap 3 |

Below-threshold findings are **auto-deferred** (Deferreds-ledger row, reported loudly) —
**never auto-rejected**. A repo override can add or reshape levels at level granularity;
it is validated **at launch, never mid-run** (`references/rigor-levels.md`).

### Module 2 — Launch: handshake, resolution, dry-run
At launch the conductor: checks for a prior `pipeline.md` (re-entry — Module 8) → resolves
rigor from the merged map (omitted → one structured question, recommending mvp, every option
self-contained) → runs the **version handshake** (deep-skills ≥ 0.2.0; refuses politely when
absent/below; a version-less dev install passes with a logged warning) → settles the effort
slug → writes the initial `pipeline.md`. **`--dry-run` prints the resolved pipeline with cost
bands and stops** — it dispatches nothing, writes nothing, and skips the handshake entirely.
Make previewing a habit: it is the cheapest question you can ask the add-on.

### Module 3 — The planning window
Branch on the plan stage's `mode`: **autonomous** (yolo/poc) dispatches
`deep-plan --autonomous --effort=<slug>` (+ `--columbo` per the map) — zero questions; every
self-answered decision lands as an **Assumptions** row in the plan, and the run report
reproduces them verbatim. **Interactive** (mvp/prod) runs `/deep-plan` inline with
`--rounds=<n>` from the map — normal planning, your answers. Either way the planning record
completes when `plan.md` exists — the autonomy boundary.

### Module 4 — Dispatch and the advance test
Each remaining stage: mark `in-flight` → render the stage briefing (the subagent's **entire
prompt**) → one fresh subagent → advance test → complete the record. One stage in flight at a
time, ever. Triage is a **second dispatch** of deep-code-review
(`--triage --auto-accept-min=<N>`), tested on findings.json statuses + the certificate's
Triage outcomes table — it has no manifest line of its own. The conductor is **read-only on
manifest stage lines**; its only manifest write, ever, is the effort summary paragraph at
completion.

### Module 5 — The review→fix loop
Round 1 = code-review → auto-triage → bugfix — with the **empty-set short-circuit** every
round: nothing `open` → triage is skipped, nothing `accepted`-and-unfixed → bugfix is skipped
and the loop exits by cap (a clean review is a healthy run, never a halt). Re-review rounds reuse the level's own
code-review entry (same mode, same threshold) and are judged by the **round-aware advance
test** — a pre-dispatch snapshot of findings.json's CR ids / count / `reviewed` date, so a
crash mid-round never marks an un-run round complete. Exit keys off the map's
`re_review_cap`: **0** → done after bugfix; **1** (mvp) → one re-review, HALT only on
unresolved Blockers, else exit to docs with residuals reported; **≥ 2** (prod) → converge on
certificate PASS + strictly fewer non-`fixed` findings each round — cap breached = HALT as a
convergence failure. (`references/loop-and-budget.md`.)

### Module 6 — Blocker policy (severity-aware)
Classified by **where in the spine it happened**: upstream blockers poison everything after
them; tail blockers are self-contained.

- **HALT + notify (spine):** plan-review Blocker verdict; implement phase blocked at the fix
  cap. Downstream stages would review rubble — the halted `pipeline.md` is the resume point.
- **CONTINUE + record (tail):** an unproven bugfix cluster (clusters are independent); docs
  anchor drift (a docs-only failure). The run finishes and the report lists them loudly.

Every blocker — both classes — lands in `pipeline.md` and the run report **with its
blocker-report path**.

### Module 7 — Budget, gates, worktree, notifications
The boundary machinery (all NL-first — see Flags):

- **`--budget`** — a soft, estimate-based token ceiling checked **between stages only** (a
  dispatched stage always finishes). Crossed → pause + notify; re-invoke to resume, raise, or
  stop.
- **`--gate=<stage>`** — a human checkpoint before a named stage, even in an autonomous run.
  Fires once, persisted so resume honors it.
- **`--worktree`** — the conductor creates **one** worktree after planning; implement, both
  review dispatches, bugfix, and docs all work in that same tree, so reviews see implement's
  commits naturally. The report ends with the path + merge instructions.
- **Notifications** fire on exactly four triggers — halts, gates, budget pauses, completion —
  never routine stage completions. `pipeline.md`'s status table is the spinner; ask for status
  in natural language any time.

### Module 8 — Resume and the run report
Re-invocation with an existing `pipeline.md` announces prior state and asks **resume / fresh**
(fresh archives the old pipeline state; artifacts remain). Resume re-enters at the first
non-`complete` record: finished-but-unrecorded stages are recognized and skipped (idempotency);
died-mid-flight stages are re-dispatched once on the core skill's own internal resume. At
completion the conductor writes **`00-Manifest/run-report.md`** — the accountability artifact:
at yolo/poc nobody was watching, so every Assumption (verbatim), every auto-deferred finding
(with severity), every blocker (with path), spend by stage, and the worktree hand-off surface
here or nowhere. Read it end-to-end after every autonomous run.

---

## Flags (know which to reach for)

Every flag is **natural-language-first** — the plain-language trigger is the primary path
(Copilot/Codex users have no CLI flags); `--flag` syntax is a convenience on top.

| Flag | Say | What it does |
|---|---|---|
| *(goal argument)* | *"run deep-goal on \<feature\>"* | The feature/goal to take through the pipeline. |
| `--rigor=<level>` | *"at mvp rigor"*, *"yolo it"* | Select the rigor level. Omitted → one structured question (recommends mvp). |
| `--dry-run` | *"preview the run"*, *"what would a prod run do"* | Print the resolved pipeline + cost bands and stop. Dispatches nothing; exempt from the version handshake. |
| `--budget=<band>` | *"cap spend at ~500k tokens"* | Soft token ceiling, checked between stages; crossing pauses + notifies; resume continues. |
| `--gate=<stage>` (repeatable) | *"pause before implement"* | Inject a human checkpoint before a named stage; persisted, honored on resume; fires once. |
| `--worktree` | *"build in a worktree"* | One conductor-owned worktree for all post-planning stages; report carries merge instructions. |

The conductor also *dispatches* core flags you already know (`deep-plan --autonomous
--effort=<slug> --columbo --rounds=<n>`, `deep-code-review --triage --auto-accept-min=<sev>`)
— those are free-tier deep-skills features, documented on their own skill pages.

---

## Directive cards

deep-goal carries its **own** Deep-Learn registry (`plugins/deep-goal/directives/`), loaded by
the same byte-identical self-locating loader as the core skills — and it ships **empty in v1**.
It never reads the core deep-skills registry (cross-registry cards are a tracked deferred). See
the [Deep-Learn overview](README.md#deep-learn--the-self-improving-directive-loop).

---

## Hands-on exercises

1. **Dry-run all four:** run `--dry-run` at yolo, poc, mvp, and prod on the same feature.
   For each, name what changed and *why that rigor wants it* (stage list, triage threshold,
   re-review cap, planning rounds).
2. **Rigor call:** for (a) a throwaway benchmark script, (b) an internal admin page, (c) a
   billing change — pick a rigor and justify it against the cost bands.
3. **Custom level:** author a `.deep-skills/rigor-map.json` override adding a `poc-reviewed`
   level (interactive plan + plan-review at poc speed); confirm it appears in `--dry-run` and
   name what the launch validation would refuse if you typo'd a stage name.
4. **Blocker triage:** for each — plan-review reports 2 Blockers; implement Phase 3 hits the
   fix cap; one bugfix cluster is unproven; docs publish blocked on drift — say HALT or
   CONTINUE, and what appears in `pipeline.md`.
5. **Kill and resume:** run an mvp effort, kill the session mid-implement, re-invoke. Verify
   the run resumes at implement with no duplicate commits, and trace *why* (advance test +
   deep-implement's phase summaries).
6. **Report audit:** take a completed poc run report and list every decision the pipeline made
   alone — Assumptions, auto-deferrals — and decide which ones you'd have made differently.

---

## Common mistakes

- **Treating deep-goal as a seventh skill** — it's an optional add-on conductor; the six core
  skills work identically without it (and never require it).
- **Reaching for yolo/poc on work that matters** — autonomous planning means the plan's
  Assumptions were nobody's decisions but the model's. Read them in the run report; better,
  use mvp and be present for planning.
- **Skipping `--dry-run`** and being surprised by what prod dispatches (multi-agent reviews ×
  loop rounds is the expensive corner).
- **Expecting mid-run questions** — after `plan.md` exists the conductor won't ask; if you
  wanted a checkpoint, that's `--gate` (say *"pause before implement"*), set at launch.
- **Trusting a subagent's "done"** — the conductor never does; neither should you. The advance
  test (artifact + manifest flip) is the only evidence.
- **Hand-editing `pipeline.md`** or another skill's manifest line — pipeline state is
  conductor-owned; stage lines are each skill's own.
- **Ignoring auto-deferred findings** because the run "passed" — deferral is loud by design;
  the run report lists every one with severity. Triage them like you would any Deferreds row.
- **Running prod rigor on a non-Claude-Code host** and hitting context limits — the inline
  fallback is functional but honestly caveated; see
  [`plugins/deep-goal/HOSTS.md`](../../plugins/deep-goal/HOSTS.md).

## Mastery checklist

- [ ] Previewed with `--dry-run` and chose a rigor deliberately, against the cost bands.
- [ ] Ran an mvp effort end-to-end from one invocation; answered questions only in the
      planning window.
- [ ] Read a run report and accounted for every Assumption and auto-deferred finding.
- [ ] Correctly predicted HALT vs CONTINUE for a spine and a tail blocker.
- [ ] Killed and resumed a run with no duplicated stage side effects.
- [ ] Authored a repo rigor override that survives launch validation.

## Quick reference

| | |
|---|---|
| Input | A goal/feature + a rigor level (`yolo` / `poc` / `mvp` / `prod`, or a repo-defined level) |
| Output | The six skills' own artifacts, plus `00-Manifest/pipeline.md` (state) and `00-Manifest/run-report.md` (accountability) |
| State | `pipeline.md` — every boundary; kill + re-invoke = resume |
| Interactivity | Planning window only; then gates and budget pauses, nothing else waits |
| Advance test | Artifact at canonical path AND manifest line flipped (round-aware in the loop) |
| Hard rules | Never writes code/plans/reviews/docs; read-only on stage lines; artifacts are the only inter-stage channel; refuses at launch, never mid-run |
| Requires | deep-skills ≥ 0.2.0 (verified at launch); the core skills never require deep-goal |
| Hosts | Claude Code = verified floor; others inline-sequential — [`plugins/deep-goal/HOSTS.md`](../../plugins/deep-goal/HOSTS.md) |

⬅ Back to the [Training Program](README.md) — or run the six-skill capstone by hand first;
deep-goal will feel earned.
