# Commit, branch, and hand-off

## Branch policy

- **Never commit on `main` or `develop`.** If the current branch is a default branch, create a feature branch first: `feat/<plan-slug>` (derive the slug from the plan filename).
- `--worktree` → create an isolated worktree via `/create_worktree <branch>`; it handles ports, install, and `.env`. Remove with `/remove_worktree` when done (ask first).
- Default (no `--worktree`) → work in the current branch (branching first only if on a default branch). This is "current branch," not a worktree.

## Worktree documentation rule (reuse from story-implementer)

When working in a worktree (path contains `/trees/`), **code changes stay in the worktree**, but **plan/Phase-Summary/hand-off updates go to the source branch root** — the worktree's `.maudel`/plan copies are ephemeral and lost on removal.

## Commits

- **Autonomous:** after a phase passes validation, commit a checkpoint. Only ever commit green code.
- **Collaborative:** commit only when the user asks.
- **Message:** conventional `type(scope): <phase title>` (`feat`/`fix`/`refactor`/`doc`/`chore`), matching repo history. End every commit message with the required trailer:

  ```
  Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>
  ```
- Never `git push` or force-push unless the user explicitly asks.

## Phase Summaries (the durable record)

After each phase, append to the plan's **Phase Summaries** appendix:
- phase title + status (done / blocked),
- files created/modified,
- validation verdict,
- notable decisions,
- anything the next phase needs.

## Implementation summary (`03-Implementation/summary.md`)

At run completion (and incrementally if useful), write a work summary to `.deep-skills/<effort>/03-Implementation/summary.md` (see `references/artifact-structure.md`):
- what was built, at the effort level (the per-phase detail stays in the plan's Phase Summaries — this does not replace them),
- the plan's acceptance/validation criteria **checked off** (or your own checklist if the plan lacks them),
- open deferreds / known gaps.

Create `00-Manifest/manifest.md` if absent and update the Implementation stage's status line. When working in a worktree, this artifact follows the worktree documentation rule above: it goes to the **source branch root**.

## Next-phase hand-off

Write a slim hand-off (`templates/phase-handoff.md`) so a fresh agent can resume cold. Keep it in the plan doc by default (portable). When running inside the maudel project, you may **also** drop a record in `.maudel/handoffs/active/` reusing the `/handoff` convention, so `/resume_handoff` works.

## Resume

To resume an interrupted run: read the plan's Phase Summaries appendix, find the first phase not marked done, and continue from there. The plan is the source of truth — no conversation memory required.
