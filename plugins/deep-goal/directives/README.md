# Directives Registry (Deep-Learn) — deep-goal

deep-goal's **own** directive-card registry, mirroring the core deep-skills registry's mechanics exactly: each learned improvement is a **directive card** — structured data, **never** a prose edit to SKILL.md. The skill doesn't change; the registry changes.

> **v1: this registry ships EMPTY.** deep-goal reads only this registry — never the core deep-skills registry. Cross-registry directive cards (a `deep-goal` token in the core taxonomy's `owner_phases` roster) are a deferred extension; under the loader's exact-token matching, core cards can never target `deep-goal` today, so a cross-plugin read would be dead machinery.

## Layout — file-per-card, directory-as-lifecycle-state

```
directives/
  README.md            ← you are here
  taxonomy.md          ← pointer to the core taxonomy (the authoritative category spine)
  toggle.sh            ← the one-command on/off switch (byte-identical to the core copy)
  cards/
    active/            ← loaded and enforced at runtime (empty in v1)
    shadow/            ← evaluated but NOT enforced
    candidate/         ← drafted, awaiting the human gate
    disabled/          ← demoted/retired, kept with provenance — never silently deleted
```

**The card's directory is the source of truth for its lifecycle state.** Don't hand-move files — use `./toggle.sh <ID> on|off`, which moves the card and updates its `status:` field together so the two never drift. `./toggle.sh` with no args lists every card and its state.

## How the skill loads active cards

`skills/deep-goal/scripts/load-active-cards.sh deep-goal` — the same self-locating loader every core skill carries, **byte-identical** (the vendoring invariant in the core `plugins/deep-skills/HOSTS.md`): it resolves this registry relative to its own path (`skills/deep-goal/scripts/ → ../../../directives/cards/active`), so `skills/` and `directives/` must stay siblings under this plugin root on every host. With the registry empty it prints "no active directive cards for phase: deep-goal" and the skill proceeds normally.

Card format, lifecycle gates, and the human-approval requirement are identical to the core registry — see `plugins/deep-skills/directives/README.md` in the deep-skills plugin; don't fork that documentation here.
