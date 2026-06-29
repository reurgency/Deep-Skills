# Intake & scope — what are we documenting?

Every run starts by resolving exactly **what** to document, **where** the artifacts live, and **what host conventions** apply. Wrong scope poisons everything downstream, so on any ambiguity, **ask the user** — never guess.

## The three input modes

| Invocation | Scope |
|---|---|
| **Effort diff** — inside a deep-* effort (a plan exists / just-implemented work) | Document the subsystems the effort's changes touch; effort mode (writes `07-Docs/` pointer + manifest line). |
| **Named subsystem** — *"document the auth module," `/deep-docs src/auth/`* | Document just that boundary (and its direct collaborators), standalone unless an effort is in flight. |
| **Whole repo** — *"map this codebase," no args* | Survey the whole repo (boundary discovery in `survey.md`), capped by the scale rule below. |

State the resolved scope in one line before launching anything — e.g. `Mapping 4 boundaries (auth, billing, ui, directives) — standalone, output docs/ai-map/`.

## Standalone vs effort resolution

- **A deep-* effort is in play** (a plan/manifest exists for this work, or deep-docs is invoked from an effort flow) → **effort mode**: artifacts still land in `docs/ai-map/` (the canonical, in-repo output), and deep-docs *additionally* writes a `07-Docs/` pointer + sets the manifest's Docs stage line. If the effort name is unknown, ask, **defaulting to the slugified current branch name** (the shared mid-series rule, `references/artifact-structure.md`). Create `00-Manifest/manifest.md` if absent (any deep-* skill owns manifest creation on first write).
- **No effort** (standalone on any repo) → **standalone mode**: write only `docs/ai-map/` (default) or the path override. No `.deep-skills/` artifacts, no manifest.

The output location is `docs/ai-map/` by default, overridable natural-language-first (*"put the map under \<path>"*) — see `place-and-report.md`.

## Host-convention discovery

Discover the host project's source dirs, language, and test layout the way `deep-code-review` does (`references/deterministic-prepass.md`, `references/scope-resolution.md`), in this order:

1. **`package.json`** (root then workspaces / `apps/*` / `packages/*`), **`angular.json`**, `go.mod`, `Cargo.toml`, `pyproject.toml`, etc. — to find source roots, the language, and the workspace shape.
2. **`CLAUDE.md` / agent-guidance files** (root + per-app) — projects often name their source layout and conventions here; these override generic guesses.
3. **Tool config** — `tsconfig*.json`, lint/test-runner configs — to confirm which dirs are source vs generated.

**Hard rule: NEVER read `.env` or any secrets file** during discovery — not for paths, commands, or anything else. If a needed value isn't in the files above, **ask the user**. Optional host helpers may be *used when present* but must degrade gracefully — deep-docs runs on a bare repo with none of them.

## Existing-docs quarantine policy

deep-docs owns `docs/ai-map/` exclusively and **never overwrites or ingests other docs.** Pre-existing human docs (README, design notes, `docs/roadmap/*`, ADRs) are useful for a crawler to *find* — but their prose is **never** absorbed into a trusted tier (tier-0/1/2), because it carries no verifiable anchor.

- Index each useful existing doc in `index.json` as an `entries` row with `trust: "external-unverified"` and **no `symbol` anchor** (a path/line pointer only), labeled `human-authored · not anchor-verified`.
- The crawling agent can follow these pointers but knows they're untrusted.
- `coverage.md` lists **referenced-vs-ingested**: which existing docs were referenced as pointers and confirms none were ingested into a trusted tier.

Laundering external prose into a trusted tier is a guardrail violation — quarantine is the defense.

## Whole-repo scale cap

A whole-repo run can blow past sane fan-out. When boundary discovery (`survey.md`) yields more than the ~12 boundary cap, or the repo is large enough that one-agent-per-boundary would exceed the ≤8 concurrency budget by a wide margin:

- **Scope interactively** — present the discovered top-level areas and ask the user which to document now (vs defer), rather than fanning out across everything silently.
- **Record the cap in `coverage.md`** — a note naming the boundaries documented, the boundaries deferred/grouped, and why, so coverage stays honest about what was *not* mapped.
