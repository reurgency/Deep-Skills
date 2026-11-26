<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-2 deep reference: loaded on demand. Every hop carries a path:line (symbol) anchor. -->

# deep-code-review - deep reference

## Flow 1: multi-agent review to findings.json

1. Scope is resolved and stated before any agent launches; ambiguity goes to the user. - `plugins/deep-skills/skills/deep-code-review/references/scope-resolution.md:30 (## The always-state-resolved-scope rule)`
2. Stage 0 (scripts, not agents): per-file diff chunks plus index, pre-pass in parallel, verifier fact pre-harvest, situational-check grep. - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:11 (## Stage 0 - Scripted setup)`
3. Pre-pass attributes test failures by running base and head worktrees concurrently and diffing normalized failure lists. - `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:9 (## Scripted base-vs-head attribution)`
4. Situational catalog is the only always-loaded entry file; bodies load only on a Match hit and attach to named finder briefs. - `plugins/deep-skills/skills/deep-code-review/references/situational/index.md:9 (### file-upload-pipeline)`
5. Model tiers are resolved from the shared model map and set explicitly on each launch (stage / one down / two down, floor smart). - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:26 (### Model tier resolution)`
6. Stage A: eight read-only single-lens finders, max 8 concurrent, ~25 tool calls each, overgenerate at sev >=4. - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:20 (## Stage A)`
7. Stage B: merge by root cause (dimension becomes an array), split when N independent fixes. - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:66 (## Stage B)`
8. Stage C: sev >=5 gets one fresh refuting verifier each, streamed; sev 5 on two-down, sev >=6 on stage tier; fixed VERDICT/SUB-CLAIMS/SEVERITY/RATIONALE format. - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:73 (## Stage C)`
9. Stage D: script assembles findings.json, rollup, funnel, certificate scaffold; model enforces evidence/last-mile chain rule and reconciles severities. - `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:110 (## Stage D)`
10. Output shape: all statuses `open`, `verification` from verdicts, `mode: multi-agent`. - `plugins/deep-skills/skills/deep-code-review/templates/finding.json:6 ("mode")`
11. Certificate verdict: PASS only with no unresolved Blockers. - `plugins/deep-skills/skills/deep-code-review/templates/certificate.md:4 (Verdict rule)`

## Flow 2: triage to bugfix and re-review

1. `--triage` reads `open` findings from the latest 04-Code-Review/findings.json; Blockers auto-accept. - `plugins/deep-skills/skills/deep-code-review/SKILL.md:93 (### 7. Triage & fix routing)`
2. HITL outcomes: fix (accepted), defer (plan Deferreds row), reject (`rejected by user`). - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:47 (## Policy actions)`
3. With `--auto-accept-min`, below-threshold findings are auto-deferred, never rejected. - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:64 (## Auto-policy triage)`
4. Accepted set goes to /deep-bugfix, with no fix-phase appended so one executor owns it; fallback appends a fix-phase to the plan. - `plugins/deep-skills/skills/deep-code-review/SKILL.md:97 (### 7. Triage & fix routing)`
5. `--fix` chains an autonomous bugfix run and passes `--max`; no-op with pointer if bugfix absent. - `plugins/deep-skills/skills/deep-code-review/SKILL.md:115 (## Flags)`
6. Re-review appends fresh CR ids (max+1), keeps prior statuses, updates `reviewed`. - `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:85 (## Re-review rounds)`
