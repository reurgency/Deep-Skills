# Model map — abstract tier → concrete model ID

> **Required launch input, not an optional pointer.** Any skill that runs a fleet **must** read this map and bind every agent's model to the concrete ID below — set explicitly on each launch, never an alias, never a host default — *before* fan-out. This is the **model-tier routing correctness guarantee** (see `references/host-affordances.md`), not a tunable affordance. One `model-map.md` lives in each fleet skill; it is **host-agnostic** — the orchestrator's own model determines both the family (Anthropic / OpenAI / …) and the ceiling, so the same file resolves correctly on Claude Code, Codex, Cursor, and Copilot.

## The ceiling — what `main` actually is

The three tiers (**main**, **mid**, **cheap**) resolve from the **orchestrator's own (session) model** — the model the user selected to run the skill. That selected model is the **ceiling**: the strongest model *this user can access*. Tiers resolve **downward from the ceiling, never upward** — a model the user cannot access (blocked by their org, not in their plan) is simply not an option, so it never appears in any tier.

`main` is therefore **relative, not an absolute grade.** For a user whose org grants Opus or GPT-5.5, `main` is that. For a restricted shop whose best available model is Sonnet 4.6 or GPT-5.4, `main` *is* Sonnet 4.6 / GPT-5.4 — the pipeline runs its heavy work there, because that is their ceiling.

## "cheap" means the cheapest *reasoning* tier — not a small model

All three tiers are **reasoning tiers**. `cheap` is the cheapest model that still does genuine **thinking** work — *not* a small/utility model. Every task in this series — finding, verifying, synthesizing — is reasoning work; there is **no** utility-grade task (bulk labeling, slug or key generation, mechanical summarization) anywhere in the Deep Skills series that would justify a small model. Consequently the host's smallest models — **Haiku, GPT-mini, GPT-nano** — are **never required anywhere in this series** and never appear in this map.

This is not a model blacklist; it is that **nothing here is small-model-appropriate.** (The old "never Haiku, ever" wording was a proxy for exactly this. The point was never to ban a model name — it was that reasoning work must run on a reasoning model.) We also deliberately do **not** layer reasoning-effort / thinking-level variables on top of the model: **the tier *is* the model**, which keeps resolution simple and unambiguous.

## Tiers

| Orchestrator (= ceiling) | main | mid | cheap |
|---|---|---|---|
| **Anthropic — Fable 5** | Fable 5 (`claude-fable-5`) | Opus 4.8 (`claude-opus-4-8`) | Sonnet 4.6 (`claude-sonnet-4-6`) |
| **Anthropic — Opus 4.8** | Opus 4.8 (`claude-opus-4-8`) | Opus 4.8 (`claude-opus-4-8`) | Sonnet 4.6 (`claude-sonnet-4-6`) |
| **Anthropic — Sonnet 4.6** (restricted shop) | Sonnet 4.6 (`claude-sonnet-4-6`) | Sonnet 4.6 (`claude-sonnet-4-6`) | Sonnet 4.6 (`claude-sonnet-4-6`) |
| **OpenAI — GPT-5.5** | GPT-5.5 | GPT-5.4 | GPT-5.4 |
| **OpenAI — GPT-5.4** (restricted shop) | GPT-5.4 | GPT-5.4 | GPT-5.4 |

Add a row for any other orchestrator the same way: list the **reasoning** models the user can access (exclude the host's small/utility models entirely), pin `main` to the ceiling, `cheap` to the cheapest reasoning model available, and `mid` between them — collapsing `mid`/`cheap` up to the ceiling when no cheaper reasoning model exists.

## Binding rules

1. **Pin the FULL model ID, never an alias.** Pass the exact IDs above at every launch. A bare alias like `opus` is resolved by the harness, not this table — a calibration run that launched mid-tier finders with the `opus` alias got Opus **4.6**, silently below the tier the table mandates.
2. **`main` IS the orchestrator's (ceiling) model — never anything smaller.** Heavy work runs at the ceiling. Tiers never resolve *upward* past it (no access = not an option) and `main` never resolves *downward* below it.
3. **Compression: as the ceiling drops, lower tiers collapse up to it.** When no reasoning model exists below the ceiling, `mid` and `cheap` equal `main` (ceiling Sonnet 4.6 → main = mid = cheap = Sonnet 4.6; ceiling GPT-5.4 → all three = GPT-5.4). A tier never resolves to a small/utility model to fill the slot — it collapses up instead.
4. **Small models never appear — any tier, any stage, any agent.** Haiku, GPT-mini, and GPT-nano are never assigned to finders, verifiers, or synthesis (which is everything this series does), on any host, at any ceiling. A calibration run whose finders silently routed to Haiku produced 0 Blockers and 0 Majors on a diff with two known Criticals — output worse than none, because it ships false confidence.
5. **Set the model explicitly on every agent launch** (the host's per-agent model parameter) — never rely on inheritance or a default. That is exactly how the Haiku mis-route happened: tier labels like "main model" were left to implicit resolution. Resolve this table to concrete full IDs, then use those IDs in every launch. **Detection (relative):** if any agent's transcript or first response shows it running **below its assigned tier** — for any task, since all tasks reason, below the ceiling-relative tier the table binds — its output is invalid: discard it and relaunch with the model set explicitly.

## Honest degradation — log the ceiling

A restricted-ceiling run does ceiling-grade work openly: a Sonnet-4.6-ceiling run is doing what an Opus run would do, on Sonnet — **allowed** (it is the user's best), but the run must **record the ceiling** in its artifacts so its output is never compared against a full-access run as if equal. Same principle as the single-agent fleet fallback: degrade openly, never silently.
