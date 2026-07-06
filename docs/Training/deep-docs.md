# Training: `/deep-docs`

> Part of the [Deep Skills Training Program](README.md). Skill 6 of 6 — **orient**.
> Source: [`plugins/deep-skills/skills/deep-docs/SKILL.md`](../../plugins/deep-skills/skills/deep-docs/SKILL.md)
> Design rationale: [`design-rationale/deep-docs.md`](design-rationale/deep-docs.md)

`/deep-docs` produces **context-window-aware documentation of what's been built** — a standing,
queryable map structured for **progressive disclosure**, where every claim is anchored to
`file:line (symbol)` and adversarially verified by fresh agents. **Documents only — it never
edits application source.**

---

## Learning objectives

By the end you can:

1. Run deep-docs after a build — or standalone on any repo — and produce a `docs/ai-map/` an
   agent can crawl under a token budget.
2. Explain the **three independently-loadable tiers** and why tier-0 must stay tiny.
3. Understand why **every claim is anchored** to `path:line (symbol)` and why an unverified
   anchor blocks publish.
4. Use **refresh** to keep the map current without regenerating the whole thing.
5. Recognize the boundary: deep-docs **documents, never decides**, and changes no source.

## Prerequisites

The whole pipeline — especially [`/deep-code-review`](deep-code-review.md) (same fresh-agent
adversarial verification, evidence/anchor discipline) and the
[shared mental model](README.md#the-shared-mental-model-read-this-before-any-skill-page)’s
*fresh-agent resumability* and *last mile + evidence*.

---

## Mental model

deep-docs is the series' missing **orientation layer**. Implement's hand-off notes are
change-scoped and discarded; code-review emits defects, not orientation; conventional
generators dump one exhaustive human altitude with **no notion of "load only this layer."**
Your product is a *standing, queryable map* — built so an agent on a token budget pays only for
the slice its task needs.

Its signature failure mode is the **dual failure of AI-facing docs**:

- the **stale map** — docs that describe intent, not the code as it is — defended by
  `path:line (symbol)` **anchoring** + always-on **anchor-verify**;
- the **bloated dump** — docs that must be loaded whole — defended by **three-tier layering**
  and a **hard tier-0 token ceiling** (~2,000 est) with grouped overflow.

Every token figure is an **estimate** (`ceil(chars/4)`), labeled as such on every surface
(`~450 est`, `~1.2k est`) — never presented as exact.

---

## The three tiers

```
docs/ai-map/
  tier-0  MAP.md + index.json   ← always loaded · tiny · hard ceiling (~2,000 est)
  tier-1  subsystem cards       ← loaded on touch · one per boundary
  tier-2  deep references       ← on demand · earned by real cross-layer flow / non-obvious invariant
```

A crawling agent reads the always-loaded index, then pulls only the cards and references its
task actually touches.

---

## Curriculum

### Stage 1 — Intake & scope
Resolve the input mode (effort diff / named subsystem / whole repo), standalone-vs-effort home,
and host conventions (source dirs, language, test layout) — **never reading `.env`/secrets**.
Apply the existing-docs **quarantine**: index human docs as `human-authored · not
anchor-verified`; never ingest their prose. State the resolved scope in one line before
launching anything. (`references/intake-and-scope.md`)

### Stage 2 — Survey (fan-out per boundary)
Discover boundaries **directory-primary + heuristic refine** (skip vendored/build dirs; split
huge dirs by entry-point; merge tiny siblings; cap ~12 boundaries). Launch **one fresh
read-only agent per boundary** (≤8 concurrent), each blind to the others, to discover entry
points, public surface, key types, invariants, and data flows. Every split/merge/cap decision
is recorded in `coverage.md`. (`references/survey.md`)

### Stage 3 — Three-tier layering with anchors
Lay the survey output into the three tiers. Every claim carries a `path:line (symbol)` anchor;
the symbol is the nearest preceding declaration. Every emitted file carries the `GENERATED — do
not hand-edit; regenerate overwrites` header. (`references/layering-and-anchors.md`)

### Stage 4 — Anchor-verify (always-on, fan-out per card)
Launch **one fresh adversarial verifier per card** (≤8 concurrent) that re-resolves **every**
anchor by symbol grep and returns `accurate | drifted | over-budget`. No sampling. **A card
with any drifted/over-budget anchor blocks publish** — the doc-analogue of an unresolved
State/Data-Flow contract row. (`references/anchor-verify.md`)

> **Anchoring is symbol-primary:** verify re-resolves by symbol first and **re-snaps the line
> number** if it drifted (benign); it flags `drifted` only if the **symbol is gone**. A raw
> line number is fragile; a content hash is too sensitive. Symbol-primary is the right
> sensitivity for "does the thing this doc describes still exist?"

### Stage 5 — Index & coverage
Emit `index.json` (concept/symbol → doc + anchor + token-est + load-when + trust), the machine
index the crawling agent reads. Hold tier-0 under its ceiling, switching to **grouped overflow**
(group by top-level area with subtotals + load-when) rather than truncating. Emit `coverage.md`
— the honesty artifact (documented / not-documented + why / card-only / referenced-vs-ingested
/ capped boundaries) — plus `learn-signal.json`, the forward-dependent drift feed (Display-only
today). (`references/index-and-coverage.md`, `references/token-budget.md`)

### Stage 6 — Place (staging + atomic mv) & report
Generate into the sibling staging dir `docs/.ai-map.staging/` with an `.in-progress` marker; on
success (verify passed) atomically replace `docs/ai-map/` via `mv`. A run that finds an existing
marker **refuses**. Effort mode also writes a `07-Docs/` pointer + the manifest line. Close with
the coverage summary and the explicit not-documented list. (`references/place-and-report.md`)

---

## Flags (natural-language-first)

Every flag is **natural-language-first** — the plain-language trigger is the primary path (users
on Copilot/Codex have no slash-commands or CLI flags); the `--flag` is a convenience on top.

| Trigger | Say | What it does |
|---|---|---|
| *(default)* | "map this codebase," "document what's built" | Runs the full default-mode pipeline above. |
| put under `<path>` | "write the map to `docs/foo`" | Overrides the default `docs/ai-map/` output location. |
| `--refresh` | "refresh the docs," "regenerate the map" | Re-resolves anchors **and** diffs the file-set against the stored fingerprint, then regenerates only the stale + new subsystems. |

> **Refresh uses a dual git-free signal:** (1) re-resolve all anchors → report drift; (2) diff
> the current source file-set against `index.json` → catch undocumented additions. Git is an
> optional accelerator, used **only when** proven reliable for this map; on any dirty / non-git
> / shallow / brownfield tree the git-free signal drives the decision. A stored
> `alignment_fingerprint` drives convergence — once anchors stop drifting and the file-set
> matches across rounds, refresh promotes to the fast git-diff path (and drops back if git
> stops aligning).

---

## Directive cards

At the start of every run, execute `scripts/load-active-cards.sh deep-docs` and treat each
printed directive as a **hard requirement** for that run. deep-docs is a directive-card
**consumer**, not an owner. If it prints "no active directive cards," proceed normally. Never
edit a card or the skill to disable one — toggle it.

---

## Hands-on exercises

1. **Standalone map:** run deep-docs on a repo you didn't write; confirm tier-0 stays under its
   ceiling and read the `coverage.md` not-documented list.
2. **Anchor drill:** open one subsystem card and verify by hand that each `path:line (symbol)`
   resolves — then move a function and re-run refresh to watch the line re-snap.
3. **Quarantine check:** point deep-docs at a repo with a rich README; confirm the README is
   indexed as `not anchor-verified` and its prose was **not** absorbed into a tier.
4. **Overflow:** run it on a repo with many subsystems and inspect the grouped tier-0 overflow
   (no silent truncation).
5. **Refresh:** add a new file, run `--refresh`, and confirm only the stale + new subsystems
   regenerate.

---

## Common mistakes

- **Editing source or other docs.** deep-docs owns `docs/ai-map/` exclusively and changes no
  application code.
- **Writing unanchored prose** into a trusted tier — every claim needs a resolvable
  `path:line (symbol)`.
- **Laundering existing READMEs** into a tier. Index them as external-unverified pointers; never
  ingest the prose.
- **Letting tier-0 bloat past its ceiling** — switch to grouped overflow, never truncate.
- **Sampling anchors** to save time — one unverified anchor and the whole tier can't be trusted.
- **Reading `.env` for host conventions** — never. Use package.json / angular.json / CLAUDE.md, else ask.
- **Half-writing the map** — all generation goes through staging + atomic `mv`; a second run
  while a marker exists refuses.

## Mastery checklist

- [ ] Generated a `docs/ai-map/` an agent can crawl, loading only the slice its task needs.
- [ ] Kept tier-0 under its ceiling — grouped overflow, never truncation.
- [ ] Every claim anchored to `path:line (symbol)`; every anchor verified before publish.
- [ ] Quarantined existing docs as external-unverified; never laundered their prose.
- [ ] Ran `--refresh` and regenerated only the stale + new subsystems.
- [ ] Touched no application source — documents, never decides.

## Quick reference

| | |
|---|---|
| Output | `docs/ai-map/` → `MAP.md` · `index.json` · subsystem cards · `coverage.md` |
| Tiers | tier-0 always-loaded · tier-1 on touch · tier-2 on demand |
| Hard rules | Anchored or it's fiction; documents, never decides; changes no source |
| Refresh | Dual git-free signal — drift + undocumented additions |
| Runs | After `/deep-implement` or `/deep-code-review`, or standalone on any repo |

⬅ **Back to:** [Training overview](README.md)
