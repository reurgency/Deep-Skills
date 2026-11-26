---
name: rigorous-change
description: >-
  Land a change with rigor scaled to its risk, using adversarial review and empirical
  verification. Use when the user wants work done carefully and wants to trust the result:
  evaluate whether it's worth doing, tier the process to the blast radius, harden a plan with
  an adversarial reviewer, implement in isolation, verify by RUNNING real code, code-review the
  diff, commit without merging until approved, then merge and prove it live. Also covers CAMPAIGN
  mode — decomposing large/multi-session efforts into dependency-ordered, independently-shippable
  slices, the surfacing cadence (what to bring to the user), and the memory handoff that keeps a
  fresh agent productive. Trigger phrases: "use our strategy / the usual rigor", "evaluate then
  build", "do this properly", "plan it, review the plan, then build", "measure first", "don't merge
  until I say", "break this into slices", "hand off to a fresh session".
---

# Rigorous Change — risk-tiered build with adversarial review + empirical verification

A procedure for landing a change you can *trust*. Two ideas carry the weight:

1. **Measure before you reason.** The review agents are the same model as you — they share your
   blind spots. The decisions that actually change outcomes come from *running things on real
   data/real execution*, not from reasoning. When a plan hinges on an empirical question
   ("will this over-match?", "is it actually slow?", "is this feature even sound on real data?"),
   spend 5 minutes measuring it before you form the hypothesis you hand to a reviewer.
2. **Match the ceremony to the risk.** Full process on a 30-line reversible tweak is waste; a
   light touch on a data migration is reckless. Tier it (Step 1).

The value is in the judgment, not the steps. Spawn *independent* reviewers, weigh their findings
on the merits (don't rubber-stamp, don't capitulate), and stop when you genuinely converge.

## Step 0 — Decide if it's worth doing (and be willing to say no)

Before planning, do enough recon + measurement to answer: *is this the highest-value thing, and
is it even sound?* A process that can talk you **out** of work is more valuable than one that just
executes. This session, this gate killed three efforts before any code (an unsound feature proven
wrong on real data, a high-risk/low-gain refactor, a fix aimed at a misdiagnosed cause). If the
evaluation says "not worth it" or "the premise is false," report that with the evidence and stop —
that's a win, not a failure. Use a scoping/eval agent for the heavy measurement; keep the
conclusion, not the file dumps.

## Step 1 — Tier the rigor (triage on four axes)

Classify the change by **blast radius**, **reversibility**, **data mutation**, and **architectural
novelty**. Then pick the depth:

| Tier | Profile | Process |
|---|---|---|
| **Light** | contained, reversible, no data/schema change, well-trodden pattern (e.g. an adapter tweak, a scoped SQL change) | implement on a branch → **one** code-review → verify → commit |
| **Standard** | real logic, touches a shared path, but reversible | scout → plan → **plan-review** → implement (worktree if the tree is busy) → code-review → commit |
| **High** | data migration, new architecture, irreversible, or live-data mutation | full Standard **+** an extra adversarial pass on the riskiest claim, staged rollout, and a tested rollback/fallback |

When unsure, round up one tier. Don't apply High ceremony to a Light change — say which tier you
picked and why, in one line.

## Step 2 — Scout (proportional to tier)

Fan out read-only `Explore`/`Agent` searches to map the integration point, the data model, and —
the make-or-break — **where the value you write actually gets read** end-to-end. Pin exact
signatures and `file:line`. **Trust the scout's output**: don't re-derive what it already mapped.
Light tier: a quick self-read may be enough.

## Step 3 — Plan + adversarial plan-review (Standard/High)

Write the plan to a scratch file (deleted before commit). Cover: problem, locked decisions, the
**verified** integration facts, a pure/unit-testable core + thin IO wrapper where possible,
failure/fallback, tests, non-goals, blast radius — **plus two sections that are easy to forget:**

- **Activation path:** how does this go live (server restart / watch reload / client/MCP reconnect /
  migration on boot)? Plan it; don't discover it after merge.
- **Verification method:** the *empirical* check that will prove the core claim (a measurement, a
  probe, real-data run) — not just "tests pass."

Then loop: spawn an **independent** reviewer pointed at the plan *and the real code*, told to be
adversarial, cite `file:line`, and end with an explicit verdict. **Weigh** each finding — take the
legitimate fixes, reject speculative ones with a stated reason, hold your ground under pushback if
the counter-argument doesn't address the concern. Revise; re-review only if you didn't converge.
**Exception:** if the review forces a *blocker-level pivot* (the whole approach changes), do one
quick re-confirm of the revised approach before building — that's the case a bad revision slips
through. Don't loop reviewers for theater.

## Step 4 — Implement (isolated per tier)

Standard/High on a busy tree: build in a **git worktree** off the current branch, deps linked, and
**do not merge until the user approves** — see the `worktree-feature` skill for the exact
worktree/junction setup and the teardown order (it has a Windows junction-teardown hazard that wipes
source `node_modules` if you skip the unlink step). Light: a feature branch is fine. **The user can
also request a worktree explicitly** even when the tier/tree wouldn't otherwise call for one — e.g.
to run multiple concurrent development tasks in isolation. Honor that request regardless of tier. Match
surrounding style; reuse the helpers recon surfaced; every edit goes in the isolated path.

