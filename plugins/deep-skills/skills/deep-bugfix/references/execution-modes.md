# Execution modes: collaborative vs autonomous

For multi-cluster runs, ask which mode if not passed as a flag (natural-language forms count: "just fix them all" / "run unattended" = autonomous; "check in with me per cluster" = collaborative). A single-cluster run executes one diagnose→fix→prove→contain pass; the mode only changes whether you gate before applying and committing.

## Collaborative

A **review gate per cluster** — and it sits *before the fix is applied*, not after: the user approves the diagnosis and the proposed fix, then the machinery proves it.

Per cluster:
1. Diagnose (fresh cluster agent) → confirmed cause + proposed minimal fix.
2. **Gate 1 — present**: the cluster's findings, the confirmed cause (explicitly compared to the review's hypothesis), and the proposed fix. User approves, redirects, or skips (`/skip-cluster`).
   - *Redirect* → relay to the cluster agent, re-present (counts against the attempt cap only if a fix was applied and failed proof).
   - *Skip* → record a skipped entry in `fix-summary.md`, statuses untouched, next cluster.
3. On approval: apply fix → adversarial proof → containment.
4. **Gate 2 — present**: the diff, the proof verdict (chain available via `/show-proof`), the containment result. Commit **only if the user asks**; then flip statuses, append the fix-summary record, continue.
5. No notifications needed — the user is present.

## Autonomous

**Continuous** execution — no gates. The user has stepped away (and typically enabled bypass-permissions).

Per cluster:
1. Diagnose → apply fix → adversarial proof → containment.
2. On `fixed` + clean containment: **commit the cluster (green-only)** per `references/commit-and-handoff.md`, flip the cluster's findings `accepted → fixed`, append the fix-summary record, continue automatically.
3. On `regressed`: revert immediately; re-attempt from clean if the cap allows.
4. On `unproven` at the attempt cap (2): **revert**, write `templates/blocker-report.md`, **notify** (`references/notifications.md`), do not commit the reverted work — then **continue to the next cluster** (clusters are independent; one blocked cluster never strands the rest).
5. On full-run completion: update the manifest, **notify** completion (clusters fixed / skipped / blocked).

Autonomous never force-pushes, never deletes user data, and never ships an unproven fix. It is "uninterrupted on proof, hard-stop per cluster on failure."

## Switching mid-run

The user can switch modes between clusters (e.g. autonomous through the nits, collaborative for the Blocker cluster). Honor the switch at the next cluster boundary.
