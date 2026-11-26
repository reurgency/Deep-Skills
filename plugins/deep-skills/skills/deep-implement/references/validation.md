# Validation

Validate every phase before committing or gating. Scope validation to the **changed files and their imports** - pre-existing errors elsewhere are expected noise; block only on **new** failures introduced by the phase.

## Host-command discovery

The skill ships **no hardcoded commands**. Discover what the host project runs - once per run, reused for every phase - in this order:

1. **Manifest scripts** - `package.json` root first, then workspaces/sub-apps (`workspaces` field, or visible `apps/*`, `packages/*`). Look for `typecheck`, `tsc`, `test`, `lint`, `check`, `build`. Non-JS ecosystems follow the same ladder with their manifests (`pyproject.toml`, `Cargo.toml`, `go.mod`, `Makefile`).
2. **CLAUDE.md / agent guidance files** - root and per-app. Projects document their canonical check commands here, including **conditional extras** ("run test X after editing Y", "run binaries from the app dir, never from root"). These override generic script guesses, and conditional extras become phase triggers (below).
3. **Tool config files** - `tsconfig*.json`, `angular.json`, `eslint.config.*`, test-runner configs - to confirm which tools exist, which tsconfig a typecheck targets, and which package manager/runner invokes them (match the lockfile: `bun.lock` → `bunx`/`bun test`, `pnpm-lock.yaml` → `pnpm`, etc.).

**Hard rule: NEVER read `.env` or any secrets file during discovery** - not for commands, ports, or anything else. A needed command not found in the sources above ⇒ ask the user (collaborative) or record it as a discovery gap in the phase summary (autonomous) - never silently skip the check.

Run tools from where the project expects them (often the app/package directory). Don't reach for `npx <tool>` from a root that has no install of it - `npx` may fetch an unrelated placeholder package and hang.

### Example - discovery output for one host project

The following is **an example of what discovery finds in one Angular + Bun monorepo, explicitly not skill behavior** - a different project yields different commands:

- `cd apps/ui && bunx tsc --noEmit -p tsconfig.app.json` - UI typecheck (per-app guidance; `angular.json` confirms the tsconfig).
- `cd apps/api && bunx tsc --noEmit` - API typecheck.
- `cd apps/api && bun test <path>` - targeted API tests.
- `cd apps/api && bun test src/tests/prompt-assembly-evaluation.test.ts` - a snapshot test that project's CLAUDE.md requires **only when** prompt-assembly inputs change: a textbook conditional extra (rule 2).

## Per-phase checks

| Check | When |
|---|---|
| Typecheck / compile of each changed app or package | Every phase |
| Targeted tests for changed files | Every phase that touches code with tests |
| Combined run of the affected suite | Every phase that touches code with tests (see below) |
| Build | When the phase warrants it (build config, routing, bundling, new entry points) |
| Lint | When the project's guidance treats lint as a gate |
| Conditional extras from rule 2 | When the phase touches the paths the guidance names |

**Run the suite together, not only per-file.** Always include at least one invocation that runs the affected suite as a single combined run (e.g. the package's plain `test` script), even when also running targeted per-file tests. Cross-file interference - shared database handles, module-level state, port collisions, global teardown ordering - only reproduces in the combined run.

## Test output capture

Run tests non-interactively (`CI=true`, or the runner's non-TTY/reporter flag) so output survives capture - some runners' TTY output doesn't survive plain shell redirection. Judge the run by its **exit code** and the runner's own summary line, not by skimming output; on failure, read stderr for the real cause. A run whose result you couldn't observe is not a pass.

## Verdict

A phase passes when: typecheck/compile of changed apps is clean (no new errors), relevant tests are green in both the targeted and combined runs, and every triggered conditional extra passes. Behavioral validation (run the app / Playwright) only when the phase's acceptance criteria call for it. Record the verdict in the phase summary, **naming the commands actually run** - and any check that couldn't be discovered or run, so a missing check never reads as a passed one.

**Green ≠ verified for external shapes.** If the phase produces a payload an external consumer reads (CLI/binary, third-party API, SDK, AI harness/model endpoint), a clean typecheck and green tests do **not** confirm the consumer accepts that shape - repo checks aren't ground truth for an out-of-repo contract (see the construction rules in `references/phase-execution.md`). When the phase's shape was verified against ground truth (sibling client, schema/docs, real probe), note it in the summary; when it wasn't reachable, record the shape as **unverified** rather than letting green imply confirmation.
