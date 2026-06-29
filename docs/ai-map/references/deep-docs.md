<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-2 reference: loaded on demand. Deep cross-layer data-flow trace for one subsystem. Every hop anchored. -->

# deep-docs — generate pipeline

> **Load when:** tracing the map-generation pipeline (intake → survey fan-out → layering → verify fan-out → index → staging → atomic mv) or the crash-safety/double-run invariant.
> Card: [subsystems/deep-docs.md](../subsystems/deep-docs.md)

## The flow it traces

The default-mode pipeline turns a target repo into a tier-layered, anchored, verified orientation map. It is a cross-stage data flow where each stage's output is the next stage's input, ending in a crash-safe atomic placement.

## Hop-by-hop

1. **Intake & scope** — three input modes; existing human docs are quarantined as external-unverified pointers, never ingested into a trusted tier. — `plugins/deep-skills/skills/deep-docs/references/intake-and-scope.md:1 (Intake & scope)` · `plugins/deep-skills/skills/deep-docs/SKILL.md:10 (Documents, never decides)`

2. **Survey (fan-out per boundary)** — directory-primary boundary discovery; a survey agent fans out per boundary, returning purpose/entry/invariants + anchor candidates. — `plugins/deep-skills/skills/deep-docs/references/survey.md:1 (Survey)`

3. **Layering with anchors** — three tiers built (tier-0 MAP+index, tier-1 cards, tier-2 refs); **load-bearing invariant:** every claim carries a file:line (symbol) anchor or it is fiction. — `plugins/deep-skills/skills/deep-docs/references/layering-and-anchors.md:1 (Layering & anchors)` · `plugins/deep-skills/skills/deep-docs/SKILL.md:19 (Every claim is anchored or it's fiction)`

4. **Anchor-verify (fan-out per card)** — always-on; a fresh agent re-resolves every anchor (symbol-primary, ±5-line re-snap) and returns a verdict. A drifted/over-budget anchor blocks publish. — `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:1 (Anchor-verify)`

5. **Index** — emit `index.json` (machine index) + `coverage.md` (honesty artifact) from the verified card set. — `plugins/deep-skills/skills/deep-docs/references/index-and-coverage.md:1 (Index & coverage)`

6. **Place & report (staging → atomic mv)** — **crash-safety invariant:** never half-write the map. Write to a staging dir under a `.in-progress` marker, then atomically `mv` into place; a present marker makes a re-run refuse rather than corrupt. — `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:1 (Place & report)`

## Outputs

`docs/ai-map/{MAP.md,index.json,subsystems/*,references/*,coverage.md}` + (effort mode) `07-Docs/` pointer + manifest line. Changes no code in the target repo. — `plugins/deep-skills/skills/deep-docs/SKILL.md:10 (Documents, never decides)`
