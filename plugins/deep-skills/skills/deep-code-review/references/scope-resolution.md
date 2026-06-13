# Scope resolution — what are we diffing?

Every review starts by resolving exactly what diff is under review. Wrong scope poisons everything downstream, so this step has one overriding rule, stated by the user verbatim:

> "If there's ever any question whatsoever, the skill should raise the question to the user to verify what we're diffing against."

**Ask on ANY ambiguity.** Guessing a base branch is never acceptable.

## The three input modes

| Invocation | Scope |
|---|---|
| `/deep-code-review` (no args) | Current feature branch vs the base it was cut from (detection below) |
| `/deep-code-review PR65` / `#65` / PR URL | That pull request's diff, resolved via `gh` |
| `/deep-code-review src/foo/ bar.ts` | Explicit-paths override — review just these files/dirs (diffed against the detected base, or reviewed as-is if the user says so) |

## No-arg flow: branch vs detected base

1. **Identify the current branch**: `git branch --show-current`. If detached HEAD, ask the user what to review.
2. **Detect the base it was cut from**, in this order:
   1. **PR-declared base** — if a PR exists for the branch: `gh pr view --json baseRefName,number,state`. A declared base is authoritative; use it.
   2. **Merge-base comparison against candidate bases** — no PR is the normal case for pre-PR review, not an error. For each candidate that exists (`develop`, `main`, `master` — local or `origin/`): compute `git merge-base <candidate> HEAD`. Pick the candidate whose merge-base is **closest to HEAD** (i.e. whose history contains the actual branch point — compare merge-base commits; if candidate A's merge-base is an ancestor of candidate B's, B is the closer cut point).
   3. **Ask the user on ANY ambiguity** — two candidates tie, merge-bases are unordered relative to each other, no candidate exists, the branch appears cut from another feature branch, history was rewritten, anything that smells off. Present what was found and ask which base to diff against. Do not pick "probably main."
3. **Build the diff**: `git diff <merge-base>...HEAD` plus, by default, **working tree + staged changes** (see below). `git diff --stat` supplies the file/line counts for the scope line.

### Uncommitted / working-tree changes

On the no-arg flow, the diff **includes working tree + staged changes by default** — a pre-merge review should see what's actually in the directory, not just what's committed. The scope line must say which it is (`working tree included` / `committed only`). If the user wants committed-only, they can say so when the scope line is stated.

## The always-state-resolved-scope rule

**Before launching any review agent or pre-pass command**, print the resolved scope as one line:

```
Diffing feat/x against develop (working tree included) — 14 files, +812/−214
```

In collaborative settings, pause a beat for the user to correct it before proceeding. This line is the contract for the whole review; everything downstream cites it.

## PR-argument parsing

Accept any of: `PR65`, `pr65`, `#65`, `65` (when clearly a PR ref), or a full PR URL (`https://github.com/<owner>/<repo>/pull/65`). Extract the number (and owner/repo from a URL — pass `--repo <owner>/<repo>` if it isn't the current repo) and resolve:

```bash
gh pr view 65 --json baseRefName,headRefName,state,title,additions,deletions,changedFiles
gh pr diff 65            # the diff itself
```

**Checkout vs remote diff:** prefer reviewing via `gh pr diff` + read-only file access at the PR's head when the working tree has unrelated state — don't disturb the user's checkout. Check the branch out only if the review needs to run the deterministic pre-pass against it (tools need a real tree) **and** the user confirms the checkout is okay. State which mode you're in as part of the scope line, e.g. `Reviewing PR #65 (feat/x → develop) via gh pr diff — 9 files, +301/−88`.

## Explicit-paths override

When the user names files/dirs, restrict the review to those paths: diff them against the detected base (default), or review the current contents as-is if the user frames it that way ("review these files"). The scope line names the paths and the comparison mode. Ambiguity about which they meant → ask.

## Error handling

- **Nonexistent PR number** — `gh pr view 99999` exits non-zero with `no pull requests found` / `Could not resolve` on stderr. Report the gh error cleanly and ask the user for the correct PR — do not fall back to guessing a branch.
- **`gh` unavailable or unauthenticated** — `command -v gh` fails, or `gh` errors with an auth message. For the no-arg flow: fall back to the merge-base candidate comparison and **say explicitly that gh was unavailable, so no PR-declared base was consulted**. For a PR-argument flow: there is no fallback — tell the user gh is required to resolve a PR ref and ask how to proceed (e.g. they name the base branch directly).
- **Plain branch with no PR** — the expected pre-PR case, **not an error**. `gh pr view` reporting "no pull requests found for branch" simply routes to the merge-base flow.
- **Empty diff** — base detected but zero changed files (and clean working tree): say so and ask what the user intended rather than reviewing nothing.
