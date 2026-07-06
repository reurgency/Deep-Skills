# Commit, branch, and hand-off

## Branch policy

- **Never commit on `main` or `develop`.** If the current branch is a default branch, create a fix branch first: `fix/<effort-slug>` (derive the slug from the effort name).
- Default: work in the current branch (branching first only if on a default branch). This is "current branch," not a worktree.
- `--worktree` ("fix in a worktree") — opt-in isolated-worktree mode; rules in the next section. The default stays current-branch.

## Worktree mode (`--worktree`) — opt-in isolation

**Creating the worktree** — two paths, both fully supported:

- **Native (preferred when the host has one):** the host's worktree command — on Claude Code, `/create_worktree fix/<effort-slug>` (it handles ports, install, and `.env`). Use it whenever it exists.
- **Plain-git fallback (any host):** `git worktree add ../<repo>-fix-<effort-slug> -b fix/<effort-slug>` from the repo root, then run the project's discovered install step in the new tree so containment tests and typechecks can run there.

Either way the worktree's branch is `fix/<effort-slug>` — the same branch the branch policy would have created in place. A missing native command never blocks the mode; degrade to plain git (see `references/host-affordances.md`).

**Artifact-location split — which tree gets which write:**

| Write | Where | Why |
|---|---|---|
| Code changes + reproduction tests (`--reproduce`) | **Worktree branch** | They *are* the fix; they ride the per-cluster fix commits on that branch. |
| `06-Bug-Fix/round-N/{scope.json,fix-summary.md}`, `00-Manifest/manifest.md`, `04-Code-Review/findings.json` status flips | **Source branch root** | Effort artifacts are durable records, not ephemeral worktree state — the worktree's `.deep-skills/` copy is lost on removal. |

A side benefit of the split: re-entry survives worktree removal — `scope.json` and the partial `fix-summary.md` live at the source root, so the resume rules below apply unchanged even if the worktree is gone.

**Removal — ask first, always.** When the run completes (or is abandoned), *offer* removal — never remove silently: `/remove_worktree` where the host has it, else `git worktree remove <path>` (then `git worktree prune`). Never remove a worktree holding uncommitted work or an unmerged branch without explicit confirmation.

**Hand-off endpoint.** At completion the worktree branch is **offered for merge/PR** — offered, not executed: opening a PR or merging follows the same rule as pushing (only when the user explicitly asks). Until merge, the reproduction-test guarantee holds **on the fix branch**: the red→green tests live in that branch's suite and its test runner/CI reads them there; on merge they land in mainline's suite and the guarantee transfers with them. The re-review hand-off below runs against the fix branch's diff — re-reviewing the branch or merging first are both fine; say which one you're pointing the user at.

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
4. **Duplicate-run guard:** intake always excludes `fixed` findings, so re-running on the same effort selects only unresolved work — a double invocation cannot re-fix or double-commit a closed cluster (its summary record exists; its commit exists if the user asked for one).

## Hand-off to re-review

The loop is **review → triage → bug-fix → re-review**. Close the run by pointing at `/deep-code-review`: a re-review **re-diffs** the code (it does not read `fixed` statuses as proof) and appends any new findings under fresh IDs in a fresh review — `findings.json` stays single-copy, statuses flipped in place, nothing overwritten.
