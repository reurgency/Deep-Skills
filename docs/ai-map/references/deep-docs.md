<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-2 deep reference: loaded on demand. -->

# deep-docs - generation and refresh flows

## Flow 1: generate and publish (never half-write the map)

1. Intake resolves scope and quarantines human docs - `plugins/deep-skills/skills/deep-docs/references/intake-and-scope.md:36 (## Existing-docs quarantine policy)`
2. Survey: one fresh read-only agent per boundary, <=8 concurrent, `docs` stage tier - `plugins/deep-skills/skills/deep-docs/references/survey.md:19 (## Fan-out - one fresh agent per boundary)`
3. Layering: unanchored claims are dropped - `plugins/deep-skills/skills/deep-docs/references/survey.md:17 (## Fan-out - one fresh agent per boundary)`; tier-2 only if earned - `plugins/deep-skills/skills/deep-docs/references/layering-and-anchors.md:15 (## When a subsystem earns a tier-2 ref)`
4. Anchor-verify per card: symbol grep, +-5 line tolerance, re-snap or drifted - `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:14 (## Per-anchor re-resolution (the procedure))`
5. Publish gate: drifted/over-budget blocks the swap; blocked cards are regenerated first - `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:47 (## Publish gate)`
6. Index: `index.json` fingerprint rewritten after verify, before the mv - `plugins/deep-skills/skills/deep-docs/references/index-and-coverage.md:22 (## The alignment-fingerprint schema)`
7. Place: output to `docs/.ai-map.staging/` with `.in-progress`, then atomic rename over `docs/ai-map/` - `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:10 (## The staging + atomic-mv mechanism)`

## Flow 2: refresh (dual signal, git as accelerator)

1. Probe git alignment (clean, non-shallow, reachable `indexed_against_commit`); any failure means not aligned - `plugins/deep-skills/skills/deep-docs/references/refresh.md:22 (## The git-index alignment check)`
2. Aligned: `git diff --name-only <sha>..HEAD` maps to stale subsystems - `plugins/deep-skills/skills/deep-docs/references/refresh.md:22 (## The git-index alignment check)`
3. Not aligned: signal 1 re-runs anchor-verify (drifted marks subsystem stale) - `plugins/deep-skills/skills/deep-docs/references/refresh.md:11 (## The dual git-free signal)`
4. Signal 2 diffs current files against `file_set` (additions, deletions, new boundaries) - `plugins/deep-skills/skills/deep-docs/references/refresh.md:7 (## The dual git-free signal)`
5. Regenerate only the stale/new union, carry the rest forward verbatim - `plugins/deep-skills/skills/deep-docs/references/refresh.md:7 (## The dual git-free signal)`
6. Rewrite fingerprint every run; promote to fast path after consecutive clean rounds, re-derived each run - `plugins/deep-skills/skills/deep-docs/references/refresh.md:50 (## The convergence model (operational rule))`
