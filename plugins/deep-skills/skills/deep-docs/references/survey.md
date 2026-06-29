# Survey — boundary discovery + fan-out

The survey turns a resolved scope into a set of **boundaries** (subsystems), then sends one fresh read-only agent per boundary to discover what each one is. Adapts `deep-code-review/references/multi-agent.md` (Stage 0 scripted setup + Stage A finder fleet) for documentation instead of defect-hunting.

## Boundary discovery — directory-primary + heuristic refine

Directories are the portable, language-agnostic first cut. Import-graph / LSP discovery is richer but non-portable — deferred as an opt-in layer; directory-primary is the standalone-on-any-repo default. Discover boundaries by script, then refine with these concrete heuristics (a reference may tune them, but ship these so an executor isn't guessing):

1. **Skip vendored/build/generated dirs** — `node_modules`, `dist`, `build`, `out`, `.git`, `vendor`, `target`, `.next`, `coverage`, `__pycache__`, and anything the host config marks generated. These are never boundaries.
2. **Split a big dir by entry-point.** A source dir with **>50 source files** is too coarse for one card — split it by entry-point. Entry-point heuristic (no LSP): `index.*` / `main.*` / `mod.rs` / `__init__.py`, the `main` field of a local `package.json`/`go.mod`, or the file with the most exported symbols. Each entry-point subtree becomes its own boundary.
3. **Merge tiny siblings.** Sibling dirs with **<3 source files each** merge into their parent boundary rather than each becoming a thin card.
4. **Cap total boundaries at ~12** per repo. Beyond the cap, group the smallest remaining boundaries into a single **"other"** boundary. (This is the *boundary* cap — distinct from the agent-concurrency cap below.)
5. **Record every decision in `coverage.md`** — every split, merge, cap, and "other"-grouping, so the boundary set is auditable and coverage stays honest.

For whole-repo runs that still exceed the cap, fall back to interactive scoping (`intake-and-scope.md` § Whole-repo scale cap).

## Fan-out — one fresh agent per boundary

- **One fresh read-only agent per boundary**, **≤8 concurrent** (the agent-concurrency cap — *not* the ~12 boundary cap; boundaries beyond 8 run in successive batches). Read-only is what makes wide parallelism safe.
- **Each agent is blind to the others** — briefed only with its own slice (the boundary's file list + the resolved host conventions + the stated scope line), never the whole repo's docs, never another agent's output, never an implementation transcript.
- **Each agent discovers, for its boundary:**
  - **entry points** — how code enters this subsystem (public functions, routes, CLI commands, exported API);
  - **public surface** — what the rest of the system calls;
  - **key types** — the central data structures / interfaces / models;
  - **invariants** — the rules the subsystem assumes and enforces;
  - **data flows** — how data moves through it, and across its seams to other subsystems.
- **Every discovered claim carries a `path:line (symbol)` anchor** (the format and symbol-identification rule live in `layering-and-anchors.md`). An un-anchored claim is dropped — it can't enter a trusted tier.

## Scripted setup (Stage 0, adapted)

Do the deterministic work by script before launching agents (the **never-read-`.env`** rule applies to scripts too):

- Enumerate the boundary file lists and per-boundary file counts (drives the split/merge heuristics).
- Pre-harvest the cheap facts each agent brief needs: the boundary's exported-symbol list (`grep` for the keyword set in `layering-and-anchors.md`), entry-point candidates, and any local config (`package.json`/`go.mod` `main`). Inject these into the agent brief so it doesn't spend its first calls re-finding them.

## Tier-2 chain-traces

When a boundary has a real **cross-layer data flow** worth a tier-2 reference (the earning rule is in `layering-and-anchors.md`), the survey agent traces it **hop-by-hop with evidence per hop**, reusing `deep-code-review/references/last-mile.md` methodology: enumerate the behavior, walk the full chain (UI/entry → handler → service → persistence → response → effect, adapted to the architecture), and record a `path:line (symbol)` anchor at every hop. A hop that can't be evidenced is a gap, noted in `coverage.md` — never papered over with intent prose.

## Progress feedback

The survey fan-out is long-running. Report progress as boundaries are discovered and agents return (e.g. `Surveyed 6/9 boundaries`), so the run never reads as "it did nothing."
