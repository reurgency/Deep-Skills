<!-- One record per cluster, appended to `.deep-skills/<effort>/06-Bug-Fix/round-N/fix-summary.md`
     AS EACH CLUSTER CLOSES (fixed, skipped, or blocked) - never batched to run-end.
     The file opens with the round header once; records accumulate under it.
     On close, the record's "Confirmed cause" line is filled from the cluster's diagnosis file
     (`round-N/diagnosis-<CL-K>.md`, templates/diagnosis.md). -->

# Bug-fix round <N> - <effort-name>

> **Started:** <YYYY-MM-DD> · **Source:** <findings.json path | bug report | failing test> · **Mode:** <collaborative | autonomous> · **Scope:** [scope.json](scope.json)
> **Base:** <session model id> · **Max:** <smartest | smarter | smart> · **Models:** diagnose <id>, fix <id>, proof <id>< (sev ≥5) / <id> (sev <5)>, containment <id | scripted> <- note any access fallback as `<id> (fallback from <id>)`>

---

## Cluster <CL-K> - <one-line confirmed cause> · <fixed | skipped | blocked>

- **Findings in cluster:** <CR-00X, CR-00Y, …> (<severities/tiers>) <- note any split/merge from the provisional plan>
- **Confirmed cause:** <from [diagnosis-<CL-K>.md](diagnosis-<CL-K>.md) - the diagnosed root cause, one paragraph, with path:line evidence>
  - **vs the review's hypothesis:** <upheld | partially upheld | rejected> - <what the recommendation guessed, and where the diagnosis agreed/diverged>
- **The fix:** <files changed (path:line) + what changed> - **why minimal:** <why this is the smallest change at the cause; what was deliberately NOT touched>
- **Proof:** tier `<chain-trace | red-green>` · model tier `<smartest | smarter | smart>` (<model id>) · verdict **`<fixed | unproven | regressed>`**
  - <the hop-by-hop chain (or test file + red/green observations); one chain per finding - summarize shared hops>
- **Containment:** <1 hop | 2 hops (escalated: exported symbol | /widen)> · <N dependents, tests run, typecheck result> · **<clean | new failures (reverted)>**
- **Commit:** `<sha>` - `fix(<scope>): <cause> - resolves <ids>` <or "not committed (collaborative - user declined)" / "reverted">
- **Artifacts:** <reproduction test path (Phase 2), blocker report path, anything else this cluster produced>

<!-- Skipped cluster: keep the header + Findings lines, then one line: "Skipped by user at the diagnosis gate - statuses untouched."
     Blocked cluster: keep header + Findings + Confirmed cause (if reached), link the blocker report, state "reverted - statuses untouched." -->
