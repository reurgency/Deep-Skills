# Learn-signal — the doc-coverage / drift feed (Display-only today)

Anchor-verify (`anchor-verify.md`) and refresh (`refresh.md`) already compute, every run, exactly the data a learning system would want about a codebase: which documented areas have **drifted**, which areas are **undocumented**, and which areas keep **churning** round after round. The learn-signal is that data, captured as a stable machine record so a future reader can consume it. deep-docs does not throw it away — it emits it.

The intended machine reader is the **Deep-Learn Distiller / Pattern Ledger**, which **does not exist yet** (plan Deferred #1; Deep-Learn is design-only). Per the State/Data-Flow Contract (row #7, DLC-001 rule 4), a signal whose runtime reader is unbuilt is **Display-only**: emitting it is honest and in scope, but it is **not** wired to a consumer. **Today the signal surfaces to humans via `coverage.md`** — a one-line pointer there sends a reader to the JSON. When the Distiller lands, it ingests this file unchanged and contract row #7 flips to RESOLVED; the `_doc`-annotation convention (mirrored from `deep-code-review/templates/finding.json`) keeps that bridge thin.

This is a **by-product, not a new mode.** There is **no user-facing flag** — the signal rides the default generation run and every `--refresh`. Nothing the user does turns it on or off.

## Output

- **Path:** `docs/ai-map/learn-signal.json` — written **alongside `coverage.md`**, in the same place stage (`place-and-report.md`), through the same staging + atomic-`mv` path. It is a machine-owned `docs/ai-map/**` artifact and carries the `_doc` annotation in place of a `GENERATED` header comment (it is strict JSON — no `//` comments in the emitted file; only the `_doc` string key, exactly like `index.json`).
- **When:** on the **default generation run AND every `--refresh` run.** A default run is round 1; each subsequent `--refresh` is the next round (see `refresh.md`'s convergence model — the round counter is the same notion refresh iterates on).
- **Schema authority:** `templates/learn-signal.json` (the executor copies that shape). This reference explains where each field comes from.

## Shape and field sourcing

The record has four parts — `generated`, `drift`, `undocumented`, `churn` — each sourced directly from machinery that already ran:

### `generated`
- `indexed_against_commit` — the commit the map was built against (the same value `index.json`'s `generated` block carries), or `null` on a non-git/unusable-git tree.
- `round` — the refresh round. A from-scratch default generation is `round: 1`; each later `--refresh` increments it.

### `drift[]` — from anchor-verify verdicts
One entry per anchor that came back `drifted` (symbol gone — `anchor-verify.md`). Sourced from the verifier verdicts, **not** re-derived:
- `subsystem` — the card/boundary the drifted anchor belongs to.
- `anchor` — the human-readable `path:line (symbol)` string (e.g. `src/auth/session.ts:88 (SessionStore.resolve)`), so the entry is legible in `coverage.md` without cross-referencing `index.json`.
- `verdict` — `"drifted"` (the only verdict that earns a drift entry; `accurate` anchors and benign re-snaps produce none).
- `round` — the round in which this anchor drifted.

Because a `drifted` anchor **blocks publish** (it forces its subsystem to regenerate and re-verify), a *published* map's drift list is normally empty — drift entries describe what a refresh *found and then fixed* in a given round, the signal a learning reader cares about. The honest steady state of a clean map is an **empty `drift` array**.

### `undocumented[]` — from refresh's file-set diff
One entry per source file present in the current tree but absent from the recorded `alignment_fingerprint.file_set` (`refresh.md`, Signal 2 — the file-set diff that catches additions outside documented code):
- `subsystem` — the boundary the new file was attributed to (an existing documented boundary, or a freshly discovered one).
- `path` — the repo-relative path of the undocumented file.
- `first_seen_round` — the round the file-set diff first surfaced it.

A from-scratch default run documents what it surveys, so its `undocumented` list is **empty** — undocumented additions only appear once code lands *after* a map exists and a `--refresh` diffs against the stored file-set.

### `churn[]` — the round counter, accumulated
One entry per subsystem that has been regenerated across rounds, the accumulator the convergence model already iterates on:
- `subsystem` — the boundary.
- `rounds_touched` — how many rounds (across refresh runs) flagged this subsystem stale or new, **accumulated** — a fast-churning area is one that keeps being regenerated. Each round that marks a subsystem stale (drift) or new-content (file-set diff) increments its counter; an untouched subsystem's counter is carried forward unchanged.

Churn is the only field that accumulates across rounds (drift and undocumented are per-round observations); it is the signal a Pattern Ledger would use to spot the areas a team keeps reworking.

## Empty is honest

Every array is **always present even when empty.** A clean map — every anchor verified accurate, nothing undocumented, no accumulated churn — emits empty `drift`/`undocumented`/`churn` arrays, not a missing key. An empty signal is a true signal ("no drift yet"), and a future reader can rely on the keys existing. This is the same honesty discipline as `coverage.md`: silence never implies completeness, and a blank field is stated, not omitted.
