# Skill comparison — `rigorous-change` vs `deep-goal` (+ the deep-* series)

**Date:** 2026-07-30
**Scope:** `docs/Skill-Review/rigorous-change/SKILL.md` compared against `plugins/deep-goal` and the six core skills in `plugins/deep-skills` it conducts. The fair unit of comparison is **rigorous-change vs the whole deep-* series** — deep-goal alone is only the conductor; rigorous-change covers the territory of the pipeline plus the conductor in one document.

---

## 1. Framing: two answers to the same question

Both skills answer: *how does an AI agent land a change a human can trust, with rigor scaled to risk, without wasting ceremony?* They converged independently on the same skeleton — evaluate → plan → adversarial plan review → isolated build → verify → adversarial code review → gated commit/merge — which is strong evidence the skeleton is right.

They differ in **altitude**:

- **rigorous-change** is a *doctrine* — ~170 lines of judgment for a single expert agent. Its self-description is explicit: "The value is in the judgment, not the steps."
- **deep-* / deep-goal** is a *machine* — seven skills, config-as-data, artifact contracts, advance tests, resume semantics, host portability. Its value is in the enforcement: independence, auditability, and repeatability that don't depend on any one agent's judgment.

## 2. Where they are the same

| Shared idea | rigorous-change | deep-* series |
|---|---|---|
| Rigor scaled to risk | Light / Standard / High, judged on blast radius, reversibility, data mutation, novelty | yolo / poc / mvp / prod, resolved from `rigor-map.json` |
| Adversarial plan review before building | Step 3: independent reviewer, `file:line`, explicit verdict, weigh don't capitulate | `deep-plan-review`: fresh agents, never see the planning transcript, evidence-cited findings by severity |
| Independent code review of the diff | Step 6: independent agent over `git diff`, adversarial, loop to convergence | `deep-code-review`: fresh agents, 4 lenses, refute-briefed verifiers, certificate + convergence caps |
| Isolated build | Worktree for Standard/High (with the `worktree-feature` teardown hazard) | `deep-implement --worktree`; deep-goal `--worktree` (conductor owns one tree, all stages share it) |
| Commit ≠ merge; user approves the merge | Step 7 explicit: "Do NOT merge until the user approves" | Same outcome by scope: never on main, never push/merge without explicit ask (merge is simply out of scope) |
| Anti-theater review discipline | "Don't loop reviewers for theater"; don't re-review an approved plan | Empty-set short-circuits, re-review caps, round-aware advance tests |
| Surfacing cadence | "Would the user's answer change what you do next? Yes → surface. No → decide and move on." | Notify-sparingly rule: exactly four triggers (halt, gate, budget pause, completion) |
| Fresh-agent continuity | Session handoff via memory: living campaign note | Artifact contract: `.deep-skills/<effort>/`, manifest, pipeline.md, per-skill resume |
| Nothing silently dropped | Capture rejected approaches + corrected assumptions to memory | Deferreds ledger, refuted-findings appendix, `rejected by user` statuses, blocker reports |

## 3. Where they are different

| Axis | rigorous-change | deep-* series |
|---|---|---|
| **Architecture** | One monolithic prose procedure; one agent plays every role | Modular pipeline; separation of concerns; each skill usable standalone; conductor as thin walker |
| **Rigor selection** | Model judgment on four axes ("round up when unsure") | Data (`rigor-map.json` + repo override), validated at launch, refusal on bad config |
| **Verification philosophy** | **Empiricist**: measure before you reason; run against real data; probe latency; print actual rows | **Procedural/static**: typecheck + tests + adversarial *reading*; behavioral runs opt-in (`--browser`, acceptance-criteria-gated) |
| **Go/no-go before work** | Step 0: kill the work if the premise is false or value is low — "a process that can talk you out of work" | Absent. deep-plan goes restate → frame → explore; no exit-with-nothing branch |
| **Activation path / prove-it-live** | First-class: plan how it goes live; after merge, confirm actually live + before/after measurement | Absent. Series ends at deep-docs; nothing runs after merge (verified: zero hits across all six skills) |
| **Scale of effort** | Campaign mode: dependency-ordered, independently-shippable slices; re-sequence on evidence; dark launches + dry-run go/no-go | Single effort only; phases within one plan; "stop and surface, don't silently re-plan" |
| **Interactivity model** | Conversational throughout; judgment about when to surface | Hard interactivity boundary: interactive planning window, then autonomy; gates/budget pauses as the only waits |
| **Autonomy machinery** | None (no budget, no resume state, no reports) | Budget guard, gate injection, crash-safe resume, run report, version handshake, notifications |
| **Continuity store** | Persistent *memory* (campaign note: shipped hashes, rejected approaches, open items) | *Artifacts* only; memory is read-only input, never written |
| **Learning loop** | Ad-hoc memory capture each round | Deep-Learn directive cards (human-gated, data-not-prose) — though the Distiller doesn't exist yet and the feeds are display-only |
| **Portability / product** | Personal/team doctrine; references a sibling `worktree-feature` skill | Cross-host (Claude Code / Copilot / Codex / Cursor), versioned, marketable paid add-on |
| **Enforced independence** | Asserted ("spawn *independent* reviewers") — same session orchestrates | Structural: fresh subagents never receive transcripts; artifact-only channels; conductor read-only on stage lines |

