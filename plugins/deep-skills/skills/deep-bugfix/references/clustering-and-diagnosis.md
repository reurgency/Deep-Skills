# Clustering and diagnosis - one cause, one fix

Fixing N findings one-by-one yields N symptom patches. The benchmark corpus is the proof: PR#65's CR-001…006 survived review as six distinct findings sharing **one** cause (a write path whose runtime reader resolves a different source). Review-time dedup merges *duplicate reports of the same defect*; bug-fix clustering is a **coarser, cause-level grouping across genuinely-distinct defects** - a different altitude, and the altitude where the real fix lives.

## Clustering heuristics - group by suspected shared cause

Cluster two defects when their evidence points at one underlying cause. The signals, in rough strength order:

1. **Same subsystem** - evidence paths land in the same service/module/feature area.
2. **Same failure shape** - the defects describe the same *class* of wrongness (e.g. several "writer's value never reaches the runtime reader" findings; several "cache never invalidated" findings), even when the symptoms differ.
3. **Overlapping evidence paths** - the cited files/symbols intersect, or one defect's evidence chain passes through another's changed site.

A defect matching no cluster forms its own singleton - a cluster of one is normal, not a failure. Record the resulting provisional plan (cluster id, member defect ids, one-line suspected cause) in `round-N/scope.json` before any agent launches.

## Clusters are hypotheses

The cluster plan is provisional until diagnosis confirms it:

- **Split** when diagnosis reveals divergent causes - N confirmed causes inside one cluster ⇒ N clusters, N fixes. Never force one fix over two causes.
- **Merge** when diagnosis proves two clusters share one cause - one fix, one proof, both clusters' findings resolved together.
- Every split/merge is appended to `scope.json` as an updated cluster entry (append-only) and noted in the cluster's `fix-summary.md` record. New cluster ids get new diagnosis files; the original's file is marked superseded (§ The diagnosis file).

The proof stage enforces the flip side: the proof agent must show **each finding in the cluster** resolved by the one fix - a cluster that only proves its exemplar is a false merge, and the unproven members split back out.

## Diagnose agent, then fix agent - two fresh agents per cluster

Each cluster gets **two agents in sequence**: a **diagnose agent** that confirms the root cause and writes it down, then a **fix agent** that implements exactly what the diagnosis file says. (Earlier versions used one fused diagnose + fix agent for continuity - the agent that found the cause authored the fix. The split moves that continuity from "same agent" to "written record": the `--max` model authors the diagnosis, the stage model implements it.) Clusters are independent, so diagnose agents may run as one parallel batch, and so may fix agents (collaborative mode gates per cluster instead - see `references/execution-modes.md`). Each cluster has its own diagnosis file, so parallel diagnose agents never share a file.

**Agent tiers** (fleet notation per `references/model-map.md`; stage = `bugfix`, i.e. `stages.<max>.bugfix` in the merged `references/model-map.json`; model set explicitly at launch):

| Agent | Tier |
|---|---|
| diagnose agent (read-only) | `max` - the `--max` tier itself |
| fix agent | `stage` |
| adversarial proof agent - cluster has any defect at sev ≥5, or an unset severity | `max` (`references/proof-of-fix.md`) |
| adversarial proof agent - every defect sev <5 | `stage` |
| containment / test runs (when an agent runs them at all) | `two down`, floor `smart` (`references/containment.md`) |

### The diagnosis file - `round-N/diagnosis-<CL-K>.md`

The diagnose agent writes `.deep-skills/<effort>/06-Bug-Fix/round-N/diagnosis-<CL-K>.md` (shape: `templates/diagnosis.md`), one file per cluster. Its `## Diagnosis` record holds the confirmed cause, the cited `path:line` chain, the comparison against the review's hypothesis, the fix approach, and the files to touch. It is the **only** cause input the fix agent receives, the confirmed-cause statement the proof agent receives, and the source of the cluster's `fix-summary.md` "Confirmed cause" line (and, under `--learn`, its `root-causes.json` record) when the cluster closes.

**Split/merge naming.** When diagnosis splits a cluster, each new cluster id gets its own file (`diagnosis-<CL-Ka>.md`, `diagnosis-<CL-Kb>.md`, …) and the original file gains a first line `Superseded by <ids>`. A merge writes one file under the surviving cluster id; the absorbed cluster's file gains `Superseded by <id>`.

### Diagnose agent - briefing

Each diagnose agent receives - and only receives:

- **The cluster's defects**: ids, titles, severities, and full `evidence` blocks (path:line, symbol, observed behavior).
- **The suspected shared cause** (one line, from the cluster plan) - labeled *suspected*.
- **Repo access** - read the code; diagnosis is code-reading, not recollection. **Read-only**: it edits nothing except its own diagnosis file.
- **The plan** (when the effort has one) - for conformance *context* only: what the behavior was supposed to be.
- **The recommendation, flagged**: every `recommendation_hypothesis` is passed under the header **"hypothesis - do not trust"**. The review (or reporter) guessed at the cause; the agent must confirm or reject that guess with its own trace.
- **On a retry or redirect only:** the failed proof's rationale (attempt 2 after `unproven`), the fix agent's `diagnosis-disputed` reason, or the user's redirect note (collaborative) - and the previous diagnosis file, which it rewrites.

