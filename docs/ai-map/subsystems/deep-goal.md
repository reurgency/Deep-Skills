<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-goal (conductor skill)

> **Load when:** changing the /deep-goal conductor: launch/rigor/model resolution, stage dispatch, advance tests, review-fix loop, resume, run report · **~tokens:** ~2.9k est
> **Deep ref:** [references/deep-goal.md](../references/deep-goal.md)

## Purpose

Thin pipeline walker: resolves a rigor level to a stage list from data, runs planning inline or dispatches fresh subagents one at a time, verifies artifacts (never narratives), and reports. It never writes source, plans, reviews or docs. - `plugins/deep-goal/skills/deep-goal/SKILL.md:9 (# DeepGoal)`
Coupling is one-way: it knows the six core skills; they never require it. - `plugins/deep-goal/skills/deep-goal/SKILL.md:11 (# DeepGoal)`

## Entry points

- `/deep-goal` + flags `--rigor --max --from-plan --dry-run --budget --gate --worktree`, natural-language first - `plugins/deep-goal/skills/deep-goal/SKILL.md:4 (argument-hint)`, `plugins/deep-goal/skills/deep-goal/SKILL.md:52 (## Inputs & flags)`
- `--dry-run`: print resolved stages + models, write nothing, skip the handshake - `plugins/deep-goal/skills/deep-goal/SKILL.md:74 (### `--dry-run` - preview, then stop)`
- Launch sequence (re-entry check first) - `plugins/deep-goal/skills/deep-goal/references/conductor.md:14 (## 1. Launch sequence)`
- Resume of an existing pipeline.md - `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:11 (### 1.1 Detection - the FIRST launch check)`
- Directive cards loaded at start - `plugins/deep-goal/skills/deep-goal/SKILL.md:18 (## Directive cards (Deep-Learn))`

## Key types

- `rigor-map.json` (levels, `known_stages`, `re_review_cap`) - single source of stage lists; repo override merges at level granularity - `plugins/deep-goal/skills/deep-goal/templates/rigor-map.json:16 ("levels")`, `plugins/deep-goal/skills/deep-goal/SKILL.md:67 (## Rigor resolution (config-as-data))`
- `00-Manifest/pipeline.md` - conductor-only state: header, Stage list, Artifact baseline, Dispatch records, Blockers, Review loop, Spend - `plugins/deep-goal/skills/deep-goal/templates/pipeline.md:52 (## Dispatch records)`
- `00-Manifest/model-map.resolved.json` - whole merged model map frozen at launch - `plugins/deep-goal/skills/deep-goal/references/conductor.md:10 (## 1. Launch sequence)`
- `stage-briefing.md` - the dispatched subagent's entire prompt - `plugins/deep-goal/skills/deep-goal/templates/stage-briefing.md:38 (Invoke the skill)`
- `run-report.md` - completion artifact - `plugins/deep-goal/skills/deep-goal/templates/run-report.md:25 (## Assumptions (from the plan - verbatim))`

## Invariants

