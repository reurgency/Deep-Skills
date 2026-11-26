<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# deep-bugfix

> **Load when:** editing or debugging the /deep-bugfix skill (clustering, diagnose/fix/proof agents, containment, resume rules, round artifacts) · **~tokens:** ~2.1k est
> **Deep ref:** [references/deep-bugfix.md](../references/deep-bugfix.md)

## Purpose

Diagnosis-first remediation of accepted review findings (or a bug report / failing test): cluster by shared cause, re-diagnose independently, fix minimally, prove with a fresh adversarial agent, contain, commit. Fixes code only - no triage, no plan edits. - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:3 (description)`

## Entry points

- `/deep-bugfix` plus natural-language triggers; flags `--autonomous --reproduce --worktree --learn --max=<smartest|smarter|smart>` - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:4 (argument-hint)`
- Three intake modes (findings.json, bug report, failing test) normalized to one defect list - `plugins/deep-skills/skills/deep-bugfix/references/intake.md:5 (## The three input modes)`
- In-session `/skip-cluster`, `/show-proof`, `/widen` - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:66 (## In-session commands)`
- 9-step workflow: intake, scope, cluster, diagnose+fix, proof, containment, commit, statuses, hand-off - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:72 (### 1. Intake & normalize)`

## Key types

- Round dir `.deep-skills/<effort>/06-Bug-Fix/round-N/` holding `scope.json` (resume record, written before cluster work) - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:45 (## Artifact wiring)`
- `diagnosis-<CL-K>.md` - the fix agent's only cause input; header `Attempt:` - `plugins/deep-skills/skills/deep-bugfix/templates/diagnosis.md:13 (# Diagnosis - cluster)`
- `fix-summary.md` - one record per closed cluster, appended incrementally - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:41 (## Artifact wiring)`
- Normalized defect (`id` CR-*/BF-*, `recommendation_hypothesis`) - `plugins/deep-skills/skills/deep-bugfix/references/intake.md:13 (## The normalized defect shape)`
- Proof verdict `fixed | unproven | regressed` - `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:55 (## The verdict - machine-readable, three values)`
- `root-causes.json` (--learn only, proven clusters only) - `plugins/deep-skills/skills/deep-bugfix/templates/root-causes.json:20 ("proof")`

## Invariants

- Order per cluster never changes: fix, proof, containment, commit - `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:33 (## Prove-before-commit ordering (never reordered))`
- Recommendation is a hypothesis; fix agent never re-diagnoses, only implements or returns `diagnosis-disputed` - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:105 (## Guardrails)`
- 2 attempts per cluster (diagnose+fix pair each); a dispute consumes one - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)`
- findings.json `accepted -> fixed` flips only on a `fixed` verdict; deferred/rejected untouched - `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:70 (## Failed-proof policy)`
- Proof agent tier: max if any sev >=5 or severity unset, else stage - `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:9 (## The proof agent - fresh, adversarial, severity-gated)`
- Containment blocks only on NEW failures; exported symbol widens to 2 hops - `plugins/deep-skills/skills/deep-bugfix/references/containment.md:15 (## Verdict: block only on NEW failures)`
- Never commit on main/develop; never read .env during command discovery - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:101 (## Guardrails)`
- Cluster closed = any fix-summary record, or diagnosis first line `Superseded by` - `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:51 (## Re-entry & resume)`

## Data-flow summary

- accepted finding -> cluster plan in scope.json -> diagnose agent writes diagnosis file -> fix agent -> proof agent -> containment -> commit -> status flip + fix-summary append - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:75 (### 2. Scope & round start)` -> `plugins/deep-skills/skills/deep-bugfix/SKILL.md:81 (### 4. Per cluster: diagnose agent, then fix agent)` -> `plugins/deep-skills/skills/deep-bugfix/SKILL.md:84 (### 5. Adversarial proof)` -> `plugins/deep-skills/skills/deep-bugfix/SKILL.md:93 (### 8. Statuses & round artifacts)`
- Crash resume: scope.json clusters minus closed minus fixed findings - `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:46 (## Re-entry & resume)`; reuse only an unrefuted diagnosis - `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)`
- Seams: shared model map, host affordances, artifact structure, directive cards - `plugins/deep-skills/skills/deep-bugfix/SKILL.md:101 (## Guardrails)`, `plugins/deep-skills/skills/deep-bugfix/SKILL.md:25 (## Directive cards (Deep-Learn))`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| purpose | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:3 (description)` |
| flags | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:4 (argument-hint)` |
| intake modes | `plugins/deep-skills/skills/deep-bugfix/references/intake.md:5 (## The three input modes)` |
| session commands | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:66 (## In-session commands)` |
| workflow | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:72 (### 1. Intake & normalize)` |
| scope.json | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:45 (## Artifact wiring)` |
| diagnosis file | `plugins/deep-skills/skills/deep-bugfix/templates/diagnosis.md:13 (# Diagnosis - cluster)` |
| fix-summary | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:41 (## Artifact wiring)` |
| defect shape | `plugins/deep-skills/skills/deep-bugfix/references/intake.md:13 (## The normalized defect shape)` |
| verdict | `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:55 (## The verdict - machine-readable, three values)` |
| root-causes | `plugins/deep-skills/skills/deep-bugfix/templates/root-causes.json:20 ("proof")` |
| ordering | `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:33 (## Prove-before-commit ordering (never reordered))` |
| hypothesis/dispute | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:105 (## Guardrails)` |
| attempt cap | `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)` |
| status flip | `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:70 (## Failed-proof policy)` |
| proof tier | `plugins/deep-skills/skills/deep-bugfix/references/proof-of-fix.md:9 (## The proof agent - fresh, adversarial, severity-gated)` |
| containment | `plugins/deep-skills/skills/deep-bugfix/references/containment.md:15 (## Verdict: block only on NEW failures)` |
| branch/.env | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:101 (## Guardrails)` |
| closed cluster | `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:51 (## Re-entry & resume)` |
| flow: scope | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:75 (### 2. Scope & round start)` |
| flow: fix | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:81 (### 4. Per cluster: diagnose agent, then fix agent)` |
| flow: proof | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:84 (### 5. Adversarial proof)` |
| flow: statuses | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:93 (### 8. Statuses & round artifacts)` |
| crash resume scope | `plugins/deep-skills/skills/deep-bugfix/references/commit-and-handoff.md:46 (## Re-entry & resume)` |
| crash resume reuse | `plugins/deep-skills/skills/deep-bugfix/references/clustering-and-diagnosis.md:84 (## Attempt cap)` |
| model routing | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:101 (## Guardrails)` |
| directive cards | `plugins/deep-skills/skills/deep-bugfix/SKILL.md:25 (## Directive cards (Deep-Learn))` |
