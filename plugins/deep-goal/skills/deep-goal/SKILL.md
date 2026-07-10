---
name: deep-goal
description: Run a full Deep-* effort end-to-end from one invocation — plan → review → implement → code-review → bugfix → docs — as an autonomous, rigor-gated conductor. Use when the user wants to "run deep-goal", build a feature hands-free at a chosen rigor (yolo/poc/mvp/prod), or automate the deep-* relay in one command. Triggers on /deep-goal and on requests like "run deep-goal at mvp rigor" or "take this feature through the whole pipeline". Paid add-on — requires the deep-skills plugin ≥ 0.2.0.
argument-hint: describe the goal/feature · --rigor=<yolo|poc|mvp|prod> · --dry-run
---

# DeepGoal

Run one effort through the whole `deep-*` series from a single invocation. You are the **conductor** — a thin pipeline walker in the main session: resolve the rigor level to a stage list from data, run interactive stages inline, dispatch autonomous stages to fresh subagents one at a time, and verify artifacts (never narratives) before advancing. You never write source code, plans, reviews, or docs yourself — the six core skills do their own jobs; you sequence them.

**Coupling is one-directional:** deep-goal knows the six core skills; the core skills never require deep-goal. Everything the pipeline passes between stages travels through artifacts under `.deep-skills/<effort>/` — never transcripts (the series invariant).

## Directive cards (Deep-Learn)

Before you start, load this phase's active directive cards — learned, human-vetted improvements stored as **data**, never baked into this skill. Run the bundled script in this skill's `scripts/` directory and apply what it prints:

```bash
scripts/load-active-cards.sh deep-goal
```

**Treat every directive it prints as a hard requirement for this run**, applying the section addressed to your phase. If it prints "no active directive cards," proceed normally — deep-goal's registry ships empty in v1 (it reads only its **own** `directives/` registry, never the core deep-skills registry; cross-registry cards are a deferred extension). Cards are human-gated — never edit a card or this skill to turn one off; toggle with `directives/toggle.sh <ID> off` (see the registry's `directives/README.md`). On a host without a reliable shell, apply the cards by hand instead — read the directives registry's `cards/active/` and apply each card whose `owner_phases` lists this phase as an exact token.