- Artifacts are the only inter-stage channel; advance test reads artifacts and manifest flips, never narratives - `plugins/deep-goal/skills/deep-goal/SKILL.md:99 (## Guardrails)`, `plugins/deep-goal/skills/deep-goal/references/conductor.md:165 (## 4. The advance test)`
- Read-only on manifest stage lines; only manifest write is the end-of-run summary paragraph - `plugins/deep-goal/skills/deep-goal/references/conductor.md:8 (READ-ONLY on manifest stage lines)`, `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:86 (### 2.1 When and how)`
- One stage in flight; marked `in-flight` before launch - `plugins/deep-goal/skills/deep-goal/references/conductor.md:115 (## 3. The dispatch loop)`
- Refuse at launch, never mid-run (unknown rigor/stage, bad override, bad --from-plan, failed handshake) - `plugins/deep-goal/skills/deep-goal/SKILL.md:96 (## Guardrails)`
- Advance tests judge against the launch baseline, not absolute existence - `plugins/deep-goal/skills/deep-goal/references/conductor.md:169 (Judged against the launch baseline)`
- Every dispatch sets the stage model explicitly, with try-and-fall-back; a small-model report HALTs and the human discards - `plugins/deep-goal/skills/deep-goal/references/conductor.md:111 (## 3. The dispatch loop)`, `plugins/deep-goal/skills/deep-goal/references/conductor.md:204 (Every discard action is an instruction to the human)`
- Spine blockers HALT; tail blockers CONTINUE - `plugins/deep-goal/skills/deep-goal/references/conductor.md:191 (## 5. Blocker policy)`
- Loop exit keys off `re_review_cap` from the resolved map, never a literal - `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:42 (### 1.4 Convergence state machine)`
- Boundary order: record, loop accounting, budget, gate, dispatch; pauses land between stages - `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:129 (## 6. Stage-boundary order)`
- First stage of every level must be `plan` - `plugins/deep-goal/skills/deep-goal/references/rigor-levels.md:86 (### Validation rules)`
- Notify on exactly four triggers (halt, gate, budget pause, completion) - `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:99 (## 4. Notifications)`

## Data-flow summary

