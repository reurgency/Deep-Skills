# Commit, branch, and hand-off

## Branch policy

- **Never commit on `main` or `develop`.** If the current branch is a default branch, create a fix branch first: `fix/<effort-slug>` (derive the slug from the effort name).
- Default: work in the current branch (branching first only if on a default branch).
- `--worktree` — isolated-worktree mode. **Lands in Phase 3**; until then, if requested, say so and proceed on the current branch.

## Prove-before-commit ordering (never reordered)

Per cluster: **apply fix → proof verdict → containment → commit.** A commit happens only when the verdict is `fixed` **and** containment is clean — green-only, no exceptions. `regressed` reverts immediately; `unproven` at the attempt cap reverts + blocker report. Broken or unproven code is never committed, in either mode.

## Commits — one per proven cluster

- **Autonomous:** commit each cluster as it closes green. **Collaborative:** commit only when the user asks.
- **Message:** `fix(<scope>): <cause> — resolves CR-00X, CR-00Y` — `<scope>` from the affected subsystem, `<cause>` the *confirmed* root cause (not the symptom), and every resolved defect id listed. End with the host-aware attribution trailer (`Co-Authored-By: <agent-name> <email>` — per-host defaults in `references/host-affordances.md`; on Claude Code, `Co-Authored-By: Claude <noreply@anthropic.com>`).
- Reverts of failed attempts use `git revert`/reset of *uncommitted* work — failed attempts are never committed, so reverting is a working-tree operation.
- Never `git push` or force-push unless the user explicitly asks.

## Fix summary (the durable record) — incremental appends

`06-Bug-Fix/round-N/fix-summary.md` gets **one record per cluster, appended as each cluster closes** (`templates/fix-summary.md`) — fixed, skipped, or blocked. Never batch records to run-end: the incremental file is half of the re-entry story (the other half is `scope.json`). At run completion, update `00-Manifest/manifest.md` — create it if absent — setting the `06 Bug Fix` row's status and its artifact link to the literal `[06-Bug-Fix/](../06-Bug-Fix/)`.

## Re-entry & resume

The skill is a resumable multi-round flow. On every start:

1. **Detect prior rounds:** scan `06-Bug-Fix/round-*/`. **Round numbering: next round = max existing round + 1.** Rounds are **append-only** — never rewrite or renumber a prior round's artifacts.
2. **Re-entry check:** if the latest round's `scope.json` lists clusters not yet closed in that round's `fix-summary.md`, offer three options: **resume** the round / start a **new round** / **abort**.
3. **Resume** = `scope.json` minus defects already `fixed` in `findings.json` — this recovers scoped-in `open` findings and synthesized `BF-*` defects that statuses alone cannot reconstruct. A crashed run leaves at worst one unproven cluster's edits in the working tree; the resumed cluster is **re-diagnosed from scratch** (its agent's state is gone — evidence + the leftover diff are re-read), counting as attempt 1 of the cap.
4. **Duplicate-run guard:** intake always excludes `fixed` findings, so re-running on the same effort selects only unresolved work — a double invocation cannot re-fix or double-commit a closed cluster (its commit exists; its summary record exists).

## Hand-off to re-review

The loop is **review → triage → bug-fix → re-review**. Close the run by pointing at `/deep-code-review`: a re-review **re-diffs** the code (it does not read `fixed` statuses as proof) and appends any new findings under fresh IDs in a fresh review — `findings.json` stays single-copy, statuses flipped in place, nothing overwritten.
