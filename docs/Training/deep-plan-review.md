# Training: `/deep-plan-review`

> Part of the [Deep Skills Training Program](README.md). Skill 2 of 5 — **critique**.
> Source: [`plugins/deep-skills/skills/deep-plan-review/SKILL.md`](../../plugins/deep-skills/skills/deep-plan-review/SKILL.md)

`/deep-plan-review` independently reviews a **finished plan** and surfaces where it
misaligns — with the *user* (taste, preferences, recorded decisions) or with the *codebase*
(best-practices, patterns, duplicate/overlapping behavior, conflicts) — then records findings
back into the plan. **Review only — never implement, never edit source.** It *may* edit the
**plan document** (findings, accepted fixes, deferrals).

---

## Learning objectives

By the end you can:

1. Explain why review must run in **fresh agents** without the planning transcript.
2. Locate the right plan to review and choose **single-agent vs `--multi-agent`** mode.
3. Brief reviewers with the two lenses + the user's recorded preference sources.
4. Present findings by **severity**, each with **evidence** and a concrete recommendation.
5. Record the review correctly: a full report **and** a summary folded into the plan, with
   accepted fixes applied to the plan and deferrals routed to the ledger.

## Prerequisites

[`/deep-plan`](deep-plan.md) (you review its output) and the
[shared mental model](README.md#the-shared-mental-model-read-this-before-any-skill-page) —
especially *independence through fresh eyes*.

---

## Mental model

**The planner and the user are too close to the plan to see its blind spots.** So the review
runs in fresh agent(s) that receive the plan + codebase access + the user's recorded
preferences — **but not the planning conversation**. Fresh eyes, codebase-aware, unanchored by
how the plan was argued into being. That independence *is* the value; passing the transcript
would destroy it.

This is the middle skill of the trilogy — it replaces the slow manual review that normally
follows planning.

---

## Curriculum

### Module 1 — Locate the plan
Resolve, in order: explicit path argument → the plan referenced in conversation → the most
recent `.deep-skills/*/01-Plan/plan.md`. Confirm with the user if ambiguous. **Read it in full.**

### Module 2 — Choose mode
- **Single-agent** (default): one agent covers both lenses.
- **`--multi-agent`** (or `/multi-agent`): fan out one fresh agent **per dimension** in
  parallel, then synthesize. **Recommend it** when the plan is large or multi-phase.
  (`references/multi-agent.md`)

### Module 3 — The two review lenses
The reviewer hunts on exactly two lenses (`references/review-dimensions.md`):

1. **User alignment** — does the plan match the user's taste, preferences, and recorded
   decisions?
2. **Codebase alignment** — does it match best-practices and existing patterns? Does it
   duplicate or overlap existing behavior? Does it conflict with what's there?

### Module 4 — Dispatch the review (briefing discipline)
Brief each fresh agent with: the **plan text**, the **two lenses**, **read access to the
codebase**, and **pointers to the user's preference sources** — the memory directory's
`MEMORY.md` + `feedback_*` memories, root `CLAUDE.md`, and per-app
`apps/*/CLAUDE.md` / `Claude.md`. **Do not pass the planning transcript.**

- **Single-agent:** one `Agent` — type `Explore` for read-only sweeps, `general-purpose` if it
  must reason across both lenses — returns findings in `references/findings-format.md`.
- **Multi-agent:** launch dimension agents **in parallel (one message, multiple `Agent`
  calls)**, then a **synthesis pass** to dedupe and rank.

### Module 5 — Present findings
Group by severity — **Blocker / Major / Minor / Nit** — each tagged with its lens, with
**evidence** (file paths / plan sections) and a **concrete recommendation**. Lead with
Blockers and Majors. Be honest: surface real conflicts even if the plan looks polished, and
say so plainly when a lens is clean.

### Module 6 — Record the review
- Write the **full report** to `.deep-skills/<effort>/02-Plan-Review/review.md` using
  `templates/review-report.md` (create the manifest if absent).
- Record a **findings summary + link** in the plan (a short **Review Findings** section: date,
  mode, severity rollup, link).
- With the user's go-ahead, apply **accepted fixes to the plan document**. Route anything
  deferred into the plan's existing **Deferreds** ledger (What / Why deferred / Integration).
- Update the manifest's Plan-Review stage status.

### Module 7 — Optional `/columbo`
A fresh-agent completeness gut check — complements alignment review with "could a fresh agent
*execute* this?"

### Module 8 — Hand off
When the user is satisfied, the plan is ready for [`/deep-implement`](deep-implement.md).

---

## Directive cards

Run `scripts/load-active-cards.sh deep-plan-review` at the start; treat each printed directive
as a hard requirement. Note `DLC-001` gives this skill a **check**: confirm the plan's
State / Data-Flow Contract is present, every row resolved, and every AC's source singular.

---

## Hands-on exercises

1. **Independence test:** brief a reviewer agent. List exactly what goes in the briefing — and
   confirm the planning transcript is *not* in it.
2. **Lens split:** take a finished plan and produce one finding on each lens (user alignment,
   codebase alignment), each with cited evidence.
3. **Mode call:** justify single-agent vs `--multi-agent` for a 1-phase vs a 5-phase plan.
4. **Clean call:** practice writing "the plan is clean on the codebase-alignment lens" instead
   of inventing a finding.
5. **Record loop:** write a Review Findings summary into a plan and route one item to the
   Deferreds ledger.

---

## Common mistakes

- **Passing the planning transcript** — kills the independence that makes the review work.
- **Inventing findings** to look thorough. If a lens is clean, say so.
- **Vague findings.** Every finding cites a path, a plan section, or a named existing function.
- **Severity inflation** — a stylistic nit is not a Blocker; severity must reflect impact.
- **Editing source.** This skill touches only the plan document.
- **Forgetting to fold the summary into the plan** — the full report alone leaves the plan
  blind to its own review.

## Mastery checklist

- [ ] Briefed reviewers with plan + lenses + preference sources, never the transcript.
- [ ] Produced findings on both lenses, each with evidence and a concrete recommendation.
- [ ] Grouped by severity, led with Blockers/Majors, called clean lenses honestly.
- [ ] Wrote the full report **and** the in-plan summary + link.
- [ ] Applied accepted fixes to the plan; routed deferrals to the ledger; updated the manifest.

## Quick reference

| | |
|---|---|
| Input | The most recent `01-Plan/plan.md` (or explicit path) |
| Output | `.deep-skills/<effort>/02-Plan-Review/review.md` + in-plan summary |
| Lenses | User alignment · Codebase alignment |
| Hard rule | Review only — may edit the plan doc, never source |
| Hand-off to | [`/deep-implement`](deep-implement.md) |

➡ **Next:** [Training: `/deep-implement`](deep-implement.md)
