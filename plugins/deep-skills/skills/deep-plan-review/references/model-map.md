# Model map — abstract tier → concrete host model ID (Claude Code)

> **Required launch input, not an optional pointer.** Any skill that runs a fleet **must** read this map and bind every agent's model to the concrete ID below — set explicitly on each launch, never an alias, never a host default — *before* fan-out. This is the **model-tier routing correctness guarantee** (see `references/host-affordances.md`), not a tunable affordance. One `model-map.md` lives in each fleet skill; this is the **Claude Code** host map.

## Tiers

The three tiers (**main**, **mid**, **cheap**) resolve from the **orchestrator's own (session) model** at launch time:

| Orchestrator (session model) | main tier | mid tier | cheap tier |
|---|---|---|---|
| Fable 5 | Fable 5 (`claude-fable-5`) | Opus 4.8 (`claude-opus-4-8`) | Sonnet (latest, e.g. `claude-sonnet-4-6`) |
| Opus 4.8 | Opus 4.8 (`claude-opus-4-8`) | Opus 4.8 (`claude-opus-4-8`) | Sonnet (latest, e.g. `claude-sonnet-4-6`) |

## Binding rules

1. **Pin the FULL model ID, never an alias.** Pass the exact IDs in parentheses above at every launch. A bare alias like `opus` is resolved by the harness, not this table — a calibration run that launched mid-tier finders with the `opus` alias got Opus **4.6**, silently below the tier the table mandates.
2. **The main tier IS the orchestrator's model — never anything smaller.** When the orchestrator is Opus 4.8, anything the Fable-5 config would route to main *or* mid stays on Opus 4.8; only the cheap tier drops to Sonnet. Tiers never resolve downward past the table above.
3. **The host's smallest tier (on Claude Code, Haiku) is NEVER used in this pipeline — any tier, any stage, any agent.** Not finders, not verifiers, not synthesis helpers. A calibration run whose main-tier lenses silently routed to Haiku produced 0 Blockers and 0 Majors on a diff with two known Criticals — that output is worse than none, because it ships false confidence.
4. **Set the model explicitly on every agent launch** (the host's per-agent model parameter) — never rely on inheritance or a default. That is exactly how the Haiku mis-route happened: tier labels like "main model" were left to implicit resolution. Resolve this table to concrete full IDs, then use those IDs in every launch. If any agent's transcript or first response shows it running below its assigned tier — above all the smallest tier — its output is invalid: discard it and relaunch with the model set explicitly.

## Other hosts

Each non-Claude host carries its **own** `model-map.md` mapping these same three tiers to that host's concrete model IDs (Codex / Cursor / Copilot map main/mid/cheap to their strongest / mid / economy models, with the same "never the smallest tier for finding or verifying" rule). The tier *semantics* are host-agnostic; only the IDs differ. A host that cannot bind per-agent models routes its fleet to a single-agent fallback for that host only (recorded in the README matrix + the maintainer note).
