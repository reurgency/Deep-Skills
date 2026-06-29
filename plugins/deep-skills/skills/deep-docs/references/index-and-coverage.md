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
- **`alignment_fingerprint`** — the `--refresh` substrate: `indexed_against_commit`, the `file_set` (the explicit list of source paths the index covers — what `--refresh` diffs against to find undocumented additions), and `per_subsystem_anchor_state`. **Stubbed with nulls/zeros in Phase 1**; fully populated in Phase 3 (`refresh.md`).

External (human-authored) docs appear as `entries` with `trust: "external-unverified"` and no `symbol` anchor — found by the crawler, never trusted as a tier.

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
