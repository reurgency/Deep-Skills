# Future prompt — design-rationale scan of the deep-* skills (training material)

> **Status:** ready-to-run prompt, not yet executed. Captured 2026-06-28 during the deep-docs planning session.
>
> **Important — where the output lives:** this produces **training-program material**, written to **`docs/Training/`**. It is **NOT** baked into any skill (no `references/design-rationale.md`). Rationale documentation does not make a skill better at its job — the skill never reads it; it only justifies design choices to a human learner. Keeping it out of the skill avoids bloating `references/` with content the skill never loads.

## The ask (paste this to a fresh agent)

You are producing **training material** that recovers and documents the **design rationale** of the deep-* skill series, for a separate training program. The skills are under `plugins/deep-skills/skills/{deep-plan,deep-plan-review,deep-implement,deep-code-review}/` (and `deep-bug-fix`, `deep-docs` once built).

**Write all output under `docs/Training/` — do not add any file to a skill's `references/` or otherwise modify the skills.** Suggested layout: `docs/Training/design-rationale/<skill>.md`, plus a `docs/Training/design-rationale/index.md` linking them.

For **each** skill, document every **non-obvious design decision** baked into it:

1. **The decision** — what the skill does (e.g. code-review's 8-finder fan-out, the sev≥5 verification floor, the byte-identical `artifact-structure.md`/`load-active-cards.sh` copies, the review/triage separation, the "findings stay open" rule, the model-tier resolution that bans Haiku).
2. **Alternatives considered / rejected** — what else could have been done, recovered from the SKILL.md, references, the design docs in `docs/roadmap/`, and git history (`git log -p` on the skill).
3. **Why this choice** — the rationale, with `file:line` anchors to where the decision lives.

Method:
- Read each skill's `SKILL.md` + all `references/` + `templates/`.
- Mine `docs/roadmap/*.md` (DESIGN-OUTLINE, DATA-FLOW-CONTRACT, the per-skill design notes) and `docs/benchmarks/` for stated rationale.
- Mine git history for decisions that changed (`git log --oneline` then `git show` on relevant commits) — these reveal rejected alternatives explicitly.
- Where a rationale is **not recoverable**, say so honestly (`rationale: not recovered from sources`) rather than inventing one.

**For `deep-docs` specifically:** its 9 key design decisions (with alternatives + rationale) are already recorded in its plan's Approach section — `.deep-skills/deep-docs/01-Plan/plan.md`. Use that as the source for the deep-docs training page rather than re-deriving.

Output is for a human learner who wants to understand *why* the series is shaped the way it is. Write it accordingly.

## Related
- `docs/roadmap/DEEP-DOCS-DESIGN.md` — the skill whose planning surfaced this ask.
- `.deep-skills/deep-docs/01-Plan/plan.md` — the deep-docs plan; the source for the deep-docs rationale page.
- Memory: `deep-skills-cross-assistant-portability` — a related cross-cutting follow-up sweep.
