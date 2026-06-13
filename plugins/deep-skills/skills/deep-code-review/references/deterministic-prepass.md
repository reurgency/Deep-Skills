# Deterministic pre-pass — tools, not agents

Lint, typecheck, and test runs are **deterministic tool work, never an agent's job**. Linting is deliberately **not** an LLM review dimension: compilers and linters are faster, cheaper, and exact at this job, and their output frees the review agents to hunt what tools can't see (last-mile gaps, plan drift, incoherence). Pre-pass results feed the report as findings alongside agent findings.

## Scheduling — before the agent (default) · alongside the fleet (`--multi-agent`)

In the default single-agent flow, run the pre-pass **before** the review agent launches. Under `--multi-agent`, run it **concurrently with the finder fleet**: finders never consume pre-pass output (results join the pipeline at synthesis), so serializing it buys nothing but wall clock — in a measured baseline, a serial inline pre-pass cost ~13 minutes before the first finder launched. Launch the pre-pass scripted/in-background, then launch the finder batch immediately (`references/multi-agent.md` § Stage 0).

## Scripted base-vs-head attribution (`--multi-agent`)

Attributing test failures to the diff is deterministic — script it, don't reason it out per failure:

1. Check out **two worktrees** — the base commit and the head — and run the affected suite in both **concurrently**.
2. **Normalize** both outputs by script: strip timestamps, durations, ports, temp paths, and ordering noise, reducing each run to a sorted failure list.
3. **Diff the failure lists.** Failures present only at head are attributable to the diff (candidate findings); failures present in both are pre-existing — emitted by the script as the one-line "pre-existing, not introduced by this diff" list, never re-derived by an agent. (Baseline: an agent spent ~13 minutes and four-plus suite runs attributing 199 pre-existing failures that one scripted comparison classifies exactly.)

## Discovering the host project's commands

The skill ships with **no hardcoded commands**. Discover what the host project runs, in this order:

1. **package.json scripts** — root first, then workspaces/sub-apps (`workspaces` field, or visible app dirs like `apps/*`, `packages/*`). Look for `lint`, `typecheck`, `tsc`, `test`, `check`, `build` scripts.
2. **CLAUDE.md / agent guidance files** — root and per-app. Projects often document their canonical check commands (and *required* extra checks, e.g. "run test X after editing Y") here; these override generic script guesses.
3. **Tool config files** — `angular.json`, `tsconfig*.json`, `eslint.config.*`, test runner configs — to confirm which tools exist and which tsconfig a typecheck should target.

**Hard rule: NEVER read `.env` or any secrets file during discovery** — not for commands, ports, or anything else. If a needed value can't be found in package.json / angular.json / CLAUDE.md (or equivalents), **ask the user**. No exceptions.

### Example — what discovery finds in *this* repo

The following are **examples of discovery output for this host project, explicitly not skill behavior** — a different project yields different commands:

- `cd apps/ui && bunx tsc --noEmit -p tsconfig.app.json` — UI typecheck (from per-app guidance; angular.json confirms the tsconfig).
- `cd apps/api && bunx tsc --noEmit` — API typecheck.
- `cd apps/api && bun test src/tests/prompt-assembly-evaluation.test.ts` — the prompt-assembly snapshot test, run **only when the diff touches files under `.maudel/pipeline_stages/**`** (a conditional documented in this repo's CLAUDE.md — a textbook case of rule 2 above).

## Run the suite together, not only per-file

**Always include at least one invocation that runs the affected test suite as a single combined run** (e.g. the package's plain `test` script), even when also running targeted per-file tests. Cross-file interference — shared database handles, module-level state, port collisions, global teardown ordering — **only reproduces in the combined run**; a review whose pre-pass ran every test file individually can report green over a suite that fails on a fresh checkout. A combined-run failure that per-file runs don't show is attributable to the diff when the diff introduced the interfering suite or resource, and is **filed as a finding** (`lens: pre-pass`), not merely noted.

## Scope to the diff

The pre-pass exists to judge **this change**, not the whole repo:

- Run checks that cover the **changed files and their import graph**. Whole-project typechecks are fine when that's the only granularity the project offers — but read the results through the diff.
- **Pre-existing failures** in untouched code are *noted in the report* (one line, "pre-existing, not introduced by this diff") — they are **not findings** against the change. In this repo, for example, pre-existing test type errors in the API are known noise.
- A failure is attributable to the diff when it's in a changed file, in a file importing a changed file, or demonstrably triggered by the change (e.g. a contract the diff altered).

## Feeding results into the report

Pre-pass failures attributable to the diff become findings with conventional severities on the series' 1–10 scale:

| Result | Typical severity |
|---|---|
| Test failure in/over changed code | 7–8 (Major) |
| Type error in changed code | ≈ 6 (Minor/Major boundary) |
| Lint issue in changed code | 3–4 (Nit) |

These are starting points — judgment applies (a lint rule guarding a real bug class can rate higher). The full severity scale, tier mapping, and finding shape live in `references/findings-and-severity.md`; pre-pass findings use lens `pre-pass` and the same shape as agent findings.
