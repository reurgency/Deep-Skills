<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-plan

> **Load when:** editing or invoking the /deep-plan planning skill, its flags, in-session commands, or plan template · **~tokens:** ~2.4k est

## Purpose

Interactive, steerable feature-planning session that writes a self-contained plan a fresh agent can execute cold; planning only, never implements - `plugins/deep-skills/skills/deep-plan/SKILL.md:9 (# DeepPlan)`

## Entry points

- `/deep-plan` or natural language ("plan a feature"); flags `--autonomous --effort --confirmed --columbo --rounds --max`, each natural-language-first - `plugins/deep-skills/skills/deep-plan/SKILL.md:4 (argument-hint)`, `plugins/deep-skills/skills/deep-plan/SKILL.md:51 (## Flags)`
- Startup: runs `scripts/load-active-cards.sh deep-plan` and treats printed directives as hard requirements - `plugins/deep-skills/skills/deep-plan/SKILL.md:18 (## Directive cards (Deep-Learn))`
- In-session commands `/drill /breakout /gaps /risks /constraints /columbo`, serviced then return to prior step - `plugins/deep-skills/skills/deep-plan/SKILL.md:36 (## In-session commands)`, `plugins/deep-skills/skills/deep-plan/references/in-session-commands.md:3 (# In-session commands)`
- 9-step state machine: Setup, Frame, Explore, Questions, Pre-write nudge, Write, Review, Columbo, Hand-off - `plugins/deep-skills/skills/deep-plan/SKILL.md:60 (## Session workflow (interruptible state machine))`
- Autonomous per-step deltas table - `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:17 (## Per-step deltas from the interactive workflow)`
- Reads shared copies (documented elsewhere): `references/model-map.md`, `model-map.json`, `host-affordances.md`, `artifact-structure.md`, `scripts/load-active-cards.sh` - `plugins/deep-skills/skills/deep-plan/SKILL.md:80 (### 3. Explore (read-only))`

## Key types

