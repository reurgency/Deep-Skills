# Validation

Validate every phase before committing or gating. Reuse the **`test-runner`** skill for tests. Scope validation to the **changed files and their imports** — pre-existing errors elsewhere are expected noise; block only on **new** failures introduced by the phase.

## Commands (monorepo)

Run per-app binaries with **`bunx` from inside the app directory**. Never run `npx tsc` (or `ng`, `vitest`) from the repo root — there is no root TypeScript install, so `npx` fetches a placeholder `tsc` that prints a stub message and hangs until timeout.

| Check | Command |
|---|---|
| UI typecheck | `cd apps/ui && bunx tsc --noEmit -p tsconfig.app.json` |
| UI build (heavier; when the phase warrants) | `cd apps/ui && bunx ng build` |
| API typecheck | `cd apps/api && bunx tsc --noEmit` |
| API tests | via `test-runner` pattern, e.g. `cd apps/api && bun test <path>` wrapped in the skill's `execSync` capture |

## Pipeline-prompt snapshot test (codebase-aware trigger)

If the phase changed anything under `.maudel/pipeline_stages/**`, any `.maudel/agents/**/AGENT.md`, or `.maudel/skills/**/SKILL.md` (prompt-assembly inputs), **run the prompt regression/snapshot test**:

```
cd apps/api && bun test src/tests/prompt-assembly-evaluation.test.ts
```

(Per root `CLAUDE.md` — it asserts zone structure/token budgets and writes assembled-prompt snapshots for diff review.)

## Test output capture

Use `test-runner`'s `node -e execSync` wrapper with `CI=true` — bun's TTY output doesn't survive plain shell redirection. Treat the run as passed only on an explicit `SUCCESS` marker; on `FAILED`, read `stderr` for the real failure.

## Verdict

A phase passes when: typecheck of changed apps is clean (no new errors), relevant tests are green, and (if applicable) the snapshot test passes. Behavioral validation (run the app / Playwright) only when the phase's acceptance criteria call for it. Record the verdict in the phase summary.
