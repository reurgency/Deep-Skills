# Place & report — staging, atomic swap, crash-safety, final report

This stage owns the **write path** and the **double-run / crash-safety mechanism**: it is the contract-row-style atomicity guarantee for the Interaction & re-entry surface. The rule is simple — **never half-write `docs/ai-map/`.**

## The staging + atomic-mv mechanism

1. **Generate into a sibling staging dir** — all output (the verified `MAP.md`, `subsystems/*.md`, tier-2 `references/*.md`, `index.json`, `coverage.md`) is written to `docs/.ai-map.staging/`, *never* directly into `docs/ai-map/`.
2. **Write an `.in-progress` marker** at the start of the run, inside the staging dir (e.g. `docs/.ai-map.staging/.in-progress`), recording who/when the run started.
3. **Run anchor-verify against the staged output** (`anchor-verify.md`) — a card with any `drifted`/`over-budget` anchor blocks the swap; it is regenerated + re-verified first.
4. **On success, atomically replace `docs/ai-map/` via `mv` (rename).** Remove the marker, then rename the staging dir into place (replacing the prior `docs/ai-map/` wholesale — generated artifacts are machine-owned, so this is a clean overwrite, no merge). The rename is the atomic commit point: before it, the old map is intact; after it, the new map is fully present. There is never a half-written `docs/ai-map/`.

### Refuse-if-marker (double-run safety)

**If a run finds an existing `.in-progress` marker, it refuses** — printing a user-facing message naming the in-flight run (its start time / id) rather than queueing, interleaving, or clobbering. So a re-trigger while one run is in flight never produces a corrupt or half-merged map.

### Crash safety

A crashed/abandoned run leaves the `.in-progress` marker behind (the `mv` never happened), so `docs/ai-map/` stays the last good map, and the leftover marker is **detectable** — the next run reports the stale marker and asks the user to clear it (rather than silently assuming it owns it). A crash leaves a detectable marker, not a corrupt map.

## Output location

- **Default:** `docs/ai-map/` (standing, in-repo, version-controlled — diffs with PRs).
- **Override (natural-language-first):** *"put the map under \<path>," "write the map to \<path>"* — the staging dir is then a sibling of the override target (`<path>/../.ai-map.staging/` or an equivalent sibling), and the atomic `mv` lands at the override path. The `--output <path>` flag is the convenience form of the same thing.

## Effort mode — `07-Docs/` pointer + manifest line

In effort mode (`intake-and-scope.md`), in addition to writing `docs/ai-map/`:

- Write a **`07-Docs/` pointer** under the effort dir — a small file pointing at the canonical in-repo `docs/ai-map/` (the map itself lives in-repo, not duplicated into the effort; `07-Docs/` holds a pointer to it).
- Set the **manifest's Docs stage line** (`07 Docs` status → complete, linking the pointer), **creating `00-Manifest/manifest.md` if absent** (the shared rule — any deep-* skill owns manifest creation on first write).

> **Intentional lag (Phase 1 ↔ Phase 5):** the `07-Docs/` stage row is added to `references/artifact-structure.md` (all copies, byte-identically) in the series-wiring phase (Phase 5), *not* here — the byte-identical invariant forbids this copy diverging early. So between Phase 1 and Phase 5, deep-docs emits a `07-Docs/` stage its own bundled stage-map doesn't yet list. This is expected and self-consistent once Phase 5 lands.

## Final report

Close the run by printing, to the user:

- the **coverage summary** — boundaries documented, cards/tier-2 counts, anchors verified, drift count;
- the **explicit not-documented list** (from `coverage.md`) — never let silence imply completeness;
- the output location (`docs/ai-map/` or the override), and in effort mode the `07-Docs/` pointer + manifest line.

Progress is reported throughout (boundaries discovered, cards verified, drift count) — the run never goes silent.
