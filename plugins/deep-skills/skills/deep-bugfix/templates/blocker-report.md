<!-- Written when a cluster hits the fix cap (2 attempts) still unproven, or reverts on regression
     with no cap room left. Saved as `06-Bug-Fix/round-N/blocker-<CL-K>.md` (one file per blocked
     cluster, e.g. round-2/blocker-CL-3.md — the round dir + cluster id keep it collision-free
     across rounds) and linked by that path from the cluster's fix-summary record ("Artifacts"
     line). Also drives the notification message. -->

### ⛔ Blocker — Cluster <CL-K>: <one-line suspected/confirmed cause>

- **When:** <YYYY-MM-DD>, after <2> fix attempts.
- **Findings:** <CR-00X, CR-00Y, …> — statuses untouched (still `accepted`).
- **Branch:** `<branch>`. **Reverted** — the working tree is clean; unproven fixes are never committed.
- **What was tried:** <attempt 1: diagnosis + fix → proof verdict + rationale; attempt 2: what changed → verdict + rationale>
- **Why proof failed:** <the prover's rationale — the unevidenced hop, the unexplained cluster member, or the regression observed>
- **Best-understood cause:** <the diagnosis as it stands — confirmed, or still hypothesis, and what would settle it>
- **Reverted state:** <what the revert removed (files); any artifacts intentionally kept (e.g. a failing reproduction test, Phase 2)>
- **Recommended next step:** <the specific decision, information, or human fix needed — e.g. "confirm which of the two write paths is canonical", "needs a runtime repro; re-run with --reproduce", "escalate to /deep-plan — the fix is a redesign">
- **Notified:** <notification emitted? y/n>

<!-- Autonomous mode continues to the NEXT cluster after writing this — clusters are independent;
     a blocked cluster never strands the rest of the round. -->