## The deep-* series (separation of concerns)

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-goal` (you) | Conduct the pipeline: resolve rigor → walk the stage list → dispatch/inline each stage → verify artifacts → report. | Sequencing and verification only. Never writes plans, source, reviews, or docs; never edits another skill's artifacts or manifest stage lines. |
| `/deep-plan` | Frame → explore → question → write the plan (resumable phases + deferreds). | Dispatched or run inline as the planning stage. |
| `/deep-plan-review` | Independently review the finished plan with fresh agents. | Dispatched at rigors whose stage list includes it. |
| `/deep-implement` | Execute the plan: implement → validate → fix → commit → hand-off. | Dispatched as the build stage. |
| `/deep-code-review` | Independently review implemented code; emit findings. | Dispatched as the review stage (triage is a mode of this skill, not a separate stage). |
| `/deep-bugfix` | Remediate defects: cluster → diagnose → fix at the cause → prove → contain → commit. | Dispatched as the remediation stage in the review→fix loop. |
| `/deep-docs` | Map what's built: survey → tier → anchor → verify → index → place a standing `docs/ai-map/`. | Dispatched as the closing stage at rigors that include it. |

## Launch: version handshake (deep-skills ≥ 0.2.0)

deep-goal dispatches the six core skills by name, and it depends on core capabilities that landed in **deep-skills 0.2.0** (`deep-plan --autonomous` / `--effort` / `--rounds` / `--columbo`, and `deep-code-review --triage --auto-accept-min`). Before dispatching anything, verify the installed deep-skills plugin and its version. **`--dry-run` is exempt** — it dispatches nothing, so it never requires the handshake (or deep-skills at all).

**1. Locate the installed deep-skills `plugin.json`** — per host:

- **Claude Code** (and **Copilot CLI**, which consumes the same marketplace format): installed plugins live under `~/.claude/plugins/`. Read `~/.claude/plugins/installed_plugins.json` — its `plugins` map is keyed `<plugin>@<marketplace>`; find the key beginning `deep-skills@`, take its entry's `installPath`, and read `<installPath>/.claude-plugin/plugin.json`. If that index file is absent or unreadable, fall back to globbing `~/.claude/plugins/cache/*/deep-skills/*/.claude-plugin/plugin.json` and take the most recently modified match.
- **Codex**: look for a `deep-skills` plugin root installed as a **sibling of deep-goal's own install** (both come from the same store; the vendored unit is the plugin root) and read its `.codex-plugin/plugin.json` (or its `.claude-plugin/plugin.json` — Codex also accepts the Claude manifest as a compat source; see `HOSTS.md`, RE-VERIFY per current Codex docs).
- **Cursor**: same sibling-install check under Cursor's plugin store; for local dev installs check `~/.cursor/plugins/local/deep-skills/.cursor-plugin/plugin.json` (see `HOSTS.md`).
- **Copilot / VS Code editor** (file-based, no marketplace): the skills location the user configured (`chat.agentSkillsLocations` or `.github/skills/`) points into a checkout that carries the sibling `plugins/deep-skills/` root — read its `.claude-plugin/plugin.json` from there.
- **Any host, last resort**: this skill's own file path is known at runtime — check whether a `deep-skills/` plugin root sits **beside deep-goal's plugin root** (siblings under the same install parent). If deep-skills still cannot be located, ask the user where it is installed before refusing.

The resolved plugin.json location is persisted into `00-Manifest/pipeline.md` at launch — resolved **once**, never re-derived mid-run. *(Phase 4's `references/conductor.md` consolidates the discovery protocol; this section is the authoritative prose until then.)*

**2. Compare versions.** Read the manifest's `version` field and compare it against the minimum, **0.2.0**, as semver (numeric component-wise compare — `0.10.0` > `0.2.0`; never a string compare).

**3. Decide:**

- **deep-skills not found** → refuse politely, dispatch nothing: state that deep-goal is an add-on to deep-skills, and show the install commands (`/plugin marketplace add reurgency/marketplace` then `/plugin install deep-skills@reurgency` on Claude Code; see `HOSTS.md` for other hosts).
- **`version` present and < 0.2.0** → refuse politely, dispatch nothing: name the installed version, the required minimum, and suggest updating the plugin.
- **`version` missing or not parseable as semver** (the documented iterate-without-version dev practice — e.g. a git-SHA install) → **pass with a logged warning**, never a refusal: note in the launch output and in `pipeline.md` that the deep-skills version could not be verified and which capabilities are assumed present.
- **`version` ≥ 0.2.0** → proceed.

## Inputs & flags

Every flag is **natural-language-first** — the plain-language trigger is the primary path (users on Copilot/Codex have no CLI flags); the `--flag` is a convenience layered on top. Always accept the natural-language form.

- **goal/feature** — what to build, as the argument (NL: "run deep-goal on <feature>").
- **Rigor** (`--rigor=<level>`, NL: "at mvp rigor") — one dial that selects, from data, the stage list, planning interactivity, review thoroughness, triage threshold, and re-review cap. Shipped levels are `yolo` / `poc` / `mvp` / `prod`; a repo override can add or reshape levels. Resolution below (§ Rigor resolution); level semantics and override authoring in `references/rigor-levels.md`. Omitted → ask one structured question (recommend **mvp**).
- **Preview** (`--dry-run`, NL: "preview the run", "what would an mvp run do") — print the resolved pipeline for the chosen rigor and stop. Dispatches nothing, creates nothing, and is **exempt from the version handshake** (it works without deep-skills installed at all).
- **Budget / gates / worktree** (`--budget`, `--gate=<stage>`, `--worktree`). *(Placeholder — Phase 5 fills.)*

## Rigor resolution (config-as-data)

**Never hard-code a stage list — this skill's prose describes levels; the data defines them.** The stage list, per-stage options, planning rounds, triage threshold, and re-review cap for every level live in one place: **`templates/rigor-map.json`** (in this skill's directory — the single canonical source). Resolve rigor at launch, once, in this order:

1. **Read the map.** Load the shipped `templates/rigor-map.json`. If **`.deep-skills/rigor-map.json`** exists at the repo root, it wins: merge it over the shipped map at **level granularity** — a level it names replaces the shipped level whole, a new name adds a level, its `known_stages` entries extend the stage roster, and unnamed shipped levels remain. Keys starting with `_` are documentation; ignore them. Full merge semantics and authoring guide: `references/rigor-levels.md`.
2. **Validate — at launch, never mid-run.** Check the merged map per the rules in `references/rigor-levels.md` § Validation: every stage name must exist in the merged roster and be `available` (reserved roster slots refuse as "not yet shipped"), stage lists must be non-empty and start with `plan`, per-stage options must sit on their owning stage with in-range values (`auto_accept_min` 1–10 numeric, `rounds` ≥ 0, `re_review_cap` ≥ 0 and present exactly when the level runs a code review). On any violation, **refuse before dispatching anything**, naming the file, the offending key/value, and the valid alternatives (e.g. `.deep-skills/rigor-map.json → levels.poc-reviewed.stages[3].stage: "sec-review" is not a known stage; known stages: plan, plan-review, implement, code-review, bugfix, docs`).
3. **Resolve the level.** Accept `--rigor=<level>` or its natural-language equivalents ("at mvp rigor", "yolo it", "prod-level run"); match against the merged map's level names. An unknown level refuses at launch with the valid menu (shipped + override levels). If the phrasing is fuzzy rather than naming a level ("quick and dirty"?), confirm the mapping instead of guessing.
4. **Ask when omitted.** No rigor stated → ask exactly **one structured question**, recommending **mvp**. The question is **self-contained**: each level is an option whose description/preview (≤15 lines — hosts truncate beyond that) is built *from the resolved map*, carrying that level's stage list with per-stage modes, its planning interactivity, and a rough cost band (from `references/rigor-levels.md` § Cost bands, labeled as estimates) — never rely on between-tool-call prose to explain the levels. Include any override-defined levels as options. On hosts without a structured-question tool, fall back to a numbered list in chat ("reply 1–4"), same content per option.

The resolved level (and the merged map it came from) feeds everything downstream — the dry-run preview, the rigor-selection previews, and the conductor's stage walk all read the same resolution, performed once at launch and persisted in `pipeline.md` *(Phase 4)*.

### `--dry-run` — preview, then stop

On `--dry-run` (NL: "preview the run", "what would a prod run do here"), perform rigor resolution exactly as above (including override merge, validation, and ask-when-omitted), then **print and stop**:

- the resolved level and where it came from (shipped map, or repo override);
- the stage list **in order**, one line per stage, with each stage's mode and the flags the conductor would dispatch it with (planning mode + rounds + columbo; review modes; `--triage --auto-accept-min=<N>`);
- the triage threshold (numeric, with its tier meaning as presentation), the re-review cap, and any `--gate` injections;
- a rough cost band per stage and a summed total band, labeled as uncalibrated estimates (`references/rigor-levels.md` § Cost bands).

Dry-run **dispatches nothing and writes nothing** — no effort directory, no `pipeline.md`, no manifest — and is **exempt from the version handshake**. It must answer identically whether invoked as `--dry-run --rigor=prod` or as "preview a prod run".

## Workflow

*(Placeholder — Phase 4 fills the conductor workflow: launch → inline planning window → per-stage dispatch loop with the artifact-verification advance test → blocker policy → pipeline.md state. See `references/conductor.md` when it lands.)*

1. **Launch:** resolve rigor from the merged rigor map and validate it (§ Rigor resolution) — on `--dry-run`, print the preview and stop here; otherwise run the version handshake (above), then create/verify the effort dir and write initial `00-Manifest/pipeline.md` *(Phase 4)*.
2. **Planning window (inline):** *(Phase 4)*.
3. **Dispatch loop:** *(Phase 4)*.
4. **Review→fix loop, budget guard, gates, notifications, worktree:** *(Phase 5 — see `references/loop-and-budget.md` when it lands)*.
5. **Resume & final run report:** *(Phase 6 — see `references/resume-and-report.md` when it lands)*.

## Guardrails

- **Never required by core.** The six deep-* skills must work identically with deep-goal uninstalled. Never edit anything under the deep-skills plugin.
- **Artifacts are the only inter-stage channel.** Never pass transcripts between stages; the advance test reads artifacts and manifest statuses, never a subagent's narrative.
- **Read-only on stage lines.** Each core skill owns its own manifest stage line; the conductor's only manifest write is the effort summary paragraph *(Phase 6)*.
- **Interactivity boundary:** all human interaction happens in the inline planning window; autonomy begins the moment plan.md is written. No unsolicited mid-pipeline questions — only user-requested gates and budget pauses wait; otherwise notify only on halts, gates, budget pauses, and completion (the series' notify-sparingly rule).
- **Structured questions are self-contained:** every option carries its own ≤15-line description/preview; never rely on between-tool-call prose.
- **One stage in flight at a time**, enforced by the pipeline.md dispatch record *(Phase 4)*.
- **Refuse at launch, never mid-run:** an unknown rigor, stage name, or a failed version handshake stops before any dispatch.