## 4. Gaps in BOTH

1. **Post-merge observation beyond a one-shot check.** rigorous-change proves liveness once; deep-* stops at merge-offered. Neither watches for regressions after the change is live (error rates, metric drift).
2. **Rollback as a tested artifact.** rigorous-change names "a tested rollback/fallback" for High tier in one line; deep-bugfix reverts regressed fixes — but neither makes a *rehearsed* rollback a deliverable.
3. **Quantified value.** Step 0 is qualitative; deep-* has cost *bands* for its own spend but no notion of the change's expected value. Neither asks "what number proves this was worth it?" as a plan field.
4. **Security review.** deep-goal reserves a `security` roster slot (not shipped); rigorous-change never mentions security at all.
5. **Closed learning loop.** rigorous-change's memory capture is unstructured prose; deep-*'s Distiller is unbuilt and its learn feeds (`root-causes.json`, `learn-signal.json`) have no machine reader. Both aspire to compounding learning; neither has it operational.
6. **Each is the other's missing half on big efforts.** rigorous-change has campaign *doctrine* with no state or tooling; deep-* has effort *state* with no cross-effort structure. Multi-effort work is under-served by both.

## 5. Advantages of deep-goal (+ series)

- **Repeatable and auditable.** Every stage leaves artifacts; pipeline.md is a dispatch ledger; the run report reproduces the loop table. A second person (or a fresh agent) can reconstruct what happened without trusting anyone's narrative.
- **Crash-safe autonomy.** Advance tests judged against a launch baseline, round-aware snapshots, idempotent resume — a run that dies mid-flight resumes correctly. rigorous-change has no equivalent.
- **Structurally enforced reviewer independence.** Fresh subagents never see prior transcripts. rigorous-change *asks* for independence but the same session briefs the reviewer — the blind-spot-sharing problem its own preamble worries about.
- **Config-as-data.** Teams reshape rigor per-repo (`.deep-skills/rigor-map.json`) without touching prose; validation refuses bad config at launch with named keys.
- **Bounded everything.** Fix caps, re-review caps, convergence tests, budget ceilings — runaway loops are impossible by construction.
- **Portable and productizable.** Works on hosts without CLI flags; versioned dependency handshake; the plugin boundary supports the paid-add-on model.

## 6. Advantages of rigorous-change

- **Empirical grounding — the biggest one.** "Measure before you reason" attacks the exact weakness of an all-agent pipeline: every deep-* reviewer is the same model reasoning over the same text. rigorous-change's strongest catches come from *running things*; deep-*'s validation is tests/typecheck with behavioral runs opt-in.
- **The Step-0 kill gate.** deep-* will faithfully and expensively execute a feature that shouldn't exist. rigorous-change reports killing three efforts in one session before any code — that's the highest-leverage judgment in either skill.
- **Activation path + prove-it-live.** Plans how the change goes live and proves it with a before/after number. deep-* declares victory at "artifact exists + tests green," which is exactly the "stale build/connection" trap rigorous-change names.
- **Campaign mode.** Dependency-ordered shippable slices, evidence-driven re-sequencing, dark launches with dry-run as the go/no-go gate for live-data mutations. deep-* has nothing at this scale.
- **Near-zero overhead.** One file, no install, no handshake, no artifacts to maintain. For a 30-line tweak, its Light tier is one review + verify; deep-goal's cheapest level still stands up a pipeline.
- **Durable decision memory.** Rejected approaches and corrected assumptions written to memory so the next session doesn't retry them. deep-*'s equivalents are per-effort artifacts nobody is required to re-read across efforts.

## 7. When to use which (as they stand today)

**Reach for deep-goal when:**
- The change is a well-framed feature you want built hands-free with a paper trail (mvp/prod).
- Multiple people/agents need to trust the process, not the operator.
- You need unattended runs: budget caps, gates, notifications, resume.
- You're on a non-Claude-Code host.

**Reach for rigorous-change when:**
- The real question is *should we build this at all* — the premise needs testing on real data first.
- The change touches live data / needs a migration — dark launch + dry-run + prove-it-live matter more than review depth.
- The effort spans many sessions and many shippable slices (campaign mode).
- You're a hands-on expert pairing with one agent and pipeline ceremony would be waste.

## 8. What rigorous-change should contribute to deep-* (ranked by value/cost)

