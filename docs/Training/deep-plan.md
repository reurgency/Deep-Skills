# Training: `/deep-plan`

> Part of the [Deep Skills Training Program](README.md). Skill 1 of 5 — **produce**.
> Source: [`plugins/deep-skills/skills/deep-plan/SKILL.md`](../../plugins/deep-skills/skills/deep-plan/SKILL.md)

`/deep-plan` runs a guided, **interruptible** feature-planning session and produces a
self-contained, fresh-agent-resumable plan document. **Plan only — it never implements.**

---

## Learning objectives

By the end you can:

1. Run a planning session end-to-end and produce a `plan.md` a fresh agent could execute cold.
2. Choose the right **question cadence** and keep questions decision-relevant.
3. Drive the **in-session commands** (`/drill`, `/breakout`, `/gaps`, `/risks`,
   `/constraints`, `/columbo`) without losing your place.
4. Structure a **multi-phase** plan and maintain a **Deferreds ledger** so nothing is lost.
5. Fill the **State / Data-Flow Contract** (directive `DLC-001`) so cross-layer bugs surface
   at plan time.

## Prerequisites

The [shared mental model](README.md#the-shared-mental-model-read-this-before-any-skill-page) —
especially *fresh-agent resumability* and *separation of concerns*.

---

## Mental model

You are the **session host**, not a code author. Your product is a *document*. The user
**steers** at any time with in-session commands; you service the command and return to exactly
where you were. The deep work is asking sharp questions, reusing before inventing, and writing
down enough that the conversation becomes disposable.

The single acceptance test for everything you write: **could a fresh agent with only this plan
+ the repo succeed?**

---

## Curriculum

### Module 1 — Setup & framing
- Restate the feature in **one sentence** and confirm it.
- Pick a **question cadence**: 1-at-a-time · 3-at-a-time · all-at-once. Recommend
  *all-at-once* for small features. (`references/question-cadence.md`)
- Propose a kebab-case **effort name**; the plan lands at
  `.deep-skills/<effort-name>/01-Plan/plan.md`. An explicit path argument overrides this.
- State scope, explicit **non-goals**, and your assumptions; get a quick confirm.

> **Drill:** Take a one-line feature request and produce just the restatement, three
> non-goals, and a proposed effort name. Stop there. This is the most-skipped, highest-value
> step.

### Module 2 — Explore before you ask (read-only)
Launch up to **3 `Explore` agents in parallel** to find reusable patterns/utilities,
integration points, data models, and the files that will be touched. **Reuse before
inventing** — name existing functions with their paths. **No edits in this phase.**

> **Why:** every question you can answer from exploration is a question you shouldn't ask the
> user. Exploration is what makes your questions sharp.

### Module 3 — Question rounds
Emit questions per the chosen cadence, each built from a `templates/questions/*.json` format
and rendered via `AskUserQuestion`. Keep them **decision-relevant** — skip anything
exploration already answered. Honor `/drill` and `/breakout` mid-round without losing place.

### Module 4 — In-session commands (the steering wheel)
Watch for these at **every** step. Service, then resume.

| Command | What it does |
|---|---|
| `/drill <note>` | Deepen the current question **in this session** (shared context), then resume. |
| `/breakout <note>` | Dispatch an **isolated fresh subagent** with a compact briefing; return only its distilled answer — protects main context. |
| `/gaps` | Gap-analysis round; surface gaps/conflicts/assumptions as follow-ups. Repeatable. |
| `/risks` | Risk assessment of the emerging plan. |
| `/constraints` | Suggest likely constraints **and** ask the user for theirs; fold accepted ones in. |
| `/columbo` | Fresh-agent "one more thing" completeness gut check on the written plan. |

> **`/drill` vs `/breakout`:** drill stays in the shared conversation (cheap, contextual);
> breakout spins an isolated agent (protects your main context from a deep tangent). Choosing
> correctly is a core skill — reach for breakout when the side-quest would otherwise flood the
> session.

### Module 5 — The pre-write nudge
Before writing **anything**, ask plainly:
> *Want a `/gaps`, `/risks`, or `/constraints` pass before I write the plan?*

Honor any, all, or none — repeatably (two gap rounds is fine). Only write when the user is ready.

### Module 6 — Design & write the plan
Write to `01-Plan/plan.md` using `templates/plan-template.md`. On first write to the effort
dir, create `00-Manifest/manifest.md` if absent. Include:

- Self-contained **Context / Approach / Steps / Files / Verification**.
- Reused functions/utilities referenced **with their paths**.
- A **Deferreds** ledger (see Module 7).
- **State / Data-Flow Contract** — one row per piece of state read/written (see Module 8).
- If **multi-phase**: structure each phase per `references/phase-structuring.md` so a fresh
  agent executes it cold; leave an empty **Phase Summaries** appendix for `/deep-implement`.
- If the feature adds a **user-triggered action/submit/navigation or a stateful/resumable
  flow**, fill the **Interaction & re-entry** section: double-submit guard, processing
  feedback, navigation fallback, re-entry story. Omit for pure refactors with no such surface.
- **No source edits — only the plan document.**

### Module 7 — Deferreds: nothing forgotten
Anything you defer goes in the **Deferreds** ledger with three fields: **What**, **Why
deferred**, **Integration** (how it connects back when done). Never bury a deferral in prose.

### Module 8 — The State / Data-Flow Contract (directive DLC-001)
A required table: **one row per piece of state the feature reads or writes at runtime.**

| # | State | Writer(s) path:line | Runtime reader(s) path:line | Same source? | Resolution / AC |
|---|---|---|---|---|---|

A row is *resolved* only if the runtime reader resolves the **same source** the writer wrote
to. Otherwise it **blocks plan completion** unless marked Display-only and moved to Deferreds.
The four rules: every new persisted store appears as a writer row; every "single source of
truth" AC points to exactly one source; **deletion-parity** (removing a surface re-homes each
behavior it provided); reader = none or reader-source ≠ writer-source ⇒ blocks.

