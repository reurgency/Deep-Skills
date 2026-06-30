<!-- Written when a phase hits the fix-cap (2 attempts) and stops. Appended to the plan's Phase Summaries appendix. Also drives the notification message. -->

### ⛔ Blocker — Phase <N>: <phase title>

- **When:** <YYYY-MM-DD>, after <2> fix attempts.
- **Branch / worktree:** `<branch>` / `<worktree path or none>`. Uncommitted (broken code is never committed).
- **What failed:** <the failing check + the actual error, scoped to changed files>
- **What was tried:** <attempt 1 → result; attempt 2 → result>
- **Suspected cause:** <best hypothesis>
- **Files in flight:** <created/modified so far>
- **To unblock, a human needs to:** <the specific decision or fix required>
- **Notified:** <notification emitted? y/n> · <hook fired? y/n>

<!-- Autonomous mode stops here — it does NOT proceed to later phases past a blocker. -->
