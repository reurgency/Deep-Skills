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
- **Rigor** (`--rigor=<yolo|poc|mvp|prod>`, NL: "at mvp rigor") — selects the stage list, planning interactivity, triage threshold, and loop cap. Omitted → ask one structured question (recommend mvp). *(Placeholder — Phase 2 fills rigor resolution, the repo override, and `templates/rigor-map.json`.)*
- **Preview** (`--dry-run`, NL: "preview the run") — print the resolved stage list and stop; dispatches nothing; exempt from the version handshake. *(Placeholder — Phase 2 fills.)*
- **Budget / gates / worktree** (`--budget`, `--gate=<stage>`, `--worktree`). *(Placeholder — Phase 5 fills.)*

## Workflow

*(Placeholder — Phase 4 fills the conductor workflow: launch → inline planning window → per-stage dispatch loop with the artifact-verification advance test → blocker policy → pipeline.md state. See `references/conductor.md` when it lands.)*

1. **Launch:** run the version handshake (above); resolve rigor *(Phase 2)*; create/verify the effort dir and write initial `00-Manifest/pipeline.md` *(Phase 4)*.
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
