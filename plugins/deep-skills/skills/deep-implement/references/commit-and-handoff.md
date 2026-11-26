# Commit, branch, and hand-off

## Branch policy

- **Never commit on `main` or `develop`.** If the current branch is a default branch, create a feature branch first: `feat/<plan-slug>` (derive the slug from the plan filename).
- `--worktree` → create an isolated worktree (see *Worktree mode* below).
- Default (no `--worktree`) → work in the current branch (branching first only if on a default branch). This is "current branch," not a worktree.

## Worktree mode (`--worktree`)

**Creating the worktree** - two paths, both fully supported:

- **Native (preferred when the host has one):** a project- or host-provided worktree command (e.g. a `/create_worktree <branch>` command that also handles ports, install, and `.env`). Use it whenever it exists.
- **Plain-git fallback (any host):** `git worktree add ../<repo>-<plan-slug> -b feat/<plan-slug>` from the repo root, then run the project's discovered install step (`references/validation.md`) in the new tree so validation can run there.

A missing native command never blocks the mode; degrade to plain git (see `references/host-affordances.md`).

**Worktree documentation rule:** when working in a worktree, **code changes stay in the worktree**, but **plan/Phase-Summary/hand-off updates go to the source branch root** - the worktree's plan and `.deep-skills/` copies are ephemeral and lost on removal.

**Removal - ask first, always.** When the run completes (or is abandoned), *offer* removal - never remove silently: the host's removal command where it has one, else `git worktree remove <path>` (then `git worktree prune`). Never remove a worktree holding uncommitted work or an unmerged branch without explicit confirmation.

## Commits

- **Autonomous:** after a phase passes validation, commit a checkpoint. Only ever commit green code.
- **Collaborative:** commit only when the user asks.
- **Message:** conventional `type(scope): <phase title>` (`feat`/`fix`/`refactor`/`doc`/`chore`), matching repo history. End every commit message with the host-aware attribution trailer (`Co-Authored-By: <agent-name> <email>` - per-host defaults in `references/host-affordances.md`; on Claude Code, `Co-Authored-By: Claude <noreply@anthropic.com>`):

  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
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
- what was built, at the effort level (the per-phase detail stays in the plan's Phase Summaries - this does not replace them),
- the plan's acceptance/validation criteria **checked off** (or your own checklist if the plan lacks them),
- open deferreds / known gaps.

Create `00-Manifest/manifest.md` if absent and update the Implementation stage's status line. When working in a worktree, this artifact follows the worktree documentation rule above: it goes to the **source branch root**.

## Next-phase hand-off

Write a slim hand-off (`templates/phase-handoff.md`) so a fresh agent can resume cold. Keep it in the plan doc - the plan is the single portable resume point. If the host project has its own hand-off convention (documented in its CLAUDE.md), you may **also** write a record there, but the plan copy is always written.

## Resume

To resume an interrupted run: read the plan's Phase Summaries appendix, find the first phase not marked done, and continue from there. The plan is the source of truth - no conversation memory required.
