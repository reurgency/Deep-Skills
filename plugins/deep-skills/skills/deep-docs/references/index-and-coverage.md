# Index & coverage — the machine index and the honesty artifact

Two artifacts come out of this stage: `index.json` (the machine index the crawling agent reads) and `coverage.md` (the doc-coverage honesty artifact). They answer different questions — the index is *how to navigate*, coverage is *what was and wasn't mapped*.

## `index.json` — the machine index

The concrete authority on shape is `templates/index.json` — the executor copies that shape verbatim (it mirrors `deep-code-review/templates/finding.json`'s `_doc`-annotation convention: `_`-prefixed keys are documentation and are omitted from a real emitted file). This reference explains the fields:

- **`_doc`** — a one-line pointer to this reference; kept in the emitted file (the `_`-prefixed human breadcrumb, the JSON analogue of the GENERATED header).
- **`generated`** — `indexed_against_commit` (the git SHA the index was built against, or `null` on a non-git/dirty tree) and `tool_version` (the deep-docs version).
- **`entries[]`** — one row per documented concept/symbol:
  - **`concept`** — the subsystem or concept/symbol name a crawler searches by.
  - **`doc`** — the relative path to the tier-1 card or tier-2 ref (e.g. `subsystems/auth.md`).
  - **`anchor`** — `{ path, line, symbol }`, the `path:line (symbol)` anchor (symbol-primary; see `layering-and-anchors.md`). **Omitted/`symbol`-less for external docs** (see trust below).
  - **`token_est`** — see token-est ownership below.
  - **`load_when`** — the trigger phrase telling a crawler when this doc is worth loading (e.g. `working inside auth/session`).
  - **`trust`** — `"anchored"` for a deep-docs-generated, anchor-verified entry; `"external-unverified"` for a quarantined existing human doc (pointer only, no `symbol`; see `intake-and-scope.md`).
- **`alignment_fingerprint`** — the `--refresh` substrate (full schema below). **Stubbed with nulls/zeros/boundary-roots in Phase 1**; rewritten with real values on every run from Phase 3 on (`refresh.md`).

External (human-authored) docs appear as `entries` with `trust: "external-unverified"` and no `symbol` anchor — found by the crawler, never trusted as a tier.

## The alignment-fingerprint schema

`alignment_fingerprint` is the state `--refresh` stands on: every run **writes** it, and the **next** `--refresh` **reads** it to decide what changed (this is the plan's State/Data-Flow contract row #4 — same `index.json` is writer and reader). It has exactly three fields:

- **`indexed_against_commit`** — the git commit `HEAD` resolved to when the map was built, or `null` when git is unusable (non-git tree, shallow clone, dirty working tree, or `git` absent/erroring). `--refresh`'s git-index alignment check compares this against current `git log`/`HEAD`; a `null` here forces the git-free path. (This mirrors `generated.indexed_against_commit`; the fingerprint copy is the one `--refresh` aligns against.)
- **`file_set`** — the **explicit stored roster of source paths the index covers**, and the exact list `--refresh` diffs the current source tree against to find undocumented additions and deletions. The authoritative fully-populated form (from Phase 3) is the **concrete source-file list** (every documented file path), which lets refresh detect file-level additions/deletions precisely. A **coarser boundary-root form** (one directory root per documented boundary, e.g. `src/auth/`) is the acceptable Phase-1 stub — the committed dogfood carries this form (the six boundary dirs). When refresh finds only roots, it cannot diff at file precision, so round 1 expands each root to its current source files, treats that as the baseline, and writes the concrete file list back (the convergence model's "round 1 writes a fresh fingerprint," `refresh.md`). Walk/diff under the same host-convention filters survey used (skip vendored/build dirs; same source-extension set).
- **`per_subsystem_anchor_state`** — a map `{ <subsystem>: { anchor_count, drifted } }`, one entry per documented subsystem. **`anchor_count`** is the number of anchors in that subsystem's card (+ its tier-2 ref, if any); **`drifted`** is how many came back `drifted` from the last anchor-verify. Because a drifted anchor blocks publish (`anchor-verify.md`), every *published* subsystem's `drifted` is `0` — a non-zero value can only exist transiently mid-run. `--refresh` reads `anchor_count` to size the re-verification fan-out and uses the per-subsystem keys to know which subsystems exist to compare against.

**How each run rewrites it.** On every default generation and every `--refresh`, after anchor-verify passes and before the atomic `mv`: set `indexed_against_commit` to the current `HEAD` (or `null` if git is unusable), set `file_set` to the source roster just walked, and rebuild `per_subsystem_anchor_state` from the published cards' anchor counts (with `drifted: 0`). The fingerprint a run writes is precisely the baseline the next `--refresh` diffs against — see `refresh.md` for the read side and the convergence model.

## Token-est ownership (Phase 1 vs Phase 2)

**Phase 1 *populates* `token_est`** with the raw `ceil(chars/4)` value, inline, so the spine emits a usable estimate from day one. Compute it per doc: `ceil(character_count / 4)`, stored as an integer.

**Phase 2 owns the *formal* treatment** — the "estimate, not exact" labeling rule (every surface showing a count marks it an estimate, e.g. `~450 est`), the tier-0 hard ceiling, and grouped overflow. **Phase 1 does not gate on a ceiling** — it emits the number; it does not enforce a budget. (The `over-budget` verdict value exists in `anchor-verify.md` so the contract is complete, but the ceiling it compares against is Phase 2's.)

## `coverage.md` — the doc-coverage honesty artifact

`coverage.md` is **distinct from the State/Data-Flow contract**: coverage is *doc-coverage* honesty (what got documented and what didn't); the contract is the skill's own state writes. `coverage.md` records:

- **Documented** — the boundaries that got a card (and which earned a tier-2 ref).
- **Not documented + why** — boundaries skipped or deferred, with the reason (scale cap, out of scope, no public surface, etc.). This is the explicit not-documented list the final report surfaces.
- **Card-only** — subsystems that got a card but no tier-2 ref, so the absence is a recorded decision (`layering-and-anchors.md`).
- **Referenced-vs-ingested** — the existing human docs indexed as `external-unverified` pointers, confirming none were ingested into a trusted tier (the quarantine audit, `intake-and-scope.md`).
- **Boundary decisions** — every split/merge/cap/"other"-grouping from `survey.md`.
- **Drift** — any `drifted` anchors surfaced by anchor-verify (which blocked publish until regenerated).
- **Capped boundaries** — when a whole-repo run was interactively scoped, what was deferred and why.

Coverage is the artifact that makes the map *honest about its own gaps* — a reader never mistakes silence for completeness.
