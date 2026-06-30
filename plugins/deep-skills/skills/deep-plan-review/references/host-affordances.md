# Host affordances — one place for every cross-assistant fallback

> **Series-shared reference.** Copied **byte-identically** into every deep-* skill's `references/` directory (the series standalone rule forbids cross-skill references). All copies must stay byte-identical, or be intentionally marked divergent at the top of the changed copy. The series consistency sweep verifies this.

The deep-* skills run on Claude Code, Codex, Cursor, and Copilot/VS Code. Their **core** machinery — `SKILL.md` skills, parallel subagent fan-out, per-agent model selection, artifact writes under `.deep-skills/**` — is portable to all four hosts and is used directly, unconditionally. This file is the single home for the **small** set of UX affordances that are *not* uniformly available, so a skill body can say "ask the user — see `host-affordances.md`" instead of inlining "if available else…" at every call site.

**How to use this file:** when a skill points here for an affordance, use the host's native capability **if it exists**, otherwise the stated text fallback. Never block the workflow on a missing affordance — every fallback keeps the skill fully functional.

## Model-tier routing — a correctness guarantee, NOT an affordance

This one is **not** a graceful-degradation item; it is load-bearing and lives here only as a pointer. **Resolve every agent's model from the host-agnostic `references/model-map.md`, set it explicitly on every launch, never an alias and never a host default.** A skill that runs a fleet **must** read `model-map.md` and bind each tier → concrete model ID *before* fan-out. The map is a **required input, not an optional pointer.** If a host cannot honor per-agent model selection, that is a capability failure handled by the distribution gate (README matrix / maintainer note) — not something a skill silently rides past.

Two properties of the map that call sites must respect (concrete model IDs stay in `model-map.md` — these are the rules, not the IDs): (1) **tiers are relative to the ceiling.** The ceiling is the orchestrator's own selected model — the strongest the user can access — and `main` *is* that ceiling, even when it is a normally-mid-grade model; tiers resolve downward from it, never up, and collapse up to it when no cheaper option exists. (2) **all three tiers are reasoning tiers.** `cheap` means the cheapest *reasoning* model, not a small/utility model — every task in this series reasons, so a host's smallest models (Haiku, GPT-mini/nano) are never required and never appear in any tier. See each fleet skill's `references/model-map.md`.

## Structured questions

- **Native:** the host's structured-question tool (Claude Code `AskUserQuestion`; equivalent pickers elsewhere) — render the question set, ≤4 questions per call, short chip headers.
- **Fallback (no structured-question UI — Codex/Cursor/Copilot today):** ask in chat as a **numbered list** ("reply 1, 2, or 3"), one round per decision batch, preserving the same cadence the skill specifies. `templates/questions/*.json` stay neutral specs that render either way.

## Notifications

- **Native:** the host's notification affordance (Claude Code `PushNotification` → terminal, and the user's phone when Remote Control is connected). One line, < 200 chars, lead with the actionable fact.
- **Shell-host fallback:** on a host with a shell on macOS, `osascript -e 'display notification "<msg>" with title "<skill>"'`; on other shells, the equivalent native notifier if present.
- **Universal fallback (no notifier):** emit a **bold `ATTENTION:` line** as the last line of the turn, leading with the actionable fact.
- **User-extensible (Claude Code):** the user may register a `Notification` hook in `.claude/settings.json` to route the signal (Slack, custom push, sound); the skill only *emits* — the hook handles routing. Offer to scaffold one via the `update-config` skill — never add it silently.

Notify sparingly regardless of mechanism: blockers and autonomous full-run completion only.

## Reasoning effort

- **Native:** where the host exposes a per-agent reasoning-effort / thinking setting (Claude Code, VS Code), use it as the skill directs.
- **Fallback:** omit it — the skill's instructions already encode the depth expected; reasoning effort is a tuning knob, never a correctness requirement.

## Browser / worktree / bypass-permissions

- Use the host's equivalent where exposed (Claude Code `/create_worktree`, browser tooling, bypass-permissions mode); **else omit** the optional affordance and proceed with the portable path. None of these gate a skill's core output.

## Attribution trailer

Commit trailers use a host-aware agent identity:

```
Co-Authored-By: <agent-name> <agent-email>
```

Per-host defaults: Claude Code → `Claude <noreply@anthropic.com>` (or the specific model name where a skill pins it); other hosts → that host's agent name + its noreply address. The generic two-token `Co-Authored-By: Name <email>` form is what git accepts — verify the host's identity renders in that shape.

## Directive-card loading without a reliable shell

The Deep-Learn loader (`scripts/load-active-cards.sh`) is the primary path. Where a host has no reliable shell, apply the cards by hand instead: read every file under the directives registry's `cards/active/` directory and apply each card whose `owner_phases:` frontmatter list contains **this phase as an exact token** (`deep-plan` ≠ `deep-plan-review`). If the registry directory is absent, proceed with no cards. (The registry is vendored alongside `skills/` in every host manifest so the relative path resolves — see the distribution section of `README.md`.)
