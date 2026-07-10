# Autonomous mode — `--autonomous`

*Natural-language trigger: say 'plan this autonomously' / 'plan it unattended, no questions.'*

Run the **same session workflow** as an interactive plan — Setup → Frame → Explore → Questions → Design & write → Review → Columbo — but with **zero questions to the user**. Every decision the interactive session would have asked about is **self-answered with best judgment and recorded as an Assumption row** in the plan's Assumptions section (`templates/plan-template.md`). Nothing else changes: same plan template, same artifact paths, same manifest behavior, same planning-only guardrails.

This mode is a free-standing feature: useful whenever a user wants a first-draft plan without a Q&A session, and equally usable by a script or orchestrator that dispatches planning unattended. It requires nothing beyond this skill.

## The one rule

**Ask nothing. Record everything.** For every point where the interactive workflow would pause for the user — the cadence question, the effort-name confirmation, each question round, the pre-write nudge, the feedback pass — either the pause is skipped because it no longer applies, or the decision is made in-session and logged as an Assumption row: **question · chosen answer · why**. A fresh reader of the plan must be able to see every judgment call the run made alone.

An Assumption row is for *decisions a user would plausibly have steered* — architecture choices, scope boundaries, naming, trade-offs. Facts settled by exploration (an existing utility, a framework convention) are not assumptions; cite them in the plan body as usual.

## Per-step deltas from the interactive workflow

| Step | Interactive behavior | Autonomous behavior |
|---|---|---|
| **1. Setup** | Confirm restatement; ask cadence; propose effort name and get confirmation. | State the one-sentence restatement (no wait). **Skip the cadence question entirely** — there are no question rounds to pace. Effort name: use `--effort=<slug>` verbatim when supplied; otherwise **derive the kebab-case slug yourself and STATE it** ("Effort: `<slug>`") — never ask. |
| **2. Frame** | Get a quick confirmation of scope/non-goals/assumptions. | State scope and non-goals; any judgment call in the framing becomes an Assumption row. |
| **3. Explore** | Read-only Explore agents. | Unchanged — exploration is what makes self-answers defensible. |
| **4. Question rounds** | Emit questions to the user per cadence. | Formulate the same decision-relevant questions, then **self-answer each with best judgment** — prefer the answer supported by exploration evidence, repo convention, or the least-surprise default. One Assumption row per question. |
| **5. Pre-write nudge** | Mandatory ask: gaps/risks/constraints pass? | Self-decide: run any pass (`/gaps`, `/risks`, `/constraints` mechanics per `references/in-session-commands.md`) you judge warranted; record the run-or-skip decision as an Assumption row. Findings from a self-run pass are folded in the normal way; any follow-up question a pass raises is also self-answered + logged. |
| **6. Design & write** | Write plan per template. | Unchanged — plus the populated **Assumptions** section (include it only when it has rows, i.e. always in practice for this mode). |
| **7. Review** | Present the plan, fold in feedback. | No user feedback to fold in — skip the pause; the written plan is the deliverable. |
| **8. Columbo** | Offer `/columbo` last. | With `--columbo`: **self-run the columbo check now** (below). Without it: don't ask — mention in the closing summary that a columbo pass is available. |

## `--columbo` — self-run the completeness check

*Natural-language trigger: say 'include a columbo pass' / 'plan autonomously with a columbo check.'*

At the end of an autonomous plan, run the **existing** `/columbo` check exactly as defined in `references/in-session-commands.md` § `/columbo` — re-read the written plan as a fresh agent with zero prior context (on Claude Code, reuse `.claude/commands/columbo.md` where present; elsewhere run the fresh-agent completeness audit directly) — and **fix what it surfaces in the plan** without asking. Note in the closing summary that the pass ran and what it changed. Meaningful primarily with `--autonomous`; in an interactive session the same flag simply pre-answers the step-8 offer as "yes."

## `--effort=<slug>` — name the effort up front

*Natural-language trigger: say 'call the effort <name>.'*

Supplies the effort name at invocation, so the plan lands at `.deep-skills/<slug>/01-Plan/plan.md` with no propose-and-confirm step. Works in any mode (an interactive session with `--effort` skips only the name confirmation); in autonomous mode it is how a caller pins the artifact location before dispatch. Absent, autonomous mode derives the slug itself and states it — see the Setup row above and the effort-name carve-out in `references/artifact-structure.md`.

## `--rounds=<n>` — and why autonomous ignores it

`--rounds=<n>` parameterizes **interactive** front-loaded question depth (see SKILL.md § Flags). Under `--autonomous` there are no user-facing question rounds, so the flag is accepted and **ignored** — an autonomous run behaves as zero rounds by definition.

## Closing an autonomous run

End with a compact summary the caller (human or script) can consume in one glance: the effort name, the plan path, single- vs multi-phase, the **number of Assumption rows** (with a pointer to the section — they are the run's audit trail), whether a columbo pass ran, and the usual hand-off pointers (`/deep-plan-review`, `/deep-implement`). Notify per `references/host-affordances.md` § Notifications only as an autonomous-run completion signal — never mid-run.

## Guardrails (unchanged, restated)

- **Planning only.** Autonomous mode never widens the write surface: the plan document and manifest, nothing else.
- **No hidden judgment.** If a decision was yours, it is in the Assumptions table. An autonomous plan whose Assumptions section is empty on a non-trivial feature is a red flag — it means questions were silently absorbed.
- **Interactive default untouched.** Without `--autonomous`, nothing in this file applies; the session runs exactly as SKILL.md describes.
