<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-code-review

> **Load when:** reviewing implemented code/diffs/PRs (`/deep-code-review`, "review the diff") · **~tokens:** ~560 est
> **Deep ref:** [references/deep-code-review.md](../references/deep-code-review.md)

## Purpose

Independently review implemented code with fresh agents, evidence-gated findings, and a clean report covering correctness / last-mile / plan-conformance / coherence — with triage as a separate opt-in step. — `plugins/deep-skills/skills/deep-code-review/SKILL.md:10 (This is the fourth skill of the `deep-*` series)`

## Entry points

- `/deep-code-review` (branch vs base); `#65` (PR); explicit paths; `--triage`; NL "review the diff / review this PR" — `plugins/deep-skills/skills/deep-code-review/SKILL.md:10 (This is the fourth skill of the `deep-*` series)`
- Resolve scope → print it, ask on ambiguity (golden rule) — `plugins/deep-skills/skills/deep-code-review/SKILL.md:24 (1. Resolve scope — and state it)`

## Key components

- Default one-agent-four-lenses (Correctness, Last-Mile, Plan-Conformance, Coherence) — `plugins/deep-skills/skills/deep-code-review/references/review-lenses.md:1 (Review lenses)`
- Last-mile hop-by-hop chain trace — `plugins/deep-skills/skills/deep-code-review/references/last-mile.md:69 (synthesis rule)`
- Multi-agent 5-stage pipeline + model tiers (Haiku ban) — `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:36 (Haiku is NEVER used in this pipeline — any tier, any stage, any agent)`
- Findings record (evidence-required) — `plugins/deep-skills/skills/deep-code-review/templates/finding.json:1`

## Invariants

- Review-only, never edit source; writes only `04-Code-Review/` (+ manifest), never the plan (that's `--triage`) — `plugins/deep-skills/skills/deep-code-review/SKILL.md:10 (This is the fourth skill of the `deep-*` series)`
- Fresh eyes: no implementation transcript (the last-mile problem) — `plugins/deep-skills/skills/deep-code-review/SKILL.md:12 (Core principle)`
- Print resolved scope, ask on ambiguity — `plugins/deep-skills/skills/deep-code-review/SKILL.md:24 (1. Resolve scope — and state it)`
- Evidence required on every finding — `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:15 (REQUIRED, no exceptions)`
- No cited chain ⇒ no finding (last-mile synthesis rule) — `plugins/deep-skills/skills/deep-code-review/references/last-mile.md:69 (synthesis rule)`
- Haiku never used at any tier — `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:36 (Haiku is NEVER used in this pipeline — any tier, any stage, any agent)`
- Never read .env/secrets — `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:25 (NEVER read `.env`)`

## Data-flow summary

- Consumes diff/PR/paths + plan + codebase + situational catalog → deterministic pre-pass → situational-check match → finder(s) over budget → evidence-gated findings → report; produces `04-Code-Review/report.md` + `findings.json` + `certificate.md` + manifest — `plugins/deep-skills/skills/deep-code-review/SKILL.md:24 (1. Resolve scope — and state it)` → `plugins/deep-skills/skills/deep-code-review/references/dimensions.md:17 (Overgenerate — within budget, above the nit floor)` → `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:15 (REQUIRED, no exceptions)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| closes the loop; gate between claimed-done and actually-done | `plugins/deep-skills/skills/deep-code-review/SKILL.md:10 (This is the fourth skill of the `deep-*` series)` |
| fresh agents, never the implementation transcript | `plugins/deep-skills/skills/deep-code-review/SKILL.md:12 (Core principle)` |
| print resolved scope, ask on ambiguity | `plugins/deep-skills/skills/deep-code-review/SKILL.md:24 (1. Resolve scope — and state it)` |
| four default lenses | `plugins/deep-skills/skills/deep-code-review/references/review-lenses.md:1 (Review lenses)` |
| no cited chain ⇒ no finding | `plugins/deep-skills/skills/deep-code-review/references/last-mile.md:69 (synthesis rule)` |
| tiers + Haiku never | `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:36 (Haiku is NEVER used in this pipeline — any tier, any stage, any agent)` |
| finder budget + severity floor | `plugins/deep-skills/skills/deep-code-review/references/dimensions.md:17 (Overgenerate — within budget, above the nit floor)` |
| evidence on every finding | `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:15 (REQUIRED, no exceptions)` |
| secrets rule | `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:25 (NEVER read `.env`)` |
| machine findings record | `plugins/deep-skills/skills/deep-code-review/templates/finding.json:1` |
