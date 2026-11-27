# Training: `/deep-goal` (optional add-on)

> Part of the [Deep Skills Training Program](README.md). **Not one of the six bundled skills** —
> `/deep-goal` is an **optional, free add-on plugin** that conducts the six.
> Source: [`plugins/deep-goal/skills/deep-goal/SKILL.md`](../../plugins/deep-goal/skills/deep-goal/SKILL.md)
> · Hosts: [`plugins/deep-goal/HOSTS.md`](../../plugins/deep-goal/HOSTS.md) (Claude Code is the verified floor)

`/deep-goal` runs one effort through the **whole deep-\* relay from a single invocation** —
plan → plan-review → implement → code-review → bugfix → docs — with a **rigor level**
(`yolo` / `poc` / `mvp` / `prod`) selecting, as data, which stages run, how interactive planning
is, what auto-triage accepts, and how many review→fix rounds the loop may take. It is a
**thin conductor**: it sequences and verifies; it never writes plans, source, reviews, or docs
itself. It requires the deep-skills plugin **≥ 0.3.0** (verified at launch); the six core skills
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
7. Explain **model allocation**: the three fixed model levels (smartest / smarter / smart),
   how `--max` picks the model each stage runs on, what your current model still decides
   (the recommended `--max`, and interactive planning, which runs in your session) — and read
   the **launch card** before anything runs.
8. **Hand off a plan you made yourself** — finish an interactive `/deep-plan`, then let
   deep-goal run the rest with `--from-plan`.

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

**Model allocation is a second axis, orthogonal to rigor.** Rigor picks *which* stages run and
whether they fan out; **`--max`** picks *what model each stage runs on*. deep-goal uses the same
model map as every deep-skills skill (`references/model-map.json` for the models,
`references/model-map.md` for the rules), with three levels pinned to specific models — they
don't shift with the model you happen to be chatting in:

| Level | Claude | GPT |
|---|---|---|
| **smartest** | Fable 5.2 (then Fable 5) | GPT-6.2 Astra (then GPT-6 Astra, GPT-5.6 Sol) |
| **smarter** | Opus 5.5 (then Opus 5) | GPT-6.2 Sol (then GPT-6 Sol, GPT-5.6 Terra) |
| **smart** | Sonnet 5.5 (then Sonnet 5) | GPT-6.2 Terra (then GPT-6.1 Terra) |

A run stays in your session's model family. Smart is the floor — small models (Haiku,
GPT Luna/mini/nano) never run. What each stage runs on, by `--max` (Claude models shown):

| Stage | `--max=smartest` | `--max=smarter` | `--max=smart` |
|---|---|---|---|
| plan | Fable 5.2 | Opus 5.5 | Sonnet 5.5 |
| plan review | Fable 5.2 | Opus 5.5 | Sonnet 5.5 |
| implement | Opus 5.5 | Opus 5.5 | Sonnet 5.5 |
| code review (+ triage, re-reviews) | Fable 5.2 | Opus 5.5 | Sonnet 5.5 |
| bug fix | Opus 5.5 | Opus 5.5 | Sonnet 5.5 |
| docs | Sonnet 5.5 | Sonnet 5.5 | Sonnet 5.5 |

