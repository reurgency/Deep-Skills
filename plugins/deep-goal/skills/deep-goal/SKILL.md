---
name: deep-goal
description: Run a full Deep-* effort end-to-end from one invocation — plan → review → implement → code-review → bugfix → docs — as an autonomous, rigor-gated conductor. Use when the user wants to "run deep-goal", build a feature hands-free at a chosen rigor (yolo/poc/mvp/prod), or automate the deep-* relay in one command. Triggers on /deep-goal and on requests like "run deep-goal at mvp rigor" or "take this feature through the whole pipeline". Paid add-on — requires the deep-skills plugin ≥ 0.2.0.
argument-hint: describe the goal/feature · --rigor=<yolo|poc|mvp|prod> · --dry-run · --budget=<band> · --gate=<stage> · --worktree
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

**1. Locate the installed deep-skills `plugin.json`** — on Claude Code (and Copilot CLI): read `~/.claude/plugins/installed_plugins.json`, take the `installPath` of the key beginning `deep-skills@`, and read `<installPath>/.claude-plugin/plugin.json` (cache-glob fallback if the index is unreadable). Other hosts use a sibling-install check, with an ask-the-user last resort. **The full per-host discovery protocol lives in `references/conductor.md` § 1a** — this is the summary. The resolved plugin.json location is persisted into `00-Manifest/pipeline.md` at launch — resolved **once**, never re-derived mid-run — and supplies the `{skill_path}` every stage briefing carries.

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
- **Budget** (`--budget=<band>`, NL: "cap spend at ~500k tokens") — an approximate token ceiling for the whole run, checked at **stage boundaries only** (a dispatched stage always finishes). Ceiling crossed → pause *between* stages + notify; a re-invocation resumes where it paused. Estimate-based (uncalibrated cost bands), so a soft ceiling. Spec: `references/loop-and-budget.md` § 2.
- **Gates** (`--gate=<stage>`, repeatable; NL: "pause before implement") — inject a human checkpoint before a named stage, even in an otherwise autonomous run. Validated at launch against the resolved stage list; persisted in `pipeline.md` so a resumed run honors it. At the gate: notify, then one self-contained proceed/stop question (what ran, what's next; option previews ≤15 lines). Fires once, before the stage's first dispatch. Spec: `references/loop-and-budget.md` § 3.
- **Worktree** (`--worktree`, NL: "build in a worktree") — the conductor creates **one** git worktree immediately after planning completes and every later stage works inside it: implement, both code-review dispatches, bugfix, every re-review round, docs — same tree, same branch, so reviews see implement's commits naturally. Core skills receive a working directory, never a flag; the path is recorded in `pipeline.md` and the run report ends with it + merge instructions. Spec: `references/loop-and-budget.md` § 5.

## Rigor resolution (config-as-data)

**Never hard-code a stage list — this skill's prose describes levels; the data defines them.** The stage list, per-stage options, planning rounds, triage threshold, and re-review cap for every level live in one place: **`templates/rigor-map.json`** (in this skill's directory — the single canonical source). Resolve rigor at launch, once, in this order:

1. **Read the map.** Load the shipped `templates/rigor-map.json`. If **`.deep-skills/rigor-map.json`** exists at the repo root, it wins: merge it over the shipped map at **level granularity** — a level it names replaces the shipped level whole, a new name adds a level, its `known_stages` entries extend the stage roster, and unnamed shipped levels remain. Keys starting with `_` are documentation; ignore them. Full merge semantics and authoring guide: `references/rigor-levels.md`.
2. **Validate — at launch, never mid-run.** Check the merged map per the rules in `references/rigor-levels.md` § Validation: every stage name must exist in the merged roster and be `available` (reserved roster slots refuse as "not yet shipped"), stage lists must be non-empty and start with `plan`, per-stage options must sit on their owning stage with in-range values (`auto_accept_min` 1–10 numeric, `rounds` ≥ 0, `re_review_cap` ≥ 0 and present exactly when the level runs a code review). On any violation, **refuse before dispatching anything**, naming the file, the offending key/value, and the valid alternatives (e.g. `.deep-skills/rigor-map.json → levels.poc-reviewed.stages[3].stage: "sec-review" is not a known stage; known stages: plan, plan-review, implement, code-review, bugfix, docs`).
3. **Resolve the level.** Accept `--rigor=<level>` or its natural-language equivalents ("at mvp rigor", "yolo it", "prod-level run"); match against the merged map's level names. An unknown level refuses at launch with the valid menu (shipped + override levels). If the phrasing is fuzzy rather than naming a level ("quick and dirty"?), confirm the mapping instead of guessing.
4. **Ask when omitted.** No rigor stated → ask exactly **one structured question**, recommending **mvp**. The question is **self-contained**: each level is an option whose description/preview (≤15 lines — hosts truncate beyond that) is built *from the resolved map*, carrying that level's stage list with per-stage modes, its planning interactivity, and a rough cost band (from `references/rigor-levels.md` § Cost bands, labeled as estimates) — never rely on between-tool-call prose to explain the levels. Include any override-defined levels as options. On hosts without a structured-question tool, fall back to a numbered list in chat ("reply 1–4"), same content per option.

