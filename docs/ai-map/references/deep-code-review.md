<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-2 reference: loaded on demand. Deep cross-layer data-flow trace for one subsystem. Every hop anchored. -->

# deep-code-review — multi-agent review pipeline

> **Load when:** tracing the multi-agent review pipeline (scripted setup → finder fleet → dedup → adversarial verification → synthesis) or the last-mile chain-trace.
> Card: [subsystems/deep-code-review.md](../subsystems/deep-code-review.md)

## The flow it traces

The escalated (`--multi-agent`/`--mega`) path is a real cross-layer pipeline: deterministic setup feeds a fleet of finder agents, whose candidate findings are deduplicated, adversarially verified, and synthesized into one report — with model-tier routing throughout (all reasoning tiers; small/utility models never appear).

## Hop-by-hop

1. **Resolve scope** — branch vs base, PR, or explicit paths; the golden rule is to print the resolved scope and ask on ambiguity before reading anything. — `plugins/deep-skills/skills/deep-code-review/SKILL.md:24 (1. Resolve scope — and state it)`

2. **Deterministic pre-pass** — scripted setup over the resolved scope; never read `.env`/secrets. — `plugins/deep-skills/skills/deep-code-review/references/deterministic-prepass.md:25 (NEVER read `.env`)`

3. **Finder fleet (overgenerate within budget)** — fresh-eyes finders run the four lenses (Correctness, Last-Mile, Plan-Conformance, Coherence), overgenerating candidates within a finder budget and severity floor. No implementation transcript reaches them. — `plugins/deep-skills/skills/deep-code-review/references/review-lenses.md:1 (Review lenses)` · `plugins/deep-skills/skills/deep-code-review/references/dimensions.md:17 (Overgenerate — within budget, above the nit floor)` · `plugins/deep-skills/skills/deep-code-review/SKILL.md:12 (Core principle)`

4. **Model-tier routing (reasoning tiers only)** — each pipeline stage is routed to a model tier, all of which are reasoning tiers; **load-bearing invariant:** small/utility models (Claude: Haiku) never appear, since every task reasons. — `plugins/deep-skills/skills/deep-code-review/references/multi-agent.md:29 (All three tiers are reasoning tiers — the host's small/utility models never appear here)`

5. **Dedup + adversarial verification** — candidates are deduplicated and each survivor is adversarially verified; evidence is required on every finding. For last-mile findings the rule is strict: no cited hop-by-hop chain ⇒ no finding. — `plugins/deep-skills/skills/deep-code-review/references/findings-and-severity.md:15 (REQUIRED, no exceptions)` · `plugins/deep-skills/skills/deep-code-review/references/last-mile.md:69 (synthesis rule)`

6. **Synthesis → report** — surviving findings (1-10 severity, all left open) are synthesized into the report + machine record; triage is a separate opt-in step, never folded in here. — `plugins/deep-skills/skills/deep-code-review/templates/finding.json:1` · `plugins/deep-skills/skills/deep-code-review/SKILL.md:10 (This is the fourth skill of the `deep-*` series)`

## Outputs

`04-Code-Review/report.md` + `findings.json` + `certificate.md` + manifest. Never the plan/deferreds (that is `--triage`).