- Launch: flags/ask -> merge rigor + model maps -> handshake -> card -> write manifest, frozen map, pipeline.md - `plugins/deep-goal/skills/deep-goal/references/conductor.md:14 (## 1. Launch sequence)` -> `plugins/deep-goal/skills/deep-goal/references/conductor.md:10 (## 1. Launch sequence)` -> `plugins/deep-goal/skills/deep-goal/references/conductor.md:10 (## 1. Launch sequence)`
- Dispatch: render briefing -> fresh subagent -> advance test -> complete record - `plugins/deep-goal/skills/deep-goal/references/conductor.md:111 (## 3. The dispatch loop)` -> `plugins/deep-goal/skills/deep-goal/references/conductor.md:111 (## 3. The dispatch loop)`
- Loop: review -> triage -> bugfix -> re-review until cap/convergence - `plugins/deep-goal/skills/deep-goal/references/conductor.md:220 (## 6. The review→fix loop (summary))` -> `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:20 (### 1.2 Round-aware advance test)`
- Resume/report: first non-complete record -> re-enter; at end write run-report - `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:47 (Resume point)` -> `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:85 (### 2.1 When and how)`
- Seam: dispatches deep-plan/-plan-review/-implement/-code-review/-bugfix/-docs by name, needs deep-skills >= 0.3.0 - `plugins/deep-goal/skills/deep-goal/SKILL.md:35 (## Launch: version handshake)`, `plugins/deep-goal/skills/deep-goal/references/conductor.md:126 (### Stage → invocation table)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| Thin pipeline walker | `plugins/deep-goal/skills/deep-goal/SKILL.md:9 (# DeepGoal)` |
| Coupling is one-way | `plugins/deep-goal/skills/deep-goal/SKILL.md:11 (# DeepGoal)` |
| /deep-goal + flags --rigor --max --from-plan --dry-run --bud | `plugins/deep-goal/skills/deep-goal/SKILL.md:4 (argument-hint)` |
| /deep-goal + flags --rigor --max --from-plan --dry-run --bud | `plugins/deep-goal/skills/deep-goal/SKILL.md:52 (## Inputs & flags)` |
| --dry-run | `plugins/deep-goal/skills/deep-goal/SKILL.md:74 (### ` |
| Launch sequence (re-entry check first) | `plugins/deep-goal/skills/deep-goal/references/conductor.md:14 (## 1. Launch sequence)` |
| Resume of an existing pipeline.md | `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:11 (### 1.1 Detection - the FIRST launch check)` |
| Directive cards loaded at start | `plugins/deep-goal/skills/deep-goal/SKILL.md:18 (## Directive cards (Deep-Learn))` |
| rigor-map.json (levels, known_stages, re_review_cap) - singl | `plugins/deep-goal/skills/deep-goal/templates/rigor-map.json:16 ("levels")` |
| rigor-map.json (levels, known_stages, re_review_cap) - singl | `plugins/deep-goal/skills/deep-goal/SKILL.md:67 (## Rigor resolution (config-as-data))` |
| 00-Manifest/pipeline.md - conductor-only state | `plugins/deep-goal/skills/deep-goal/templates/pipeline.md:52 (## Dispatch records)` |
| 00-Manifest/model-map.resolved.json - whole merged model map | `plugins/deep-goal/skills/deep-goal/references/conductor.md:10 (## 1. Launch sequence)` |
| stage-briefing.md - the dispatched subagent's entire prompt | `plugins/deep-goal/skills/deep-goal/templates/stage-briefing.md:38 (Invoke the skill)` |
| run-report.md - completion artifact | `plugins/deep-goal/skills/deep-goal/templates/run-report.md:25 (## Assumptions (from the plan - verbatim))` |
| Artifacts are the only inter-stage channel; advance test rea | `plugins/deep-goal/skills/deep-goal/SKILL.md:99 (## Guardrails)` |
| Artifacts are the only inter-stage channel; advance test rea | `plugins/deep-goal/skills/deep-goal/references/conductor.md:165 (## 4. The advance test)` |
| Read-only on manifest stage lines; only manifest write is th | `plugins/deep-goal/skills/deep-goal/references/conductor.md:8 (READ-ONLY on manifest stage lines)` |
| Read-only on manifest stage lines; only manifest write is th | `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:86 (### 2.1 When and how)` |
| One stage in flight; marked in-flight before launch | `plugins/deep-goal/skills/deep-goal/references/conductor.md:115 (## 3. The dispatch loop)` |
| Refuse at launch, never mid-run (unknown rigor/stage, bad ov | `plugins/deep-goal/skills/deep-goal/SKILL.md:96 (## Guardrails)` |
| Advance tests judge against the launch baseline, not absolut | `plugins/deep-goal/skills/deep-goal/references/conductor.md:169 (Judged against the launch baseline)` |
| Every dispatch sets the stage model explicitly, with try-and | `plugins/deep-goal/skills/deep-goal/references/conductor.md:111 (## 3. The dispatch loop)` |
| Every dispatch sets the stage model explicitly, with try-and | `plugins/deep-goal/skills/deep-goal/references/conductor.md:204 (Every discard action is an instruction to the human)` |
| Spine blockers HALT; tail blockers CONTINUE | `plugins/deep-goal/skills/deep-goal/references/conductor.md:191 (## 5. Blocker policy)` |
| Loop exit keys off re_review_cap from the resolved map, neve | `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:42 (### 1.4 Convergence state machine)` |
| Boundary order | `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:129 (## 6. Stage-boundary order)` |
| First stage of every level must be plan | `plugins/deep-goal/skills/deep-goal/references/rigor-levels.md:86 (### Validation rules)` |
| Notify on exactly four triggers (halt, gate, budget pause, c | `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:99 (## 4. Notifications)` |
| Launch | `plugins/deep-goal/skills/deep-goal/references/conductor.md:10 (## 1. Launch sequence)` |
| Dispatch | `plugins/deep-goal/skills/deep-goal/references/conductor.md:111 (## 3. The dispatch loop)` |
| Dispatch | `plugins/deep-goal/skills/deep-goal/references/conductor.md:111 (## 3. The dispatch loop)` |
| Loop | `plugins/deep-goal/skills/deep-goal/references/conductor.md:220 (## 6. The review→fix loop (summary))` |
| Loop | `plugins/deep-goal/skills/deep-goal/references/loop-and-budget.md:20 (### 1.2 Round-aware advance test)` |
| Resume/report | `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:47 (Resume point)` |
| Resume/report | `plugins/deep-goal/skills/deep-goal/references/resume-and-report.md:85 (### 2.1 When and how)` |
| Seam | `plugins/deep-goal/skills/deep-goal/SKILL.md:35 (## Launch: version handshake)` |
| Seam | `plugins/deep-goal/skills/deep-goal/references/conductor.md:126 (### Stage → invocation table)` |
