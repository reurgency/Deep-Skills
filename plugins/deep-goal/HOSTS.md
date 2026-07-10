# Hosts & distribution — deep-goal (STUB)

> **Status: stub.** Phase 7 fills the full per-host degradation matrix. Until then, treat this file as the honest minimum: **Claude Code is the designed-and-verified floor**; everything else degrades.

deep-goal is a **paid add-on** to the deep-skills plugin and follows the same packaging rules as its sibling (`plugins/deep-skills/HOSTS.md`): one skill body, thin per-host manifests (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`), and the vendoring invariant — `skills/` and `directives/` stay siblings under this plugin root so the byte-identical directive loader self-locates on every host.

## Install (Claude Code — reference host)

```
/plugin marketplace add reurgency/marketplace
/plugin install deep-goal@reurgency
```

Requires the **deep-skills plugin ≥ 0.2.0** installed alongside — deep-goal verifies this at launch (the version handshake in `skills/deep-goal/SKILL.md`) and refuses politely if it's absent or below minimum.

## Degradation (to be filled by Phase 7)

- **Claude Code:** full conductor — per-stage fresh-subagent dispatch, structured questions, notifications.
- **Codex / Cursor / Copilot:** degrade to **inline sequential execution** — functional, but prod-rigor runs may hit context limits. The full matrix, per-host install steps, and honest caveats land in Phase 7.
