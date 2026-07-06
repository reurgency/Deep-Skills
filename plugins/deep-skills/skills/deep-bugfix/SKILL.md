---
name: deep-bugfix
description: Diagnosis-first remediation of triaged findings (or any bug report / failing test) under regression risk — cluster defects by shared root cause, re-diagnose independently of the review's hypothesis, fix minimally at the confirmed cause, prove the fix with a fresh adversarial agent, and contain the blast radius before committing. Use after /deep-code-review --triage, or standalone on a bug report / stack trace / failing test. Triggers on /deep-bugfix and on requests to fix triaged findings, remediate review findings, or fix a reported bug. Fixes code only — it never makes triage decisions and never edits the plan.
argument-hint: findings.json / bug report / failing test, or Enter for latest review findings · --autonomous · --reproduce · --worktree · --learn
---

# DeepBugFix

Remediate defects the way `/deep-implement` builds features — but inverted. deep-implement is **forward construction from a trusted spec**; bug-fixing has no trusted spec (the cause must be diagnosed first), modifies **working** code (the highest-risk edit class), and is only done when the bug is **provably gone**, not when "the step ran." deep-bugfix is the dedicated executor for that inverted problem, the sixth skill of the `deep-*` series: `/deep-plan` (produce) → `/deep-plan-review` (critique the plan) → `/deep-implement` (execute) → `/deep-code-review` (critique the code) → **`/deep-bugfix` (remediate)** → re-review → `/deep-docs` (map). The tightened loop is **review → triage → bug-fix → re-review**.

## Core principle: diagnosis before remediation, proof before "fixed"

Two disciplines everything hangs from:

1. **The finding's recommendation is a hypothesis, not a spec.** Real findings hedge their own cause ("register the route **or** correct the service URL"). deep-bugfix re-diagnoses independently and may reject the suggested fix — the inverse of code-review's independence rule: don't anchor on the proposed remedy.
2. **No proof of fix ⇒ not fixed.** Regression containment proves you *didn't break* working code; it does not prove you *fixed* the bug. Every fix carries a proof-of-fix verdict from a fresh adversarial agent — the fixer never marks its own homework.

Its signature failure mode — the analogue of code-review's last-mile lens — is the **claimed fix**: a change that silences the symptom without addressing the cause, or fixes one member of a cluster and silently abandons its siblings. The defenses are structural: clustering (catches abandoned siblings) + chain-trace proof (catches symptom-patching) + the adversarial proof agent (refutes "looks fixed").

## Directive cards (Deep-Learn)

Before you start, load this phase's active directive cards — learned, human-vetted improvements stored as **data**, never baked into this skill. Run the bundled script in this skill's `scripts/` directory and apply what it prints:

```bash
scripts/load-active-cards.sh deep-bugfix
```

