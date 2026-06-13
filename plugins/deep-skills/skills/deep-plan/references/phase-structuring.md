# Structuring resumable phases

When a feature needs more than one phase, write the plan so a **fresh agent** — or `/deep-implement` — can execute *any* phase cold, reading only the plan doc + the repo. `/deep-plan` produces the structure; it does **not** execute it.

## What every phase entry must contain

- **Goal** — one sentence: what this phase delivers.
- **Prerequisites / inputs** — what must be done first (prior phases, env, data). State "none" if independent.
- **Files** — the files this phase creates or edits, with paths. Reuse-before-new: name existing functions/utilities to lean on.
- **Steps** — ordered, concrete actions. Concrete enough to execute without guessing.
- **Acceptance / validation** — how this phase proves itself done (commands to run, tests, observable behavior).

## Resumability rules

- No phase may rely on conversation memory. If a decision matters, it's written in the plan.
- Phases are ordered and numbered. State cross-phase dependencies explicitly.
- Reserve a **Phase Summaries** appendix in the plan (empty at planning time). Execution agents append one summary per completed phase there — `/deep-plan` does not fill it.
- Reconcile each phase against the **Deferreds** ledger: if a phase touches an area with a deferred item, note the interaction.

## Boundary with `/deep-implement`

Out of scope for `/deep-plan` (owned by `/deep-implement`):
- the implement → validate → fix → commit loop,
- the collaborative-vs-autonomous execution choice,
- writing per-phase hand-off documents during execution.

`/deep-plan` only leaves phases shaped so that loop can run.
