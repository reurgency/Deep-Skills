# Retrospective — First deep-goal Run

> **Effort:** `pipeline-page-simplification` (Maudel repo) · **Rigor:** `mvp` · **Run date:** 2026-08-03
> **Outcome:** complete — 7/7 dispatches; code review PASS; 3 findings auto-deferred; bugfix skipped (empty-set short-circuit); `docs/ai-map/` published.
> **Source:** conductor's firsthand account, grounded in `pipeline.md` dispatch records and run artifacts — not the spec.

This was the first live run of `/deep-goal` (deep-goal add-on conducting deep-skills 0.2.0). The run completed successfully end-to-end, including surviving a mid-run context compaction, but surfaced one significant protocol gap (docs-stage stalling) and several smaller improvements.

## What went well

### 1. The state-file architecture earned its keep immediately
The run survived a full context compaction mid-pipeline (between triage and docs) with zero loss — because everything lived in `pipeline.md` dispatch records and artifacts, not in the conductor's transcript. The resumed conductor picked up at the exact promised action (dispatching docs). This is the core design paying off on run one.

### 2. Advance tests caught a real false-completion
The docs subagent twice reported plausible-sounding progress ("cards staged", "coverage drafted") while nothing existed on disk. Because the protocol tests artifacts and never narratives, both stalls were detected in seconds. A narrative-trusting conductor would have marked docs complete on stall one. **"Verify artifacts, never narratives" is validated as the single most important rule in the skill.**

### 3. The interactivity boundary held perfectly
All questions were front-loaded in the planning window (including a late user addition — dock icon tinting — folded in during plan review); from the moment plan.md existed through docs publishing, zero unsolicited questions across five autonomous stages. Notifications fired only at completion, per the notify-sparingly rule.

### 4. The review→fix loop's edge-case machinery worked untested-in-anger
Certificate PASS + 3 sub-threshold findings → auto-triage (`--auto-accept-min=7`) deferred all three with zero prompts → empty-set short-circuit skipped bugfix → loop exited by cap (cap 1). No spurious dispatch, no spurious halt. This was the scenario most likely to misfire and it was clean.

### 5. Stage briefings were sufficient
Plan-review, implement, code-review, and triage all one-shotted from a rendered `stage-briefing.md` with no clarification requests. Implement produced two clean commits with tsc, build, and live Playwright verification; plan-review found a genuine blocker (an unreachable `storyScope` writer invalidating a contract row) and fixed it in-stage.

### 6. Config-as-data rigor resolution was frictionless
`mvp` resolved from the shipped `templates/rigor-map.json`, the version handshake passed cleanly, and the absence of hard-coded stage lists meant nothing to fight.

## What could be improved

