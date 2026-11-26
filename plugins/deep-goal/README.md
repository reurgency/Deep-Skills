# deep-goal - autonomous pipeline conductor for the Deep-* series

An optional **add-on plugin** to the [deep-skills](../deep-skills/) plugin - bundled free in the same marketplace. One invocation runs an effort end-to-end - plan → review → implement → code-review → bugfix → docs - with a `--rigor=<yolo|poc|mvp|prod>` level selecting which stages run, how interactive planning is, how triage decides, and how many review→fix rounds the loop may take.

- **Requires:** the deep-skills plugin **≥ 0.3.0** installed alongside (verified at launch; deep-goal refuses politely otherwise). The core skills never require deep-goal - coupling is strictly one-directional.
- **Install (Claude Code):** `/plugin marketplace add reurgency/marketplace` → `/plugin install deep-goal@reurgency`. Other hosts: see `HOSTS.md` (Claude Code is the verified floor).
- **Invoke:** `/deep-goal <feature>` or natural language - "run deep-goal at mvp rigor".

> **Distribution note:** deep-goal currently ships from the public `reurgency/marketplace` store; at launch, distribution may move to a **private channel** (the plugin boundary makes that a folder move - the plugin itself is unchanged).

Layout mirrors the core plugin: `skills/deep-goal/` (SKILL.md + scripts/ + references/ + templates/), `directives/` (deep-goal's own Deep-Learn registry - empty in v1), thin per-host manifests, `HOSTS.md`.

## Flags

Natural-language-first, like everything in the series - say it in plain words or use the flag.

- **Goal** - the argument: *"run deep-goal on <feature>"*.
- **`--rigor=<yolo|poc|mvp|prod>`** - *"at mvp rigor"*. Which stages run, how interactive planning is, what auto-triage accepts, how many review→fix rounds. Omitted → asked before launch (recommends mvp).
- **`--max=<smartest|smarter|smart>`** - *"use the smartest models"*, *"keep it to smarter models"*, *"max smart"* (the phrase must name a level). The highest model level any stage may use - see below. Omitted → asked together with rigor; the recommended answer is your current model's level.
- **`--from-plan[=<path>]`** - *"continue from my plan"*. Adopt a plan you already made with `/deep-plan` (path: `.deep-skills/<effort>/01-Plan/plan.md`) instead of planning again; the run starts at plan review (mvp/prod) or implement (yolo/poc). With no path, deep-goal finds your plan - or asks which one if there are several. An interactive `/deep-plan` offers this hand-off at the end when deep-goal is installed.
- **`--dry-run`** - *"preview the run"*. Print every stage with the model it would run on, then stop. Writes nothing; works without deep-skills installed.
- **`--budget=<band>`** - *"cap spend at ~500k tokens"*. Soft ceiling, checked between stages.
- **`--gate=<stage>`** - *"pause before implement"*. A human checkpoint before a named stage (repeatable).
- **`--worktree`** - *"build in a worktree"*. One worktree for every stage after planning.

**Before anything runs you see a launch card:** goal, effort name, rigor, model level, the model each stage will run on, and at most one warning line. At mvp/prod it waits for **Launch** (or change rigor/max, edit the goal or name, or cancel - nothing is written until you launch); at yolo/poc it prints and goes.

## Model allocation - three fixed levels, capped by `--max`

deep-goal uses the same model map as every deep-skills skill (`skills/deep-goal/references/model-map.json` for the models, [`references/model-map.md`](skills/deep-goal/references/model-map.md) for the rules). There are three levels, each pinned to specific models - they don't shift with the model you happen to be chatting in:

| Level | Claude | GPT |
|---|---|---|
| **smartest** | Fable 5.2 (then Fable 5) | Astra-6 (then GPT-5.6 Sol) |
| **smarter** | Opus 5.5 (then Opus 5) | GPT-6-Sol (then GPT-5.6 Terra) |
| **smart** | Sonnet 5.5 (then Sonnet 5) | GPT-6.1-Terra (then GPT-5.6 Luna) |

A run stays in your session's model family. Smart is the floor - small models (Haiku, GPT-mini/nano) never run. GPT names are display names until host IDs are confirmed.

**`--max` picks what each stage runs on** (Claude models shown):

| Stage | `--max=smartest` | `--max=smarter` | `--max=smart` |
|---|---|---|---|
| plan | Fable 5.2 | Opus 5.5 | Sonnet 5.5 |
| plan review | Fable 5.2 | Opus 5.5 | Sonnet 5.5 |
| implement | Opus 5.5 | Opus 5.5 | Sonnet 5.5 |
| code review (+ triage, re-reviews) | Fable 5.2 | Opus 5.5 | Sonnet 5.5 |
| bug fix | Opus 5.5 | Opus 5.5 | Sonnet 5.5 |
| docs | Sonnet 5.5 | Sonnet 5.5 | Sonnet 5.5 |

The principle: **planners and reviewers ≥ builders ≥ documenters.** Every stage is also told your `--max`, so its own helper agents pick their models exactly as the skill would standalone (for example, code review's quality checker runs on Sonnet 5.5).

**Your current model** sets two things: the recommended `--max` (its own level), and whatever runs in your session - the conductor itself and **interactive planning at mvp/prod**, which runs inline while you're present. If your model is below the planning level you chose, the launch card suggests switching with `/model` (or your assistant's model picker) first. A run may put stages *above* your current model - that's intended. On hosts that can't run background agents (Codex, Cursor, Copilot today), each stage's lead runs in your session too, while its helper agents still use the level you chose (`HOSTS.md`).

**If you can't reach a model** (your plan or org blocks it), the stage tries the same level's previous generation, then the next level down - never below smart. `pipeline.md` and the run report record the model each stage actually ran on, e.g. "smartest ran on Fable 5 (no Fable 5.2 access)".

**Customizing:** drop a `.deep-skills/model-map.json` at your repo root to repin a model or move a stage's level - for every deep-skills skill and deep-goal. Only the keys you change; it merges over the shipped map and is validated at launch (an invalid file stops the run before anything is written). Example - run docs on Opus 5.5 when you choose smartest:

```json
{"stages":{"smartest":{"docs":"smarter"}}}
```

A config UI for this file (the *Deep Dashboard*) is planned.