It never receives the implementer's transcript, the reviewer's transcript or reasoning, or any prior attempt's chat history - evidence only, fresh eyes.

### Diagnose agent - what it must do

1. **Diagnose to a confirmed root cause.** Trace from each defect's evidence to the mechanism that produces it, with cited `path:line` evidence per hop. Confirmation means the trace *explains every defect in the cluster*; a cause that explains only some members means the cluster splits.
2. **Compare against the hypothesis.** State explicitly whether the review's recommendation named the true cause - this comparison is recorded in `fix-summary.md` (and feeds `--learn`).
3. **Write the fix approach - minimal, at the cause.** The smallest change that corrects the mechanism and the files to touch - no drive-by refactors, no symptom-side patches, no scope creep. If the fix would be a redesign, say so in the file and stop: that's `/deep-plan`'s job, and a blocker report here.
4. **Write `diagnosis-<CL-K>.md` and return** a one-paragraph summary. It changes no source.

### Fix agent - briefing

Each fix agent receives - and only receives:

- **The cluster's diagnosis file** (`round-N/diagnosis-<CL-K>.md`) - its **only** cause input. It never re-diagnoses.
- **The cluster's defects** (ids + evidence blocks) - so it knows what the fix must resolve.
- **Repo access** (write) - inside the worktree under `--worktree`.
- **Under `--reproduce`:** the red→green protocol (`references/proof-of-fix.md`) - it writes the reproducing test first and records the pre-fix red before applying the fix.

It never receives transcripts, the recommendation (the diagnosis already weighed it), or prior attempts' chat history.

### Fix agent - what it must do

1. **Implement only the diagnosis file's fix approach**, touching only the files it names (a trivially adjacent line - an import, a type - is fine; anything more is a dispute).
2. **If it judges the diagnosis wrong** (the named site doesn't produce the defect, the approach can't work, or the fix needs files the diagnosis didn't name in a non-trivial way), it **stops without editing further** and returns `diagnosis-disputed` with a one-paragraph reason. Any edits it made are reverted. See § Attempt cap for what happens next.
3. **Report back** the diff and its claimed-fix rationale - which then goes to a **separate** adversarial proof agent (`references/proof-of-fix.md`). The fixer never marks its own homework.

## Attempt cap

**2 attempts per cluster, total.** An attempt is one **pair - a diagnose agent plus a fix agent**: the initial pair, plus at most one retry. No third loop.

- **`unproven` ⇒ attempt 2** = a **fresh diagnose agent** (given the failed proof's rationale and the previous diagnosis file, which it rewrites) + a fresh fix agent, then a fresh proof agent (see the failed-proof policy in `references/proof-of-fix.md`).
- **`regressed` ⇒ revert**, then attempt 2 from clean, same shape.
- **`diagnosis-disputed` consumes an attempt.** A dispute on attempt 1 ⇒ one fresh diagnose agent (given the dispute reason) rewrites the file, then a fresh fix agent runs - that is attempt 2. A dispute on attempt 2 ⇒ the cluster is `unproven`.
- **Persist the refutation:** the moment an attempt fails - an `unproven` or `regressed` proof verdict, a containment failure (handled as `regressed`, `references/containment.md`), or a `diagnosis-disputed` stop - and **before** any revert, retry or cap handling, append a line `> **Refuted:** <unproven | regressed | diagnosis-disputed> - <one-line reason>` to the diagnosis file. This applies to attempt 2 as well; it is what lets a resume detect the cap. Only the next attempt's diagnose agent removes it (its rewrite drops the line).
- **Resume after a crash:** a cluster with *any* `fix-summary.md` record (`fixed`, `skipped` or `blocked`) is closed and is not resumed. A diagnosis file whose first line is `Superseded by ...` is never reused - resume its successor clusters instead. Otherwise revert any leftover diff from the crashed attempt and take the attempt number from the file's `Attempt:` header (no file means attempt 1), then:
  - **`Refuted:` line present** - that attempt failed: run the next attempt (a fresh diagnose agent given the refutation reason and this file, which it rewrites), or, if that attempt was already 2, the cluster is at the cap (revert, blocker report, append its `blocked` record to `fix-summary.md`, notify).
  - **No `Refuted:` line** - **reuse** the file and run the fix agent as that same attempt. In collaborative mode re-present Gate 1 first (`references/execution-modes.md`), since a crash may have come before approval.
  - **No diagnosis file** - re-diagnose from scratch as attempt 1.

At the cap: revert, write `templates/blocker-report.md`, notify, move to the next cluster.
