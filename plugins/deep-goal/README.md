# deep-goal — autonomous pipeline conductor for the Deep-* series

**Paid add-on** to the [deep-skills](../deep-skills/) plugin. One invocation runs an effort end-to-end — plan → review → implement → code-review → bugfix → docs — with a `--rigor=<yolo|poc|mvp|prod>` level selecting which stages run, how interactive planning is, how triage decides, and how many review→fix rounds the loop may take.

- **Requires:** the deep-skills plugin **≥ 0.2.0** installed alongside (verified at launch; deep-goal refuses politely otherwise). The core skills never require deep-goal — coupling is strictly one-directional.
- **Install (Claude Code):** `/plugin marketplace add reurgency/marketplace` → `/plugin install deep-goal@reurgency`. Other hosts: see `HOSTS.md` (stub — Claude Code is the verified floor).
- **Invoke:** `/deep-goal <feature>` or natural language — "run deep-goal at mvp rigor".

> **Distribution note:** deep-goal currently ships from the public `reurgency/marketplace` store; at launch, distribution may move to a **private channel** (the plugin boundary makes that a folder move — the plugin itself is unchanged).

Layout mirrors the core plugin: `skills/deep-goal/` (SKILL.md + scripts/ + references/ + templates/), `directives/` (deep-goal's own Deep-Learn registry — empty in v1), thin per-host manifests, `HOSTS.md`.
