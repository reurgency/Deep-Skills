<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-docs

> **Load when:** editing the deep-docs skill, its map pipeline (survey, anchor-verify, place, refresh), or its templates · **~tokens:** ~1.3k est
> **Deep ref:** [references/deep-docs.md](../references/deep-docs.md)

## Purpose

Skill that writes a standing, tiered (MAP.md + index.json / subsystem cards / deep refs), anchor-verified orientation map `docs/ai-map/`; documents only, never edits application source. - `plugins/deep-skills/skills/deep-docs/SKILL.md:7 (# DeepDocs)`

## Entry points

- `/deep-docs`, args: path scope, `--refresh`, `--max=<smartest|smarter|smart>`; natural language is primary - `plugins/deep-skills/skills/deep-docs/SKILL.md:4 (argument-hint)`, `plugins/deep-skills/skills/deep-docs/SKILL.md:71 (## Flags)`
- Six-stage pipeline: intake, survey, layering, anchor-verify, index+coverage, place+report - `plugins/deep-skills/skills/deep-docs/SKILL.md:45 (## Default-mode workflow)`
- Directive-card consumer; run first: `scripts/load-active-cards.sh deep-docs` (exact-token match on `owner_phases`) - `plugins/deep-skills/skills/deep-docs/SKILL.md:29 (## Directive cards (Deep-Learn))`, `plugins/deep-skills/skills/deep-docs/scripts/load-active-cards.sh:34 (# exact-token match so)`
- `--refresh` regenerates only stale + new subsystems - `plugins/deep-skills/skills/deep-docs/references/refresh.md:7 (## The dual git-free signal)`

## Key types

- Anchor `path:line (symbol)`; symbol primary, nearest preceding declaration, else trimmed-line landmark - `plugins/deep-skills/skills/deep-docs/references/layering-and-anchors.md:28 (### Symbol identification without LSP)`
- `index.json` entries (concept, doc, anchor, token_est, load_when, trust) plus `alignment_fingerprint` (indexed_against_commit, file_set, per_subsystem_anchor_state) - `plugins/deep-skills/skills/deep-docs/templates/index.json:4 ("entries")`, `plugins/deep-skills/skills/deep-docs/templates/index.json:14 ("alignment_fingerprint")`
- `learn-signal.json` (drift, undocumented, churn arrays, always present) - `plugins/deep-skills/skills/deep-docs/templates/learn-signal.json:7 ("drift")`
- Anchor-verify verdict `accurate | drifted | over-budget` - `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:29 (VERDICT: accurate | drifted | over-budget)`

## Invariants

- Writes only `docs/ai-map/**`, effort manifest line and `07-Docs/` pointer; owns `docs/ai-map/` exclusively - `plugins/deep-skills/skills/deep-docs/SKILL.md:80 (## Guardrails)`
- A card with any drifted/over-budget anchor blocks publish - `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:47 (## Publish gate)`
- Anchor-verify is exhaustive per card, no sampling, fresh read-only verifier, <=8 concurrent - `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:10 (## The model - one fresh verifier per card, exhaustive)`
- Survey/verify/refresh agents run on the `docs` stage tier, model ID set explicitly per launch, never small - `plugins/deep-skills/skills/deep-docs/SKILL.md:78 (## Guardrails)`
- Tier-0 hard ceiling ~2,000 est; overflow is grouped, never truncated - `plugins/deep-skills/skills/deep-docs/references/token-budget.md:35 (## The tier-0 hard ceiling - ~2,000 est)`
- Existing human docs indexed `external-unverified`, prose never ingested - `plugins/deep-skills/skills/deep-docs/references/intake-and-scope.md:36 (## Existing-docs quarantine policy)`
- Never read `.env`/secrets - `plugins/deep-skills/skills/deep-docs/SKILL.md:83 (## Guardrails)`
- Boundaries capped ~12; split >50 files, merge siblings <3 files; decisions logged to coverage.md - `plugins/deep-skills/skills/deep-docs/references/survey.md:10 (## Boundary discovery - directory-primary + heuristic refine)`
- A leftover `.in-progress` marker makes the next run refuse - `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:14 (### Refuse-if-marker (double-run safety))`

## Data-flow summary

- Generation: scope, boundary survey, tiers + anchors, verify gate, index/fingerprint, staging then atomic `mv` - `plugins/deep-skills/skills/deep-docs/references/survey.md:19 (## Fan-out - one fresh agent per boundary)` → `plugins/deep-skills/skills/deep-docs/references/anchor-verify.md:47 (## Publish gate)` → `plugins/deep-skills/skills/deep-docs/references/place-and-report.md:10 (## The staging + atomic-mv mechanism)`
- Refresh: reads fingerprint written by the prior run; git fast path only when aligned, else file-set diff + anchor re-resolve - `plugins/deep-skills/skills/deep-docs/references/refresh.md:40 (## Fingerprint lifecycle - written every run, read on the next)`
- learn-signal.json: Display-only, no reader exists yet - `plugins/deep-skills/skills/deep-docs/references/learn-signal.md:1 (# Learn-signal - the doc-coverage / drift feed (Display-only today))`

## Anchors

| Claim | Anchor |
|---|---|
| purpose | `plugins/deep-skills/skills/deep-docs/SKILL.md:7 (# DeepDocs)` |
| flags | `plugins/deep-skills/skills/deep-docs/SKILL.md:71 (## Flags)` |
| fingerprint | `plugins/deep-skills/skills/deep-docs/references/refresh.md:40 (## Fingerprint lifecycle - written every run, read on the next)` |
