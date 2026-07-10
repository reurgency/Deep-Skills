# Review→fix loop, budget guard, gates, notifications, worktree

The spec for the conductor's **review→fix loop** (code-review → triage → bugfix → re-review, with rigor-mapped convergence) and the four v1 enhancement flags (`--budget`, `--gate`, `--worktree`; `--dry-run` is specced in SKILL.md § Rigor resolution). `references/conductor.md` § 6 is the summary; this file is the spec. Everything here writes to and reads from `00-Manifest/pipeline.md` (`templates/pipeline.md` — the Review loop table and Budget events log live there), and every loop decision reads the same `findings.json` triage wrote — the exact status literals are `open` / `accepted` / `deferred` / `rejected by user` / `fixed` (canonical: deep-code-review's `references/findings-and-severity.md`).

## 1. The review→fix loop

### 1.1 Rounds and records

The loop exists whenever the resolved level's stage list contains `code-review` (which is also exactly when the level carries `re_review_cap` — the map validates this pairing).

- **Round 1** is the map's own stages, dispatched by the normal loop (`conductor.md` § 3) with the normal advance tests (§ 4): `code-review` (the review; mode per the stage entry) → `code-review (triage)` (`--triage --auto-accept-min=<triage.auto_accept_min>` — the threshold always flows from the resolved map into the dispatch args, every round) → `bugfix`.
- **Re-review rounds (N ≥ 2)** append dispatch records past the resolved stage list: `code-review (round N)`, and — only when the convergence test says *continue* — `code-review (triage, round N)` and `bugfix (round N)`. A re-review dispatch reuses the level's `code-review` stage entry verbatim (same `mode`, same `triage.auto_accept_min`): per-rigor thoroughness applies to every round, not just the first.
- **Both post-review dispatches are conditional on work existing** in `findings.json` — every round, including round 1: triage is skipped when nothing is `open`, bugfix is skipped when nothing is `accepted`-and-not-`fixed`, and a skipped bugfix exits the loop by cap. The **empty-set short-circuits** (§ 1.5) define both skips; a skipped dispatch still completes its record.
- Every loop dispatch gets a normal dispatch record **and** each round gets one row in pipeline.md's **Review loop** table (snapshot, fresh ids, non-`fixed` count, certificate verdict, decision).

Re-reviews **append** to the same `04-Code-Review/findings.json` — fresh sequential CR ids, prior statuses preserved, top-level `reviewed` date updated, `report.md`/`certificate.md` rewritten for the round (canonical: findings-and-severity.md § Re-review rounds). That append contract is what makes everything below possible.

### 1.2 Round-aware advance test (review rounds ≥ 2)

`04-Code-Review/` artifacts are **not round-versioned** — from round 2, "the artifact exists" is vacuously true, so the plain advance test (`conductor.md` § 4) proves nothing. The loop replaces it:

**Round 1 over a pre-existing `findings.json`** (a fresh restart over a prior run, or a manual review predating deep-goal — the append contract makes it indistinguishable from a round ≥ 2) uses this same test, with the **launch baseline** (`conductor.md` § 4; `templates/pipeline.md` § Artifact baseline) standing in as the snapshot.

**Snapshot — before dispatch.** When the round's re-review record is marked `in-flight` (i.e. *before* the subagent launches — this is what makes a crash detectable), the conductor writes into that round's Review loop row: the highest existing CR id, the findings count, findings.json's top-level `reviewed` date, and the file mtimes of `findings.json` and `certificate.md`.

**Pass — compare after the dispatch returns.** Per dispatch type:

