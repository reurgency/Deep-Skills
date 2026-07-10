# Conductor — dispatch protocol, advance test, blocker policy

How the conductor actually walks the pipeline: the launch sequence, the inline planning window, the per-stage dispatch loop, the artifact-verification **advance test**, and the severity-aware **blocker policy**. SKILL.md § Workflow is the summary; this file is the protocol.

Two invariants frame everything here (contract rows #3 and #4 of the plan's State/Data-Flow Contract):

- **`00-Manifest/pipeline.md` is the conductor's state file** — conductor-written only, updated at every stage boundary, and the single thing a re-invocation needs to resume. Its shape is `templates/pipeline.md`.
- **The conductor is READ-ONLY on manifest stage lines.** Each core skill flips its own line in `00-Manifest/manifest.md`; the conductor reads those flips as evidence and never writes one. (Its only manifest write, ever, is the effort summary paragraph at run end — Phase 6.)

## 1. Launch sequence

Run these in order, once, before anything is dispatched. Everything resolved here is persisted into `pipeline.md` and **never re-derived mid-run**.

1. **Rigor resolution** — merge shipped `templates/rigor-map.json` with any `.deep-skills/rigor-map.json` override, validate, resolve the level (or ask), per SKILL.md § Rigor resolution and `references/rigor-levels.md`. On `--dry-run`: print the preview and **stop here** — no handshake, no writes.
2. **Version handshake** — locate the installed deep-skills plugin (§ 1a below), read its `plugin.json` `version`, require ≥ 0.2.0 as semver; refuse / warn / proceed per SKILL.md § Launch. Record the resolved plugin.json path and version outcome in the `pipeline.md` header.
3. **Effort slug** — the conductor derives the kebab-case slug from the goal:
   - **yolo / poc** (autonomous planning): the derived slug is final — it is passed to the planner as `deep-plan --autonomous --effort=<slug>`, which uses it verbatim (deep-plan's autonomous-mode contract). State it; never ask.
   - **mvp / prod** (interactive planning): the derived slug is a *proposal* — deep-plan's own inline Setup step proposes it and the **user confirms** (or renames) as usual. Nothing is created until the name is confirmed.
4. **Effort dir + manifest** — once the slug is final/confirmed, create `.deep-skills/<effort>/` and `00-Manifest/manifest.md` **if absent**, in the exact format of `references/artifact-structure.md` § Manifest format, all stage statuses `pending`. (Creating the manifest is allowed — the read-only rule covers *flipping* stage lines, which only core skills do.)
5. **Initial `pipeline.md`** — write `00-Manifest/pipeline.md` from `templates/pipeline.md`: full header (goal, rigor + source, resolved deep-skills location + version outcome, gates/budget/worktree), the resolved stage list with per-stage dispatch modes and invocations, one dispatch record per planned dispatch (all `pending`), empty Blockers, zero spend. **Pipeline state exists from launch** — a crash at any later point, including mid-planning, is resumable from this file (Phase 6 owns the resume walk; this file is what it reads).

At mvp/prod, steps 4–5 execute the moment the effort name is confirmed at the top of the inline planning window — *before* any question round — so the long interactive session is crash-covered too.

### 1a. Locating the installed deep-skills plugin (per host)

Consolidated here from SKILL.md § Launch (which keeps the summary). Resolve **once** at launch; persist the resolved `plugin.json` path in `pipeline.md`.

- **Claude Code** (and **Copilot CLI**, which consumes the same marketplace format): installed plugins live under `~/.claude/plugins/`. Read `~/.claude/plugins/installed_plugins.json` — its `plugins` map is keyed `<plugin>@<marketplace>`; find the key beginning `deep-skills@`, take its entry's `installPath`, and read `<installPath>/.claude-plugin/plugin.json`. If that index file is absent or unreadable, fall back to globbing `~/.claude/plugins/cache/*/deep-skills/*/.claude-plugin/plugin.json` and take the most recently modified match.
- **Codex**: look for a `deep-skills` plugin root installed as a **sibling of deep-goal's own install** (both come from the same store; the vendored unit is the plugin root) and read its `.codex-plugin/plugin.json` (or its `.claude-plugin/plugin.json` — Codex also accepts the Claude manifest as a compat source; see `HOSTS.md`, RE-VERIFY per current Codex docs).
- **Cursor**: same sibling-install check under Cursor's plugin store; for local dev installs check `~/.cursor/plugins/local/deep-skills/.cursor-plugin/plugin.json` (see `HOSTS.md`).
- **Copilot / VS Code editor** (file-based, no marketplace): the skills location the user configured (`chat.agentSkillsLocations` or `.github/skills/`) points into a checkout that carries the sibling `plugins/deep-skills/` root — read its `.claude-plugin/plugin.json` from there.
- **Any host, last resort**: this skill's own file path is known at runtime — check whether a `deep-skills/` plugin root sits **beside deep-goal's plugin root** (siblings under the same install parent). If deep-skills still cannot be located, ask the user where it is installed before refusing.

The resolved location also supplies `{skill_path}` for every stage briefing: a dispatched skill's SKILL.md sits at `<deep-skills plugin root>/skills/<skill-name>/SKILL.md`.

## 2. The planning window

Planning is the **interactivity boundary**: all human interaction happens here; **autonomy starts when `01-Plan/plan.md` exists.**

Branch on the plan stage's `mode` in the resolved map:

- **`autonomous`** (shipped: yolo, poc) — a dispatched stage like any other: render the stage briefing for `deep-plan --autonomous --effort=<slug>`, appending `--columbo` when the stage entry has `"columbo": true`, and launch one fresh subagent. The user sees nothing until it's done. (`--columbo` folds into the *same* dispatch — core defines it as a flag of the planning run itself, self-run at the end; it is never a second dispatch.)
- **`interactive`** (shipped: mvp, prod) — the conductor runs `/deep-plan` **inline in the main session** (the user is present by definition — a background agent can't ask questions), passing `--rounds=<n>` from the stage entry's `rounds` and honoring `columbo` per the map; deep-plan's own workflow drives name confirmation, the front-loaded question rounds, optional gap rounds, and the pre-write nudge.

**Every stage — inline or dispatched — gets a `pipeline.md` dispatch record.** Mark the planning record `in-flight` when the window opens (dispatch launched, or inline session started). The planning record's completion test is deliberately simple: **it completes when `01-Plan/plan.md` exists.** That moment is the autonomy boundary — from here on the conductor asks no unsolicited questions; it only notifies (halts, gates, budget pauses, completion) and, at user-injected `--gate`s or budget ceilings, waits.

## 3. The dispatch loop

For each remaining stage in the resolved list, in order:

1. **Guard:** exactly **one stage in flight at a time.** Before launching, confirm no other record is `in-flight`, then mark this record `in-flight` with its start time. (If deep-goal is re-invoked while a record is `in-flight`, announce the running stage instead of double-dispatching — see the plan's Interaction & re-entry rules; Phase 6 owns full resume.)
2. **Render the briefing:** fill `templates/stage-briefing.md` — substitute `{skill_name}` (from the merged map's `known_stages.<stage>.skill`), `{skill_path}` (from the launch-resolved deep-skills location), `{effort_name}`, `{stage_flags}` (per the invocation table below), and `{worktree_path}` (the conductor-created worktree on `--worktree` runs, else the none-form — both renderings: `references/loop-and-budget.md` § 5 and the template's comment block). The rendered text is the subagent's **entire prompt** — nothing else rides along, no transcripts, no plan excerpts; the briefed agent reads the skill's own SKILL.md and the effort's artifacts.
3. **Dispatch:** launch **one fresh subagent** at the session model (no model tiering here — fleet skills self-tier via their own `model-map.md`). Await completion. Never dispatch two stages concurrently, never reuse a stage's agent for the next stage.
4. **Advance test** (§ 4): verify artifacts and manifest evidence — never the subagent's closing narrative. Pass → complete the record (finished time, advance-test result, spend estimate from `references/rigor-levels.md` § Cost bands — refined by observed usage where the host surfaces it, always labeled an estimate) and continue. Fail → inspect for a blocker artifact and apply the blocker policy (§ 5).
5. **Boundary checks** before looping to the next stage: round accounting + convergence when inside the review→fix loop (§ 6), then the **budget check** (`--budget` runs), then the **gate check** (`--gate` before the next stage) — full order and pause procedures in `references/loop-and-budget.md` § 6. A pause always lands *between* stages, never mid-stage.

**Idempotency:** because the advance test is artifact-based, an accidental re-dispatch is harmless — if the expected artifact already exists and the manifest line is already flipped, mark the record complete and move on without dispatching. **Exception:** review rounds ≥ 2 in the review→fix loop (`04-Code-Review/` artifacts are not round-versioned, so bare existence is vacuously true from round 2) use the **round-aware test** — pre-dispatch findings.json snapshot vs fresh CR ids / status changes / updated `reviewed` date — specified with the loop controller in `references/loop-and-budget.md` § 1.2.

### Stage → invocation table

What `{stage_flags}` renders to, per stage entry in the resolved map. Skills are invoked **by name** (the house cross-skill precedent); explicit artifact paths are passed where a skill accepts one, so "latest" never has to be guessed.

| Stage entry | Dispatch(es) | Invocation (`{skill_name}` + `{stage_flags}`) |
|---|---|---|
| `plan`, `mode: autonomous` | 1 subagent | `deep-plan` — `<goal> --autonomous --effort=<slug>` + `--columbo` if `columbo: true` |
| `plan`, `mode: interactive` | inline | `deep-plan` — `<goal> --rounds=<rounds>` (+ columbo per map; user present) |
| `plan-review` | 1 subagent | `deep-plan-review` — `.deep-skills/<effort>/01-Plan/plan.md` + `--multi-agent` if `mode: multi-agent` |
| `implement` | 1 subagent | `deep-implement` — `.deep-skills/<effort>/01-Plan/plan.md --autonomous` |
| `code-review` (the review) | 1 subagent | `deep-code-review` — current branch + `--multi-agent` if `mode: multi-agent` (single-agent is core's default; no flag) |
| `code-review` → `triage` option | 1 **more** subagent | `deep-code-review` — `--triage --auto-accept-min=<triage.auto_accept_min>` |
| `bugfix` | 1 subagent | `deep-bugfix` — `.deep-skills/<effort>/04-Code-Review/findings.json --autonomous` |
| `docs` | 1 subagent | `deep-docs` — effort mode (the effort is named in the briefing; deep-docs' intake resolves it) |

**Why triage is a second dispatch of the same skill (and columbo isn't):** the rigor map encodes both as *per-stage options, not standalone stages* — that is a statement about the **data shape and the artifact contract** (triage writes the same `04-Code-Review/` artifacts and has **no manifest line of its own**), and it matches *how core exposes them*. And core exposes them differently: `--columbo` is a flag **of the planning run** (self-run at its end — one invocation), while `--triage` is a **separate opt-in invocation** of deep-code-review that runs *only* the triage step and "never re-runs the review" (deep-code-review SKILL.md § 7 / § Flags) — core defines no combined review+triage invocation, and deep-goal never requires core changes. Separate dispatches also buy exactly what the plan values in rejecting the `--fix` triage+bugfix fusion: a per-dispatch spend record, a fresh agent per step, and the clean triage boundary the loop's per-round accounting hangs on (`references/loop-and-budget.md` § 1.3). So one `code-review` stage entry with a `triage` option expands to **two consecutive dispatch records** in `pipeline.md` (`code-review`, then `code-review (triage)`); a `code-review` entry *without* the option (custom overrides) expands to one, and triage falls to the user.

## 4. The advance test

After every dispatch (and the inline planning window), the conductor verifies, itself, with its own reads:

> **The expected artifact exists at its canonical path AND the skill flipped its own manifest stage line.**

Never advance on the subagent's word — a closing message is not evidence. Canonical paths and manifest line names are the series contract (`references/artifact-structure.md`); the exact per-stage checks:

| Stage record | Expected artifact (canonical path, under `.deep-skills/<effort>/`) | Manifest evidence (`00-Manifest/manifest.md`) |
|---|---|---|
| `plan` | `01-Plan/plan.md` exists | none required — **plan.md's existence is the test** (the autonomy boundary; deep-plan flips `01 Plan` as usual, but the record completes on the artifact) |
| `plan-review` | `02-Plan-Review/review.md` exists | `02 Plan Review` flipped to `complete` |
| `implement` | `03-Implementation/summary.md` exists | `03 Implementation` flipped to `complete` |
| `code-review` (review) | `04-Code-Review/report.md` + `findings.json` + `certificate.md` all exist; findings statuses all `open` | `04 Code Review` flipped by the skill |
| `code-review (triage)` | **no manifest line of its own** — test reads the artifacts triage rewrites: `04-Code-Review/findings.json` has **zero `open` statuses** (each finding now `accepted` / `deferred` / `rejected by user` — the exact literals) AND `certificate.md`'s **Triage outcomes** table is filled (no longer "Triage pending") | n/a (triage also updates the Code Review status per its own workflow, but the findings.json + certificate check is the test) |
| `bugfix` | `06-Bug-Fix/round-N/fix-summary.md` exists in the highest `round-N/` | `06 Bug Fix` flipped by the skill |
| `docs` | in-repo `docs/ai-map/` published (`MAP.md` + `index.json`) and the `07-Docs/` pointer present | `07 Docs` flipped to `complete` |

- **Review rounds ≥ 2** replace the code-review/triage rows with the **round-aware test** (fresh CR ids or status changes AND an updated `reviewed` date vs the pre-dispatch snapshot) — `references/loop-and-budget.md` § 1.2 specifies it; never use bare artifact existence there.
- On **pass**: append/complete the dispatch record and move to the next stage.
- On **fail**: do not advance and do not blindly re-dispatch — look for the stage's blocker artifact (§ 5 table) and classify. A failed advance test with *no* blocker artifact means the stage died mid-flight (crash, context loss): leave the record `in-flight`-annotated per `templates/pipeline.md` and re-dispatch once; the core skills' own internal resume (phase summaries, round scope, `--refresh`) makes that safe. Fails again → treat as a HALT-class blocker with a note that no blocker report exists.

## 5. Blocker policy (severity-aware)

A blocker is a stage saying "a human is needed." The conductor classifies by **where in the spine it happened**, not by who reported it: upstream ("spine") blockers poison every later stage — halting is cheaper than reviewing rubble; tail blockers are self-contained — the run finishes and reports them loudly.

| Blocker | Where it shows up | Class | Conductor action |
|---|---|---|---|
| Plan-review **Blocker verdict** (verdict line reports `Blockers: N`, N > 0) | `02-Plan-Review/review.md` verdict line + Blockers section | **spine** | **HALT + notify** — downstream would implement a plan with known fatal flaws |
| Implement **phase blocked at the fix cap** (2 attempts) | ⛔ Blocker report appended to `01-Plan/plan.md` § Phase Summaries (deep-implement's `templates/blocker-report.md`; broken code never committed) | **spine** | **HALT + notify** — later stages would review rubble |
| Bugfix **unproven cluster at the fix cap** (reverted) | `06-Bug-Fix/round-N/blocker-<CL-K>.md` (one per blocked cluster) | **tail** | **CONTINUE + record** — clusters are independent; other clusters' fixes stand |
| Docs **anchor drift blocks publish** (`drifted` / `over-budget` anchors) | the drift record: `docs/ai-map/coverage.md` + the drifted-anchor list in `docs/ai-map/learn-signal.json` | **tail** | **CONTINUE + record** — a docs-only failure never invalidates the built code |

**Either way, `pipeline.md` carries the blocker-report path** (Blockers table row: stage · policy · report path · one-line note), and the final run report (Phase 6) lists every blocker with its path.

**HALT procedure:** mark the stage's dispatch record `halted` (with the advance-test result), append the Blockers row with policy `HALT`, **notify**, and stop — dispatch nothing further. Do not archive or unwind anything: the halted `pipeline.md` *is* the resume point (Phase 6 re-enters at the halted stage once the human unblocks it).

**CONTINUE procedure:** record the blocker (Blockers row, policy `CONTINUE`) and proceed to the next stage. The stage's own record reflects its actual outcome: `complete` when its advance test still passed (bugfix with one blocked cluster among fixed ones — `fix-summary.md` exists and the manifest flipped), `halted` when it didn't (docs publish blocked by drift) — `halted` on a record means *the stage* stopped, the Blockers row's policy column says whether *the run* did. No mid-run notification for CONTINUE blockers — they ride the completion notification and the run report (the notify-sparingly rule: halts, gates, budget pauses, completion only).

**Notification mechanics:** one line, < 200 chars, lead with the actionable fact and the blocker-report path, via the host fallback chain (native, e.g. Claude Code PushNotification → shell `osascript` → bold `ATTENTION:` line as the last line of the turn — the series' host-affordances convention). Example:

> `deep-goal halted: implement blocked at Phase 2 (fix cap) — see .deep-skills/<effort>/01-Plan/plan.md § Phase Summaries. Re-invoke deep-goal to resume once unblocked.`

The full trigger set — **halts (blocker or convergence), gates, budget pauses, completion — and nothing else** — with per-trigger example lines lives in `references/loop-and-budget.md` § 4; halts use the mechanics above.

## 6. The review→fix loop (summary)

Spec: `references/loop-and-budget.md` § 1. **Round 1** is the map's own `code-review` (+ its triage option, a second dispatch) and `bugfix` stages, tested per § 4. **Re-review rounds (≥ 2)** append records `code-review (round N)` — plus `code-review (triage, round N)` and `bugfix (round N)` when the loop continues — reuse the level's `code-review` stage entry verbatim (same mode, same threshold), and use the **round-aware advance test** (pre-dispatch snapshot of findings.json's CR ids / count / `reviewed` date, taken when the record goes `in-flight`). After each round the conductor appends the round's **non-`fixed` findings count** to pipeline.md's Review loop table.

Exit semantics key off the level's **`re_review_cap`, read from the resolved map — never a hard-coded literal**:

- **cap 0** — loop ends after round 1's bugfix; residual `deferred` findings go to the run report.
- **cap 1** — exactly one re-review; **HALT** only on unresolved Blockers (certificate FAIL), else **exit to docs** with round-2 residuals (fresh `open` + all `deferred`) reported.
- **cap ≥ 2** — from round 2: exit on certificate **PASS** AND **strictly fewer** non-`fixed` findings than the prior round; fail with re-reviews remaining → triage → bugfix → next round; cap reached without convergence → **HALT + notify as a convergence failure**.

## 7. Hosts

Everything above assumes **Claude Code subagent affordances** (fresh background subagents with a supplied prompt) — the v1 designed-and-verified floor. On hosts without them (Codex / Cursor / Copilot), dispatch degrades to **inline sequential execution** per `HOSTS.md` — same stage order, same briefing content, same advance tests and pipeline.md records; honestly caveated (prod-rigor runs may hit context limits). Only this section's *mechanism* changes per host; the protocol does not.