The resolved level (and the merged map it came from) feeds everything downstream — the dry-run preview, the rigor-selection previews, and the conductor's stage walk all read the same resolution, performed once at launch and persisted in `pipeline.md` (`templates/pipeline.md` header).

### `--dry-run` — preview, then stop

On `--dry-run` (NL: "preview the run", "what would a prod run do here"), perform rigor resolution exactly as above (including override merge, validation, and ask-when-omitted), then **print and stop**:

- the resolved level and where it came from (shipped map, or repo override);
- the stage list **in order**, one line per stage, with each stage's mode and the flags the conductor would dispatch it with (planning mode + rounds + columbo; review modes; `--triage --auto-accept-min=<N>`);
- the triage threshold (numeric, with its tier meaning as presentation), the re-review cap, and any `--gate` injections;
- a rough cost band per stage and a summed total band, labeled as uncalibrated estimates (`references/rigor-levels.md` § Cost bands).

Dry-run **dispatches nothing and writes nothing** — no effort directory, no `pipeline.md`, no manifest — and is **exempt from the version handshake**. It must answer identically whether invoked as `--dry-run --rigor=prod` or as "preview a prod run".

## Workflow

The full protocol — launch sequence, planning window, dispatch loop, per-stage advance tests, blocker policy — lives in **`references/conductor.md`**; this is the walk at summary level.