| Loop dispatch | Round-aware pass condition (vs the snapshot) |
|---|---|
| `code-review (round N)` | **Fresh CR ids** appended (max id and count above the snapshot) AND the `reviewed` date is current. **Clean-round case** (a re-review may legitimately find nothing new): no fresh ids, but the `reviewed` date is strictly newer — or, when the snapshot date is already today (day-granular dates can't discriminate a same-day rerun), both `findings.json` and `certificate.md` mtimes are strictly newer than the snapshot's. |
| `code-review (triage, round N)` | **Status changes**: the fresh `open` findings the snapshot proves existed are now zero — every finding is `accepted` / `deferred` / `rejected by user` / `fixed` — AND `certificate.md`'s Triage outcomes table is filled for this round. (Not vacuous from round 2: the snapshot shows the opens were there before the dispatch.) |
| `bugfix (round N)` | A `06-Bug-Fix/round-K/fix-summary.md` exists with **K greater than the highest pre-dispatch round dir** (the conductor snapshots the highest `round-K/` into the record's Notes before dispatch) — deep-bugfix's own round dirs make this stage naturally round-versioned. |

**Fail** — nothing moved (ids, count, `reviewed`, and mtimes all unchanged): the round did not run; a crash mid-re-review never marks an un-run round complete. Handle per `conductor.md` § 4's fail path: no blocker artifact → leave the record `in-flight`-annotated and re-dispatch once; fails again → HALT-class blocker.

### 1.3 Round accounting

After each round's review/re-review passes its advance test, the conductor counts the findings in `findings.json` whose **status ≠ `fixed`** (that is: `open` + `accepted`-but-unfixed + `deferred` + `rejected by user` — in an autonomous run nothing is ever auto-rejected, so the last is normally zero) and appends the count to the round's Review loop row, together with the certificate verdict. Round 1's count is taken right after the review (on a virgin `findings.json` all findings are `open`, so it equals the total found; over a pre-existing file it also carries the prior non-`fixed` statuses — a constant across this run's rounds, so the strict-decrease comparison still measures this run's progress). This table — same file the convergence test reads — is the loop's ledger; the run report reproduces it.

### 1.4 Convergence state machine

Exit semantics key off the level's **`re_review_cap`** — **always read from the resolved map** (`rigor-map.json`, or the merged repo override), never a hard-coded literal — so custom override levels inherit coherent behavior by cap value, not by level name. (When a round's bugfix was **skipped** under § 1.5's empty-set short-circuit, the loop exits there per § 1.5 — the machine below governs rounds whose bugfix actually ran.)

**"Exit to docs"** — the shorthand used below, in § 1.5, and in the summaries (`conductor.md` § 6, SKILL.md) — means: **exit the loop and proceed to the level's remaining map stages** (at the shipped cap ≥ 1 levels the next stage is `docs`, hence the name); a level with no stages after the loop — legal for a custom override (`rigor-levels.md` § Validation imposes no docs requirement) — completes the run there, exactly like cap 0's "next map stage" exit.

- **No `code-review` stage** (shipped: yolo) — no loop, nothing here applies.
- **cap = 0** (shipped: poc) — the loop **ends after round 1's bugfix**. No re-review is ever dispatched. Residuals — every `deferred` finding and any blocked bugfix cluster — go to the run report (`references/resume-and-report.md` § 2); the run proceeds to the next map stage (poc has none — the run completes).
- **cap = 1** (shipped: mvp) — **exactly one re-review** (round 2), then a single check, no counting test:
  - `certificate.md` verdict **FAIL** (unresolved Blockers — a fresh 9–10 finding, or a prior Blocker not `fixed`) → **HALT + notify**. Blockers row: stage `code-review (round 2)`, policy HALT, report = the certificate path.
  - otherwise → **exit to docs**. Round 2's fresh findings are *not* triaged or bugfixed — they stay `open` and join every `deferred` finding as **residuals, listed prominently in the run report** (`references/resume-and-report.md` § 2.2 — the "still open, never triaged" section).
- **cap ≥ 2** (shipped: prod, cap 3) — from round 2 on, after each re-review's round accounting, the **exit test**:

  > certificate verdict **PASS** (no unresolved Blockers) **AND** this round's non-`fixed` count **< the prior round's count** (strictly — both read from the Review loop table / findings.json).

  - Test **passes** → exit to docs (residuals = `deferred` findings, reported as above).
  - Test **fails** and re-reviews dispatched so far **< cap** → continue the round: `code-review (triage, round N)` at the same threshold → `bugfix (round N)` → re-review `code-review (round N+1)`.
  - Test **fails** and re-reviews dispatched **= cap** → **HALT + notify as a convergence failure**. The last re-review's record is `complete` (it ran and passed its advance test); the *run* halts: Blockers row with stage `code-review (round N)`, policy HALT, report = the certificate path, note = the count series (e.g. `convergence failure: counts 7 → 7 → 7, cap 3 reached`). The halted pipeline.md is the resume point, as with any HALT.

### 1.5 Empty-set short-circuits (any round)

Both post-review loop dispatches presuppose a non-empty work set, and dispatching an autonomous agent with an empty one strands it: deep-bugfix's own intake, finding nothing actionable, says so and asks for an input — and the stage briefing forbids asking (`templates/stage-briefing.md`, rule 3) — so the agent stops with no `fix-summary.md` and no manifest flip, and the advance test would spuriously HALT a healthy run. The conductor therefore checks the set itself, reading `findings.json`, at the boundary before each dispatch:

- **Skip triage** when `findings.json` has **zero `open` findings** (round 1: the review found nothing; round N: a clean re-review with every prior finding already triaged). There is nothing to accept or defer — do not dispatch; mark the `code-review (triage)` / `code-review (triage, round N)` record `complete` straight from `pending` (never `in-flight`), advance test `skipped — zero open findings, nothing to triage`. A skip is a conductor decision recorded in pipeline.md — it needs no artifact evidence, and the certificate's Triage-outcomes table stays exactly as the review left it.
- **Skip bugfix** when `findings.json` has **zero findings with status `accepted` that are not `fixed`** (e.g. poc's threshold-9 auto-triage deferring everything below a Blocker). Do not dispatch; mark the `bugfix` / `bugfix (round N)` record `complete` straight from `pending`, advance test `skipped — zero accepted-and-unfixed findings, nothing to fix`. No `06-Bug-Fix/round-K/` dir is created, and the `06 Bug Fix` manifest line stays untouched — a skill that never ran flips nothing, and the conductor never flips a stage line.
- **Exit after a skipped bugfix — by cap, immediately.** A skipped bugfix leaves the tree unchanged, so a re-review of it could neither verify a fix nor strictly reduce the non-`fixed` count — never dispatch one after a skip. Read the current `certificate.md` verdict and exit:
  - **cap = 0** — unchanged: the loop was ending after round 1's bugfix anyway; the run proceeds to the next map stage (poc has none — the run completes).
  - **cap = 1 / cap ≥ 2** — verdict **PASS** → **exit to docs** (at cap ≥ 2 this *is* convergence: nothing the loop is allowed to fix remains). Verdict **FAIL** → **HALT + notify** per § 1.4's Blocker rule — structurally FAIL should not co-occur with an empty accepted set (Blockers always auto-accept, and an unfixed prior Blocker stays `accepted`), but a FAIL certificate never rides silently into docs.

  The round's Review loop row records the skip in its Decision cell (e.g. `bugfix skipped (empty set) → exit → docs`), and residuals — every `deferred` finding and any never-triaged `open` — go to the run report as usual (`references/resume-and-report.md` § 2.2).

A skip is a **normal boundary decision**, not a blocker: it runs as part of § 6 step 2 (so a resumed run re-derives it at the same boundary), spends nothing, appends no Blockers row, and triggers no notification — a clean(ish) review is a healthy run.

## 2. Budget guard — `--budget=<band>`

*Natural-language trigger: "cap spend at ~500k tokens," "budget this run to a million tokens."*

- **Band:** an approximate total-token ceiling for the run (`--budget=500k`, `~500k tokens`, `1.5m`), normalized and recorded in the pipeline.md header's Budget slot at launch. It is a **soft, estimate-based ceiling** — spend figures are the uncalibrated heuristic bands of `rigor-levels.md` § Cost bands (refined by observed usage where the host surfaces it), so treat the ceiling as "roughly here," never an exact meter.
- **Recording:** as each dispatch record completes, its Spend (est) cell is filled (`conductor.md` § 3 behavior — unchanged); the Spend section's running total sums the completed records' estimates (band midpoints, or observed figures where available).
- **Check — at stage boundaries ONLY.** A dispatched stage always finishes; the conductor never interrupts one mid-flight and never leaves a half-written artifact. At each boundary (after completing a record, before marking the next `in-flight` — see § 6 for the boundary order), compare the running total against the ceiling. **Crossed** → pause:
  1. append a **Budget events** row to pipeline.md (boundary = the next, undispatched stage; running total; ceiling; action `paused — notified, waiting`);
  2. **notify** (§ 4) — one line, e.g. `deep-goal paused: budget ~150k tokens crossed (est ~185k) before code-review — re-invoke deep-goal to resume, raise, or stop.`;
  3. **stop the turn and wait.** Nothing further is dispatched. The next stage's record stays `pending`.
- **Resume** (contract row #8's other half — spec: `references/resume-and-report.md` § 1.3): a re-invocation reads the Budget events row and re-enters **at the paused boundary** — the budget check re-runs with the current ceiling, then any unapproved gate at the same boundary re-fires; the user may raise or remove the ceiling there (logged as another Budget events row). Without `--budget`, no check runs and the Budget events log stays empty.

## 3. Gate injection — `--gate=<stage>` (repeatable)

*Natural-language trigger: "pause before implement," "check in with me before docs" ("…before implement and before docs" = two gates).*

- **Validated at launch, never mid-run:** each gate must name a stage in the **resolved** stage list; an unknown or not-in-this-level name refuses at launch with the valid menu (the launch-refusal guardrail). Gating `plan` is legal but redundant at interactive levels (the user is already present).
- **Persisted:** gates are written into the pipeline.md header's Gates slot at launch, so a resumed run honors them (resume re-reads the header, `references/resume-and-report.md` § 1.3 — the gate survives crashes and budget pauses).
- **Fires once,** at the stage boundary immediately before the named stage's **first** dispatch. Loop rounds do not re-fire it (a gate on `code-review` fires before round 1 only — gating every re-review would turn the loop into an interview).
- **At the gate:** notify (§ 4 — gates are on the trigger list; the user may be away from the terminal), then ask **one self-contained structured question** (host-affordances: native structured-question tool, numbered-list chat fallback) and wait:
  - **Content** — everything needed to decide lives in the question itself, never in between-tool-call prose: *what ran* (per completed record: stage + one-line advance-test result + spend est), *what's next* (the gated stage, its exact invocation from the Stage list table, its cost band), and the two options.
  - **Options** — **Proceed** (continue the walk) / **Stop** (pause the run here). Each option's description/preview is **≤ 15 lines** — hosts truncate beyond that; trim the what-ran list to fit before trimming what's-next.
  - **Proceed** → record `gate: approved <timestamp>` in the gated stage's record Notes and dispatch. **Stop** → record `gate: stopped by user <timestamp>`, leave the record `pending`, and stop the turn — the run pauses exactly like a budget pause; pipeline.md is the resume point.

## 4. Notifications

The conductor notifies on **exactly four triggers** — the series' notify-sparingly rule (`references/host-affordances.md`: gates and budget pauses are its *user-requested checkpoints*; HALTs are its blockers); `pipeline.md`'s dispatch-record table is the per-stage "spinner," and a user can ask for status in natural language at any time. Never ping on routine stage completion, and CONTINUE-class blockers ride the completion notification + run report, never their own ping.

| Trigger | Example line |
|---|---|
| **HALT** (blocker policy, `conductor.md` § 5 — or a convergence failure, § 1.4) | `deep-goal halted: implement blocked at Phase 2 (fix cap) — see .deep-skills/<effort>/01-Plan/plan.md § Phase Summaries. Re-invoke deep-goal to resume once unblocked.` |
| **Gate** (§ 3) | `deep-goal at your --gate before implement: 3 stages done, plan reviewed clean — answer the question in the session to proceed or stop.` |
| **Budget pause** (§ 2) | `deep-goal paused: budget ~500k tokens crossed (est ~530k) before code-review — re-invoke deep-goal to resume, raise, or stop.` |
| **Completion** (run report written — `references/resume-and-report.md` § 2.1) | `deep-goal done: mvp run complete, 6/6 stages, 3 findings fixed, 2 deferred — run report at .deep-skills/<effort>/00-Manifest/run-report.md.` |

**Mechanics** (same as `conductor.md` § 5): **one line, < 200 chars, lead with the actionable fact** (what needs the user, where the artifact is), delivered via the host-affordances fallback chain — native notifier (Claude Code `PushNotification`) → shell `osascript` → a bold **`ATTENTION:`** line as the last line of the turn.

## 5. Worktree — `--worktree`

*Natural-language trigger: "build in a worktree," "keep my checkout clean — use a worktree."*

**The conductor owns ONE worktree** (contract row #9). Core skills never see a `--worktree` flag — they receive a *working directory* through the stage briefing, so no core changes, no second worktree, and reviews see implement's commits naturally.

- **At launch:** record the intent in the pipeline.md header Worktree slot as `pending (created after planning)`. Nothing is created yet — planning artifacts go to the source repo, and the tree should branch from the repo as it stands when building starts.
- **Create — immediately after the planning record completes** (i.e. the moment `01-Plan/plan.md` exists): one worktree from the current HEAD, sibling of the repo, never inside it:

  ```bash
  git worktree add ../<repo-dirname>--deep-goal-<effort> -b deep-goal/<effort>
  ```

  Record the absolute path and branch in the header Worktree slot — and, in the same pipeline.md update, **re-record the Artifact baseline's `docs/ai-map/ (code tree)` row from the fresh worktree** (`templates/pipeline.md` § Artifact baseline): `git worktree add` materializes every file with checkout-time mtimes, all strictly after launch, so the launch row's invocation-repo mtime would read "strictly newer" even for a docs stage that never ran — and the docs advance test reads `docs/ai-map/` **in the worktree** (below; `conductor.md` § 4), so it must be judged against the worktree copy's state: write `absent`, or `present` + the worktree `index.json`'s mtime. This is the **only** baseline row ever re-recorded, and only when the worktree is created. Resolved once — a resumed run **reuses the recorded path and never creates a second worktree**; if the recorded path has vanished, the recreate step (`resume-and-report.md` § 1.3) counts as creation: re-record this row again from the fresh checkout (fail-safe — a committed pre-crash publish then reads as pre-existing and costs at most one re-dispatch of deep-docs `--refresh`, never a false pass).
- **Substitute into every subsequent stage briefing:** from here on, every rendered `stage-briefing.md` gets the worktree form of `{worktree_path}` (both renderings are defined in the template's comment block): *do ALL code work — reads, edits, builds, commits — inside `<path>`; effort artifacts under `.deep-skills/<effort>/` stay in the invocation repo.* That covers **implement, code-review (both dispatches), bugfix, every re-review round, and docs** — all in the same tree, on the same `deep-goal/<effort>` branch — and **plan-review**, when the level runs one (mvp/prod): it is dispatched right after the worktree is created, so its briefing carries the same form — inert for a read-only stage whose tree still equals the HEAD it was cut from.
- **Where the conductor reads:** effort artifacts (plan, manifest, pipeline.md, review artifacts) live in the **invocation repo** — advance tests read them there, and resume works from the repo deep-goal is invoked in. Artifacts that live in the **code tree** (commits; deep-docs' published `docs/ai-map/`) are read **in the worktree** on a `--worktree` run.
- **At completion** (requirement specced here; the run report writes it — `references/resume-and-report.md` § 2.2): the run report **must** carry the worktree path, its branch, and merge instructions (review the branch, `git merge deep-goal/<effort>` or PR it, then `git worktree remove <path>`). The conductor never deletes the worktree itself.
- **Omitted:** `{worktree_path}` renders the none-form; every stage runs on the current branch per its own skill's defaults — no worktree anywhere.

## 6. Stage-boundary order

At every stage boundary the conductor runs, in order — each step reading/writing pipeline.md before the next:

1. **Complete the finishing record** (advance test result, finished time, spend estimate — `conductor.md` §§ 3–4).
2. **Round accounting + convergence + empty-set check** when inside the review→fix loop (§§ 1.3–1.5) — this may turn "next stage" into a loop dispatch, a skipped record (§ 1.5), an exit to docs, or a HALT.
3. **Budget check** (§ 2) — may pause the run here.
4. **Gate check** (§ 3) — may pause the run here. (Budget is checked first: if both fire, the budget pause wins and the gate re-fires at this same boundary on resume.)
5. **Mark the next record `in-flight`** and dispatch (with the § 1.2 snapshot first when it is a loop round ≥ 2).

A pause or halt always lands **between** stages — steps 2–4 never interrupt a dispatched stage, and a stage is never dispatched after its boundary checks fail.
