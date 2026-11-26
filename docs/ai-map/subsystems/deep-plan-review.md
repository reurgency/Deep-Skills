<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-plan-review

> **Load when:** editing or invoking /deep-plan-review (plan critique by fresh agents, multi-agent fan-out, review report format) · **~tokens:** ~1.8k est

## Purpose

Skill that reviews a finished plan with fresh, codebase-aware agents that never see the planning transcript, then records findings back into the plan. Review only, never edits source. - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:9 (# DeepPlanReview)`

## Entry points

- `/deep-plan-review` (path arg, or latest plan); natural-language triggers primary - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:4 (argument-hint)`
- `--multi-agent` or `/multi-agent` escalates to parallel mode - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:42 (## In-session commands)`
- `--max=<smartest|smarter|smart>` caps helper-agent model level - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:50 (## Flags)`
- `/columbo` optional completeness gut check, runs on the stage tier - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:43 (## In-session commands)`
- Startup: runs `scripts/load-active-cards.sh deep-plan-review`; printed directives are hard requirements - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:18 (## Directive cards (Deep-Learn))`
- Plan resolution order: explicit path, conversation, latest `.deep-skills/*/01-Plan/plan.md` - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:55 (### 1. Locate the plan)`

## Key types

- Two lenses: A user alignment (4 dims), B codebase alignment (6 dims, incl. behavioral completeness) - `plugins/deep-skills/skills/deep-plan-review/references/review-dimensions.md:5 (## Lens A - User alignment)`
- Finding: Severity Blocker/Major/Minor/Nit, Lens, Title, Evidence, Impact, Recommendation - `plugins/deep-skills/skills/deep-plan-review/references/findings-format.md:14 (## Finding fields)`
- Review report template (header carries Base, Max, Models) - `plugins/deep-skills/skills/deep-plan-review/templates/review-report.md:8 (> **Base:**)`
- Agent roster: codebase-duplication, patterns-and-practices, user-alignment, coherence-conflicts, synthesis - `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:5 (## Fan-out)`

## Invariants

- Review only: never modify source or implement; only the plan document may be edited - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:79 (## Guardrails)`
- Fresh agents get plan, lenses, codebase access, preference pointers, but not the planning transcript - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:61 (### 3. Dispatch the review)`
- Every agent model is resolved from the model map and passed explicitly per launch, even for `Explore`; never a host default or small model - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:82 (## Guardrails)`
- user-alignment stays on the stage tier; other dimensions run one tier down, floor `smart` - `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:5 (## Fan-out)`
- Findings must cite evidence; a clean lens is reported clean, not padded - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:80 (## Guardrails)`
- Parallelism capped at 2-4 agents - `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:38 (## Caution)`; launched in one message - `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:9 (## Fan-out)`
- Strip each agent's trailing `MODEL:` line before dedupe; it goes in the report header - `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:25 (## Synthesis)`

## Data-flow summary

- Locate plan, choose mode, dispatch single or parallel agents, present by severity - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:55 (### 1. Locate the plan)` → `plugins/deep-skills/skills/deep-plan-review/SKILL.md:66 (### 4. Present findings)`
- Write full report to `.deep-skills/<effort>/02-Plan-Review/review.md`, create manifest if absent, add Review Findings summary to plan, route deferrals to the plan's Deferreds ledger, update manifest status - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:70 (### 5. Record the review)`
- Stage model comes from `stages.<max>.plan-review` in the model map (shared refs, not documented here) - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:63 (### 3. Dispatch the review)`
- Upstream /deep-plan produces the plan; downstream /deep-implement consumes it - `plugins/deep-skills/skills/deep-plan-review/SKILL.md:11 (# DeepPlanReview)`

## Anchors

| Claim | Anchor |
|---|---|
| purpose | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:9 (# DeepPlanReview)` |
| invocation | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:4 (argument-hint)` |
| multi-agent cmd | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:42 (## In-session commands)` |
| max flag | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:50 (## Flags)` |
| columbo | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:43 (## In-session commands)` |
| cards script | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:18 (## Directive cards (Deep-Learn))` |
| plan resolution | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:55 (### 1. Locate the plan)` |
| lenses | `plugins/deep-skills/skills/deep-plan-review/references/review-dimensions.md:5 (## Lens A - User alignment)` |
| finding fields | `plugins/deep-skills/skills/deep-plan-review/references/findings-format.md:14 (## Finding fields)` |
| report template | `plugins/deep-skills/skills/deep-plan-review/templates/review-report.md:8 (> **Base:**)` |
| roster | `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:5 (## Fan-out)` |
| review only | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:79 (## Guardrails)` |
| no transcript | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:61 (### 3. Dispatch the review)` |
| explicit model | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:82 (## Guardrails)` |
| tier split | `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:5 (## Fan-out)` |
| evidence rule | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:80 (## Guardrails)` |
| agent cap | `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:38 (## Caution)` |
| one-message launch | `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:9 (## Fan-out)` |
| MODEL strip | `plugins/deep-skills/skills/deep-plan-review/references/multi-agent.md:25 (## Synthesis)` |
| present | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:66 (### 4. Present findings)` |
| record | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:70 (### 5. Record the review)` |
| stage tier | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:63 (### 3. Dispatch the review)` |
| series | `plugins/deep-skills/skills/deep-plan-review/SKILL.md:11 (# DeepPlanReview)` |
