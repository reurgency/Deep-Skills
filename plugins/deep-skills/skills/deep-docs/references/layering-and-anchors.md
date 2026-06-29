# Layering & anchors — three tiers, every claim anchored

The survey output is laid into **three independently-loadable tiers** so a crawling agent loads only the slice its task needs, and **every claim is anchored** so the map describes the code as it *is*, not as it was intended.

## The three tiers

| Tier | Artifact | Loaded | Contents |
|---|---|---|---|
| **tier-0** | `MAP.md` + `index.json` | **always** (tiny) | One line per subsystem/group: pointer + token-est + load-when. The entry point. |
| **tier-1** | `subsystems/*.md` (one card per boundary) | **on touch** | Purpose, entry points, key types, invariants, data-flow summary, anchors. |
| **tier-2** | `references/*.md` (deep ref) | **on demand** | Cross-layer data-flow traces, non-obvious invariants — the deep dive. |

(Note: tier-2 deep references live under the *generated* `docs/ai-map/references/` — distinct from this skill's own bundled `references/`.)

## When a subsystem earns a tier-2 ref

A tier-2 reference is **earned, not default.** Write one only when the subsystem has:

- a **real cross-layer data flow** worth a hop-by-hop trace (the kind `last-mile.md` walks), or
- a **non-obvious invariant** that a one-line card can't convey safely.

Otherwise the subsystem is **card-only** (tier-1). Record every card-only choice in `coverage.md` (so a reader knows the tier-2 absence was a decision, not an omission).

## The anchor format — `path:line (symbol)`

Every claim in a trusted tier (tier-0/1/2) carries an anchor: a repo-relative `path`, a `line`, and a `symbol`. Rendered in prose as `src/auth/session.ts:88 (SessionStore.resolve)`; stored structurally in `index.json` as `{ "path": ..., "line": ..., "symbol": ... }`. **Symbol-primary**: the symbol is the source of truth, the line is a convenience that may drift.

### Symbol identification without LSP

The default floor an executor can ship (no language server required): the symbol is the **nearest preceding declaration** matching this language-agnostic keyword set, plus the identifier on that line —

```
func | function | def | class | interface | type | struct | impl | method | const | export
```

Per-language refinements (decorators, `pub fn`, `export default`, methods inside a class, etc.) are added on top, but the keyword floor works everywhere. **If no declaration is found**, fall back to a stable textual landmark — the line's trimmed content — plus the line number, and mark the anchor's symbol as that landmark text so verify still has something to re-resolve.

## Re-resolution & drift (the verify contract)

Anchor-verify (`anchor-verify.md`) re-resolves each anchor by **searching the symbol name in the file first**, then confirming the match is **within ±5 lines** of the recorded line:

- **symbol found within ±5 lines** → `accurate`.
- **symbol found, but the line moved** (benign drift) → **re-snap** the recorded line to the symbol's current line; verdict stays `accurate` (re-snapped).
- **symbol absent from the file** → `drifted` (the claim may be stale; blocks publish until regenerated).

Symbol-primary + re-snap absorbs benign edits (insertions above the symbol) without noise, while a genuinely gone symbol still trips the flag. (Content-hash anchoring is a documented future upgrade — rejected for now as noisy.)

## The GENERATED header

**Every emitted file** (`MAP.md`, every `subsystems/*.md`, every tier-2 `references/*.md`, `coverage.md`; `index.json` carries the equivalent via its `_doc` key) opens with:

```
<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
```

Artifacts are 100% machine-owned: regeneration is wholesale overwrite, no merge. Humans annotate elsewhere.
