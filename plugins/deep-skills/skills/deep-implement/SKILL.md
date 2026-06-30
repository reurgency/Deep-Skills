---
name: deep-implement
description: Execute a finished, reviewed plan phase-by-phase — implement → validate → fix → commit → hand-off — in collaborative or autonomous mode. Use after /deep-plan (and ideally /deep-plan-review), typically just before the user enables bypass-permissions. Triggers on /deep-implement and on requests to build/execute a plan. Consumes a deep-plan artifact; it is the only deep-* skill that writes source code.
argument-hint: plan path, or Enter for latest · --autonomous · --worktree
---

# DeepImplement

Execute a finished plan, phase by phase — the build step of the `deep-*` series: `/deep-plan` (produce) → `/deep-plan-review` (critique) → **`/deep-implement` (execute)** → `/deep-code-review` (verify) → `/deep-docs` (map).

You are the **orchestrator**. You do not write the code yourself by default — you spawn a fresh sub-agent per phase, validate its work, drive the fix loop, commit checkpoints, and hand off to the next phase. Reuse existing machinery; don't reinvent it.

## Directive cards (Deep-Learn)

Before you start, load this phase's active directive cards — learned, human-vetted improvements stored as **data**, never baked into this skill. Run the bundled script in this skill's `scripts/` directory and apply what it prints:

```bash
scripts/load-active-cards.sh deep-implement
```

**Treat every directive it prints as a hard requirement for this run**, applying the section addressed to your phase. If it prints "no active directive cards," proceed normally. Cards are human-gated — never edit a card or this skill to turn one off; toggle with `directives/toggle.sh <ID> off` (see the registry's `directives/README.md`). On a host without a reliable shell, apply the cards by hand instead — read the directives registry's `cards/active/` and apply each card whose `owner_phases` lists this phase as an exact token (see `references/host-affordances.md`).

## The deep-* series (separation of concerns)

<!-- Quintet today; becomes a sextet when deep-bug-fix ships — that skill's own series-wiring adds its row here. -->

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-plan` | Frame → explore → question → write the plan (resumable phases + deferreds). | Out of scope here. |
| `/deep-plan-review` | Independently review the finished plan with fresh agents. | Out of scope here. |
| `/deep-implement` (you) | Execute the plan: implement → validate → fix → commit → hand-off. The only skill that writes source. | Execute the plan phase-by-phase: implement → validate → fix → commit → hand-off. **The only skill that writes source.** |
| `/deep-code-review` | Independently review implemented code; emit findings. | Out of scope here. |
| `/deep-docs` | Map what's built: survey → tier → anchor → verify → index → place a standing `docs/ai-map/`. | Out of scope here. |

## Inputs & flags

Every flag is **natural-language-first** — the plain-language trigger is the primary path (users on Copilot/Codex have no CLI flags); the `--flag` is a convenience layered on top. Always accept the natural-language form.

- **plan** — explicit path argument → plan in context → most recent `.deep-skills/*/01-Plan/plan.md` (see `references/artifact-structure.md`; pre-retrofit plans remain reachable via explicit path). Read it fully, including the **Phase Summaries** appendix and **Deferreds** ledger.
- **Run autonomously / unattended** (`--autonomous`) or **check in with me at each phase** (`--collaborative`) — execution mode. If omitted on a multi-phase plan, **ask** (see `references/execution-modes.md`).
- **Work in an isolated worktree** (`--worktree`) — isolate work in a git worktree via `/create_worktree`. Default: **work in the current branch** (see `references/commit-and-handoff.md`).
- **Run independent phases in parallel** (`--parallel`) — opt-in parallel phase execution, **only** when phases are provably independent (see `references/phase-execution.md`). Never parallelize unless this is explicitly requested.

## Reuse, don't reinvent

- Tests → the **`test-runner`** skill's `execSync` capture pattern.
- Worktrees → `/create_worktree` · `/remove_worktree`.
- Hand-off/resume → `/handoff` · `/resume_handoff` machinery + the plan's Phase Summaries appendix.
- Build/validate commands & git conventions → `references/validation.md`, `references/commit-and-handoff.md`.

`deep-implement` is a lightweight, plan-driven orchestrator — deliberately *not* the DB-backed story pipeline (`story-implementer`, `.maudel/pipeline_stages/**`). Don't duplicate that machinery.

## Workflow

### 1. Load & assess
Read the plan. Identify: single- vs multi-phase, which phases are already done (Phase Summaries appendix), the Deferreds ledger, and each phase's acceptance/validation criteria. Resolve mode and flags. If resuming, start at the first unfinished phase.

### 2. Set up the worktree (if `--worktree`)
Create the isolated worktree via `/create_worktree`. Otherwise branch-first if on `main`/`develop` (see `references/commit-and-handoff.md`). Code changes go in the worktree; **plan/summary updates go to the source branch root** (reuse the story-implementer rule).

### 3. Execute phases
Per `references/phase-execution.md`:
- **Default (sequential):** for each phase, spawn **one fresh sub-agent** briefed with the plan + that phase + prior Phase Summaries. It implements only that phase.
- **`--parallel` (guarded):** only for phases verified independent (no shared files, no ordering dependency, contract pre-defined). Otherwise fall back to sequential and say why.

For each phase run the loop: **implement → validate → fix → (commit) → summarize → hand-off.**

### 4. Validate each phase
Per `references/validation.md`: typecheck (`bunx tsc` from the app dir — never `npx` from root), run relevant tests via `test-runner`, and auto-run the prompt-assembly snapshot test if the phase touched `.maudel/pipeline_stages/**`. Block only on **new** failures in changed files/their imports.

### 5. Fix loop (bounded)
If validation fails, the phase agent fixes and re-validates. **Cap: 2 attempts.** If still failing → **stop**, write a blocker report (`templates/blocker-report.md`), **notify** (see `references/notifications.md`), and in autonomous mode do **not** commit broken code.

### 6. Commit / gate (mode-dependent)
- **Collaborative:** present the diff + validation result + phase summary; await approve / request-fix. Commit only if the user wants.
- **Autonomous:** on green validation, **commit a per-phase checkpoint** (conventional message + the host-aware `Co-Authored-By` trailer — see `references/commit-and-handoff.md`), append the phase summary, write the next-phase hand-off, continue.

### 7. Summarize & hand off
After each phase: append a summary to the plan's **Phase Summaries** appendix and write a slim next-phase hand-off (`templates/phase-handoff.md`). Phase Summaries still live in the plan document — `03-Implementation/summary.md` does not replace them.

### 8. Finish
Write/update the work summary at `.deep-skills/<effort>/03-Implementation/summary.md` — check off the plan's acceptance/validation criteria there (or maintain your own checklist if the plan lacks them); create `00-Manifest/manifest.md` if absent and update the Implementation stage status (see `references/artifact-structure.md` and `references/commit-and-handoff.md`). Reconcile the **Deferreds** ledger (which were addressed vs. still open) and report it. In autonomous mode, **notify** on full-run completion. Leave the plan doc as the durable record.

## Guardrails
- Only build what the plan specifies. Found a gap or conflict mid-execution? Stop and surface it — don't silently re-plan (that's `/deep-plan`'s job).
- Never commit on `main`/`develop`; branch first. Never commit failing code.
- Notify sparingly: blockers and autonomous completion only — not routine progress.
- Autonomous mode assumes the user has enabled bypass-permissions; still behave conservatively (no destructive ops, no force-push).
