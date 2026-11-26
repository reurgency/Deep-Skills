<!-- One file per cluster: `.deep-skills/<effort>/06-Bug-Fix/round-N/diagnosis-<CL-K>.md`.
     Written by the cluster's DIAGNOSE agent (read-only otherwise); read by the FIX agent (its only
     cause input), the proof agent (the confirmed-cause statement), and - when the cluster closes -
     copied into the cluster's fix-summary.md "Confirmed cause" line (and root-causes.json under --learn).
     A retry, a redirect, or a diagnosis-disputed re-run REWRITES this file (fresh diagnose agent);
     whenever an attempt fails (attempt 1 or 2 - before any revert, retry or cap handling), the orchestrator appends a "> **Refuted:** <unproven | regressed | diagnosis-disputed> - <reason>"
     line here so a crash-resume knows this attempt failed (the rewrite removes it).
     Split: each new cluster id gets its own file; the original file's first line becomes
     "Superseded by <CL-Ka>, <CL-Kb>". See references/clustering-and-diagnosis.md. -->

# Diagnosis - cluster <CL-K> - <effort-name> · round <N>

> **Attempt:** <1 | 2> · **Written:** <YYYY-MM-DD> · **Diagnose model:** <model id><; rewritten after: unproven proof | diagnosis-disputed | user redirect - one line on why>
> **Defects:** <CR-00X, CR-00Y, … | BF-00N> (<severities>)

## Diagnosis

- **Confirmed cause:** <one paragraph - the mechanism that produces every defect in the cluster>
- **Causal chain:** <hop-by-hop, a cited `path:line` (or named symbol) per hop, from each defect's evidence to the cause>
  - <CR-00X: evidence site → … → causal site>
  - <CR-00Y: …>
- **vs the review's hypothesis:** <upheld | partially upheld | rejected | none given> - <what the recommendation guessed, and where this diagnosis agreed/diverged>
- **Fix approach:** <the smallest change that corrects the mechanism, at the cause - what changes, not the diff itself>
- **Files to touch:** <path (and line/symbol) for each file the fix agent may edit; anything beyond these (other than a trivially adjacent import/type) is a dispute>
- **Deliberately not touched:** <adjacent code a symptom-patch would reach for, and why it stays>
- **Split / merge:** <none | this cluster splits into <ids> because <divergent causes> | merges with <CL-J> because <one cause>>
- **Redesign needed?** <no | yes - <why>; stop: blocker report, route to /deep-plan>
