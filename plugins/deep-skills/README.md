# Deep Skills

A planning → review → implementation → code-review → bug-fix → docs workflow for AI coding agents. Six skills that hand off to each other, each producing a **self-contained, fresh-agent-resumable artifact** so any step can be picked up later by an agent with zero prior context. Fleet steps fan out independent, evidence-driven agents; a **self-improving directive loop** feeds lessons from each review back into the next run.

Works natively across Claude Code, Codex, Cursor, and GitHub Copilot / VS Code - one set of skills, thin per-host manifests. See [`HOSTS.md`](./HOSTS.md) for per-host install and capability details.

## The workflow

```
/deep-plan → /deep-plan-review → /deep-implement → /deep-code-review ─┐
                                                                      │
                     /deep-docs  ◄───────  /deep-bugfix ◄── (triage) ─┘
```

Each skill also runs standalone - you don't have to start at `/deep-plan`. Run `/deep-code-review` on any branch, `/deep-bugfix` on a stack trace, or `/deep-docs` on any repo.

## The six skills

| Skill | What it does | Writes source? |
|---|---|---|
| **deep-plan** | Interactive, steerable planning session → a resumable plan artifact. Also runs unattended with `--autonomous`. | No |
| **deep-plan-review** | Fresh codebase-aware agents review the plan for misalignment, duplication, and conflicts before you build. | No |
| **deep-implement** | Executes a reviewed plan phase-by-phase: implement → validate → fix → commit → hand-off. | Yes (forward construction) |
| **deep-code-review** | Independent agents review implemented code for correctness bugs, last-mile functional gaps, plan conformance, and coherence. Optional `--triage`/`--fix`. | No |
| **deep-bugfix** | Diagnosis-first remediation under regression risk: cluster by root cause, re-diagnose, fix minimally, prove with an adversarial agent. | Yes (remediation) |
| **deep-docs** | A context-window-aware, machine-readable orientation map of what the codebase has built, every claim anchored to `file:line` and adversarially verified. | No |

## Invoking

Every skill responds to **both** its slash command and natural language:

```
/deep-plan add rate limiting to the public API
```
```
plan out the rate-limiting feature, then review the plan
```

Slash commands are the explicit path; natural-language phrasing ("deep plan this", "review this PR", "map this repo for an agent") triggers the same skills.

## What's in this package

```
deep-skills/
├── skills/           # the six SKILL.md skills (+ references/, scripts/, templates/)
├── directives/       # shared self-improving directive registry (cards + loader)
├── assets/           # icon and install imagery
├── HOSTS.md          # cross-assistant install + capability matrix
├── .claude-plugin/   # Claude Code manifest
├── .codex-plugin/    # Codex manifest
└── .cursor-plugin/   # Cursor manifest
```

`skills/` and `directives/` are **siblings by design** - the directive loader resolves the shared registry relative to its own file, so the two must stay together under this plugin root. See [`HOSTS.md`](./HOSTS.md) § *The vendoring invariant*.

## Model-tier routing

Every helper agent a skill launches gets its model set explicitly, from one shared model map with three fixed levels: **smartest** (Fable 5.2), **smarter** (Opus 5.5) and **smart** (Sonnet 5.5) - or their GPT equivalents when your session runs a GPT model. Small models never run. Add `--max=<smartest|smarter|smart>` (or say *"use the smartest models"*) to set the highest level a run may use; it defaults to your current model's level. Each skill then puts some helpers lower - for example, deep-code-review's quality checker runs on Sonnet 5.5 - and anything done in your own session (like the planning conversation) runs on your current model. A repo can repin models with an optional `.deep-skills/model-map.json`. Details in [`HOSTS.md`](./HOSTS.md) § *Model-tier routing*.

## Optional companion

**deep-goal** is a separately-installed, free pipeline conductor that runs these six skills end-to-end from a single invocation. It **works with** deep-skills but is never required by it, and nothing here depends on it. If deep-goal is installed, an interactive `/deep-plan` offers at the end to hand the remaining stages to deep-goal, which continues from your plan instead of planning again. If you don't have it, there's no offer and everything above works exactly the same. deep-goal 0.3.0 requires deep-skills ≥ 0.3.0.

## License

MIT © reUrgency
