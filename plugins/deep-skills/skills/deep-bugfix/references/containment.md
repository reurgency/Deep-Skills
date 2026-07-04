# Containment — the blast radius of fixing working code

Bug fixes modify **working** code; the risk is regressing the things that depended on it. Containment answers the question proof-of-fix doesn't: *did this fix break anything that was fine?* It runs after the proof verdict and before any commit (prove-before-commit ordering, `references/commit-and-handoff.md`). Containment is mechanical work — run it on the cheapest tier per `references/model-map.md`, or as plain scripted checks where no agent is needed.

## The default: 1 hop + full typecheck

1. **Extract the changed symbols from the diff** — every function, method, class, exported constant, type, route, or config key the fix modified (added lines' enclosing declarations; deleted/renamed symbols count too).
2. **Discover direct dependents (1 hop).** Prefer the precise tool the host offers, degrading gracefully:
   - **LSP / host code index** (find-references) when present — exact caller lists.
   - **Degrade to grep + import-walk:** grep the repo for each symbol name; walk files importing the changed modules. Over-matching is fine — containment errs inclusive.
   The dependent set = files that call, import, subscribe to, or route through a changed symbol.
3. **Run the dependents' tests** — the test files covering the dependent set (their own tests plus any suite the host project's guidance names for those areas). Include at least one combined run of the affected suite where the project has one — cross-file interference only reproduces in the combined run.
4. **Run a full typecheck** — cheap, and it transitively catches signature breaks beyond any hop limit.

## Verdict: block only on NEW failures

Compare against the pre-fix state (run or reconstruct the baseline when in doubt): failures that already existed are noted as pre-existing noise, **not** containment failures. A **new** failure in the dependent set or the typecheck ⇒ containment fails — treat it as evidence for the proof stage's `regressed` handling: **revert**, and the re-attempt (if the cap allows) starts from clean. Never commit over a failed containment; never "fix forward" a regression inside the same cluster attempt.

## Escalation: exported/shared symbol ⇒ 2 hops

When any changed symbol is **exported across a package/app boundary** (a shared types package, a published module, a symbol imported by another workspace/app), widen discovery to **2 hops** — the dependents' dependents — before running tests. The user can also demand this at any time (`/widen` / "widen the containment"). One escalation level is the ceiling: beyond 2 hops, the full typecheck plus the project's combined suite is the practical net.

## Host-command discovery

The skill ships **no hardcoded commands**. Discover what the host project runs, in this order:

1. **package.json scripts** — root first, then workspaces/sub-apps (`workspaces` field, or visible `apps/*`, `packages/*`). Look for `test`, `typecheck`, `tsc`, `lint`, `check`, `build`.
2. **CLAUDE.md / agent guidance files** — root and per-app; projects document canonical check commands (and conditional extras — "run test X after editing Y") here. These override generic script guesses.
3. **Tool config files** — `tsconfig*.json`, `angular.json`, test-runner configs — to confirm which tools exist and which tsconfig a typecheck targets.

**Hard rule: NEVER read `.env` or any secrets file during discovery** — not for commands, ports, or anything else. A needed value not found in the sources above ⇒ ask the user. Non-JS ecosystems follow the same ladder with their manifests (pyproject.toml, Cargo.toml, go.mod, Makefile).
