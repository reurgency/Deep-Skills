# Directives Registry (Deep-Learn)

The "central directive" store for the [Deep-Learn](../../../docs/roadmap/DESIGN-OUTLINE.md) self-improving loop. Each learned improvement is a **directive card** — structured data, **never** a prose edit to a SKILL.md. The skills don't change; the registry changes. This is what gives clean on/off, provenance, and effectiveness telemetry without skill bloat or drift.

> **Phase 1 (current):** taxonomy + the `DLC-001` seed card, shipped active. The Distiller (`/deep-learn`) and Effectiveness Monitor are later phases — see DESIGN-OUTLINE.md §10.

## Layout — file-per-card, directory-as-lifecycle-state

```
directives/
  README.md            ← you are here
  taxonomy.md          ← the shared category spine (the hub↔spoke contract)
  cards/
    active/            ← loaded and enforced at runtime
    shadow/            ← evaluated but NOT enforced (logs "would this have changed the plan?")
    candidate/         ← drafted, awaiting the human gate
    disabled/          ← demoted/retired, kept with provenance — never silently deleted
```

**The card's directory is the source of truth for its lifecycle state.** The `status:` field in each card's frontmatter mirrors the directory for readability. Don't hand-move files — use `./toggle.sh <ID> on|off` (next section), which moves the card and updates its `status:` field together so the two never drift. (A future lint can assert they agree.)

## Card format

A card is a Markdown file with YAML frontmatter (structured metadata) + a Markdown body (the directive text a skill applies). This refines the draft JSON schema in DESIGN-OUTLINE.md §5 — same fields, but Markdown body because the payload is prose directives an LLM injects, and one card may carry a phase-scoped section for each of its `owner_phases`.

Frontmatter fields: `id`, `category` (a slug from `taxonomy.md`), `owner_phases` (which spokes apply it), `title`, `trigger`, `status`, `provenance`, `promotion` (incl. the human gate), `outcome` (maintained by the Effectiveness Monitor).

## Lifecycle (the gates)

```
candidate ──(distiller: class clears threshold)──▶ shadow
  shadow  ──(human gate: approve)──────────────▶ active     ◀── HUMAN GATE (required)
  active  ──(monitor: class recurrence drops)──▶ stays active, verdict=working
  active  ──(monitor: class keeps recurring)───▶ disabled (ineffective)   ◀── REMOVAL
  active  ──(monitor: friction/false positives)▶ disabled (false-positive)
  disabled ─ kept with provenance; never silently deleted
```

- **Human gate:** no card reaches `active/` without explicit approval (recorded in `promotion.human_approved_by`).
- **Removal is first-class:** cards can be demoted, not only added — guards against monotonic bloat.

## Turning a card on / off (the one command)

```bash
./toggle.sh DLC-001 off     # stop applying it (moves to disabled/, sets status: disabled)
./toggle.sh DLC-001 on      # apply it again  (moves to active/,   sets status: active)
./toggle.sh                 # list every card and its current state
```

`toggle.sh` moves the card **and** updates its `status:` field in one step, so the directory and the field never drift. The change is a normal file move — `git diff` shows exactly what flipped, and reverting is `toggle.sh … on` (or `git revert`). That's the whole on/off mechanism: no skill edits, no config.

> Why a card might be turned off: the Effectiveness Monitor (Phase 4) flags it as ineffective or as a false-positive, or you hit an unexpected side effect and want to disable it immediately. Disabled cards stay in `disabled/` with full provenance — never deleted.

## How skills load active cards

Each of `deep-plan`, `deep-plan-review`, `deep-implement` carries one stable stanza that runs the bundled `scripts/load-active-cards.sh <phase>` and applies the **active** cards whose `owner_phases` include its phase. That script **self-locates this registry relative to its own path**, so it resolves correctly no matter where the plugin is installed or what the working directory is — sidestepping the platform constraint that `${CLAUDE_PLUGIN_ROOT}` is *not* interpolated in SKILL.md prose (GitHub anthropics/claude-code#9354). Loading is **lazy and scoped**: cards reach a skill only when that skill actually runs, so unrelated sessions pay nothing. The script is copied byte-identically into each skill's `scripts/` dir (the "standalone rule"); only this registry is shared.
