<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-2 deep reference: loaded on demand. Every hop carries a path:line (symbol) anchor. -->

# deep-bugfix - deep reference

## Flow 1: accepted finding to fixed status

1. Intake: findings.json `recommendation` is renamed `recommendation_hypothesis`; only the `accepted` set loads, `fixed` excluded - `plugins/deep-skills/skills/deep-bugfix/references/intake.md:13 (## The normalized defect shape)`, `plugins/deep-skills/skills/deep-bugfix/references/intake.md:36 (## Scope rules - what enters the round)`
2. Round start: `scope.json` (defects + provisional clusters) is written before any cluster work - `plugins/deep-skills/skills/deep-bugfix/references/intake.md:40 (## Round start - persist `scope.json` before any cluster work)`
3. Clusters are hypotheses: split on divergent causes, merge on one cause; entries appended, never rewritten - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:19 (## Clusters are hypotheses)`
4. Diagnose agent (read-only, max tier) gets evidence, the recommendation under "hypothesis - do not trust", never transcripts; writes the diagnosis file - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:45 (### Diagnose agent - briefing)`
5. Fix agent receives the diagnosis file as its only cause input; edits only named files or returns `diagnosis-disputed` - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:70 (### Fix agent - briefing)`, `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:81 (### Fix agent - what it must do)`
6. Collaborative Gate 1 sits before the fix agent runs - `plugins/deep-skills/skills/deep-bugfix/references/execution-modes.md:5 (## Collaborative)`
7. Fresh proof agent re-derives everything; static chain-trace needs a cited path:line per hop per defect - `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:12 (## The static chain-trace tier (default))`; under --reproduce it re-runs red and green itself - `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:34 (## The dynamic red→green tier (`--reproduce`))`
8. Containment: 1 hop of dependents + full typecheck, baseline-compared - `plugins/deep-skills/skills/deep-bugfix/references/containment.md:5 (## The default: 1 hop + full typecheck)`
9. Commit only on fixed + clean containment: `fix(<scope>): <cause> - resolves CR-00X` - `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:38 (## Commits - one per proven cluster)`
10. On fixed only: flip `accepted -> fixed` in findings.json and append the fix-summary record - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:94 (### 8. Statuses & round artifacts)`

## Flow 2: failure, attempt cap and crash resume

1. Failure verdicts: regressed reverts at once; unproven gets one retry; a dispute consumes an attempt - `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:68 (## Failed-proof policy)`, `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)`
2. Before any revert or retry, append `> **Refuted:** <reason>` to the diagnosis file; the next diagnose rewrite drops it - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)`
3. Containment failure is handled as regressed (revert) - `plugins/deep-skills/skills/deep-bugfix/references/containment.md:17 (## Verdict: block only on NEW failures)`
4. At cap 2: revert, blocker report, append a `blocked` record, notify - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)`, `plugins/deep-skills/skills/deep-bugfix/references/notifications.md:3 (# Notifications)`
5. Resume scan: next round = max+1; rounds append-only - `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:50 (## Re-entry & resume)`
6. Closed cluster = any fix-summary record (fixed/skipped/blocked) or diagnosis line 1 `Superseded by ...`; judged by latest scope.json entry - `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:51 (## Re-entry & resume)`
7. Resume set = unclosed clusters minus defects already fixed in findings.json - `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:46 (## Re-entry & resume)`
8. Crashed cluster: revert leftover diff; Refuted present -> next attempt (or cap -> blocked); absent -> reuse diagnosis and re-present Gate 1; no file -> attempt 1 - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)`
9. Split/merge naming: original diagnosis gets first line `Superseded by <ids>` - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:39 (### The diagnosis file - `round-N/diagnosis-<CL-K>.md`)`