## Step 5 — Verify by RUNNING, not reasoning

Typecheck and run tests from inside the worktree with the project's own runner. Then do the thing
agent reasoning can't: **execute the change against reality.** Run it on the live/real data, probe
the latency, print the actual rows, watch the event loop. The strongest catches come here. If the
repo has pre-existing failures, filter to *your* files and say so.

## Step 6 — Code-review loop

Spawn an independent code-review agent over the diff (`git diff <base> -- <paths>`), adversarial,
`file:line`, explicit verdict — even for Light tier. Apply legitimate fixes, **re-verify** (rerun
tests/measurement), repeat until genuine convergence. A "should-fix" that's actually cosmetic gets
done if cheap or pushed back on with reasoning.

## Step 7 — Commit, hold the merge

Delete the scratch plan; stage only intended files; commit with a clear message + the user's
required trailer. **Do NOT merge** until the user approves. Report: what you built, the
verification result with **numbers**, the activation path, and the commit hash.

## Step 8 — After approval: merge, prove it live, capture

Merge; confirm it's **actually live** via the activation path you planned (don't assume — a stale
build/connection is the classic gap); **prove the change with a measurement** (the before/after, the
probe), not just "it merged"; tear down the worktree (correct order — see `worktree-feature`); and
**capture the decision/learning to memory** (what was chosen, what was rejected and why, any
corrected assumption) so the next session inherits it.

## Cross-cutting (the judgment core)
- **Measure before you reason** — and before you hand a hypothesis to a reviewer.
- **Be willing to conclude it isn't worth building.**
- **Plan the activation + verification path** as first-class.
- **Tier effort to risk; round up when unsure.**
- **Push back, weigh, don't capitulate; don't loop reviewers for theater.**
- **Capture decisions to memory** at the end of each round.

## Campaign mode — multi-slice work (and across sessions)

A single change uses the loop above. A LARGE effort (a redesign, a migration, a multi-part feature) is
a *campaign* — a sequence of changes — and needs structure the single-change loop doesn't give:
- **Decompose into dependency-ordered, independently-shippable slices.** Each slice is its own
  rigorous-change cycle: individually valuable, individually verifiable, merged with the user's
  approval before the next. Order by dependency (a later slice consumes an earlier one's output), not
  by ambition. Ship the foundational/seam-building slice even when its own payoff is modest, if later
  slices reuse it.
- **The plan is a hypothesis — re-sequence when measurement breaks it.** When a measure-first finding
  undercuts a slice's value or premise (the pile is diverse not duplicative; the anchors don't
  resolve), STOP and re-order or drop it — don't execute a now-wrong plan because it was the plan.
  Surface the re-sequence and its evidence.
- **Ship risky live-data mutations DARK + dry-run.** A handler that mutates the live store ships behind
  an off-by-default flag with a dry-run that LOGS what it would do, with justification. The dry-run IS
  the go/no-go gate — read the real output on real data before enabling; if it's unsound, park it.

## Surfacing cadence — what to bring to the user
The campaign's value comes from surfacing the RIGHT things: a measured surprise that shifts the
premise, a genuine fork with a real tradeoff, a "this isn't worth building" conclusion. Bring those —
with the evidence and a recommendation. Do NOT surface routine progress, choices with an obvious
default, or anything you can verify yourself; act and report concisely. The test: *would the user's
answer change what you do next?* Yes → surface. No → decide and move on.

## Session handoff — make the next agent as productive
Cross-session continuity lives in MEMORY, not context — a fresh agent inherits only what was written.
- **Recall first.** Before new work on an ongoing effort, recall + read the project's campaign memory:
  the goals, what shipped, what was tried-and-REJECTED and why, the open items. Don't re-derive or
  repeat settled decisions.
- **Keep one living campaign note** a fresh agent can read to reach your altitude — shipped (with
  commit hashes), what's live, rejected approaches (so they aren't retried), open items, current
  sequencing. Update it each slice; it IS the handoff.
- A campaign isn't done when the code merges — it's done when it's **verified live AND the memory
  reflects reality.**

## Anti-patterns
- One-size-fits-all ceremony (High process on a Light change, or vice-versa).
- Reasoning about an empirical question you could measure in 5 minutes.
- Building because you were asked, without checking it's the highest-value / sound thing.
- Discovering the activation path (it's not live!) after merge instead of planning it.
- Merging without approval; trusting "tests pass" without an empirical proof of the core claim.
- Re-reviewing a plan the reviewer already approved, or caving to asserted severity without evaluating it.
- Executing a slice the measurement just invalidated, because it was the plan.
- Over-surfacing (asking about obvious defaults) or under-surfacing (barreling past a premise-shift).
- Letting cross-session continuity live in context instead of memory — so the next agent re-derives or repeats settled work.