The principle: **planners and reviewers ≥ builders ≥ documenters.** Every stage is also told
your `--max`, so its own helper agents pick their models exactly as the skill would standalone
(e.g. code review's quality checker runs on Sonnet 5.5).

**Your current model** sets two things: the **recommended `--max`** (its own level — omit the
flag and deep-goal asks, recommending it), and **whatever runs in your session** — the conductor
itself and **interactive planning at mvp/prod**, which runs inline because you're present. If
your model is below the planning level you chose, the launch card suggests switching with
`/model` (or your assistant's model picker) first. A run may put stages *above* your current
model — that's intended. On hosts that can't run background agents (Codex, Cursor, Copilot
today), each stage's lead runs in your session too, while its helper agents still use the level
you chose. **If you can't reach a model** (your plan or org blocks it), the stage tries the same
level's previous generation, then the next level down — never below smart — and `pipeline.md`
and the run report record the model that actually ran (e.g. "smartest ran on Fable 5").

**Customizing:** a `.deep-skills/model-map.json` at your repo root repins a model or moves a
stage's level — for every deep-skills skill and deep-goal. Only the keys you change; it merges
over the shipped map and is validated at launch. Example — run docs on Opus 5.5 when you choose
smartest:

```json
{"stages":{"smartest":{"docs":"smarter"}}}
```

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

### Module 2 — Launch: questions, handshake, the launch card, dry-run
At launch the conductor: checks for a prior `pipeline.md` (re-entry — Module 8) → if rigor
and/or `--max` are missing, asks them as **one batched question set** (rigor recommends mvp;
max recommends your current model's level, each choice previewing the model every stage would
run on) → resolves each stage's model (`--dry-run` stops here) → runs the **version handshake**
(deep-skills ≥ 0.3.0; refuses politely when absent/below; a version-less dev install passes
with a logged warning) → derives the effort name → shows the **launch card**:

```
Goal: <one sentence>
Effort: <slug>
Rigor: mvp · Max: smarter · Your session: Opus 5.5
Plan: inline on your session (Opus 5.5)
Plan review: smarter - Opus 5.5
Implement: smarter - Opus 5.5
Code review (+ triage, re-reviews): smarter - Opus 5.5
Bug fix: smarter - Opus 5.5
Docs: smart - Sonnet 5.5
```

…plus at most one warning line (e.g. your model is below the planning level, or the host runs
every step in your session). **At mvp/prod the card waits for one answer:** Launch (also
confirms the effort name) · Change rigor or max · Edit goal or name · Cancel — nothing is
written to disk before Launch, so cancelling is always clean. **At yolo/poc it prints and goes.**
The card replaces deep-plan's own goal-confirmation question — deep-goal passes `--confirmed`
so you aren't asked twice. **`--dry-run` prints the resolved pipeline, with the model each stage
would run on and cost bands, and stops** — it dispatches nothing, writes nothing, and skips the
handshake entirely. Make previewing a habit: it is the cheapest question you can ask the add-on.

### Module 3 — The planning window
Branch on the plan stage's `mode`: **autonomous** (yolo/poc) dispatches
`deep-plan --autonomous --effort=<slug>` (+ `--columbo` per the map) — zero questions; every
self-answered decision lands as an **Assumptions** row in the plan, and the run report
reproduces them verbatim. **Interactive** (mvp/prod) runs `/deep-plan` inline with
`--rounds=<n>` from the map — normal planning, your answers, **on your current model** (it runs
in your session). Either way the planning record completes when `plan.md` exists — the autonomy
boundary.

**Already planned? Continue from your plan.** Plan interactively with `/deep-plan` on its own;
when it finishes it offers to *"run the remaining stages autonomously with deep-goal"* (only
when deep-goal is installed, and only for an interactive, standalone plan). Saying yes — or
later saying *"continue from my plan"* / `--from-plan[=<path>]` — makes deep-goal **adopt** that
plan (`.deep-skills/<effort>/01-Plan/plan.md`) instead of planning again: the plan stage is
recorded `complete (adopted)` and the run starts at **plan review** (mvp/prod) or **implement**
(yolo/poc). With no path, deep-goal finds the plan, or asks which one if there are several.

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
  review dispatches, bugfix, and docs all work in that same tree (plan-review's briefing
  carries it too — inert for a read-only stage), so reviews see implement's commits naturally.
  The report ends with the path + merge instructions.
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
| `--rigor=<level>` | *"at mvp rigor"*, *"yolo it"* | Select the rigor level. Omitted → asked before launch, together with `--max` if that's missing too (recommends mvp). |
| `--max=<smartest\|smarter\|smart>` | *"use the smartest models"*, *"keep it to smarter models"*, *"max smart"* | The highest model level any stage may use. With smartest: planning, plan review and code review on Fable 5.2, building and bug fixing on Opus 5.5, docs on Sonnet 5.5. Omitted → asked (recommends your current model's level). The phrase must name a level. |
| `--from-plan[=<path>]` | *"continue from my plan"* | Adopt a plan you already made with `/deep-plan` instead of planning again; starts at plan review (mvp/prod) or implement (yolo/poc). |
| `--dry-run` | *"preview the run"*, *"what would a prod run do"* | Print the resolved pipeline — each stage with the model it would run on — plus cost bands, and stop. Dispatches nothing; exempt from the version handshake. |
| `--budget=<band>` | *"cap spend at ~500k tokens"* | Soft token ceiling, checked between stages; crossing pauses + notifies; resume continues. |
| `--gate=<stage>` (repeatable) | *"pause before implement"* | Inject a human checkpoint before a named stage; persisted, honored on resume; fires once. |
| `--worktree` | *"build in a worktree"* | One conductor-owned worktree for all post-planning stages; report carries merge instructions. |

The conductor also *dispatches* core flags you already know (`deep-plan --autonomous
--effort=<slug> --columbo --rounds=<n> --confirmed`, `deep-code-review --triage
--auto-accept-min=<sev>`, and `--max=<level>` on every stage)
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
7. **Model call:** from a Sonnet 5.5 session, dry-run an mvp effort at `--max=smartest`, then at
   `--max=smart`. Predict each stage's model before reading the output, and name the one stage
   whose model the dry-run can't change (interactive planning — it runs in your session).

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
- **Assuming your current model decides what every stage runs on** — it only sets the
  recommended `--max` and what runs in your session (the conductor and interactive planning).
  Starting in Sonnet 5.5 with `--max=smartest` still builds on Opus 5.5 and reviews on
  Fable 5.2. To change what runs where, pick a different `--max` (or repin it in
  `.deep-skills/model-map.json`).
- **Planning at mvp/prod below the level you chose** — interactive planning runs in your
  session. If the launch card warns that your model is below the planning level, switch with
  `/model` (or your assistant's model picker) *before* Launch.
- **Re-planning work you already planned** — if you ran `/deep-plan` yourself, say *"continue
  from my plan"* (`--from-plan`) instead of starting deep-goal from scratch.
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
- [ ] Read a launch card and predicted each stage's model for a `--max` you chose.
- [ ] Handed an interactive `/deep-plan` to deep-goal with `--from-plan`.
- [ ] Authored a repo rigor override that survives launch validation.

## Quick reference

| | |
|---|---|
| Input | A goal/feature + a rigor level (`yolo` / `poc` / `mvp` / `prod`, or a repo-defined level) |
| Output | The six skills' own artifacts, plus `00-Manifest/pipeline.md` (state) and `00-Manifest/run-report.md` (accountability) |
| State | `pipeline.md` — every boundary; kill + re-invoke = resume |
| Interactivity | Planning window only; then gates and budget pauses, nothing else waits |
| Model allocation | Three fixed levels — smartest (Fable 5.2), smarter (Opus 5.5), smart (Sonnet 5.5); `--max` picks each stage's model (with smartest: plan/plan review/code review Fable 5.2, implement/bug fix Opus 5.5, docs Sonnet 5.5); default = your current model's level; interactive planning runs in your session |
| Launch card | Goal, effort, rigor, max, the model per stage, ≤ 1 warning; waits for Launch at mvp/prod, prints and goes at yolo/poc |
| Continue from a plan | `--from-plan` / *"continue from my plan"* — adopts your `/deep-plan` plan, starts at plan review (mvp/prod) or implement (yolo/poc) |
| Advance test | Artifact at canonical path AND manifest line flipped (round-aware in the loop) |
| Hard rules | Never writes code/plans/reviews/docs; read-only on stage lines; artifacts are the only inter-stage channel; refuses at launch, never mid-run |
| Requires | deep-skills ≥ 0.3.0 (verified at launch); the core skills never require deep-goal |
| Hosts | Claude Code = verified floor; others inline-sequential — [`plugins/deep-goal/HOSTS.md`](../../plugins/deep-goal/HOSTS.md) |

⬅ Back to the [Training Program](README.md) — or run the six-skill capstone by hand first;
deep-goal will feel earned.