1. **Launch:** resolve rigor from the merged rigor map and validate it (§ Rigor resolution) — on `--dry-run`, print the preview and stop here. Otherwise run the version handshake (above), settle the **effort slug** (yolo/poc: you derive it and pass it to the planner via `--effort=<slug>`; mvp/prod: deep-plan proposes and the user confirms it at the top of the inline planning window), then create the effort dir + `00-Manifest/manifest.md` if absent and write the initial `00-Manifest/pipeline.md` from `templates/pipeline.md` — header, resolved stage list, the artifact baseline (what already exists at each canonical path; advance tests judge this run's work against it), all dispatch records `pending`. **Pipeline state exists from launch**, so even a crash during planning is resumable. (`references/conductor.md` § 1.)
2. **Planning window (inline):** the interactivity boundary. Plan `mode: autonomous` (yolo/poc) → dispatch one fresh subagent running `deep-plan --autonomous --effort=<slug>` (+ `--columbo` per the map — it folds into the same dispatch). `mode: interactive` (mvp/prod) → run deep-plan **inline** with `--rounds=<n>` from the map, gap rounds and columbo per deep-plan's own workflow. **Every stage — inline or dispatched — gets a pipeline.md dispatch record**; the planning record completes when `01-Plan/plan.md` exists — **autonomy starts the moment plan.md exists.** (`references/conductor.md` § 2.)
3. **Dispatch loop:** for each remaining stage: mark its record `in-flight` → render `templates/stage-briefing.md` (skill **name** + flags from the map, effort, worktree slot) as the subagent's **entire prompt** → launch one fresh subagent and await → run the **advance test**: the expected artifact exists at its canonical path **new against the launch baseline** (surviving artifacts from a fresh restart or a pre-run manual skill never pass or fail this run's stages — `references/conductor.md` § 4) AND the skill flipped its own manifest stage line (you are read-only on stage lines; triage — a second dispatch of deep-code-review, per conductor.md — is tested on findings.json statuses + the certificate's Triage outcomes table instead; review rounds ≥ 2 use the round-aware test, `references/loop-and-budget.md` § 1.2) → complete the record and continue. On a blocker, classify per the **blocker policy**: **HALT + notify** on spine blockers (plan-review Blocker verdict; implement phase blocked at the fix cap), **CONTINUE + record** on tail blockers (unproven bugfix cluster; docs anchor drift) — either way pipeline.md carries the blocker-report path. (`references/conductor.md` §§ 3–5.)
4. **Review→fix loop + boundary machinery:** round 1 is the map's own code-review (+ auto-triage at the map's threshold — the second dispatch) and bugfix stages — with the **empty-set short-circuit** every round: triage is skipped when the review left nothing `open`, bugfix is skipped when nothing is `accepted`-and-unfixed, and a skipped bugfix exits the loop by cap (a clean(ish) review is a healthy run, never a spurious halt; `references/loop-and-budget.md` § 1.5); re-review rounds follow per the level's **`re_review_cap`** (read from the map, never hard-coded), each tested with the **round-aware advance test** — a pre-dispatch snapshot of findings.json's CR ids / count / `reviewed` date, so a crash mid-round never marks an un-run round complete. Exit by cap value: **0** → done after bugfix; **1** → exactly one re-review, halt only on unresolved Blockers, else exit to docs with residuals reported; **≥ 2** → converge on certificate PASS + strictly fewer non-`fixed` findings each round, cap breached → halt as a convergence failure. At every stage boundary: round accounting → budget check → gate check → next dispatch; notifications fire **only** on halts, gates, budget pauses, and completion (host-affordances fallback chain); on `--worktree` every post-planning briefing carries the one conductor-created worktree. Full spec: `references/loop-and-budget.md`; summary: `references/conductor.md` § 6.
5. **Resume & final run report:** re-invocation with an existing `pipeline.md` is the launch sequence's **first check** — announce prior state and ask **resume / fresh** as one self-contained question (previews ≤15 lines; fresh archives the old pipeline.md as `pipeline-archived-<n>.md`). Resume re-enters at the **first non-`complete` dispatch record**, honoring persisted gates/budget/worktree (re-read, never re-derived): `pending` → re-run its boundary checks and dispatch; `in-flight` with artifacts complete → mark complete and advance (the idempotency rule); `in-flight` with incomplete artifacts or `halted` → re-dispatch once on the core skill's own internal resume (review rounds ≥ 2 judged round-aware, never bare existence). At completion: write **`00-Manifest/run-report.md`** — stages + commits, the plan's Assumptions **verbatim**, every auto-deferred finding with severity (source of truth: findings.json `status: deferred`), residual open findings, every blocker with its report path, spend by stage + total (uncalibrated), worktree + merge instructions when set — update the manifest effort summary paragraph, notify, and deliver the full report as the closing message. (`references/resume-and-report.md`.)

## Guardrails

- **Never required by core.** The six deep-* skills must work identically with deep-goal uninstalled. Never edit anything under the deep-skills plugin.
- **Artifacts are the only inter-stage channel.** Never pass transcripts between stages; the advance test reads artifacts and manifest statuses, never a subagent's narrative.
- **Read-only on stage lines.** Each core skill owns its own manifest stage line; the conductor's only manifest write is the effort summary paragraph at run completion (`references/resume-and-report.md` § 2.1).
- **Interactivity boundary:** all human interaction happens in the inline planning window; autonomy begins the moment plan.md is written. No unsolicited mid-pipeline questions — only user-requested gates and budget pauses wait; otherwise notify only on halts, gates, budget pauses, and completion (the series' notify-sparingly rule).
- **Structured questions are self-contained:** every option carries its own ≤15-line description/preview; never rely on between-tool-call prose.
- **One stage in flight at a time**, enforced by the pipeline.md dispatch record — a stage is marked `in-flight` before its subagent launches; a re-invocation that finds an `in-flight` record announces the running stage instead of double-dispatching.
- **Refuse at launch, never mid-run:** an unknown rigor, stage name, or a failed version handshake stops before any dispatch.
