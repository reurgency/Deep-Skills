# deep-bug-fix — Design Rationale

> **Training material. Stage: design outline, not yet planned or built.** There is no skill tree
> and no `/deep-plan` artifact yet — only a design note. This page derives entirely from
> `docs/roadmap/DEEP-BUG-FIX-DESIGN.md`; anchors point there.
>
> **The skill's one job:** **diagnosis-first remediation of existing behavior under regression
> risk** — root-cause clustering, proof-of-fix, and blast-radius containment that `/deep-implement`
> structurally lacks (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:5`). **Signature failure it hunts:**
> the **claimed fix** — a change that makes the reproduction stop without addressing the root
> cause, or that patches one symptom of a cluster and silently leaves its siblings
> (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:52-59`).

## Decisions at a glance
- [1. A dedicated skill at all (vs re-running deep-implement on findings)](#1-a-dedicated-skill-at-all)
- [2. Diagnosis before remediation; the recommendation is a hypothesis](#2-diagnosis-before-remediation)
- [3. Root-cause clustering — one fix per cause](#3-root-cause-clustering)
- [4. Proof-of-fix in two tiers, always a real guarantee](#4-proof-of-fix-two-tiers)
- [5. Reproduce-before-fix is opt-in (`--reproduce`), not default](#5-reproduce-before-fix-is-opt-in)
- [6. Regression containment is default](#6-regression-containment-is-default)
- [7. A tuned independence model (continuity to diagnose, fresh agent to prove)](#7-tuned-independence-model)
- [8. Boundary: triage still decides; bug-fix only executes the `accepted` set](#8-boundary-triage-still-decides)
- [9. Deep-Learn `--learn` emits a cause-truthed record](#9-deep-learn---learn-record)

---

## 1. A dedicated skill at all
**What it does.** deep-bug-fix exists as a 5th skill instead of routing findings back through
deep-implement. The design opens by taking the cheaper alternative seriously: `/deep-code-review
--triage` already routes accepted findings into a fix-phase appended to the plan, which
`/deep-implement` then executes cold — so "re-run DeepImplement on the findings" is the *current*
design, not a strawman (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:11`).
**Alternatives considered / rejected.** Keep using deep-implement as the fix-phase executor
(rejected as insufficient); merely wrapping deep-implement "more nicely" (explicitly rejected —
the bar is doing what deep-implement is *structurally incapable* of)
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:13`).
**Why this choice.** deep-implement is forward construction from a trusted spec: known steps, adds
code, gates on *new* failures in changed files. Bug-fixing inverts all four assumptions — the spec
is unknown (must diagnose first), you modify working code (highest-risk edit class), findings often
share one root cause, and "done" means *provably gone* not "the step ran." Pointing a fresh agent
at `findings.json` and saying "fix these" yields N symptom patches with no proof and no regression
guard (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:13-20`).

## 2. Diagnosis before remediation
**What it does.** Two disciplines anchor the design: the finding's recommendation is a **hypothesis,
not a spec** (deep-bug-fix re-diagnoses independently and may reject the suggested fix), and **no
proof of fix ⇒ not fixed** (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:24-27`).
**Alternatives considered / rejected.** Trusting the review's proposed remedy. Rejected because
real findings hedge their own cause — the corpus example CR-001 literally says "Register the route
**or** correct the service URL" (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:26`).
**Why this choice.** This is the inverse of code-review's independence rule: don't anchor on the
proposed remedy. A recommendation written by an agent that was *guessing* at cause is not a spec
you can build against (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:26`).

## 3. Root-cause clustering
**What it does.** Group distinct findings by *shared underlying cause* and apply one fix per cause
(default mode) (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:33`).
**Alternatives considered / rejected.** Fixing findings one-by-one (yields symptom patches); and
relying on code-review's existing dedup. The design pre-empts the "isn't this redundant with
review-time dedup?" objection explicitly (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:39-41`).
**Why this choice.** Review-time dedup merges *duplicate reports of the same defect*; bug-fix
clustering is a *coarser, cause-level grouping across genuinely-distinct defects* — a different
altitude. The seed corpus is the proof: PR#65's CR-001…006 survived as six distinct findings that
shared one cause ("a write path whose runtime reader resolves a different source"). That is the
altitude where the real fix lives (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:41`).

## 4. Proof-of-fix, two tiers
**What it does.** The skill never ships a "claimed fix." Default tier is a **static chain-trace
proof** (walk the root-cause chain hop-by-hop, reusing code-review's last-mile methodology,
asserting corrected behavior with cited evidence per hop). The `--reproduce` tier upgrades to a
dynamic **red→green** test. Both tiers are gated by an adversarial proof agent — "the fixer does
not mark its own homework" (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:44-50`).
**Alternatives considered / rejected.** Accepting a claimed fix on the fixer's own say-so.
**Why this choice.** Regression containment proves you didn't *break* working code; it does not
prove you *fixed* the bug — so a separate positive proof is required, and it must be checked by
someone other than the author (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:27,50`).

## 5. Reproduce-before-fix is opt-in
**What it does.** A failing-then-passing reproduction test is `--reproduce`, **opt-in**, not the
default (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:34`).
**Alternatives considered / rejected.** Making red→green mandatory for every fix.
**Why this choice.** Some bugs genuinely can't be reproduced cheaply; the static chain-trace proof
gives a real guarantee at the default tier, and when a bug can't be reproduced "that is itself a
reported finding — never a silent skip." Proof *scales with the mode chosen at invocation* rather
than forcing the most expensive proof on every defect
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:45,48`).

## 6. Regression containment is default
**What it does.** Default-on: identify changed symbols, find their callers/dependents, and re-run
their tests (`--worktree` to isolate) (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:35,75`).
**Alternatives considered / rejected.** deep-implement's validation, which "validates the changed
file's imports, not its dependents" — insufficient for the modify-working-code edit class
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:35`).
**Why this choice.** The danger in bug-fixing is regressing the things that depended on the buggy
behavior; that risk lives in the *dependents*, so containment must look outward from the change,
not just inward (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:16,35`).

## 7. Tuned independence model
**What it does.** Independence is tuned per stage: **diagnose + fix is one agent per cluster**
(bug-fixing needs continuity — the agent that found the cause authors the fix), while **proof is a
fresh, adversarial agent** that tries to *refute* "fixed" and returns `fixed | unproven |
regressed` (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:62-67`).
**Alternatives considered / rejected.** The series' default — withhold the prior transcript and
split every stage across fresh agents (as review and implement do). Applied *uniformly*, that would
sever the diagnose→fix continuity bug-fixing depends on.
**Why this choice.** The series enforces independence by withholding transcripts; deep-bug-fix keeps
that DNA exactly where it pays — the proof stage, so the fixer can't grade itself — but relaxes it
where continuity is the whole point. The fix agent still gets evidence + codebase + plan but *not*
the implementer's transcript, and the recommendation arrives flagged "hypothesis — do not trust"
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:61-67`).

## 8. Boundary: triage still decides
**What it does.** Triage stays the decision step (fix / defer / reject); deep-bug-fix is the
*specialized executor* for the `accepted` set only — it makes no triage decisions and touches
neither `deferred` nor `rejected` findings. It replaces deep-implement as the fix-phase executor
(keeping deep-implement a pure feature-builder) and also runs standalone on a raw bug report /
trace / failing test (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:85-87`).
**Alternatives considered / rejected.** Letting the fixer also decide *whether* to fix (collapsing
triage into bug-fix); keeping deep-implement's fix-phase path as the primary route (the design
proposes deprecating it in favor of routing to deep-bug-fix)
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:86`).
**Why this choice.** One skill, one job — the series' separation-of-concerns rule. Triage is a
decision; bug-fix is an execution; conflating them re-couples what the pipeline deliberately split.
Running standalone mirrors how code-review runs on any PR/branch, not just deep-* efforts
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:85-87`).

## 9. Deep-Learn `--learn` record
**What it does.** Under `--learn` (opt-in), the skill emits `root-causes.json` — cluster → confirmed
cause → taxonomy class → fix → findings resolved — to feed the future Deep-Learn Pattern Ledger
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:36,102-104`).
**Alternatives considered / rejected.** Continuing to feed the Distiller only `findings.json`, which
carries the review's *guess* at root cause.
**Why this choice.** Fix-time is where cause becomes *ground truth* — the confirmed cause (proven by
the fix) plus which findings collapsed into one cluster is strictly better signal for the Ledger's
recurrence and overfitting guards than review's guess. It is opt-in because Deep-Learn isn't built
yet, making the reader a forward dependency (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:36,104`).

---

### Where rationale was *not* recovered
The design note records its own **open questions** (resolve in `/deep-plan`): the stage
number / round model for multiple review→fix→re-review rounds, the exact normalized defect shape
across the three standalone inputs, whether to remove deep-implement's triage-routed fix-phase path
or keep it as a fallback, regression-scope discovery by grep vs LSP vs an existing util, and whether
the proof agent can literally reuse code-review's last-mile verifier brief
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:106-112`). These are unresolved *by design* at this stage —
not missing rationale, but decisions deferred to the eventual planning pass.
