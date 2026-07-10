---
name: deep-plan
description: Run an interactive, steerable feature-planning session that produces a self-contained, fresh-agent-resumable plan artifact. Use when the user wants to plan a feature, run a planning session, "deep plan" something, or before handing work to /deep-implement. Also runs unattended — "plan this autonomously" (--autonomous) self-answers every planning question and records each as an Assumption. Triggers on /deep-plan and on requests to plan a feature, design an approach, or scope work before building. Planning only — it does not implement.
argument-hint: describe feature/task to plan · --autonomous · --effort=<slug> · --columbo · --rounds=<n>
---

# DeepPlan

Run a guided feature-planning session and produce a plan document. **Plan only — never implement.** Execution belongs to the sibling skill `/deep-implement`. Reviewing the plan belongs to `/deep-plan-review`.

You are the session host. The user steers with in-session commands at any time. Stay calm, ask sharp questions, reuse before inventing, and write a plan a fresh agent could execute cold.

## Directive cards (Deep-Learn)

Before you start, load this phase's active directive cards — learned, human-vetted improvements stored as **data**, never baked into this skill. Run the bundled script in this skill's `scripts/` directory and apply what it prints:

```bash
scripts/load-active-cards.sh deep-plan
```

**Treat every directive it prints as a hard requirement for this run**, applying the section addressed to your phase. If it prints "no active directive cards," proceed normally. Cards are human-gated — never edit a card or this skill to turn one off; toggle with `directives/toggle.sh <ID> off` (see the registry's `directives/README.md`). On a host without a reliable shell, apply the cards by hand instead — read the directives registry's `cards/active/` and apply each card whose `owner_phases` lists this phase as an exact token (see `references/host-affordances.md`).

## The deep-* series (separation of concerns)

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-plan` (you) | Frame → explore → question → write the plan (resumable phases + deferreds). | Stop after the plan (+ optional /columbo). **No code edits** — you only frame and structure the work. |
| `/deep-plan-review` | Independently review the finished plan with fresh agents. | Out of scope here. |
| `/deep-implement` | Execute the plan: implement → validate → fix → commit → hand-off. The only skill that writes source as forward construction from a plan. | Out of scope here. |
| `/deep-code-review` | Independently review implemented code; emit findings. | Out of scope here. |
| `/deep-bugfix` | Remediate defects: cluster → diagnose → fix at the cause → prove → contain → commit. | Out of scope here. |
| `/deep-docs` | Map what's built: survey → tier → anchor → verify → index → place a standing `docs/ai-map/`. | Out of scope here. |

## In-session commands — watch for these at EVERY step

The user may type any of these at any point. Service the command, then return to exactly where you were. Full behavior: `references/in-session-commands.md`.

| Command | One-line behavior |
|---|---|
| `/drill <note>` | Deepen the current question **in this session** (shared context), then resume. |
| `/breakout <note>` | Dispatch an **isolated fresh subagent** with a compact briefing; return only its distilled answer. Protects main context. |
| `/gaps` | Run a gap-analysis round; surface gaps/conflicts/assumptions as follow-up questions. Repeatable. |
| `/risks` | Produce a risk assessment of the emerging plan. |
| `/constraints` | Suggest likely constraints AND ask the user for their own; fold accepted ones into the plan. |
| `/columbo` | Fresh-agent "one more thing" completeness gut check on the written plan. |

These in-session commands are natural-language-first — say e.g. *'run a columbo pass,' 'drill into X,' 'break out Y,' 'check for gaps/risks/constraints'*; the `/slash` forms are conveniences on hosts that have them. If a user types one of these without the leading slash but clearly means it, treat it the same way.

## Flags

Per the cross-assistant **Portability** rule, every flag is **natural-language-first** — the plain-language trigger is the primary path (users on Copilot/Codex have no CLI flags); the `--flag` is a convenience layered on top. Always accept the natural-language form. **With none of these flags, the session runs exactly as the workflow below describes — interactive behavior is unchanged.**

- **Plan autonomously** (`--autonomous`) — say *"plan this autonomously," "plan it unattended, no questions."* Run the same workflow with **zero questions to the user**: skip the cadence question, self-answer every planning question with best judgment, and record each as a row in the plan's **Assumptions** section (question · chosen answer · why). Full mode spec: `references/autonomous-mode.md`.
- **Include a columbo pass** (`--columbo`) — say *"include a columbo pass."* Self-run the existing `/columbo` completeness check at the end of the session and fix what it surfaces — meaningful primarily with `--autonomous` (interactively it pre-answers the step-8 offer as "yes"). See `references/autonomous-mode.md`.
- **Name the effort up front** (`--effort=<slug>`) — say *"call the effort <name>."* Use the supplied kebab-case slug as the effort name, skipping the propose-and-confirm step. In autonomous mode with no `--effort`, the slug is self-derived and **stated, never asked**.
- **Set the question depth** (`--rounds=<n>`) — say *"three rounds of questions."* Interactive sessions only: skip the cadence question and run exactly *n* front-loaded question rounds (each a batched round via the host's structured-question tool), then proceed; the user can still request extra gap rounds. Ignored under `--autonomous` (no rounds by definition).

## Session workflow (interruptible state machine)

Everything below describes the default **interactive** session. Under `--autonomous` the same state machine runs unattended with the per-step deltas in `references/autonomous-mode.md`.

### 1. Setup
- Restate the feature in one sentence; confirm with the user.
- Ask **question cadence** — 1-at-a-time · 3-at-a-time · all-at-once. Recommend **all-at-once** for small features. See `references/question-cadence.md`. (Skipped when `--rounds=<n>` was given — run exactly *n* front-loaded rounds instead, per § Flags.)
- Propose an **effort name** — a kebab-case slug derived from the feature — and get the user's confirmation. (When `--effort=<slug>` was supplied, use it as-is and state it instead of asking.) The plan is written to `.deep-skills/<effort-name>/01-Plan/plan.md` (see `references/artifact-structure.md`). An explicit path argument overrides this default.
- Form an initial **multi-phase?** judgment (you'll revisit before writing).

### 2. Frame
State scope, explicit **non-goals**, and the assumptions you're making. Get a quick confirmation.

### 3. Explore (read-only)
Launch up to 3 `Explore` agents in parallel to find: reusable patterns/utilities, integration points, data models, and the files that will be touched. **Reuse before inventing** — prefer existing functions over new code, and name them with paths. Do not edit anything in this phase.

### 4. Question rounds
Emit questions per the chosen cadence. Build each question from a `templates/questions/*.json` format and render via the host's structured-question tool (see `references/host-affordances.md`). Keep questions decision-relevant — skip anything you can answer yourself from exploration. Honor `/drill` and `/breakout` mid-round without losing your place.

### 5. Pre-write nudge
**Always ask this before writing — it is a mandatory step at the end of every plan session, never skipped.** Ask plainly, in natural language (no slash required, so it works for users on Copilot/Codex too):
> *Before I write the plan: tell me to "run gaps", "run risks", or "run constraints" pass first? I can run any, all, or none (and repeatably). Or ask me what those commands can provide.*

Follow the ask with a one-line **recommendation if pertinent** (e.g. "I'd suggest a gaps pass — there are a couple of unresolved seams worth surfacing first"). If nothing warrants one, omit it.

Honor any, all, or none — and repeatably (e.g. two gap rounds). Only proceed to writing when the user is ready.

### 6. Design & write the plan
Write to `.deep-skills/<effort-name>/01-Plan/plan.md` (or the explicit path override) using `templates/plan-template.md`. On first write to the effort directory, create `00-Manifest/manifest.md` if absent (per `references/artifact-structure.md`) and set the Plan stage status. Include:
- Self-contained **Context / Approach / Steps / Files / Verification**.
- Reference reused functions/utilities with their paths.
- A **Deferreds** ledger (see `templates/plan-template.md` and below).
- In autonomous runs only: the populated **Assumptions** section — one row per self-answered question (see `references/autonomous-mode.md`); interactive sessions omit it.
- If **multi-phase**: structure each phase per `references/phase-structuring.md` so a fresh agent can execute it cold, and leave an empty **Phase Summaries** appendix for `/deep-implement` to append to.
- If the feature adds a **user-triggered action/submit/navigation or a stateful/resumable flow**, fill the template's **Interaction & re-entry** section — specify the double-submit guard, processing feedback, navigation fallback, and re-entry story rather than leaving them implicit. Omit the section for pure refactors/migrations with no such surface.
- **Do not implement.** No source edits — only the plan document.

### 7. Review
Present the plan, fold in feedback, update the doc.

### 8. Columbo (offered last)
Offer `/columbo` as the final completeness check. Fix anything it surfaces. This is the hand-off point to `/deep-plan-review` / `/deep-implement`.

## Deferreds — nothing gets forgotten by phase 4

Anything you decide to defer goes in the plan's **Deferreds** ledger with three fields: **What**, **Why deferred**, and **Integration** (how it must connect back to the completed work when done). Never drop a deferral into prose where it gets lost.

## Guardrails
- Planning only. If the user asks you to start building, point them to `/deep-implement` (or confirm they want to leave the planning skill).
- Keep the plan scannable but executable. A fresh agent with only the plan doc + repo should succeed.
- Convert relative dates to absolute when writing the plan.
