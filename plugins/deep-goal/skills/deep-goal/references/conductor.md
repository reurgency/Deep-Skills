# Conductor - dispatch protocol, advance test, blocker policy

How the conductor actually walks the pipeline: the launch sequence (re-entry first), the inline planning window, the per-stage dispatch loop, the artifact-verification **advance test**, the severity-aware **blocker policy**, and the run's bookends - resume and the final run report (§ 7 summary; spec in `references/resume-and-report.md`). SKILL.md § Workflow is the summary; this file is the protocol.

Two invariants frame everything here (contract rows #3 and #4 of the plan's State/Data-Flow Contract):

- **`00-Manifest/pipeline.md` is the conductor's state file** - conductor-written only, updated at every stage boundary, and the single thing a re-invocation needs to resume. Its shape is `templates/pipeline.md`.
- **The conductor is READ-ONLY on manifest stage lines.** Each core skill flips its own line in `00-Manifest/manifest.md`; the conductor reads those flips as evidence and never writes one. (Its only manifest write, ever, is the effort summary paragraph at run completion - § 7.)

## 1. Launch sequence

Run these in order, once, before anything is dispatched. Everything resolved here is persisted into `pipeline.md` and **never re-derived mid-run**. **Nothing is written to disk before the launch card's Launch answer** (step 7) - a refusal, a dry-run, or a Cancel at any earlier point leaves the repo untouched, so re-invoking is always a clean fresh launch.

1. **Re-entry check - FIRST, before everything.** Does the invocation target an effort whose `00-Manifest/pipeline.md` already exists - or is it a bare "resume"? → the **re-entry protocol** (`references/resume-and-report.md` § 1): announce prior state and ask resume/fresh as one self-contained question. **Resume skips the rest of this sequence** - prior state (rigor, max, base, …) is re-read from the pipeline.md header, never re-derived or re-asked; **fresh** archives the old pipeline.md (`pipeline-archived-<n>.md`) and falls through here. No prior pipeline.md → continue. (`--dry-run` never re-enters.) Under `--from-plan`, the plan is located here first (§ 1c - a given path, or discovery when none is given), because it names the target effort; an effort that already has a `pipeline.md` is handled by re-entry - resume/fresh, never adoption.
2. **Rigor + max resolution.** Parse `--rigor` / `--max` and their natural-language forms (a max phrase must name a level word - `smartest`, `smarter`, `smart`; `references/model-map.md` § `--max`). Rigor: merge shipped `templates/rigor-map.json` with any `.deep-skills/rigor-map.json` override, validate, resolve the level, per SKILL.md § Rigor resolution and `references/rigor-levels.md`. **If rigor and/or max is missing, ask the missing one(s) as ONE batched structured question set** - one tool call carrying one question per missing value, never two rounds:
   - **Rigor** - options per SKILL.md § Rigor resolution step 4 (per-level previews from the resolved map, recommend mvp).
   - **Max** - one option per level (`smartest` / `smarter` / `smart`), recommended = base's level (§ Model resolution - base and the merged model map are loaded and validated *before* this question is rendered, so an invalid override refuses before the user is asked anything). Each option's preview (≤ 15 lines) lists the model every stage would run on under that choice, one stage per line, in plain words with real model IDs (inline planning as "your session: <id>").
   - Hosts without a structured-question tool: one numbered chat message covering both, same content.
   Flags or phrases given in the invocation are never re-asked. Under `--from-plan` the same rule applies - deep-plan's hand-off passes `--rigor`, so typically only max is asked.
3. **Model resolution** (§ Model resolution below) - finish resolving for the chosen max: base tier + family → per-stage tier from the merged stage table → **host-capability check** (can this host run a stage lead as a background agent with its own model? If not, every stage lead will run inline on base - § 8) → a planned model ID per stage. Fallback to other models happens later, at dispatch (try-and-fall-back), never here.
4. **`--dry-run` stops here** - print the preview (SKILL.md § `--dry-run`: stage list **with each stage's planned model**, max + base, any warning) and stop. No handshake, no card, no writes.
5. **Version handshake** - locate the installed deep-skills plugin (§ 1a below), read its `plugin.json` `version`, require ≥ 0.3.0 as semver; refuse / warn / proceed per SKILL.md § Launch. The resolved plugin.json path and version outcome are held for the `pipeline.md` header (written in step 8).
6. **Effort slug** - the conductor derives the kebab-case slug from the goal (all rigors); under `--from-plan` the slug is the adopted plan's effort directory (§ 1c). The slug is a proposal until the card: at mvp/prod the card's **Launch** answer confirms it (or **Edit goal or name** changes it); at yolo/poc the printed card states it. Either way it reaches deep-plan as `--effort=<slug>`, which uses it verbatim - deep-plan never asks for a name inside a deep-goal run.
7. **Launch card** (§ 1b) - one card summarising the run. **mvp/prod pause once** for the user's answer; **yolo/poc print the card and go** (they were already asked any missing rigor/max in step 2).
8. **Effort dir + manifest + `pipeline.md`** - only after Launch:
   - create `.deep-skills/<effort>/` and `00-Manifest/manifest.md` **if absent**, in the exact format of `references/artifact-structure.md` § Manifest format, all stage statuses `pending`. (Creating the manifest is allowed - the read-only rule covers *flipping* stage lines, which only core skills do.)
   - write `00-Manifest/pipeline.md` from `templates/pipeline.md`: full header (goal, rigor + source, **max + source, base**, resolved deep-skills location + version outcome, gates/budget/worktree), the resolved stage list with per-stage dispatch modes, invocations and **planned models** (contract row 4, write 1), the **artifact baseline** (what already exists at each stage's canonical path at this moment - § 4 defines it and judges every advance test against it; all-absent on a virgin effort; on `--worktree` runs the code-tree row is later re-recorded from the worktree at its creation - § 4, `loop-and-budget.md` § 5), one dispatch record per planned dispatch (all `pending`, except an adopted plan record - `complete`, § 1c), empty Blockers, zero spend. **Pipeline state exists from Launch** - a crash at any later point, including mid-planning, is resumable from this file (`references/resume-and-report.md` § 1 owns the resume walk; this file is what it reads).

Because the slug is now confirmed on the card, step 8's writes happen **before** the inline planning window opens at mvp/prod - before deep-plan's first question - so the long interactive session is crash-covered too.

### 1a. Locating the installed deep-skills plugin (per host)

Consolidated here from SKILL.md § Launch (which keeps the summary). Resolve **once** at launch; persist the resolved `plugin.json` path in `pipeline.md`.

- **Claude Code** (and **Copilot CLI**, which consumes the same marketplace format): installed plugins live under `~/.claude/plugins/`. Read `~/.claude/plugins/installed_plugins.json` - its `plugins` map is keyed `<plugin>@<marketplace>`; find the key beginning `deep-skills@`, take its entry's `installPath`, and read `<installPath>/.claude-plugin/plugin.json`. If that index file is absent or unreadable, fall back to globbing `~/.claude/plugins/cache/*/deep-skills/*/.claude-plugin/plugin.json` and take the most recently modified match.
- **Codex**: look for a `deep-skills` plugin root installed as a **sibling of deep-goal's own install** (both come from the same store; the vendored unit is the plugin root) and read its `.codex-plugin/plugin.json` (or its `.claude-plugin/plugin.json` - Codex also accepts the Claude manifest as a compat source; see `HOSTS.md`, RE-VERIFY per current Codex docs).
- **Cursor**: same sibling-install check under Cursor's plugin store; for local dev installs check `~/.cursor/plugins/local/deep-skills/.cursor-plugin/plugin.json` (see `HOSTS.md`).
- **Copilot / VS Code editor** (file-based, no marketplace): the skills location the user configured (`chat.agentSkillsLocations` or `.github/skills/`) points into a checkout that carries the sibling `plugins/deep-skills/` root - read its `.claude-plugin/plugin.json` from there.
- **Any host, last resort**: this skill's own file path is known at runtime - check whether a `deep-skills/` plugin root sits **beside deep-goal's plugin root** (siblings under the same install parent). If deep-skills still cannot be located, ask the user where it is installed before refusing.

The resolved location also supplies `{skill_path}` for every stage briefing: a dispatched skill's SKILL.md sits at `<deep-skills plugin root>/skills/<skill-name>/SKILL.md`.

### 1b. The launch card

One structured question (native tool; numbered-list chat fallback) shown after any step-2 questions. Its preview is **≤ 15 lines** - hosts truncate beyond that - one stage per line:

```
Goal: <one sentence>
Effort: <slug>
Rigor: <level> · Max: <tier> · Your session: <base id>
Plan: inline on your session (<base id>)      ← mvp/prod
Plan: <tier> - <model id>                     ← yolo/poc (dispatched)
Plan: adopted (<path>)                        ← --from-plan
Plan review: <tier> - <model id>
Implement: <tier> - <model id>
Code review (+ triage, re-reviews): <tier> - <model id>
Bug fix: <tier> - <model id>
Docs: <tier> - <model id>
<one warning line, only when needed>
```

Only the stages in the resolved list appear. Models are the **planned** IDs (step 3); a fallback at dispatch is recorded later, never predicted here. On a host without background agents, each stage line reads `<stage>: your session (<base id>)`.

**At most one warning line**, in plain words, merging every launch warning that applies (joined with "; ", most important first; trim to fit):

- **Base below the floor or not on the ladder** (`references/model-map.md` § Base): "Your current model (<id>) is smaller than these skills are built for (<current smart models> or better). Switch models with /model (or your assistant's model picker) for reliable results."
- **mvp/prod, base's level below the plan stage's level** (interactive planning runs in your session, so it would plan below the level you chose): "Planning runs in your session on <base id>, below the <plan tier> level you chose - to plan on <plan model id>, switch with /model (or your assistant's model picker) before launching."
- **Host can't run background agents** (§ 8): "This assistant runs each step in your current session (<base id>). Helper agents inside a step still use the model level you chose."
- **Version handshake passed with a warning** (unverifiable deep-skills version - SKILL.md § Launch): "deep-skills version couldn't be checked; assuming 0.3.0 features."

**Options (mvp/prod):**

- **Launch** (recommended) - confirms everything on the card, **including the effort slug**; go to step 8.
- **Change rigor or max** - ask only the question the user picks: if their answer already names it ("max smartest", "make it prod"), apply that; otherwise ask "Change which?" (Rigor · Max), then that one question with the same previews as step 2. Re-resolve what depends on it (a rigor change re-resolves the stage list and re-validates `--gate`s; a max change re-resolves models) and **re-render the card**. A card that has paused once keeps pausing until Launch or Cancel, even if the new rigor is yolo/poc - the user is already present.
- **Edit goal or name** - one free-text question ("new goal, new effort name, or both"), then re-derive the slug if the goal changed and **re-render the card**. A new slug that names an effort with a `pipeline.md` is refused ("that effort already has a deep-goal run - resume it, or pick another name") and the question re-asked. **Hidden under `--from-plan`** - goal and name come from the adopted plan.
- **Cancel - nothing written** - stop. Nothing was created; re-invoking starts a clean fresh launch.

**yolo/poc:** print the same card (plain text, no options) as part of the launch output and continue to step 8 - the user sees what will run before anything is dispatched.

### 1c. Continuing from a plan (`--from-plan`)

Adopts a plan written outside this run (typically an interactive `/deep-plan` whose hand-off offered deep-goal) instead of planning again. Fresh launches only - an effort that already has a `pipeline.md` goes through re-entry (§ 1 step 1), never adoption.

**Finding the plan:**

- **Path given** → it must be `.deep-skills/<slug>/01-Plan/plan.md` (relative to the repo root). Anything else - a plan outside `.deep-skills/`, a different file name - refuses at launch, naming the expected layout. The slug is the path's effort directory.
- **No path** → candidates = every `.deep-skills/*/01-Plan/plan.md` whose effort has **no** `00-Manifest/pipeline.md`. Exactly one → use it. More than one → ask which (one structured question, newest first, each preview showing the plan's goal sentence + effort + modified date). None → refuse: "No plan to continue from - run /deep-plan first."
- **Goal** = the first sentence of the plan's `## Context` section.

**What adoption does:**

- At step 8 the **plan dispatch record is written `complete`** - Started/Finished = launch time, advance test `adopted - <path> @ <mtime>`, spend `0`, Notes `adopted (--from-plan)` - and the Stage list's plan row reads Dispatch `adopted`, Model `adopted - not run`. The plan stage stays in the stage list (`references/rigor-levels.md`: a level's first stage is always `plan`); it is simply already done.
- The plan stage entry's `mode` / `rounds` / `columbo` settings are **ignored**: nothing is planned and no planning window opens.
- **Dispatch begins at the first stage after `plan` in the resolved list** - plan-review at mvp/prod, implement at yolo/poc (and whatever a custom override level lists next).
- **The adopted record is never re-tested** - not by the advance test (§ 4), not by the idempotency rule (§ 3), not on resume (`references/resume-and-report.md` § 1.3). Every later stage is judged against the normal launch baseline (which records the adopted plan.md as present, like any pre-existing artifact).
- **Autonomy starts at Launch** (the plan already exists - the autonomy boundary of § 2 is already behind us). On `--worktree` runs the worktree is created right after step 8, since planning is already complete (`references/loop-and-budget.md` § 5's "after planning" moment).
- A `--gate=plan` under `--from-plan` refuses at launch: the plan stage is adopted, not run, so a gate before it could never fire.

## 2. The planning window

Planning is the **interactivity boundary**: after the launch questions and card (§ 1), all human interaction happens here; **autonomy starts when `01-Plan/plan.md` exists.** (Under `--from-plan` there is no planning window - § 1c.)

Branch on the plan stage's `mode` in the resolved map:

- **`autonomous`** (shipped: yolo, poc) - a dispatched stage like any other: render the stage briefing for `deep-plan <goal> --autonomous --effort=<slug> --max=<x>`, appending `--columbo` when the stage entry has `"columbo": true`, and launch one fresh subagent **at the `plan` stage's model** like every dispatch (§ Model resolution). The user sees nothing until it's done. (`--columbo` folds into the *same* dispatch - core defines it as a flag of the planning run itself, self-run at the end; it is never a second dispatch.)
- **`interactive`** (shipped: mvp, prod) - the conductor runs `/deep-plan <goal> --rounds=<n> --effort=<slug> --confirmed --max=<x>` **inline in the main session** (the user is present by definition - a background agent can't ask questions), with `--rounds` from the stage entry's `rounds` and columbo honored per the map. `--confirmed` + `--effort` tell deep-plan the launch card already confirmed the goal and the name, so it skips its restate question and its naming question (its scope/non-goals Frame step still runs - that is planning content); deep-plan's own workflow then drives the front-loaded question rounds, optional gap rounds, and the pre-write nudge. **Being inline, the planning conversation runs on base** (the session model - nothing can change it); `--max=<x>` makes deep-plan's helper agents (exploration, columbo) use the plan stage's level (§ Model resolution).

**Every stage - inline, dispatched, or adopted - gets a `pipeline.md` dispatch record.** Mark the planning record `in-flight` when the window opens (dispatch launched, or inline session started). **Adoption carve-out:** under `--from-plan` the planning record is written `complete` at Launch with advance test `adopted - <path> @ <mtime>` and is never tested or re-tested (§ 1c) - everything below applies only to a plan this run actually writes. The planning record's completion test is deliberately simple: **it completes when `01-Plan/plan.md` exists** - judged against the launch baseline like every advance test (§ 4), so a plan.md that survived a fresh restart completes the record only once the planner has (re)written it. That moment is the autonomy boundary - from here on the conductor asks no unsolicited questions; it only notifies (halts, gates, budget pauses, completion) and, at user-injected `--gate`s or budget ceilings, waits.

## 3. The dispatch loop

For each remaining stage in the resolved list, in order:

1. **Guard:** exactly **one stage in flight at a time.** Before launching, confirm no other record is `in-flight`, then mark this record `in-flight` with its start time. (If deep-goal is re-invoked while a record is `in-flight`, announce the running stage instead of double-dispatching; full resume - including the re-entry edition of this guard - is `references/resume-and-report.md` § 1.)
2. **Render the briefing:** fill `templates/stage-briefing.md` - substitute `{skill_name}` (from the merged map's `known_stages.<stage>.skill`), `{skill_path}` (from the launch-resolved deep-skills location), `{effort_name}`, `{stage_flags}` (per the invocation table below - **always ending with `--max=<x>`**, the run's max from the pipeline.md header), `{stage_tier}` + `{stage_model}` (the stage's level and the model ID it is being launched on - § Model resolution below), and `{worktree_path}` (the conductor-created worktree on `--worktree` runs, else the none-form - both renderings: `references/loop-and-budget.md` § 5 and the template's comment block). The rendered text is the subagent's **entire prompt** - nothing else rides along, no transcripts, no plan excerpts; the briefed agent reads the skill's own SKILL.md and the effort's artifacts.
3. **Dispatch:** launch **one fresh subagent** with its model **set explicitly to the stage tier's resolved model ID** (§ Model resolution below) - never left to inherit the session model. **Try-and-fall-back:** if the host rejects the launch as unavailable/unauthorized, relaunch with the next candidate per `references/model-map.md` § Access fallback (same tier's previous generation, then one tier down, floor `smart`; collapse up only if nothing at or below is accessible). The stage's helper agents resolve from `--max` via the stage skill's own model map and agent table. Await completion. Never dispatch two stages concurrently, never reuse a stage's agent for the next stage.
   **Record the model that ran** (contract row 4, write 2): when the record leaves `in-flight` (`complete` or `halted`), overwrite the stage's Stage-list `Model` cell with `<tier>: <id actually used>`, plus ` (fallback from <planned id>)` when a fallback happened. A later dispatch of the same stage (triage, re-review rounds) that ran on a different model notes `model: <id>` in its own record's Notes. Inline stages record theirs on completion (or on resume) - `your session: <id> (inline)`.
4. **Advance test** (§ 4): verify artifacts and manifest evidence - never the subagent's closing narrative. Pass → complete the record (finished time, advance-test result, spend estimate from `references/rigor-levels.md` § Cost bands - refined by observed usage where the host surfaces it, always labeled an estimate) and continue. Fail → inspect for a blocker artifact and apply the blocker policy (§ 5).
5. **Boundary checks** before looping to the next stage: round accounting + convergence when inside the review→fix loop (§ 6), then the **budget check** (`--budget` runs), then the **gate check** (`--gate` before the next stage) - full order and pause procedures in `references/loop-and-budget.md` § 6. A pause always lands *between* stages, never mid-stage.

**Empty-set skips (review→fix loop only):** two loop dispatches are conditional on work existing in `findings.json` - `code-review (triage)` is **skipped** when zero findings are `open`, and `bugfix` is **skipped** when zero findings are `accepted`-and-not-`fixed` (dispatching deep-bugfix with nothing actionable strands an autonomous agent that is forbidden to ask for input, and the advance test would then HALT a healthy run). A skipped record is marked `complete` straight from `pending` with advance test `skipped - …`, and a skipped bugfix ends the loop by cap. Spec: `references/loop-and-budget.md` § 1.5.

**Idempotency:** because the advance test is artifact-based and launch-relative (§ 4), an accidental re-dispatch is harmless - if the expected artifact already exists **new against the baseline** and the manifest line is already flipped, mark the record complete and move on without dispatching. An artifact the baseline shows pre-existed never triggers this rule - a fresh restart's surviving stages, or a pre-run manual skill's artifacts, are not this run's work. **Adoption carve-out:** the one pre-existing artifact a run counts as its own is a plan adopted with `--from-plan` - its record is written `complete` at Launch (§ 1c) and never reaches this rule. **Exception:** review rounds ≥ 2 in the review→fix loop (`04-Code-Review/` artifacts are not round-versioned, so bare existence is vacuously true from round 2) use the **round-aware test** - pre-dispatch findings.json snapshot vs fresh CR ids / status changes / updated `reviewed` date - specified with the loop controller in `references/loop-and-budget.md` § 1.2.

### Stage → invocation table

What `{stage_flags}` renders to, per stage entry in the resolved map. **Every invocation - inline or dispatched - ends with `--max=<x>`** (the run's max, from the pipeline.md header), shown explicitly in the plan rows and appended to every other row, so each stage's helper agents resolve exactly as they would standalone. Skills are invoked **by name** (the house cross-skill precedent); explicit artifact paths are passed where a skill accepts one, so "latest" never has to be guessed.

| Stage entry | Dispatch(es) | Invocation (`{skill_name}` + `{stage_flags}`) |
|---|---|---|
| `plan`, `mode: autonomous` | 1 subagent | `deep-plan` - `<goal> --autonomous --effort=<slug> --max=<x>` + `--columbo` if `columbo: true` |
| `plan`, `mode: interactive` | inline | `deep-plan` - `<goal> --rounds=<rounds> --effort=<slug> --confirmed --max=<x>` (+ columbo per map; user present) |
| `plan`, adopted (`--from-plan`) | none | - (record written `complete` at Launch, § 1c) |
| `plan-review` | 1 subagent | `deep-plan-review` - `.deep-skills/<effort>/01-Plan/plan.md` + `--multi-agent` if `mode: multi-agent` |
| `implement` | 1 subagent | `deep-implement` - `.deep-skills/<effort>/01-Plan/plan.md --autonomous` |
| `code-review` (the review) | 1 subagent | `deep-code-review` - current branch + `--multi-agent` if `mode: multi-agent` (single-agent is core's default; no flag) |
| `code-review` → `triage` option | 1 **more** subagent | `deep-code-review` - `--triage --auto-accept-min=<triage.auto_accept_min>` |
| `bugfix` | 1 subagent | `deep-bugfix` - `.deep-skills/<effort>/04-Code-Review/findings.json --autonomous` |
| `docs` | 1 subagent | `deep-docs` - effort mode (the effort is named in the briefing; deep-docs' intake resolves it) |

**Why triage is a second dispatch of the same skill (and columbo isn't):** the rigor map encodes both as *per-stage options, not standalone stages* - that is a statement about the **data shape and the artifact contract** (triage writes the same `04-Code-Review/` artifacts and has **no manifest line of its own**), and it matches *how core exposes them*. And core exposes them differently: `--columbo` is a flag **of the planning run** (self-run at its end - one invocation), while `--triage` is a **separate opt-in invocation** of deep-code-review that runs *only* the triage step and "never re-runs the review" (deep-code-review SKILL.md § 7 / § Flags) - core defines no combined review+triage invocation, and deep-goal relies only on documented core flags. Separate dispatches also buy exactly what the plan values in rejecting the `--fix` triage+bugfix fusion: a per-dispatch spend record, a fresh agent per step, and the clean triage boundary the loop's per-round accounting hangs on (`references/loop-and-budget.md` § 1.3). So one `code-review` stage entry with a `triage` option expands to **two consecutive dispatch records** in `pipeline.md` (`code-review`, then `code-review (triage)`); a `code-review` entry *without* the option (custom overrides) expands to one, and triage falls to the user.

### Model resolution

deep-goal reads the same model data as every core skill: the shipped **`references/model-map.json`** (the ladder and the `--max` stage table - the only place model IDs and stage tiers live) merged with the optional repo override **`.deep-skills/model-map.json`**, read by the rules in **`references/model-map.md`** (both are byte-identical series-shared copies). Resolve once at launch (§ 1 steps 2-3), persist into pipeline.md, never re-derive mid-run.

1. **Load + merge + validate** the model map per `model-map.md` § Repo override - **before the step-2 max question is rendered and before anything is dispatched or written**. An invalid override refuses at launch naming the key, the file, and the valid values.
2. **Base** = the session model the conductor runs on. Look up its tier in the merged ladder (`model-map.md` § Base-tier lookup - exact match, no family guessing) and its family (the column it was found in). Not on the ladder (a utility model, an older or unknown model) → base tier `smart` for the default max, the host's native family column (Claude on Claude Code; GPT on Codex and on Copilot running a GPT model), and the below-floor warning on the card.
3. **Max** = `--max` / phrase / the step-2 answer; the recommended (default) answer is base's tier. Persist with its source (`flag` | `asked` | `default`). **Max may put stages above base** - intended.
4. **Stage tier** = `stages.<max>.<stage>` in the merged JSON. The `code-review (triage)` dispatch and re-review rounds ≥ 2 (and their triage/bugfix records) use their stage's tier - triage and re-reviews the `code-review` tier.
5. **Host-capability check** - can this host launch a stage lead as a background agent with its own model? Yes → each dispatched stage lead runs on its stage tier's model. No → every stage lead runs inline on base (§ 8); record `your session: <base id> (inline-led)` for those stages and put the plain-words line on the card.
6. **Planned model** = the first entry of `ladder.<stage tier>.<base family>` in the merged map. This is what the card, the dry-run, and pipeline.md's Stage list show at launch (contract row 4, write 1). Access is **never pre-guessed**: the dispatch applies try-and-fall-back (§ 3 step 3) and records the model that actually ran (write 2).

**Inline work runs on base.** The conductor itself and interactive planning (mvp/prod, § 2) run in the user's session on base - nothing can change that session's model. The interactive plan row therefore shows `your session: <base id> (inline)`, and its `--max=<x>` still makes deep-plan's helper agents run at the plan tier. A **dispatched** autonomous plan (yolo/poc) launches at the plan tier like any other stage.

**Reasoning effort** follows `model-map.md` § Reasoning effort (pass none where the host default is medium or higher; set `medium` where it is lower). **Small models never run**, at any stage (`model-map.md` § Binding rules).

**Resume never re-resolves.** Max and Base are re-read from the header and the Stage list's planned/actual models are reused; a session that now runs a different model only changes what runs *inline* from here on (`references/resume-and-report.md` § 1.3).

## 4. The advance test

After every dispatch (and the inline planning window), the conductor verifies, itself, with its own reads - except for a plan adopted with `--from-plan`, whose record is `complete` from Launch and is never tested (§ 1c; carve-out below):

> **The expected artifact exists at its canonical path AND the skill flipped its own manifest stage line.**

Never advance on the subagent's word - a closing message is not evidence. Canonical paths and manifest line names are the series contract (`references/artifact-structure.md`).

**Judged against the launch baseline, always.** Efforts are not always virgin: a fresh restart archives *only* pipeline state (`references/resume-and-report.md` § 1.2 - the manifest, plan, and stage artifacts survive), and a stage skill may have been run manually before deep-goal ever saw the effort. Against such artifacts, absolute predicates lie in both directions - bare existence is vacuously true for stages that never ran, and "findings statuses all `open`" is false for a review that ran perfectly (appends preserve prior statuses by contract). So the launch sequence (§ 1 step 8) records the **artifact baseline** in `pipeline.md` (`templates/pipeline.md` § Artifact baseline): for each canonical artifact, `absent` or present-with-mtime - plus, where present, findings.json's max CR id · count · `reviewed` date · findings/certificate mtimes, the highest pre-existing `06-Bug-Fix/round-K/`, and the manifest's stage statuses at launch. **Worktree exception - the one row ever re-recorded:** on `--worktree` runs the docs check reads `docs/ai-map/` in the worktree (`loop-and-budget.md` § 5), where `git worktree add` gives every file a checkout-time mtime - strictly after launch - so the launch-recorded invocation-repo mtime could never fail a docs stage that died; the `docs/ai-map/ (code tree)` row is therefore **re-recorded from the fresh worktree at worktree creation**, and the docs row below is judged against that re-recorded value. In the table below, **"exists" means exists new against that baseline** - absent at launch, or mtime strictly newer than the baseline's - and **"flipped" means changed from its baseline status** (a line already `complete` at launch is inconclusive evidence; the artifact half of the test carries alone). On a virgin effort the baseline is all-absent and every check reduces to its plain reading - round-1 behavior over a clean effort is unchanged. § 1.5 **skips are exempt**: a skipped record is a conductor decision that writes no artifacts and is never judged against the baseline (or any artifact) at all. **Adoption carve-out:** so is an adopted plan record (`--from-plan`, § 1c) - the baseline records the adopted plan.md as present, the record is `complete` with advance test `adopted - <path> @ <mtime>`, and it is never judged or re-judged; a *plain* launch over an existing plan.md still re-plans and is judged normally (a surviving plan.md is not this run's work). Every later stage of an adopted run is judged against the baseline as usual.

The exact per-stage checks:

| Stage record | Expected artifact (canonical path, under `.deep-skills/<effort>/`) | Manifest evidence (`00-Manifest/manifest.md`) |
|---|---|---|
| `plan` | `01-Plan/plan.md` exists | none required - **plan.md's existence is the test** (the autonomy boundary; deep-plan flips `01 Plan` as usual, but the record completes on the artifact). Adopted (`--from-plan`): no test - written `complete` at Launch (§ 1c) |
| `plan-review` | `02-Plan-Review/review.md` exists | `02 Plan Review` flipped to `complete` |
| `implement` | `03-Implementation/summary.md` exists | `03 Implementation` flipped to `complete` |
| `code-review` (review) | `04-Code-Review/report.md` + `findings.json` + `certificate.md` all exist; every finding **this round appended** is `open` - that is all of them when the baseline shows no `findings.json`; over a pre-existing one (fresh restart, manual prior review) the appended set is the CR ids above the baseline's max, prior statuses are preserved by the append contract and never fail this test, and the whole row is judged as the **round-aware test** (`loop-and-budget.md` § 1.2) with the launch baseline as its snapshot | `04 Code Review` flipped by the skill |
| `code-review (triage)` | **no manifest line of its own** - test reads the artifacts triage rewrites: `04-Code-Review/findings.json` has **zero `open` statuses** (each finding now `accepted` / `deferred` / `rejected by user` - the exact literals) AND `certificate.md`'s **Triage outcomes** table is filled (no longer "Triage pending") | n/a (triage also updates the Code Review status per its own workflow, but the findings.json + certificate check is the test) |
| `bugfix` | `06-Bug-Fix/round-N/fix-summary.md` exists in the highest `round-N/`, with N **above the baseline's highest pre-existing round dir** (any N when the baseline shows none - rounds are append-only, so a prior run's round dir never passes for a bugfix that did not run) | `06 Bug Fix` flipped by the skill |
| `docs` | in-repo `docs/ai-map/` published (`MAP.md` + `index.json`) and the `07-Docs/` pointer present - on `--worktree` runs `docs/ai-map/` is read **in the worktree** and judged against the baseline row **re-recorded at worktree creation** (`loop-and-budget.md` § 5), never the launch mtime | `07 Docs` flipped to `complete` |

- **Review rounds ≥ 2** replace the code-review/triage rows with the **round-aware test** (fresh CR ids or status changes AND an updated `reviewed` date vs the pre-dispatch snapshot) - `references/loop-and-budget.md` § 1.2 specifies it; never use bare artifact existence there.
- On **pass**: append/complete the dispatch record and move to the next stage.
- On **fail**: do not advance and do not blindly re-dispatch - look for the stage's blocker artifact (§ 5 table) and classify. A failed advance test with *no* blocker artifact means the stage died mid-flight (crash, context loss): leave the record `in-flight`-annotated per `templates/pipeline.md` and re-dispatch once; the core skills' own internal resume (phase summaries, round scope, `--refresh`) makes that safe. Fails again → treat as a HALT-class blocker with a note that no blocker report exists.

## 5. Blocker policy (severity-aware)

A blocker is a stage saying "a human is needed." The conductor classifies by **where in the spine it happened**, not by who reported it: upstream ("spine") blockers poison every later stage - halting is cheaper than reviewing rubble; tail blockers are self-contained - the run finishes and reports them loudly.

| Blocker | Where it shows up | Class | Conductor action |
|---|---|---|---|
| Plan-review **Blocker verdict** (verdict line reports `Blockers: N`, N > 0) | `02-Plan-Review/review.md` verdict line + Blockers section | **spine** | **HALT + notify** - downstream would implement a plan with known fatal flaws |
| Implement **phase blocked at the fix cap** (2 attempts) | ⛔ Blocker report appended to `01-Plan/plan.md` § Phase Summaries (deep-implement's `templates/blocker-report.md`; broken code never committed) | **spine** | **HALT + notify** - later stages would review rubble |
| Bugfix **unproven cluster at the fix cap** (reverted) | `06-Bug-Fix/round-N/blocker-<CL-K>.md` (one per blocked cluster) | **tail** | **CONTINUE + record** - clusters are independent; other clusters' fixes stand |
| Docs **anchor drift blocks publish** (`drifted` / `over-budget` anchors) | the drift record: `docs/ai-map/coverage.md` + the drifted-anchor list in `docs/ai-map/learn-signal.json` | **tail** | **CONTINUE + record** - a docs-only failure never invalidates the built code |

**Either way, `pipeline.md` carries the blocker-report path** (Blockers table row: stage · policy · report path · one-line note), and the final run report (§ 7; `references/resume-and-report.md` § 2) lists every blocker with its path.

**HALT procedure:** mark the stage's dispatch record `halted` (with the advance-test result), append the Blockers row with policy `HALT`, **notify**, and stop - dispatch nothing further. Do not archive or unwind anything: the halted `pipeline.md` *is* the resume point (a re-invocation re-enters at the halted stage once the human unblocks it - `references/resume-and-report.md` § 1.3).

**CONTINUE procedure:** record the blocker (Blockers row, policy `CONTINUE`) and proceed to the next stage. The stage's own record reflects its actual outcome: `complete` when its advance test still passed (bugfix with one blocked cluster among fixed ones - `fix-summary.md` exists and the manifest flipped), `halted` when it didn't (docs publish blocked by drift) - `halted` on a record means *the stage* stopped, the Blockers row's policy column says whether *the run* did. No mid-run notification for CONTINUE blockers - they ride the completion notification and the run report (the notify-sparingly rule: halts, gates, budget pauses, completion only).

**Notification mechanics:** one line, < 200 chars, lead with the actionable fact and the blocker-report path, via the host fallback chain (native, e.g. Claude Code PushNotification → shell `osascript` → bold `ATTENTION:` line as the last line of the turn - the series' host-affordances convention). Example:

> `deep-goal halted: implement blocked at Phase 2 (fix cap) - see .deep-skills/<effort>/01-Plan/plan.md § Phase Summaries. Re-invoke deep-goal to resume once unblocked.`

The full trigger set - **halts (blocker or convergence), gates, budget pauses, completion - and nothing else** - with per-trigger example lines lives in `references/loop-and-budget.md` § 4; halts use the mechanics above.

## 6. The review→fix loop (summary)

Spec: `references/loop-and-budget.md` § 1. **Round 1** is the map's own `code-review` (+ its triage option, a second dispatch) and `bugfix` stages, tested per § 4. **Re-review rounds (≥ 2)** append records `code-review (round N)` - plus `code-review (triage, round N)` and `bugfix (round N)` when the loop continues - reuse the level's `code-review` stage entry verbatim (same mode, same threshold), and use the **round-aware advance test** (pre-dispatch snapshot of findings.json's CR ids / count / `reviewed` date, taken when the record goes `in-flight`). Every round, both post-review dispatches are subject to the **empty-set short-circuit** (spec § 1.5): zero `open` findings → triage is skipped; zero `accepted`-and-not-`fixed` findings → bugfix is skipped and the loop exits by cap (cap 0 → next map stage; cap ≥ 1 → certificate PASS → exit to docs, FAIL → HALT - and a re-review of an unchanged tree is never dispatched). Skipped records go `complete` with advance test `skipped - …`, never a Blockers row. After each round the conductor appends the round's **non-`fixed` findings count** to pipeline.md's Review loop table.

Exit semantics key off the level's **`re_review_cap`, read from the resolved map - never a hard-coded literal**:

- **cap 0** - loop ends after round 1's bugfix; residual `deferred` findings go to the run report.
- **cap 1** - exactly one re-review; **HALT** only on unresolved Blockers (certificate FAIL), else **exit to docs** with round-2 residuals (fresh `open` + all `deferred`) reported.
- **cap ≥ 2** - from round 2: exit on certificate **PASS** AND **strictly fewer** non-`fixed` findings than the prior round; fail with re-reviews remaining → triage → bugfix → next round; cap reached without convergence → **HALT + notify as a convergence failure**.

## 7. Re-entry & run completion (summary)

Spec: `references/resume-and-report.md`. **Re-entry** is the launch sequence's **first check** (§ 1 item 1): an invocation that finds an existing `00-Manifest/pipeline.md` announces prior state and asks **resume / fresh** as one self-contained question - resume re-enters at the **first dispatch record that is not `complete`** (a `pending` record re-runs its boundary checks - budget with the current ceiling, then any unapproved gate re-fires; an `in-flight` record whose artifacts pass the advance test is marked complete and skipped - the idempotency rule; one that fails is re-dispatched once, on the core skills' own internal resume; review rounds ≥ 2 judged by the round-aware test, never bare existence); fresh archives the old pipeline.md as `pipeline-archived-<n>.md` and relaunches. All persisted header state - rigor, **max, base**, stage list (with its planned/actual models), deep-skills location, gates, budget, worktree - is **re-read, never re-derived** (max is never re-asked; the resume preview shows "base was <id>, now <id>" when the session model changed). An adopted plan record is `complete` and is never re-tested.

**Completion** - when the walk's last record is `complete`, in order: **write `00-Manifest/run-report.md`** (`templates/run-report.md`; contents spec `resume-and-report.md` § 2.2 - stages + commits, the plan's Assumptions **verbatim**, every `deferred` finding with severity from findings.json, every blocker with its report path, per-stage + total spend with the uncalibrated caveat, worktree + merge instructions when set) → **update the manifest effort summary paragraph** (the conductor's ONLY manifest write, ever) → **completion notification** (`loop-and-budget.md` § 4) → **deliver the full report as the closing message**. HALTed runs write no report; the halted pipeline.md is the resume point.

## 8. Hosts

Everything above assumes **Claude Code subagent affordances** (fresh background subagents with a supplied prompt and their own model) - the v1 designed-and-verified floor. On hosts without them (Codex / Cursor / Copilot), dispatch degrades to **inline sequential execution** per `HOSTS.md` - same stage order, same briefing content, same advance tests and pipeline.md records; honestly caveated (prod-rigor runs may hit context limits). Only this section's *mechanism* changes per host; the protocol does not.

**Models on such hosts** (`references/model-map.md` § Hosts without background subagents): only the **stage leads** then run on base - the session can't switch models per stage. Helper agents inside a stage still get their `--max` models wherever the host binds a model per agent (all four hosts can; on VS Code Copilot a fleet may fall back to one agent), because every stage still receives `--max=<x>`. The launch card says, in plain words: "This assistant runs each step in your current session (<base id>). Helper agents inside a step still use the model level you chose." Each inline-led stage's Model cell records `your session: <base id> (inline-led)`.