**Treat every directive it prints as a hard requirement for this run**, applying the section addressed to your phase. If it prints "no active directive cards," proceed normally. Cards are human-gated — never edit a card or this skill to turn one off; toggle with `directives/toggle.sh <ID> off` (see the registry's `directives/README.md`). On a host without a reliable shell, apply the cards by hand instead — read the directives registry's `cards/active/` and apply each card whose `owner_phases` lists this phase as an exact token (see `references/host-affordances.md`).

## The deep-* series (separation of concerns)

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-plan` | Frame → explore → question → write the plan (resumable phases + deferreds). | Out of scope here. |
| `/deep-plan-review` | Independently review the finished plan with fresh agents. | Out of scope here. |
| `/deep-implement` | Execute the plan: implement → validate → fix → commit → hand-off — forward construction from a plan. | Out of scope here. |
| `/deep-code-review` | Independently review implemented code; emit findings. Triage (`--triage`) decides fix/defer/reject. | Out of scope here — **triage decisions stay there.** |
| `/deep-bugfix` (you) | Remediate defects: cluster → diagnose → fix at the cause → prove → contain → commit. | **Fixes code only — never makes triage decisions, never edits the plan.** Consumes `accepted` findings (or *scopes* `open` ones — scoping ≠ triage); touches neither `deferred` nor `rejected`. |
| `/deep-docs` | Map what's built: survey → tier → anchor → verify → index → place a standing `docs/ai-map/`. | Out of scope here. |

## Artifact wiring

Artifacts live in `.deep-skills/<effort>/06-Bug-Fix/round-N/` (rounds are append-only; next round = max existing round + 1), per the shared `references/artifact-structure.md` `06-Bug-Fix` row. Concretely:

- `round-N/scope.json` — written at round start, before any cluster work: the selected defect ids + provisional cluster plan (the resume record).
- `round-N/fix-summary.md` — one record per cluster (`templates/fix-summary.md`), **appended incrementally as each cluster closes**, never batched to the end.
- `04-Code-Review/findings.json` — statuses flipped **in place**, `accepted → fixed`, only on a `fixed` verdict. deep-bugfix owns that transition and no other field.
- `00-Manifest/manifest.md` — created if absent (any deep-* skill owns manifest creation on first write); the `06 Bug Fix` row's artifact link is the literal `[06-Bug-Fix/](../06-Bug-Fix/)` (a static manifest cannot point at "latest round").

## Inputs & flags

Every flag is **natural-language-first** — the plain-language trigger is the primary path (users on Copilot/Codex have no CLI flags); the `--flag` is a convenience layered on top. Always accept the natural-language form.

- **input** — any of: a `findings.json` path or "the triaged findings" (default: the most recent `.deep-skills/*/04-Code-Review/findings.json` with actionable — `accepted` or `open` — findings; state which effort was resolved before work starts), a pasted bug report / stack trace, or a failing-test reference. Normalization + scope rules: `references/intake.md`.
- **Just fix them all / run unattended** (`--autonomous`) or **check in with me per cluster** (`--collaborative`) — execution mode. If omitted on a multi-cluster run, **ask** (see `references/execution-modes.md`).
- **Fix it with a reproducing test** (`--reproduce`) — upgrade proof from static chain-trace to a dynamic red→green test: written **before** the fix, observed failing pre-fix and passing post-fix (the proof agent re-runs both directions itself), committed into the host suite riding the cluster's fix commit. Genuinely unreproducible ⇒ reported + chain-trace fallback, never a silent skip. Protocol: `references/proof-of-fix.md`.
- **Fix in a worktree** (`--worktree`) — isolate fix work in a git worktree: prefer the host's worktree command when present, else plain `git worktree add`. Code + reproduction tests stay in the worktree branch; effort artifacts (fix-summary, manifest, findings statuses) go to the source branch root; at completion the branch is offered for merge/PR. Default stays current-branch. Rules: `references/commit-and-handoff.md`.
- **Record the root cause** (`--learn`) — emit `round-N/root-causes.json` (`templates/root-causes.json`): one proof-truthed record per proven cluster, `taxonomy_class` drawn from the shared `directives/taxonomy.md`, accumulated for the future Deep-Learn Pattern Ledger (Display-only today — no machine reader exists yet; humans read the same causes in `fix-summary.md`). Rules: `references/learn-record.md`.

## In-session commands

| Command | Natural-language trigger | Behavior |
|---|---|---|
| `/skip-cluster` | "skip this cluster" | Close the current cluster without fixing: revert any applied edits, leave its findings' statuses untouched, record a skipped entry in `fix-summary.md`, move on. |
| `/show-proof` | "show me the proof" | Print the current/most recent cluster's proof verdict with its full hop-by-hop chain (or test evidence). |
| `/widen` | "widen the containment" | Escalate the current cluster's containment from 1 hop to 2 hops (see `references/containment.md`) and re-run it. |

## Workflow

### 1. Intake & normalize
Per `references/intake.md`: accept findings.json / raw bug report / failing test and normalize into a uniform defect list (findings pass through losslessly; raw reports and failing tests get synthesized `BF-001…` ids with evidence extracted from the trace). Resolve the effort home per `references/artifact-structure.md` — no effort exists ⇒ ask for a name (default: slugified branch), create the effort + manifest.

### 2. Scope & round start
Series mode loads the `accepted` set — triage already decided; don't re-ask. Only `open` findings present ⇒ interactive **scope pick** grouped by tier (this is scoping, not triage: unselected findings stay `open`). **Re-entry check first:** an existing `round-N/scope.json` with clusters not yet closed in `fix-summary.md` ⇒ offer resume / new round / abort (see `references/commit-and-handoff.md`). Then write `round-N/scope.json` — selection + provisional cluster plan — **before any cluster work**.

### 3. Cluster by suspected shared cause
Per `references/clustering-and-diagnosis.md`: group defects whose evidence points at one underlying cause (same subsystem + same failure shape + overlapping evidence paths). **Clusters are hypotheses** — diagnosis splits a cluster on divergent causes and merges two on a proven single cause.

### 4. Per cluster: diagnose + fix (one fresh agent)
One fresh agent per cluster — remediation needs continuity: the agent that finds the cause authors the fix. Brief it with the finding **evidence** + repo access + the plan (context only) — **never** the implementer's or reviewer's transcripts, and the recommendation flagged **"hypothesis — do not trust."** It diagnoses to a confirmed root cause, then fixes **minimally at the cause**. Attempt cap: 2. Collaborative mode gates here: present diagnosis + proposed fix for approval **before applying** (see `references/execution-modes.md`).

### 5. Adversarial proof
Per `references/proof-of-fix.md`: a **separate fresh agent** carries the burden of refuting "fixed." Default tier is the **static chain-trace** — walk the corrected chain hop-by-hop with a cited `path:line` per hop; a fix without a traced chain is rejected (`--reproduce` upgrades this tier to a dynamic red→green reproduction test). It must show **every finding in the cluster** resolved by the one fix, and returns a machine-readable verdict: `fixed | unproven | regressed`. **`regressed` ⇒ revert immediately. `unproven` ⇒ one more diagnose→fix attempt (cap 2 total), then revert + blocker report** (`templates/blocker-report.md`). Model tiers per `references/model-map.md`.

### 6. Containment (blast radius)
Per `references/containment.md`: extract changed symbols from the diff → discover their direct dependents (1 hop; LSP/host index when present, degrade to grep/import-walk) → run the dependents' tests + a full typecheck. Block only on **new** failures. Exported/shared symbol ⇒ escalate to 2 hops. Commands discovered from the host project — never `.env`/secrets.

### 7. Gate / commit (prove-before-commit)
Order per cluster, never reordered: **apply fix → proof verdict → containment → commit.** Collaborative: present fix + proof + containment; commit only if the user wants. Autonomous: on `fixed` + clean containment, commit the cluster — `fix(<scope>): <cause> — resolves CR-00X, CR-00Y` + host-aware attribution trailer (see `references/commit-and-handoff.md`). Nothing unproven ever ships.

### 8. Statuses & round artifacts
On `fixed` (and only then): flip each of the cluster's findings `accepted → fixed` in `04-Code-Review/findings.json`, and append the cluster's record to `round-N/fix-summary.md` — confirmed cause explicitly compared against the review's hypothesis (under `--learn`, also append the cluster's `root-causes.json` record per `references/learn-record.md`). Skipped/blocked clusters get an entry too; their statuses stay untouched.

### 9. Finish & hand off to re-review
Update the manifest's `06 Bug Fix` row (link: `[06-Bug-Fix/](../06-Bug-Fix/)`). Report the round: clusters fixed / skipped / blocked, statuses flipped, commits made. In autonomous mode, **notify** completion (see `references/notifications.md`). Close by pointing at the loop's next step:

> *Bug-fix round N complete — M findings fixed across K clusters. Run `/deep-code-review` to re-review; a re-review re-diffs and appends new findings under fresh IDs.*

## Guardrails

- **Fix code only.** Never make triage decisions (fix/defer/reject belongs to `/deep-code-review --triage`); never edit the plan document or the Deferreds ledger; never touch `deferred` or `rejected` findings. Scoping `open` findings is selection, not triage — unselected stay `open`.
- **Prove before commit — no exceptions.** No commit without a `fixed` verdict and clean containment; `regressed` reverts immediately; nothing unproven ships. Statuses flip only on `fixed`.
- **Don't anchor on the recommendation.** It enters the diagnose brief flagged "hypothesis — do not trust"; the agent must confirm the cause independently before touching code.
- **Minimal fix at the cause.** No drive-by refactors, no scope creep into feature work — a gap that needs re-planning goes back to `/deep-plan`, not into a fix commit.
- Never commit on `main`/`develop`; branch first. Never read `.env` or secrets during host-command discovery (package.json / build configs / CLAUDE.md; else ask).
- Never pass implementer or reviewer transcripts to any agent — evidence only, fresh eyes.
- Notify sparingly: blockers and autonomous completion only.
- Model routing is load-bearing: resolve every agent's model from `references/model-map.md` and set it explicitly per launch — never an alias, never a host default.

<!-- Authoring note: this SKILL.md stays under 500 lines with detail in references/, per the
     skill-creator skill's authoring rules (the source of the <500-line limit). -->