### 1. Docs-stage stall pattern — the big one
`deep-docs` spawned its own survey subagent, then ended its turn to "wait" — **twice**. Worse, the survey agent's report couldn't route back (it tried to message a peer named `general-purpose`, which doesn't exist in the dispatched-subagent topology), so the report landed with the conductor, who had to relay it by hand. Three manual conductor interventions on an "autonomous" stage.

**Proposed fixes:**
- The stage briefing template should tell dispatched skills that *spawn-and-stop-to-wait is a stall* — do fan-out work inline or await children synchronously.
- The conductor spec (`references/conductor.md`) should gain an explicit **stall policy**: on a completion notification with no expected artifacts on disk and no live children, auto-resume once with a no-stall directive rather than leaving it to conductor improvisation.
- Root cause worth fixing in deep-docs itself: its verifier/survey fan-out assumes a messaging topology (named peers) that doesn't exist when the skill runs inside a dispatched subagent.

### 2. Blocker verdict semantics are ambiguous
Plan-review's verdict line read "Blockers: 1" — literal policy says HALT on a plan-review Blocker verdict. But the blocker was `accepted → fixed in plan` in-stage, so halting would have paged the user for nothing. The conductor judged "no unresolved blocker = no halt," which was correct, but the conductor shouldn't need judgment there.

**Proposed fix:** the verdict format should distinguish *found* from *unresolved* blockers (e.g. `Blockers: 1 found / 0 unresolved`), and the HALT trigger in the blocker policy should key on **unresolved**.

### 3. Spend tracking is nearly useless as-is
The final total — "~485–925k tokens" — is a 2× range. The host actually surfaces observed `subagent_tokens` in every task-completion notification; the conductor could record those per dispatch instead of quoting uncalibrated bands, falling back to bands only for inline stages (where usage isn't surfaced). One line in the dispatch-record procedure fixes this.

### 4. Skipped stages leave a misleading manifest
"06 Bug Fix: pending" will sit in the manifest forever — the conductor is read-only on stage lines and no core skill ran to flip it. Anyone reading the manifest first sees an unfinished run; the explanation lives only in the run report.

**Proposed fix:** either allow the conductor to write `skipped (<reason>)` on stage lines for *conductor-skipped* stages (a narrow, principled exception to the read-only rule), or have the manifest template distinguish "pending" from "not reached / skipped."

### 5. Verification side-effects are unowned
Implement's live Playwright probes mutated real application data — a test workspace's base template is permanently "MVP (customized)". It was recorded honestly in the stage summary, but nothing in the pipeline requires probes to revert what they touch, and `--worktree` wouldn't help since this is runtime DB state, not files.

**Proposed fix:** a briefing rule (or deep-implement guidance) — *record and revert data mutations made during verification, or probe against a scratch workspace.*

### 6. Small template wart
The Review loop table in `templates/pipeline.md` has a snapshot column that round 1 can definitionally never fill (pre-dispatch snapshots exist only for re-review rounds). Cosmetic — every mvp run will carry a "—" with an explanatory note — but the template could mark the column as rounds-≥2-only.

## Not exercised this run — no verdict yet

- `--gate`, `--budget`, `--worktree`
- Re-review rounds ≥ 2 (round-aware advance test, convergence exit)
- The HALT + notify + resume path
- Repo-level rigor-map overrides (`.deep-skills/rigor-map.json`)
- Autonomous planning (`deep-plan --autonomous` dispatch — this run used interactive mvp planning)

Worth exercising each deliberately before trusting them at prod rigor.

---

# Retrospective — Second deep-goal Run

> **Effort:** `pipeline-ui-cleanup` (Maudel repo) · **Rigor:** `mvp` · **Run date:** 2026-08-04
> **Outcome:** complete — 7/7 dispatches; code review PASS (0 Blocker / 0 Major); 4 findings auto-deferred; bugfix skipped (empty-set short-circuit); `docs/ai-map/` refreshed (round 2, 0 drift).
> **Source:** conductor's firsthand account, grounded in `pipeline.md` dispatch records and run artifacts — not the spec.

Second live run, picking up directly from run 1's effort (a follow-up UI punchlist on the same page). Clean end-to-end: one human touchpoint (the planning window), ~90 minutes of autonomy, no stalls, no manual interventions. The improvement surface has shifted from protocol mechanics (run 1) to the loop's tail: triage thresholds, deferred-debt flow, and tail-stage cost.

## What went well

### 1. The upstream-kill chain fired end to end (DLC-001 validated)
The State/Data-Flow Contract forced plan-time discovery that the Coverage Check write path (stage config) and runtime read path (a tracker service signal) diverged. Then each later layer caught something the previous one missed: columbo caught the replace-not-merge PUT (a single-key payload would silently wipe sibling `stageSpecific` keys) and a display-vs-request default contradiction; plan-review caught a concurrent-writer race (Config tab's debounced flush vs the new card toggle) and promoted the shared-save-helper from optional to required; implement's contract probe proved the wiring both directions in a live browser (intercepted POST bodies). Code review's 0 Blockers / 0 Majors is the payoff — the expensive bug class was dead before review. This is the directive-card system working exactly as designed.

### 2. Columbo and plan-review found disjoint defect sets
Potential-redundancy concern from the design: both passes ran (~84k + ~79k) and overlapped on nothing. Columbo (plan-vs-repo verification) found API semantics the plan mis-assumed; plan-review (fresh-agent review) found a temporal race no line-by-line check would surface. Two cheap majors caught pre-implementation; both passes earned their keep at mvp.

### 3. The interactivity boundary held perfectly (again)
Effort name, 4 design decisions, and the pre-write nudge all front-loaded into one batched question round; zero unsolicited questions from plan.md onward; notification only at completion. Two-for-two on the core promise.

### 4. Empty-set short-circuit + cap exit clean (again)
0 accepted findings → bugfix skipped straight to `complete`, loop exited by cap without re-reviewing an unchanged tree. Two-for-two on the edge case most likely to misfire; ~100k+ of pointless re-review avoided each time.

### 5. Advance tests stayed cheap and useful
Every stage verified against artifacts with one-liner checks (`ls`/`grep`/`jq`-equivalents). No subagent narrative diverged from disk this run — but the checks twice surfaced load-bearing detail the summaries glossed (exact finding statuses, certificate triage state).

### 6. Fresh-agent-per-stage held context budgets
Observed per-stage spend 60–209k; no context blowouts, no compaction events. Notable in a repo with a history of subagent context-limit failures.

### 7. No docs stall this run
Run 1's big finding (deep-docs spawn-and-stop-to-wait, 3 manual interventions) did not recur: docs ran as a single background dispatch and completed in one pass — staging + atomic rename, 188 anchors adversarially verified. One run is not proof of fix, but the pattern didn't reproduce.

## What could be improved

### 1. Auto-triage at `min=7` has never accepted a finding — the loop tail is dead code in practice
Both runs: 0 accepted / all deferred / bugfix skipped. The mvp loop machinery (bugfix dispatch, re-review, round-aware test, convergence exit) has still never executed live. Meanwhile real bugs accumulate in ledgers: this run deferred a sev-6 (failed toggle save leaves the switch visually lying); run 1 deferred a sev-6 deep-link bug that only got fixed this run *by coincidence* (the plan happened to touch that code). **Proposed fixes:** lower mvp's threshold to 6, or add a post-run "human-triage the deferreds?" prompt to the completion flow, or an accept-if-cheap heuristic for Minors ≥ 5.

### 2. No cross-effort deferred-debt visibility
Run 1's deferred findings were only considered because the conductor happened to read the prior run-report during exploration — mechanism, not luck, is needed. **Proposed fix:** a launch-time (or planning-briefing) step that surfaces open `status: deferred` findings from sibling efforts whose files intersect the new effort's scope.

### 3. Cost skews to the tail; mechanical stages are over-provisioned
Docs was the most expensive stage (~209k — 3 blind survey agents + 5 adversarial verifiers for a 6-file UI diff). Triage cost ~60k (4× its 5–15k band) to apply a numeric threshold to 4 findings. **Proposed fixes:** a lighter incremental docs mode selectable in the rigor map for small diffs; dispatch mechanical stages (triage) at a lower model/effort tier via the map's per-stage options.

### 4. Spend bands can now be calibrated
Run 1 flagged spend tracking as nearly useless; run 2 confirms the bands are too wide to inform anything (implement: "~80–300k" vs 164k observed). Two runs of per-stage observed data now exist — enough to tighten `rigor-levels.md` § Cost bands to observed ± 50%.

### 5. Conductor bookkeeping is fiddly hand-editing
pipeline.md is maintained through manual template-shaped edits; one edit failed mid-run because the written file had drifted slightly from the template text being matched. **Proposed fix:** a small `scripts/` helper (in the spirit of `load-active-cards.sh`) that renders/updates dispatch records mechanically.

### 6. No human-visual checkpoint for UI efforts
Light mode was verified by class-toggle only; the run report *recommends* a human glance but nothing enforces or offers it. **Proposed fix:** for UI-heavy efforts, surface an optional pre-docs gate (the `--gate` machinery already exists) or a "visual sign-off" checkpoint type at plan time.

### 7. Side-findings are informational orphans
Implement's NG0956 perf warning; docs' anchored discoveries (server-side `resolveStageSpecific` has no production caller; `styleClass="track-select"` matches no CSS rule) — genuinely useful, but they land as prose in the run report and route nowhere. **Proposed fix:** a standing "side-findings" artifact (or an append to the repo's punchlist convention) that outlives the run report.

### 8. Skipped-stage manifest wart recurred (run-1 finding #4 confirmed)
Second run, second "06 Bug Fix: pending" on a completed pipeline, second explanatory note required in the run report. The proposed `skipped (<reason>)` literal remains the right fix.

## Run-1 follow-ups — status after run 2

| Run-1 finding | Status this run |
|---|---|
| 1. Docs-stage stall pattern | **Did not reproduce** (single clean background dispatch); keep watching |
| 2. Blocker verdict ambiguity | Not exercised (plan-review verdict had 0 Blockers) |
| 3. Spend tracking nearly useless | **Confirmed**; calibration now possible (see #4 above) |
| 4. Skipped-stage manifest wart | **Reproduced** (see #8 above) |
| 5. Verification side-effects unowned | Improved unprompted: implement intercepted the generate POST (no real generation) and restored workspace state — but still convention, not rule |
| 6. Review-loop snapshot column wart | Reproduced (cosmetic, round-1 "—" again) |

## Still not exercised after two runs — no verdict yet

- `--gate`, `--budget`, `--worktree`
- Re-review rounds ≥ 2 (round-aware advance test, convergence exit) — and any bugfix dispatch at all
- The HALT + notify + resume path
- Repo-level rigor-map overrides (`.deep-skills/rigor-map.json`)
- Autonomous planning (`deep-plan --autonomous` dispatch — both runs used interactive mvp planning)

The triage-threshold issue (#1) is why bugfix/re-review remain unexercised: at current thresholds, mvp runs on decent code may *never* reach them. A deliberate exercise run (seeded bugs, or `--auto-accept-min=5`) is the fastest way to de-risk that machinery before trusting it at prod rigor.


## JB Findings
- 1 million token orchestrator
- Verify if using smartest agent as orchestrator is the best approach. 
- Verify if using a smarter agent as orchestrator, do all subagents use the same smart model or are they different based on the task? I tend to use smartest agent as planners and reviewers and one tier down for implementers and other subagents.