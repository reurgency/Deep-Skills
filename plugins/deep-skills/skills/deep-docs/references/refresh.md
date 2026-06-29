# Refresh — the stale-map defense, kept current

`--refresh` (natural language: *"refresh the docs," "regenerate the map"*) is how a standing map stays true to code that keeps changing. It re-resolves every recorded anchor against current code, reports drift, **and** detects undocumented additions — then **regenerates only the stale + new subsystems and leaves the rest untouched.** A full regenerate re-surveys everything; refresh does the minimum, which is why it can run often (and why the convergence model below pays off).

Refresh **consumes** the anchor-verify mechanism — it does not redefine it. The per-anchor procedure (symbol grep → confirm within ±5 lines → re-snap on benign drift → `drifted` if the symbol is gone) lives in `anchor-verify.md` and `layering-and-anchors.md`; refresh calls it and acts on its verdicts. Any token figure refresh reports (drift counts are integers, but card/group estimates are not) renders through the labeling rule in `token-budget.md` (`~N est` / `~Nk est`).

## The dual git-free signal

The decision of *what to regenerate* rests on two independent signals, **neither of which requires git.** This is the always-available substrate — when git is reliable it is an accelerator (next section), but refresh is correct and complete without it.

**Signal 1 — anchor re-resolution (does documented code still match?).** Re-run anchor-verify across the existing cards/refs (`anchor-verify.md`): one fresh verifier per card, exhaustive, symbol grep + ±5-line re-snap. A benign line move is re-snapped silently (no regeneration needed — the anchor is still accurate). **Any anchor that comes back `drifted` (symbol gone) marks its subsystem stale.** This catches *changes inside documented code*.

**Signal 2 — file-set diff (did undocumented code appear or vanish?).** Read `alignment_fingerprint.file_set` from `index.json` — the explicit roster of source paths the index was built against (schema in `index-and-coverage.md`). Re-walk the current source tree under the same host-convention filters used at survey time (skip vendored/build dirs; same source-extension set), and diff:

- **A current source file not in the recorded file_set → an undocumented addition.** Attribute it to a boundary: if it falls under an existing documented boundary, that subsystem is marked **new-content stale** (regenerate it so the new file is surveyed and anchored); if it falls outside every documented boundary, it is a **new boundary** (run survey's boundary discovery on it and generate a fresh card).
- **A recorded file no longer present → a deletion.** Its owning subsystem is marked stale (regenerate so the gone file's anchors and prose are dropped).

This catches *changes outside documented code* — exactly the blind spot anchor re-resolution alone has (an anchor can't drift toward a file nobody anchored).

**Regenerate only stale + new.** Union the two signals into a stale-or-new subsystem set. Subsystems with no drifted anchor, no added/deleted file, and no new-boundary overlap are **left untouched** — their cards/refs/index entries are carried forward verbatim. Only the flagged subsystems go back through the pipeline (survey that boundary → layer + anchor → anchor-verify), then the whole set (untouched + regenerated) is re-assembled and published through the staging + atomic-`mv` path in `place-and-report.md`. Refresh never half-writes the map: the same `.in-progress` marker + refuse-if-marker + atomic rename rules apply.

## The git-index alignment check

When git is present and trustworthy, signal 1's exhaustive grep can be skipped in favor of a cheap `git diff` — but only after proving git is trustworthy *for this map*. That proof is the **alignment check** against the stored fingerprint.

Read `alignment_fingerprint` from `index.json` (`index-and-coverage.md` defines every field):

- `indexed_against_commit` — the commit the map was last built against (or `null`).
- `file_set` — the recorded source roster (above).
- `per_subsystem_anchor_state` — `{ <subsystem>: { anchor_count, drifted } }` from the last run.

Then probe current git state and compare:

1. **Is git usable at all?** `git rev-parse` succeeds, the repo is not shallow (`git rev-parse --is-shallow-repository` is `false`), the working tree is clean (`git status --porcelain` empty), and `indexed_against_commit` is non-`null` and reachable in history (`git cat-file -e <sha>`). **If `git` is absent, `git log`/any probe errors, the clone is shallow, the tree is dirty, or the commit is unknown → git is NOT aligned.**
2. **Aligned → take the fast git-diff path.** `git diff --name-only <indexed_against_commit>..HEAD` yields the exact changed/added/deleted files since the map was built. Map each to its boundary, mark those subsystems stale/new, and regenerate only them — skipping the exhaustive anchor re-grep entirely (git already told us what moved). This is the cheap path.
3. **Not aligned → fall back to the dual git-free signal** (previous section), in full. **The git-free path is fully self-sufficient** — it never calls git, so a missing/broken/shallow/dirty git environment, or a brownfield repo with rewritten history, degrades to correct-but-slower, never to incorrect.

Either path ends the same way: regenerate the flagged subsystems, carry the rest forward, **rewrite the fingerprint** (next section), and publish via staging + atomic `mv`.

## Fingerprint lifecycle — written every run, read on the next

The `alignment_fingerprint` is the substrate both paths stand on, so it is **rewritten on every run** — default generation *and* every `--refresh`:

- `indexed_against_commit` ← current `HEAD` SHA if git is usable, else `null`.
- `file_set` ← the current source roster just walked.
- `per_subsystem_anchor_state` ← each subsystem's current `anchor_count` and post-verify `drifted` count (`drifted` should be `0` for every published subsystem, since drift blocks publish; a non-zero value can only appear transiently mid-run).

The **next** `--refresh` reads exactly this. So the fingerprint a run writes is the baseline the following run diffs against — the loop is closed by construction (this is contract row #4 in the plan: deep-docs writes the fingerprint into `index.json`; the next `--refresh` is its runtime reader, same source).

## The convergence model (operational rule)

On a **brownfield repo with unreliable git** (no history, shallow clone, perpetually dirty tree, or no git at all), refresh cannot trust git on day one — so it doesn't. The operational rule:

1. **Round 1** — git is not aligned (brownfield), so refresh uses the **dual git-free signal** and writes a **fresh fingerprint** (current `HEAD` if obtainable else `null`, the full current file_set, current anchor state).
2. **Each subsequent round** — re-check alignment, run the appropriate path, and **write an updated fingerprint** every time.
3. **Promotion to the fast path** — once, across **consecutive rounds**, (a) **no anchor drifts** and (b) **the current file-set matches the fingerprint's `file_set`**, *and* git has become usable (non-shallow, clean, reachable `indexed_against_commit`), refresh treats git as reliable and takes the **fast git-diff path** thereafter. Any later misalignment (a dirty tree, a rewritten history, a deleted `.git`) drops it straight back to the git-free signal — promotion is not permanent, it is re-derived from the fingerprint every run.

The rule is purely mechanical: each run reads the prior fingerprint, picks a path, regenerates the minimum, and writes the next fingerprint. *Why* this sequence converges (the brownfield → reliable-git progression as a teaching point) is rationale and lives only in the `docs/Training/` write-up — it is deliberately **not** restated here.

## Re-entry

Refresh is the incremental half of the re-entry story (`place-and-report.md`): a prior `docs/ai-map/` plus its fingerprint signals "a map already exists," and the user chooses refresh (incremental, this reference) vs. a full regenerate (whole, the default pipeline). Refresh is idempotent — run twice with no code change between, the second run finds zero drift and an unchanged file-set, regenerates nothing, and rewrites an identical fingerprint.
