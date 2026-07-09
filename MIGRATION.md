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

## GitHub Copilot — CLI

Copilot CLI reads the same marketplace format as Claude Code, so the sequence mirrors it:
uninstall the old plugin, drop the retired marketplace, add the store, reinstall. From a
Copilot CLI session:

```
copilot plugin uninstall deep-skills@deep-skills-by-reu
copilot plugin marketplace remove deep-skills-by-reu
copilot plugin marketplace add reurgency/marketplace
copilot plugin install deep-skills@reurgency
```

Then run `/skills list` in Copilot and confirm the `deep-*` skills are listed. (If you never
added the old `deep-skills-by-reu` marketplace, skip the first two commands.)

## GitHub Copilot — VS Code editor

**Nothing to migrate.** The editor install is file-based, not marketplace-based — it points at
this repo directly, via `chat.agentSkillsLocations` set to `plugins/deep-skills/skills`, or via
skills copied/symlinked into `.github/skills/`. This repo hasn't moved and its layout is
unchanged; only the marketplace name was retired. Your existing setup keeps working as-is.
Setting up fresh? See [`plugins/deep-skills/HOSTS.md`](plugins/deep-skills/HOSTS.md).

## Codex · Cursor

Same shape: remove the old `deep-skills-by-reu` marketplace entry if you added one, add
`reurgency/marketplace`, and install `deep-skills@reurgency`. Exact commands vary by version —
see the [README](README.md#install) and
[`plugins/deep-skills/HOSTS.md`](plugins/deep-skills/HOSTS.md) for current per-host steps.

## Why the change

reUrgency had three separate plugin repos, each acting as its own marketplace under a different
name. They're now consolidated into one store (`reurgency/marketplace`) so you add it once and
get every reUrgency tool — [deep-skills](https://github.com/reurgency/Deep-Skills),
[overton-snapshot](https://github.com/reurgency/Overton-Snapshot), and
[sym-visualizer](https://github.com/reurgency/Sym-Visualizer) — from a single place.
