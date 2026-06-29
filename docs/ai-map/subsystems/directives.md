<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# directives

> **Load when:** working with Deep-Learn directive cards (toggle, author, load) · **~tokens:** ~420 est

## Purpose

The Deep-Learn directive-card registry — a shared, versioned data store of learned, human-vetted improvements injected into deep-* skills at runtime as data (never baked into skill prose), with on/off toggling and provenance. — `plugins/deep-skills/directives/README.md:1 (Directives Registry (Deep-Learn))`

## Entry points

- README.md (contract); `./toggle.sh <ID> on|off`; `cards/active/` working set loaded by each skill's `scripts/load-active-cards.sh <phase>` — `plugins/deep-skills/directives/README.md:54 (How skills load active cards)`
- Card format / frontmatter fields — `plugins/deep-skills/directives/README.md:22 (Card format)`

## Key components

- Lifecycle / directory source of truth + status mirror — `plugins/deep-skills/directives/README.md:20 (The card's directory is the source of truth for its lifecycle state)`
- toggle.sh movement logic (active↔disabled, sync status) — `plugins/deep-skills/directives/toggle.sh:36 (if [ "$action" = "off" ])`
- Taxonomy (5 category classes mapped to spokes) — `plugins/deep-skills/directives/taxonomy.md:1 (Deep-Learn — Shared Taxonomy (the spine))`
- DLC-001 (only active card; State/Data-Flow Contract) — `plugins/deep-skills/directives/cards/active/DLC-001.md:2 (id: DLC-001)`

## Invariants

- Cards human-gated; no active card without `promotion.human_approved_by` — `plugins/deep-skills/directives/cards/active/DLC-001.md:2 (id: DLC-001)`
- Never edit a card/skill to disable — toggle only — `plugins/deep-skills/directives/README.md:42 (Turning a card on / off)`
- Cards are data not code; directory + `status:` field kept in sync — `plugins/deep-skills/directives/README.md:20 (The card's directory is the source of truth for its lifecycle state)`
- Cards reference only taxonomy categories — `plugins/deep-skills/directives/taxonomy.md:1 (Deep-Learn — Shared Taxonomy (the spine))`

## Data-flow summary

- Humans write/promote cards → toggle.sh moves card + syncs status → deep-* skills read via `load-active-cards.sh <phase>` filtered by `owner_phases` — `plugins/deep-skills/directives/toggle.sh:36 (if [ "$action" = "off" ])` → `plugins/deep-skills/directives/README.md:54 (How skills load active cards)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| registry is the central directive store; cards as data not skill edits | `plugins/deep-skills/directives/README.md:1 (Directives Registry (Deep-Learn))` |
| toggle.sh keeps directory + status in sync | `plugins/deep-skills/directives/README.md:20 (The card's directory is the source of truth for its lifecycle state)` |
| frontmatter fields | `plugins/deep-skills/directives/README.md:22 (Card format)` |
| toggle.sh one command | `plugins/deep-skills/directives/README.md:42 (Turning a card on / off)` |
| load-active-cards.sh <phase> + owner_phases | `plugins/deep-skills/directives/README.md:54 (How skills load active cards)` |
| off: active→disabled; on: disabled→active; sync status | `plugins/deep-skills/directives/toggle.sh:36 (if [ "$action" = "off" ])` |
| taxonomy is the hub↔spoke contract; classes map to spokes | `plugins/deep-skills/directives/taxonomy.md:1 (Deep-Learn — Shared Taxonomy (the spine))` |
| DLC-001 card structure | `plugins/deep-skills/directives/cards/active/DLC-001.md:2 (id: DLC-001)` |