- Plan artifact written to `.deep-skills/<effort>/01-Plan/plan.md` (plus `00-Manifest/manifest.md` on first write) - `plugins/deep-skills/skills/deep-plan/SKILL.md:94 (### 6. Design & write the plan)`
- Plan template: Status, Base/Max/Models header, Context, Constraints, Assumptions, Approach, Steps or Phases, Files, Verification, Risks, Deferreds, Phase Summaries - `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:3 (# <Feature Name>)`
- Assumptions table (# / Question / Chosen answer / Why), autonomous only - `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:18 (## Assumptions)`
- Deferreds ledger (What / Why deferred / Integration) - `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:71 (## Deferreds)`
- Question templates (`multiple-choice`, `yes-no-explain`, `open-ended`); `_*` keys stripped before render - `plugins/deep-skills/skills/deep-plan/templates/questions/_README.md:9 (## Shipped types)`, `plugins/deep-skills/skills/deep-plan/templates/questions/multiple-choice.json:7 ("allowMultiple")`, `plugins/deep-skills/skills/deep-plan/templates/questions/yes-no-explain.json:7 ("requireExplanation")`, `plugins/deep-skills/skills/deep-plan/templates/questions/open-ended.json:7 ("placeholder")`
- Phase entry shape (Goal, Prerequisites, Files, Steps, Acceptance) - `plugins/deep-skills/skills/deep-plan/references/phase-structuring.md:5 (## What every phase entry must contain)`

## Invariants

- Plan only; no source edits, execution belongs to /deep-implement - `plugins/deep-skills/skills/deep-plan/SKILL.md:136 (## Guardrails)`
- Pre-write gaps/risks/constraints nudge is mandatory (self-decided under --autonomous) - `plugins/deep-skills/skills/deep-plan/SKILL.md:86 (### 5. Pre-write nudge)`
- Every launched agent (Explore, breakout, columbo) runs on the `stage` tier with the full model ID set explicitly, never a host default or alias; inline planning runs on session model - `plugins/deep-skills/skills/deep-plan/SKILL.md:138 (## Guardrails)`
- Autonomous: ask nothing, record every self-answer as an Assumption row; empty Assumptions on a non-trivial feature is a red flag - `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:11 (## The one rule)`, `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:52 (## Guardrails (unchanged, restated))`
- `--confirmed` only skips the restate question and the hand-off; Frame still runs - `plugins/deep-skills/skills/deep-plan/SKILL.md:49 (## Flags)`
- Phases must not rely on conversation memory; Phase Summaries stay empty at plan time - `plugins/deep-skills/skills/deep-plan/references/phase-structuring.md:15 (## Resumability rules)`
- Deferrals go in the ledger, never prose - `plugins/deep-skills/skills/deep-plan/SKILL.md:133 (## Deferreds - nothing gets forgotten by phase 4)`
- `--rounds` is ignored under `--autonomous` - `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:43 (## `--rounds=<n>` - and why autonomous ignores it)`

## Data-flow summary

- Explore (up to 3 agents on stage tier, model-report line) → questions → plan.md + manifest → columbo - `plugins/deep-skills/skills/deep-plan/SKILL.md:80 (### 3. Explore (read-only))` → `plugins/deep-skills/skills/deep-plan/SKILL.md:94 (### 6. Design & write the plan)` → `plugins/deep-skills/skills/deep-plan/references/in-session-commands.md:81 (## `/columbo`)`
- Breakout returns only the distilled answer; trailing `MODEL:` line stripped into plan header Models - `plugins/deep-skills/skills/deep-plan/references/in-session-commands.md:21 (## `/breakout <instructions>`)`
- Hand-off to deep-goal only for interactive standalone runs (none of --autonomous/--confirmed/--rounds/--effort), when listing advertises `--from-plan`, plan at default path; invokes `/deep-goal --from-plan=<repo-relative path> --rigor=<level>` - `plugins/deep-skills/skills/deep-plan/SKILL.md:111 (### 9. Hand-off (optional deep-goal offer))`, `plugins/deep-skills/skills/deep-plan/SKILL.md:110 (### 9. Hand-off (optional deep-goal offer))`
- Downstream: plan consumed by /deep-plan-review and /deep-implement, which append Phase Summaries - `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:75 (## Phase Summaries)`

## Anchors

| Claim | Anchor |
|---|---|
| purpose | `plugins/deep-skills/skills/deep-plan/SKILL.md:9 (# DeepPlan)` |
| entry flags | `plugins/deep-skills/skills/deep-plan/SKILL.md:4 (argument-hint)` |
| flags section | `plugins/deep-skills/skills/deep-plan/SKILL.md:51 (## Flags)` |
| directive script | `plugins/deep-skills/skills/deep-plan/SKILL.md:18 (## Directive cards (Deep-Learn))` |
| commands table | `plugins/deep-skills/skills/deep-plan/SKILL.md:36 (## In-session commands)` |
| command behaviors | `plugins/deep-skills/skills/deep-plan/references/in-session-commands.md:3 (# In-session commands)` |
| state machine | `plugins/deep-skills/skills/deep-plan/SKILL.md:60 (## Session workflow (interruptible state machine))` |
| autonomous deltas | `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:17 (## Per-step deltas from the interactive workflow)` |
| shared reads / explore | `plugins/deep-skills/skills/deep-plan/SKILL.md:80 (### 3. Explore (read-only))` |
| plan path / write | `plugins/deep-skills/skills/deep-plan/SKILL.md:94 (### 6. Design & write the plan)` |
| template header | `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:3 (# <Feature Name>)` |
| assumptions table | `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:18 (## Assumptions)` |
| deferreds ledger | `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:71 (## Deferreds)` |
| question types | `plugins/deep-skills/skills/deep-plan/templates/questions/_README.md:9 (## Shipped types)` |
| multiple-choice | `plugins/deep-skills/skills/deep-plan/templates/questions/multiple-choice.json:7 ("allowMultiple")` |
| yes-no | `plugins/deep-skills/skills/deep-plan/templates/questions/yes-no-explain.json:7 ("requireExplanation")` |
| open-ended | `plugins/deep-skills/skills/deep-plan/templates/questions/open-ended.json:7 ("placeholder")` |
| phase entry | `plugins/deep-skills/skills/deep-plan/references/phase-structuring.md:5 (## What every phase entry must contain)` |
| plan only | `plugins/deep-skills/skills/deep-plan/SKILL.md:136 (## Guardrails)` |
| nudge | `plugins/deep-skills/skills/deep-plan/SKILL.md:86 (### 5. Pre-write nudge)` |
| model routing | `plugins/deep-skills/skills/deep-plan/SKILL.md:138 (## Guardrails)` |
| one rule | `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:11 (## The one rule)` |
| red flag | `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:52 (## Guardrails (unchanged, restated))` |
| confirmed | `plugins/deep-skills/skills/deep-plan/SKILL.md:49 (## Flags)` |
| resumability | `plugins/deep-skills/skills/deep-plan/references/phase-structuring.md:15 (## Resumability rules)` |
| deferrals | `plugins/deep-skills/skills/deep-plan/SKILL.md:133 (## Deferreds - nothing gets forgotten by phase 4)` |
| rounds ignored | `plugins/deep-skills/skills/deep-plan/references/autonomous-mode.md:43 (## `--rounds=<n>` - and why autonomous ignores it)` |
| columbo | `plugins/deep-skills/skills/deep-plan/references/in-session-commands.md:81 (## `/columbo`)` |
| breakout | `plugins/deep-skills/skills/deep-plan/references/in-session-commands.md:21 (## `/breakout <instructions>`)` |
| hand-off gate | `plugins/deep-skills/skills/deep-plan/SKILL.md:111 (### 9. Hand-off (optional deep-goal offer))` |
| deep-goal invoke | `plugins/deep-skills/skills/deep-plan/SKILL.md:110 (### 9. Hand-off (optional deep-goal offer))` |
| phase summaries | `plugins/deep-skills/skills/deep-plan/templates/plan-template.md:75 (## Phase Summaries)` |
