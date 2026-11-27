# Model map - fixed intelligence tiers, `--max`, and how every agent gets its model

> **Series-shared reference.** Copied **byte-identically** into every deep-* skill's and deep-goal's `references/` directory (the series standalone rule forbids cross-skill references). All copies must stay byte-identical. The series consistency sweep (`scripts/check-shared.sh`, maintainers only) verifies this.

> **Required launch input, not an optional pointer.** Before launching any agent, a skill reads this file and its sibling **`references/model-map.json`**, merges the optional repo override (§ Repo override), resolves every agent's model to a full model ID, and sets it **explicitly** on every launch with the host's launch value (§ Host binding). This is the model-tier routing correctness guarantee (`references/host-affordances.md`), not a tunable affordance. It is host-agnostic: the same files resolve on Claude Code, Codex, Cursor, and Copilot.

**Data vs rules.** `model-map.json` is the **only** place model IDs and stage tiers live: the ladder (per tier, per model family, current then previous generation), the unused utility equivalents, and the `--max` stage table. This file holds the **rules** for reading it and never restates an ID. When this file seems to disagree with the JSON about a model or a tier assignment, the (merged) JSON wins.

**Which agent gets which tier** is not in this file or the JSON. Each skill keeps its own agent table in its own references (for example deep-code-review `multi-agent.md`, deep-bugfix `clustering-and-diagnosis.md`). Those tables use the fleet notation below.

## Tiers

Three tiers, named by intelligence only, from strongest down:

1. **smartest**
2. **smarter**
3. **smart** - the floor. Nothing in the series runs below it.

**Tiers are fixed to specific models.** A tier always means the same models, whatever model the user's session runs. (They do not shift with the session model.)

**Every tier is a reasoning tier.** Finding, verifying, diagnosing, fixing, planning and documenting all reason; there is no utility-grade task anywhere in the series. The host's small/utility models are recorded in the JSON as `_utility_unused` only so they can be recognised and refused - they are **never** assigned to any agent (§ Binding rules, rule 4).

## The ladder

`ladder.<tier>.<family>` in `model-map.json` is a list of model IDs for that tier in that model family (`claude`, `gpt`). The **first** entry is the current generation, the next is the previous generation - the list is also the access-fallback order for that tier (§ Access fallback).

Claude entries are host model IDs; GPT entries are Codex model IDs (as `codex debug models` lists them). A list may hold more than two entries - for example the newest GPT generation first for accounts that have it - and is always tried in order. Matching against the ladder uses the normalization in § Base-tier lookup.

## Column = base's family

Resolve every agent from the **same family as base** (the session model, § Base): a Claude base reads the `claude` lists, a GPT base reads the `gpt` lists. A run never mixes families - hosts cannot dispatch the other family's models.

If base is not on the ladder (unknown ID), use the host's native family (GPT on Codex and on Copilot running a GPT model; Claude everywhere else - Claude Code, Cursor, Copilot on any other model, any other host) and warn as for a below-floor model (§ Base). If the host cannot launch that family, § Access fallback step 5 applies.

## Reasoning effort

Reasoning effort is the host's thinking-level setting (not the effort *slug*, which names a `.deep-skills/<slug>/` directory).

- Where the host's default reasoning effort is **medium or higher**: pass no effort parameter.
- Where the host exposes an effort parameter and its default is **below medium**: set `medium` on every launch.
- Where the host has no effort control: nothing to do.

The tier is the model; effort is never used to make up for a lower tier.

## Base

**Base** = the entry model: the model of the session the skill (or deep-goal) was invoked in. Base is also the **orchestrator**. Base decides exactly two things:

1. **Inline work runs on base.** Anything a skill does in the user's own session (interactive deep-plan, synthesis done in-session, a deep-goal stage run inline) uses base - the skill cannot change the session's model.
2. **The default `--max`** is base's tier.

### Base-tier lookup

Find base's tier by matching the session model's ID against **every list in the merged ladder** (both families, current and previous generation; ignore case, treat spaces, hyphens and underscores as equal, and ignore any host-added suffix such as a date or context-size tag). Exact match only - never guess a tier from a family name. The same normalization applies to the one-tier-only uniqueness check (§ Repo override, rule 6) and to matching a reported model ID (§ Binding rules, rule 5).

| Session model | Base tier |
|---|---|
| Any ID listed under `ladder.smartest` | smartest |
| Any ID listed under `ladder.smarter` | smarter |
| Any ID listed under `ladder.smart` | smart |
| Anything else (a utility model, an older or unknown model) | `smart` for the default `--max`, **plus a warning** |

