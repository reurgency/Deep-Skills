# In-session commands

The user can type these at any point during a `/deep-plan` session. Each thin command file in `.claude/commands/` injects a one-line trigger; the real behavior lives here so it works whether typed as a slash command or recognized as a keyword. After servicing any command, **return to exactly where you were** in the session.

---

## `/drill <instructions>`

Deepen the **current question inside this session** — shared context, full history.

1. Treat `<instructions>` as the angle to pursue.
2. Run a mini loop: surface what's unclear → clarify with the user → resolve.
3. Fold the resolution into the working answer and **resume the same question round**.

Use when the user wants to poke at the answer right here. It costs main-session context (that's fine — it's a deliberate dive in the room).

---

## `/breakout <instructions>`

Split off an **isolated fresh subagent** so the investigation does **not** bloat or block the main session. The away-team to `/drill`'s in-room discussion.

1. **Compose a compact briefing** — NOT the whole transcript. Include only:
   - a short summary of the session so far (the feature, key decisions, relevant constraints),
   - the **current question** under discussion,
   - the user's `<instructions>` / commentary / angle.
2. **Launch one `Agent`** with that briefing as its entire context:
   - use the `Explore` agent type for read-only investigation; `general-purpose` if it must reason or prototype.
   - **Foreground (default):** wait for it and return its distilled answer.
   - **Background:** if the user says so (or the investigation is slow and other questions can proceed), pass `run_in_background: true` and keep the session moving; surface the answer when it lands.
3. **Return only the pearl** — the subagent's distilled answer/recommendation — into the main session. The user accepts or refines; the question resolves; continue.

Use when you want a focused investigation without spending main-session context.

---

## `/gaps`

Run a **gap-analysis round** on the current plan/answers. Repeatable.

For each finding, classify it (model on the repo's gap schema):
- **area** — domain (e.g. Auth, Data Model, UI).
- **findingType** — `gap` (missing info), `conflict` (contradiction), or `assumption` (unvalidated).
- **severity** — high / medium / low.
- **assumption** — what you'd assume if unanswered.

Turn high/medium findings into follow-up questions (rendered via `AskUserQuestion`). Fold answers back into the plan.

---

## `/risks`

Produce a **risk assessment** of the emerging plan. For each risk: description, likelihood, impact, and a mitigation or fallback. Flag anything that warrants a spike. Record material risks in the plan's status header / a Risks note.

---

## `/constraints`

Two moves in one:
1. **Suggest** likely constraints the user may not have stated — performance, compatibility/back-compat, security, scope boundaries, deadlines, platform/runtime, data/privacy.
2. **Ask** the user for any additional constraints.

Fold every accepted constraint into the plan (Context or a Constraints section) so design honors them.

---

## `/columbo`

The existing repo command (`.claude/commands/columbo.md`), reused in place. Re-read the written plan as a fresh agent with zero prior context and audit for unstated assumptions, undefined terms, missing paths/commands, ambiguous steps, and implicit ordering. If a fresh agent couldn't succeed, list what's missing and fix it in the plan. Offer this as the final step before hand-off.
