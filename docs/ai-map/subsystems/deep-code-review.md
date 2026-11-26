<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-code-review

> **Load when:** editing or invoking /deep-code-review (review, --multi-agent, --mega, --triage, --fix), finding/severity shape, or its artifacts · **~tokens:** ~1.6k est
> **Deep ref:** [references/deep-code-review.md](../references/deep-code-review.md)

## Purpose

Independent review of implemented code by fresh agents (never given the implementation transcript); emits evidence-backed findings, all left `open`, and never edits source or the plan. - `plugins/deep-skills/skills/deep-code-review/SKILL.md:9 (# DeepCodeReview)`

## Entry points

- `/deep-code-review [branch/PR/diff/folder] --multi-agent --mega --max=<level> --triage [--auto-accept-min=<sev>] --fix` - `plugins/deep-skills/skills/deep-code-review/SKILL.md:4 (argument-hint)`
- `--triage` is a separate step run over the latest `open` findings - `plugins/deep-skills/skills/deep-code-review/SKILL.md:93 (### 7. Triage & fix routing)`

## Key types

- Finding (id CR-NNN, lens, dimension, severity 1-10, tier, evidence, status, verification) - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:7 (## Finding shape)`
- `findings.json` (`effort`, `scope`, `reviewed`, `mode`, `findings[]`) - `plugins/deep-skills/skills/deep-code-review/templates/finding.json:7 ("findings")`
- Tiers 9-10 Blocker, 7-8 Major, 5-6 Minor, 1-4 Nit; numeric is canonical - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:24 (## Severity scale and tier mapping)`

## Invariants

- Review run writes only `.deep-skills/<effort>/04-Code-Review/` plus manifest; never plan or Deferreds - `plugins/deep-skills/skills/deep-code-review/SKILL.md:128 (## Guardrails)`
- Every finding needs evidence (path:line, symbol, or observed) - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:5 (## Finding shape)`
- Ask the user on any scope ambiguity; state resolved scope before launching agents - `plugins/deep-skills/skills/deep-code-review/references/scope-resolution.md:1 (# Scope resolution - what are we diffing?)`
- Lint/typecheck/tests are scripts, never agents - `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:1 (# Deterministic pre-pass - tools, not agents)`; never read `.env` - `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:17 (## Discovering the host project's commands)`
- Set model explicitly per agent launch from the model map; no small models - `plugins/deep-skills/skills/deep-code-review/SKILL.md:126 (## Guardrails)`
- Verification floor sev >=5; refuted go to an appendix, not dropped - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:73 (## Stage C)`
- Blockers always auto-accept at triage; nothing is auto-rejected - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:64 (## Auto-policy triage)`
- Re-review appends fresh CR ids and preserves prior statuses - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:85 (## Re-review rounds)`

## Data-flow summary

- Default: scope -> effort home -> pre-pass -> situational match -> one 4-lens agent -> report/findings/certificate - `plugins/deep-skills/skills/deep-code-review/SKILL.md:46 (### 1. Resolve scope - and state it)` -> `plugins/deep-skills/skills/deep-code-review/SKILL.md:80 (### 6. Findings & report)`
- `--multi-agent`: Stage 0 script -> A eight finders -> B dedup -> C verifiers -> D synthesis - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:11 (## Stage 0)` -> `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:106 (## Stage D)`
- Triage: accepted set -> `/deep-bugfix` (fallback: fix-phase in plan for `/deep-implement`) - `plugins/deep-skills/skills/deep-code-review/SKILL.md:97 (### 7. Triage & fix routing)`

## Anchors

| Claim | Anchor |
|---|---|
| purpose | `plugins/deep-skills/skills/deep-code-review/SKILL.md:9 (# DeepCodeReview)` |
| entry flags | `plugins/deep-skills/skills/deep-code-review/SKILL.md:4 (argument-hint)` |
| triage entry | `plugins/deep-skills/skills/deep-code-review/SKILL.md:93 (### 7. Triage & fix routing)` |
| finding shape | `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:7 (## Finding shape)` |
| findings.json | `plugins/deep-skills/skills/deep-code-review/templates/finding.json:7 ("findings")` |
| tiers | `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:24 (## Severity scale and tier mapping)` |
| write boundary | `plugins/deep-skills/skills/deep-code-review/SKILL.md:128 (## Guardrails)` |
| evidence rule | `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:5 (## Finding shape)` |
| scope ask | `plugins/deep-skills/skills/deep-code-review/references/scope-resolution.md:1 (# Scope resolution - what are we diffing?)` |
| prepass tools | `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:1 (# Deterministic pre-pass - tools, not agents)` |
| prepass never reads .env | `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:17 (## Discovering the host project's commands)` |
| model explicit | `plugins/deep-skills/skills/deep-code-review/SKILL.md:126 (## Guardrails)` |
| verify floor | `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:73 (## Stage C)` |
| blockers auto-accept | `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:64 (## Auto-policy triage)` |
| re-review | `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:85 (## Re-review rounds)` |
| default flow | `plugins/deep-skills/skills/deep-code-review/SKILL.md:46 (### 1. Resolve scope - and state it)` |
| report step | `plugins/deep-skills/skills/deep-code-review/SKILL.md:80 (### 6. Findings & report)` |
| stage 0 | `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:11 (## Stage 0)` |
| stage D | `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:106 (## Stage D)` |
| triage routing | `plugins/deep-skills/skills/deep-code-review/SKILL.md:97 (### 7. Triage & fix routing)` |