The warning, in plain words (fill the brackets from the ladder's current `smart` entries):

> "Your current model (<id>) is smaller than these skills are built for (<current Claude smart model> / <current GPT smart model> or better). Switch models with /model (or your assistant's model picker) for reliable results."

It is a warning, not a refusal: the skill can't change the session's model.

## `--max` - the highest level a run may use

`--max=<smartest|smarter|smart>` is accepted by deep-goal and by every standalone skill.

- **Default = base's tier.** Standalone skills use the default silently; deep-goal asks when `--max` is absent.
- **Stage tier = `stages.<max>.<stage>`** in the merged JSON. Stage names: `plan` (deep-plan), `plan-review` (deep-plan-review), `implement` (deep-implement), `code-review` (deep-code-review), `bugfix` (deep-bugfix), `docs` (deep-docs).
- **`--max` may launch agents above base.** That is intended: a run started in a smart-tier session with `--max=smartest` launches its helper agents on the stronger models the table names. Inline work still runs on base.
- **Natural-language phrases must name a level word** - "use the smartest models", "keep it to smarter models", "max smart". A bare "max"/"maximum" never means `--max` (in deep-code-review it keeps meaning `--mega`).

### `--max` propagates through chains

- `deep-code-review --triage --fix` forwards `--max=<x>` to the chained deep-bugfix run.
- deep-goal passes `--max=<x>` in every dispatched stage's flags, so each stage's fleet resolves exactly as it would standalone. deep-goal's triage dispatch and re-review rounds 2+ use the `code-review` stage tier.
- deep-plan's deep-goal hand-off (step 9) forwards `--max=<x>` when deep-plan was given one.

### Hosts without background subagents

Where a host can't run a stage lead as a background agent, deep-goal runs each stage's lead inline, in sequence. Then **only the stage leads run on base**; fleets inside a stage still get their `--max` models wherever the host binds a model per agent (all four hosts can; on VS Code Copilot a fleet may fall back to one agent). The run records base as the model for each inline-led stage, and the user is told in plain words: "This assistant runs each step in your current session (<base id>). Helper agents inside a step still use the model level you chose."

## Fleet notation (internal)

Each skill's agent table gives every agent one of these. **This notation is for skill references only** - never show it to users (§ Plain words).

| Notation | Means |
|---|---|
| `stage` | the stage tier (`stages.<max>.<stage>`) |
| `one down` | one tier below the stage tier, floor `smart` |
| `two down` | two tiers below the stage tier, floor `smart` |
| `max` | the `--max` tier itself - used only where an agent table says so |

Then resolve the tier to a model ID from the ladder (base's family) and apply § Access fallback.

## Access fallback

The user's **access** (their plan or org may block a model) is the only thing the environment changes. For each agent:

1. Try the tier's current-generation ID.
2. Then the **same tier's** previous-generation ID.
3. Then step down one tier and repeat (current, then previous) - down to the floor `smart`.
4. If nothing at or below the tier is accessible, collapse **up** to the nearest accessible tier.
5. If no ladder model in base's family is accessible at any tier: a small/utility base (rule 4) → refuse, with the below-floor warning wording plus "no supported model is available to launch helper agents" (nothing below overrides this). Any other base → one sanctioned launch on base, exempt from rule 5's relaunch and from § Host binding's same-launch-value and set-aside/discard rules. If earlier attempts set any off-ladder output aside (§ Host binding), the **first one set aside** is the step-5 result - no new launch. Otherwise launch once on base - its full ID on an exact-ID host, its family word on an alias host, or inherit the session model where the host allows only that (the one sanctioned exception to rule 2); a reported small model, or that launch rejected as unavailable or unauthorized, → refuse (rule 4 wording, or "no supported model is available to launch helper agents"). Record `<reported id> (fallback: no ladder model accessible)` (no report or `unknown` → `<base id> (unverified - launched as <launch value>; fallback: no ladder model accessible)`) and present the run as degraded.

**Detection is try-and-fall-back:** launch with the candidate; a launch the host rejects as unavailable or unauthorized moves to the next candidate (a schema or validation rejection is a binding error - § Host binding - not unavailability). Never pre-guess what the user can access.

**Record the model actually used.** Every run records, in its report header, `Base: <id> · Max: <tier> · Models: <role> <id>, …`, with any fallback noted (`<id> (fallback from <id>)`, or `<id> (host substituted for <id>)` when the host ran a different tier - § Host binding). deep-goal writes the same into `pipeline.md` and its run report. A degraded run is allowed - it is the user's best - but it is never presented as equal to a full-access run.

## Host binding

The ladder ID is the model's **identity**: what is resolved, recorded and verified. The **launch value** is what the host's per-agent model setting accepts. Each host:

- **Claude Code:** the Agent tool's `model` accepts family aliases only (`fable`, `opus`, `sonnet`; RE-VERIFY per release). The launch value is the family word of the resolved ID (the token after `claude-`). It is never `haiku`, whatever the tier. Pass it explicitly on every launch, built-in types included (rule 3). Because the host resolves the alias, verification is mandatory: every launch carries the model report (below), then rule 5 applies. The plugins ship no `.claude/agents/*.md` files, so full-ID pinning is not available on this host today.
- **Codex, Cursor, Copilot:** the launch value is the resolved ID itself, in the host's per-agent `model` field (RE-VERIFY per host, especially GPT display names, § The ladder).

**Model report.** Every brief the orchestrator gives a launched agent (finder, verifier, diagnose/fix/proof agent, explorer, deep-goal stage lead) ends with this line, appended verbatim after the brief's own output contract: *'After everything else in your final response, add one last line: `MODEL: <your exact model ID>` - the ID from your own system context, not any ID this brief names; if your context names no model ID, write `MODEL: unknown`.'* The line sits **outside** any fixed output format the brief requires. The orchestrator reads it and strips it before parsing or assembling that format (verdict blocks, card verdicts, proof verdicts). The **reported ID** is the model that ran: compare it with the resolved ID (normalization: § Base-tier lookup) and apply rule 5 and the Verified-ID classification paragraph below. Where host transcript metadata names the model, that metadata substitutes for the line. `MODEL: unknown`, or neither line nor metadata present → record `<resolved id> (unverified - launched as <launch value>)` and continue (never relaunch for a missing or unknown report). This convention applies on every host and is mandatory where the launch value is an alias.

**Binding errors are not access errors.** A launch the host rejects because the value fails its schema or validation (not an allowed value, malformed) is a binding error. Correct the launch value per this section and relaunch, **at most once per candidate.** If this section defines no other launch value for that candidate, or the corrected value is also rejected, the candidate counts as **not accessible on this host** and § Access fallback advances, recorded as `<id> (binding error: <rejected value>)`. If every candidate, step 5 included, ends this way, refuse, naming the host and the rejected values (a host-binding defect, reported for the HOSTS matrix). Short of that exit, a binding error never counts as unavailable and never advances § Access fallback. Only an access, authorization or model-not-available rejection advances it.

**Verified-ID classification (and alias hosts' previous generation).** On an alias host, one alias stands for a whole tier, so step 2 (same tier, previous generation) cannot be selected. The alias's own resolution is that tier's single candidate. A reported ID that differs from the resolved ID is classified - on an alias host at once, on an exact-ID host after rule 5's one relaunch also mismatches: on the merged ladder in base's family and not small → compare its tier with the attempted candidate's tier: **same tier** → valid; record `<reported id> (fallback from <resolved id>)`. **Lower tier** → valid only where it is the candidate § Access fallback would try next (always on an alias host, where step 2 cannot be selected); record `<reported id> (host substituted for <resolved id>)`. On an exact-ID host, a lower tier whose same-tier previous generation is untried → that candidate counts as not accessible: discard the output. **Higher tier** → valid only if not above `--max` (§ `--max`); record `<reported id> (host substituted for <resolved id>)`. Above `--max` → that candidate counts as not accessible: discard the output. Small → that tier counts as not accessible on this host: discard the output. Off the ladder (not small) → that tier counts as not accessible on this host: **set the output aside** (step 5 may use it). Either way, continue § Access fallback at the next candidate (on an alias host, the next tier's alias; no relaunch with the same launch value, step 5 excepted). No model report, `MODEL: unknown` or no metadata → record `<resolved id> (unverified - launched as <launch value>)` (Model report paragraph above).

## Binding rules

1. **Resolve to the FULL model ID, never to an alias.** The resolved ID is what every run records and verifies; the value passed at launch follows § Host binding. Where any skill says "pass/bind the full model ID, never an alias", read it this way. A bare alias like `opus` is resolved by the host, not by this map: a calibration run that launched its finders with the `opus` alias silently got Opus 4.6, below the tier it was meant to run at - which is why an alias launch is always verified (rule 5, § Host binding).
2. **Set the model explicitly on every agent launch** (the host's per-agent model parameter). Never rely on inheritance from the session or on a host default.
3. **Built-in agent types need the explicit model too.** Some hosts' built-in agent types carry their own default model - for example Claude Code's `Explore` type defaults to a small model (RE-VERIFY per host release). Every launch of such a type (exploration in deep-plan, plan-review dimensions, a single-agent review) passes the tier's model explicitly.
4. **Small models never appear - any tier, any stage, any agent, any host.** The `_utility_unused` entries and the host's other small models (Haiku, GPT-mini, GPT-nano and the like) are never assigned. A calibration run whose finders silently routed to Haiku reported 0 Blockers and 0 Majors on a diff with two known Criticals - worse than no review, because it ships false confidence.
5. **Detection → discard + relaunch, once.** If an agent's model report (§ Host binding) or transcript shows it ran on a different model than the one this map resolved for it (other than a recorded access fallback), discard its output and relaunch with the model set explicitly - **at most once per candidate, on every host**, and not at all on an alias host (the same alias resolves the same way). If the relaunch also mismatches (or, on an alias host, at once), classify the reported ID per § Host binding (Verified-ID classification) instead of relaunching again. A missing or `unknown` report is recorded unverified, never relaunched. § Access fallback step 5 is exempt.

## Repo override

A repository can repin a model or move a stage's tier without touching plugin files, by adding **`.deep-skills/model-map.json`** at the repo root (beside the effort directories). It is optional; when absent, the shipped JSON is used as is. Every skill - and deep-goal - reads it **at launch, before any agent is launched**. A future Deep Dashboard edits only this file.

**Exception - a stage launched with a resolved-map snapshot.** An orchestrator that resolves the map once for a whole run may freeze it as **`.deep-skills/<effort>/00-Manifest/model-map.resolved.json`** (the whole merged map - `map_version`, `ladder`, `_utility_unused`, `stages` - same schema, plus a `_source` key) and name that file to the stage - in its briefing, or, for a skill it runs inline, in the invocation. A stage given a snapshot that way uses the snapshot as its merged map, in place of the shipped `model-map.json` and this override: the snapshot was validated when it was written, so the stage does not re-read, re-merge or re-validate either file, and never refuses over them. If the named snapshot is missing, unreadable or not valid JSON, stop with a blocker naming its path; never fall back to the shipped map or this override (the orchestrator owns its repair). Everything else in this file (tiers, `--max`, fleet notation, binding rules, host binding) applies unchanged.

**Same schema, sparse.** Only the keys you want to change. Example - run docs on the smarter tier when `--max=smartest`:

```json
{ "stages": { "smartest": { "docs": "smarter" } } }
```

**Merge at key granularity:**

- `ladder.<tier>.<family>` in the override **replaces that whole list** (current then previous, as in the shipped file).
- `stages.<max>.<stage>` in the override **replaces that one value**.
- Every key the override doesn't name keeps its shipped value. Keys starting with `_` are documentation and ignored everywhere.

**Validate at launch; on any failure refuse** with a message naming the key, the file (`.deep-skills/model-map.json`), and the valid values:

1. The file must parse as JSON.
2. Top-level keys: only `map_version`, `ladder`, `stages` (plus `_` keys). **Per-agent fleet tables are not overridable** - they live in each skill.
3. Tiers (`ladder.<tier>`) and max levels (`stages.<max>`) are one of `smartest`, `smarter`, `smart`. No new tiers. Family keys under `ladder.<tier>` are `claude` and `gpt` only (`map_version` 2); any other key → refuse.
4. The stage roster is fixed: `plan`, `plan-review`, `implement`, `code-review`, `bugfix`, `docs`. A stage's value is one of the three tiers.
5. A stage's tier may not exceed its max (`stages.smart.docs = "smartest"` → refuse).
6. Each ladder list is a non-empty list of non-empty model IDs; none may be a small/utility model; and an ID may appear in only one tier (so base-tier lookup stays unambiguous).

**The base-tier lookup uses the merged ladder**, so an overridden ID maps to the tier it was placed in.

## Plain words in user-facing text

`stage` / `one down` / `two down` / `max` are internal notation. Anything a user reads - flag descriptions, `argument-hint`, warnings, launch cards, reports, READMEs, training pages, the website - uses plain sentences and real model names: "the quality checker runs on <model name>", never "one down".

## Updating for a new release

*Maintainers only; end users never edit plugin files - a repo that wants different models uses § Repo override.*

1. Edit the ladder in the canonical `model-map.json` (the copy under `plugins/deep-skills/skills/deep-code-review/references/`): put the new model first in its tier's list and keep the outgoing current model as the previous generation.
2. Run `scripts/check-shared.sh --sync` to copy it to every skill, then `scripts/check-shared.sh --all`.
3. Update display copies (READMEs, HOSTS, training pages, website) by hand; `--stale` finds leftovers.
