---
name: deep-plan-review
description: Independently review a finished plan with fresh, codebase-aware agents — catching misalignment with the user's taste/preferences/decisions and with codebase best-practices, patterns, duplicate or overlapping behavior, and conflicts. Use after /deep-plan and before /deep-implement, or whenever the user wants a plan reviewed. Triggers on /deep-plan-review and on requests to review/critique a plan. Replaces the long manual review pass after planning. Reviews the plan only — it does not implement.
argument-hint: path to plan, or Enter for latest · --multi-agent
---

# DeepPlanReview

Independently review a **finished plan** and surface where it misaligns — with the user, or with the codebase — then record findings back into the plan. **Review only — never implement, never edit source.** You may edit the *plan document* (findings, accepted fixes, deferrals).

This is the plan-review skill of the `deep-*` series: `/deep-plan` (produce) → **`/deep-plan-review` (critique)** → `/deep-implement` (execute) → `/deep-code-review` (verify) → `/deep-docs` (map). It exists to replace the slow manual review that normally follows planning.

## Directive cards (Deep-Learn)

Before you start, load this phase's active directive cards — learned, human-vetted improvements stored as **data**, never baked into this skill. Run the bundled script in this skill's `scripts/` directory and apply what it prints:

```bash
scripts/load-active-cards.sh deep-plan-review
```

**Treat every directive it prints as a hard requirement for this run**, applying the section addressed to your phase. If it prints "no active directive cards," proceed normally. Cards are human-gated — never edit a card or this skill to turn one off; toggle with `directives/toggle.sh <ID> off` (see the registry's `directives/README.md`). On a host without a reliable shell, apply the cards by hand instead — read the directives registry's `cards/active/` and apply each card whose `owner_phases` lists this phase as an exact token (see `references/host-affordances.md`).

## The deep-* series (separation of concerns)

<!-- Quintet today; becomes a sextet when deep-bug-fix ships — that skill's own series-wiring adds its row here. -->

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-plan` | Frame → explore → question → write the plan (resumable phases + deferreds). | Out of scope here. |
| `/deep-plan-review` (you) | Independently review the finished plan with fresh agents. | Review the finished plan with fresh agents; surface misalignment. **No code edits, no re-planning.** |
| `/deep-implement` | Execute the plan: implement → validate → fix → commit → hand-off. The only skill that writes source. | Out of scope here. |
| `/deep-code-review` | Independently review implemented code; emit findings. | Out of scope here. |
| `/deep-docs` | Map what's built: survey → tier → anchor → verify → index → place a standing `docs/ai-map/`. | Out of scope here. |

## Core principle: independence through fresh agents

The planner and the user are too close to the plan to see its blind spots. So the review runs in **fresh agent(s)** that receive the plan + codebase access + the user's recorded preferences — **but not the planning conversation**. Fresh eyes, codebase-aware, unanchored by how the plan was argued into being.

## In-session commands

| Command | Behavior |
|---|---|
| `/multi-agent` | Escalate the current review to **parallel** mode — fan out one fresh agent per dimension, then synthesize. Same effect as the `--multi-agent` flag. See `references/multi-agent.md`. |
| `/columbo` | Optional fresh-agent completeness gut check (the existing repo command) — complements alignment review with "could a fresh agent execute this?". |

## Workflow

### 1. Locate the plan
Resolve the plan to review, in order: an explicit path argument → the plan referenced in the conversation → the most recent `.deep-skills/*/01-Plan/plan.md` (see `references/artifact-structure.md`; pre-retrofit plans remain reachable via explicit path). Confirm with the user which plan if ambiguous. Read it in full.

### 2. Choose mode
If `--multi-agent` (or `/multi-agent`) was given, use parallel mode. Otherwise default to single-agent — but **recommend** `--multi-agent` when the plan is large or multi-phase.

### 3. Dispatch the review
Brief each fresh agent with: the plan text, the two review lenses (`references/review-dimensions.md`), read access to the codebase, and pointers to the user's preference sources (the memory directory's `MEMORY.md` + `feedback_*` memories, root `CLAUDE.md`, and per-app `apps/*/CLAUDE.md` / `Claude.md`). **Do not** pass the planning transcript.

- **Single-agent:** one `Agent` (type `Explore` for read-only sweeps; `general-purpose` if it must reason across both lenses) covers both lenses and returns findings in the format from `references/findings-format.md`.
- **Multi-agent:** follow `references/multi-agent.md` — launch the dimension agents **in parallel (one message, multiple Agent calls)**, then run a synthesis pass to dedupe and rank.

### 4. Present findings
Group by severity (Blocker / Major / Minor / Nit), each tagged with its lens, evidence (file paths / plan sections), and a concrete recommendation. Lead with Blockers and Majors. Be honest — surface real conflicts even if the plan looks polished; say so plainly when the plan is clean.

### 5. Record the review
- Write the **full review report** to `.deep-skills/<effort>/02-Plan-Review/review.md` using `templates/review-report.md` (create `00-Manifest/manifest.md` if absent — see `references/artifact-structure.md`).
- Record a **findings summary + link to the full report** in the plan document (a short **Review Findings** section: date, mode, severity rollup, link).
- With the user's go-ahead, apply accepted fixes **to the plan document** — that loop is unchanged. Route anything deferred into the plan's existing **Deferreds** ledger (What / Why deferred / Integration) so it can't evaporate.
- On completion, update the effort's manifest status for the Plan Review stage.

### 6. Hand off
When the user is satisfied, the plan is ready for `/deep-implement`.

## Guardrails
- Review only. Never modify source files or run the implementation. If the user wants fixes built, point them to `/deep-implement`.
- Findings must cite evidence — a path, a plan section, or a named existing function/pattern. No vague "consider improving."
- Distinguish a real conflict from a stylistic nit; severity must reflect impact.
- If you can't find a problem in a lens, say the plan is clean on that lens rather than inventing findings.