> **Why it has teeth:** you can't fill the row honestly without discovering the bug. The
> writer column forces "where does the save land?"; the reader column forces a runtime trace;
> "Same?" is a binary. See [`DLC-001`](../../plugins/deep-skills/directives/cards/active/DLC-001.md).

### Module 9 — Review, Columbo, hand off
Present the plan, fold in feedback, update the doc. Offer `/columbo` **last** as the final
completeness check; fix what it surfaces. That's the hand-off point to `/deep-plan-review` /
`/deep-implement`.

---

## Directive cards

At the start of every run, execute `scripts/load-active-cards.sh deep-plan` and treat each
printed directive as a **hard requirement** for that run. If it prints "no active directive
cards," proceed normally. Never edit a card or the skill to disable one — toggle it.

---

## Hands-on exercises

1. **Framing-only:** restate a feature, list non-goals, name the effort. No questions yet.
2. **Reuse hunt:** run the 3 `Explore` agents; produce a list of existing functions (with
   paths) you'll reuse instead of writing new code.
3. **Cadence call:** for a 2-file change vs a 6-phase migration, justify your cadence choice.
4. **Contract drill:** for a feature that writes a new localStorage key, fill its Data-Flow
   Contract row and decide whether it's resolved.
5. **Steering:** mid-question, practice a `/breakout` for a deep tangent, then resume cleanly.

---

## Common mistakes

- **Writing code.** This skill plans only. If asked to build, point to `/deep-implement`.
- **Asking what you could have explored.** Burn the Explore budget first.
- **Burying deferrals in prose.** They evaporate. Use the ledger's three fields.
- **A plan that needs the chat to understand.** Fails the fresh-agent test — make it self-contained.
- **Skipping the Data-Flow Contract** on a stateful feature — that's exactly where cross-layer bugs hide.
- **Writing before the pre-write nudge** — you skip the user's chance to ask for gaps/risks.

## Mastery checklist

- [ ] Produced a `plan.md` a fresh agent executed without the conversation.
- [ ] Chose cadence deliberately and kept every question decision-relevant.
- [ ] Used `/drill` vs `/breakout` for the right reasons.
- [ ] Multi-phase plan with cold-executable phases + an empty Phase Summaries appendix.
- [ ] Every deferral in the ledger; every state row resolved or explicitly Display-only/deferred.
- [ ] Ran `/columbo` as the last gate before hand-off.

## Quick reference

| | |
|---|---|
| Output | `.deep-skills/<effort>/01-Plan/plan.md` |
| Template | `templates/plan-template.md` |
| Hard rule | Plan only — no source edits |
| Hand-off to | [`/deep-plan-review`](deep-plan-review.md) → [`/deep-implement`](deep-implement.md) |

➡ **Next:** [Training: `/deep-plan-review`](deep-plan-review.md)