1. **Activation path + prove-it-live** *(cheap, high value)*. Add an **Activation** section to `deep-plan/templates/plan-template.md` (how does this go live: restart / reload / reconnect / migration-on-boot); have deep-implement's summary and deep-goal's run report carry it; add a "confirm live + before/after measurement" line to the merge instructions in the run report.
2. **Step-0 worth-doing gate** *(cheap, highest leverage)*. A short evaluation at the top of deep-plan's Frame phase — is this sound, is it the highest-value thing — with a sanctioned **exit-with-evidence, no plan written** outcome. At prod rigor, deep-goal could surface the verdict at the planning window. A process that can say "no" is the cheapest quality mechanism either skill has.
3. **Empirical verification, rigor-gated** *(medium cost, high value)*. Promote `deep-implement/references/validation.md`'s opt-in behavioral validation to **required at mvp/prod**: the plan's Verification section must name one *empirical* check of the core claim (a probe, a real-data run, a measurement — not "tests pass"), and validation blocks on it. This also plugs the shared-blind-spot hole in review: reviewers get a measurement, not just a hypothesis.
4. **Measure-before-plan probes** *(small change)*. deep-plan's Explore phase is read-only by design; keep the source tree read-only but explicitly permit *empirical probes* (run a query, time an endpoint, sample real data) whose results land in the plan's Context/Assumptions. Today a plan can be written on an unmeasured premise and no later stage will catch it.
5. **Dark-launch / dry-run doctrine for live-data mutations** *(fits existing seams)*. Author the pending "DB migrations" situational check in `deep-code-review/references/situational-checks.md` and add the rule: a handler mutating a live store ships flag-off with a logging dry-run, and reading the dry-run output is the go/no-go. This is pure doctrine — it drops into existing machinery.
6. **Rejected-approaches ledger** *(cheap)*. Make "rejected alternative and why" a structured plan/manifest field (like Deferreds) rather than an optional prose line, and surface it in the run report — the raw material Deep-Learn's future Distiller needs anyway.
7. **Campaign mode → deep-goal v2** *(large; the natural roadmap item)*. Multi-effort conducting is deep-goal-shaped work: a campaign note artifact (goals, shipped slices + hashes, rejected approaches, sequencing), each slice a full pipeline run, re-sequencing gates between slices. rigorous-change's campaign section is effectively the requirements doc for this feature — and as a conductor-level concern it stays on the paid side of the plugin boundary.

Items 1–6 all land in the **core deep-skills plugin** (plan template, deep-plan, deep-implement, deep-code-review); only 7 belongs to deep-goal itself. That preserves the one-directional coupling: core skills get better standalone, and deep-goal inherits the improvements through the stages it dispatches.

## 9. Consolidation recommendation

**Consolidate — with deep-* as the chassis and rigorous-change as the doctrine.** Do not maintain two overlapping procedures.

Reasoning:
- The two artifacts are **complementary, not duplicative**: rigorous-change's differentiators are portable *ideas* (Step 0, measure-first, activation path, campaign structure) that slot cleanly into deep-*'s existing seams (plan template, validation spec, situational checks, run report). deep-*'s differentiators are *infrastructure* (artifact contracts, advance tests, resume, config-as-data, host portability) that would be prohibitively expensive to rebuild inside a monolithic prose skill — and shouldn't be, since prose can't enforce independence.
- Merging in the other direction (deep-* mechanics into rigorous-change) is not viable: you can't get structural reviewer independence, crash-safe resume, or cross-host dispatch from a single-session prose procedure.
- The plugin boundary already answers the "one skill or two" product question: doctrine (items 1–6) strengthens the **free core**, campaign conducting (item 7) extends the **paid deep-goal** — consistent with keeping deep-goal loosely coupled and separately gated.

**Suggested path:**
1. Land §8 items 1–2 (activation path, Step-0 gate) in deep-plan — smallest diffs, biggest behavioral change.
2. Land items 3–5 (empirical validation, planning probes, dark-launch check) across deep-implement / deep-code-review, gated by rigor level so yolo/poc stay cheap.
3. Land item 6 (rejected-approaches ledger) in the plan template + run report.
4. Retire rigorous-change as a standalone procedure; keep it in `docs/` as the design rationale, credited to its author. Its judgment aphorisms ("measure before you reason," "be willing to say no," "don't loop reviewers for theater") could also ship as **seed Deep-Learn directive cards** — the registry is exactly the designed channel for doctrine-as-data, and it gives the coworker's work a visible, attributed home inside the merged product.
5. Schedule item 7 (campaign mode) as deep-goal's next major feature, using rigorous-change's campaign section as the spec.

**The one reason to keep them separate** would be if rigorous-change must remain usable with zero installation (a paste-anywhere doctrine for hosts where even the core plugin can't be installed). If that audience is real, keep a slim "judgment core" excerpt (~40 lines: Step 0, measure-first, tiering, activation path, anti-patterns) as a standalone doc — but treat it as an export of the merged skill, not a second source of truth.
