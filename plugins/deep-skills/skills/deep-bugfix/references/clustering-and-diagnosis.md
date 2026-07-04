# Clustering and diagnosis — one cause, one fix

Fixing N findings one-by-one yields N symptom patches. The benchmark corpus is the proof: PR#65's CR-001…006 survived review as six distinct findings sharing **one** cause (a write path whose runtime reader resolves a different source). Review-time dedup merges *duplicate reports of the same defect*; bug-fix clustering is a **coarser, cause-level grouping across genuinely-distinct defects** — a different altitude, and the altitude where the real fix lives.

## Clustering heuristics — group by suspected shared cause

Cluster two defects when their evidence points at one underlying cause. The signals, in rough strength order:

1. **Same subsystem** — evidence paths land in the same service/module/feature area.
2. **Same failure shape** — the defects describe the same *class* of wrongness (e.g. several "writer's value never reaches the runtime reader" findings; several "cache never invalidated" findings), even when the symptoms differ.
3. **Overlapping evidence paths** — the cited files/symbols intersect, or one defect's evidence chain passes through another's changed site.

A defect matching no cluster forms its own singleton — a cluster of one is normal, not a failure. Record the resulting provisional plan (cluster id, member defect ids, one-line suspected cause) in `round-N/scope.json` before any agent launches.

## Clusters are hypotheses

The cluster plan is provisional until diagnosis confirms it:

- **Split** when diagnosis reveals divergent causes — N confirmed causes inside one cluster ⇒ N clusters, N fixes. Never force one fix over two causes.
- **Merge** when diagnosis proves two clusters share one cause — one fix, one proof, both clusters' findings resolved together.
- Every split/merge is appended to `scope.json` as an updated cluster entry (append-only) and noted in the cluster's `fix-summary.md` record.

The proof stage enforces the flip side: the proof agent must show **each finding in the cluster** resolved by the one fix — a cluster that only proves its exemplar is a false merge, and the unproven members split back out.

## The diagnose + fix agent — one fresh agent per cluster

Diagnose and fix are **one agent** (unlike review/implement's stage-per-agent split): remediation needs continuity — the agent that found the cause should author the fix. Clusters are independent, so diagnose+fix agents may run as one parallel batch (collaborative mode gates per cluster instead — see `references/execution-modes.md`). Model: the high-reasoning tier per `references/model-map.md`, set explicitly at launch.

### Briefing template

Each agent receives — and only receives:

- **The cluster's defects**: ids, titles, severities, and full `evidence` blocks (path:line, symbol, observed behavior).
- **The suspected shared cause** (one line, from the cluster plan) — labeled *suspected*.
- **Repo access** — read the code; diagnosis is code-reading, not recollection.
- **The plan** (when the effort has one) — for conformance *context* only: what the behavior was supposed to be.
- **The recommendation, flagged**: every `recommendation_hypothesis` is passed under the header **"hypothesis — do not trust"**. The review (or reporter) guessed at the cause; the agent must confirm or reject that guess with its own trace before touching code.

It never receives the implementer's transcript, the reviewer's transcript or reasoning, or any prior fix attempt's chat history — evidence only, fresh eyes.

### What the agent must do

1. **Diagnose to a confirmed root cause.** Trace from each defect's evidence to the mechanism that produces it, with cited `path:line` evidence per hop. Confirmation means the trace *explains every defect in the cluster*; a cause that explains only some members means the cluster splits.
2. **Compare against the hypothesis.** State explicitly whether the review's recommendation named the true cause — this comparison is recorded in `fix-summary.md` (and feeds `--learn` in Phase 4).
3. **Fix minimally at the cause.** The smallest change that corrects the mechanism — no drive-by refactors, no symptom-side patches layered on top, no scope creep. If the "fix" would be a redesign, stop and surface it (that's `/deep-plan`'s job, and a blocker report here).
4. **Report back** the confirmed cause, the diff, and its own claimed-fix rationale — which then goes to a **separate** adversarial proof agent (`references/proof-of-fix.md`). The fixer never marks its own homework.

## Attempt cap

**2 attempts per cluster, total** — counting the initial fix and any post-`unproven` retry (see the failed-proof policy in `references/proof-of-fix.md`). A resumed cluster after a crash re-diagnoses from scratch (the agent's state is gone; evidence + diff are re-read) and that counts as attempt 1. At the cap: revert, write `templates/blocker-report.md`, notify, move to the next cluster.
