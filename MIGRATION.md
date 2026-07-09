# Migrating to the reUrgency marketplace

Deep-Skills now installs from reUrgency's **single marketplace** instead of its own.
The old marketplace name (`deep-skills-by-reu`) is retired; everything reUrgency ships
lives under one storefront:

```
/plugin marketplace add reurgency/marketplace
```

**Your current install keeps working** — migrate whenever it's convenient. Nothing breaks
until you choose to switch.

## Claude Code

Claude Code currently matches plugins by name across marketplaces, so a plain reinstall from
the new store fails with "already installed"
([claude-code#20593](https://github.com/anthropics/claude-code/issues/20593)). Uninstall the
old plugin first, then install from the store:

```
/plugin uninstall deep-skills@deep-skills-by-reu
/plugin marketplace remove deep-skills-by-reu
/plugin marketplace add reurgency/marketplace
/plugin install deep-skills@reurgency
/reload-plugins
```

Update later with `/plugin marketplace update reurgency`.

## Codex · Cursor · Copilot

Point the marketplace at `reurgency/marketplace` and install `deep-skills@reurgency`. Full
per-host commands are in the [README](README.md#install) and
[`plugins/deep-skills/HOSTS.md`](plugins/deep-skills/HOSTS.md).

## Why the change

reUrgency had three separate plugin repos, each acting as its own marketplace under a different
name. They're now consolidated into one store (`reurgency/marketplace`) so you add it once and
get every reUrgency tool — [deep-skills](https://github.com/reurgency/Deep-Skills),
[overton-snapshot](https://github.com/reurgency/Overton-Snapshot), and
[sym-visualizer](https://github.com/reurgency/Sym-Visualizer) — from a single place.
