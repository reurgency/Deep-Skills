# DeepDocs — Design Outline

> **Status:** future dev — design note, not yet planned via `/deep-plan`.
> **Authored:** 2026-06-25 · seeded from the request "a skill that documents what has been built and indexes it so AI crawling is context-window-sensitive, enabling Progressive Disclosure."
> **One-liner:** A 6th deep-* skill that produces **context-window-aware documentation of what's been built** — a layered, anchored, machine-indexed map structured for **Progressive Disclosure**, so an agent crawling it loads only the slice its task and token budget need.

---

## 1. Why this exists

The series builds code; nothing in it produces a **standing, queryable map of the system written for a machine reader.** The closest artifacts are change-scoped and ephemeral:

- `/deep-implement` emits **per-phase hand-off notes** — forward-construction context for the *next implementer mid-effort*, scoped to one change. Not a whole-system orientation, and discarded once the effort lands.
- `/deep-code-review` emits **findings** — defects, not orientation.

And the standard tooling doesn't fill the gap either: a doc generator (typedoc / sphinx / docusaurus) produces **exhaustive human reference** indexed for a browser and full-text search. It dumps everything at one altitude and has no notion of "load only this layer" — pointing an agent at it costs the whole context window to answer a one-subsystem question. That is the inverse of what an agent needs.

The gap DeepDocs fills: documentation **optimized for a reader with a finite context window** — progressive disclosure with token budgets and load-when triggers, so the cheap top layer orients and the expensive deep layer is fetched only on demand.

## 2. Core principle — write for a token budget, anchor every claim

Two disciplines the rest of the design hangs from:

1. **Optimize for retrieval and partial loading, not cover-to-cover reading.** A human reads linearly and tolerates a 5,000-line reference. An agent crawls under a budget: it should load a tiny map, decide what it needs, and disclose detail progressively — stopping the moment it has enough. Docs are an **index, not a narrative.**
2. **Every claim is anchored or it's fiction.** A doc that has drifted from the code is *worse* than none, because an agent trusts it and is led wrong. Every statement cites `file:line`; freshness is verifiable and re-checkable. This is the `claim-vs-evidence` lens (see `DATA-FLOW-CONTRACT.md`) applied to documentation.

> **Reflexive note:** DeepDocs essentially recreates Claude Code's own **Skills architecture** — a small always-loaded `SKILL.md` card plus `references/` fetched on demand — for an arbitrary codebase. That split is the proven template for progressive disclosure; DeepDocs generalizes it.

## 3. The three tiers (Progressive Disclosure)

The output is layered so each tier is independently loadable, cheaper-first:

| Tier | Artifact | Always loaded? | Contents |
|---|---|---|---|
| **0 — Map** | `MAP.md` + `index.json` | yes (tiny) | every subsystem, one line each, with a pointer + token cost + load-when trigger. The agent's entry point. |
| **1 — Subsystem cards** | `subsystems/<name>.md` | on touch | purpose, entry points, key types, invariants, data-flow summary, `file:line` anchors. |
| **2 — Deep references** | `references/<topic>.md` | on demand | full data flow, edge cases, rationale, cross-layer traces. Loaded only when working *inside* it. |

An agent reads top-down and stops when it has enough — that *is* the disclosure. Each tier links down to the next; tier 0 never forces a tier-2 read.

## 4. The disciplines (and what's default vs opt-in)

| # | Discipline | Why the rest of the series / doc-gen can't | Mode |
|---|---|---|---|
| 1 | **Tiered progressive disclosure** — map → cards → deep refs. | implement's notes are flat & change-scoped; doc-gen dumps one exhaustive altitude. | **Default** |
| 2 | **Token-budgeted index** — each doc carries a token estimate + a "load-when" trigger. | no existing artifact models the *reader's context budget*. | **Default** |
| 3 | **Anchor verification** — every claim → `file:line`, adversarially checked it resolves and matches. | table stakes; reuses the `claim-vs-evidence` lens. | **Default** |
| 4 | **Machine-readable map** (`index.json`) — concept/symbol → doc + anchor + token cost. | doc-gen indexes for humans + full-text search, not for an agent crawler. | **Default** |
| 5 | **Coverage honesty** — explicitly list what was *not* documented and why. | silent gaps read as "fully documented." | **Default** |
| 6 | **Freshness re-check** — re-verify every anchor against current code; flag drift. | docs rot; nothing re-validates them. | **Opt-in** (`--verify`) |

## 5. Signature concern — the stale map and the bloated dump

Every deep-* skill hunts one signature failure mode. DeepDocs hunts the **two ways AI-facing docs fail**, which are duals:

- **The stale map** — docs that describe *intent*, not the code as it is now. An agent trusts the doc over the code and is led wrong. Defended by **anchoring** (every claim cites `file:line`) + **freshness re-check** (`--verify`).
- **The bloated dump** — docs that must be loaded whole to answer anything, defeating the entire premise. Defended by **tiering** + **token budgets** (tier 0 stays tiny; the agent never pays for tier 2 it didn't ask for).

The defenses are structural, not exhortative: tier 0 has a hard token ceiling, and a doc with an unresolved anchor is rejected the same way an AC over a stub is.

## 6. Independence model — where the series' fresh-agent DNA applies

- **Survey = fan-out, one agent per subsystem boundary.** Each surveys its slice in parallel — entry points, public surface, invariants, data flows — reusing `/deep-code-review`'s chain-trace methodology for the tier-2 traces. Each is blind to the others (boundaries are independent).
- **Verify = a fresh, adversarial agent.** Mirroring code-review's verification stage: a separate agent tries to *refute* the docs — does every anchor resolve? does each claim match the code at that line? is tier 0 loadable within its budget? — and returns a machine-readable verdict (`accurate` / `drifted` / `over-budget`). The surveyor does not grade its own map.

## 7. Workflow (sketch)

1. **Intake & scope.** Accept any of: an effort's diff (document what this effort built), a named subsystem, or a whole repo. Standalone-capable — with no prior effort, create the effort + manifest (effort name defaulting to the slugified branch — the shared mid-series-entry rule).
2. **Survey.** Fan out per subsystem boundary: discover entry points, public surface, invariants, data flows.
3. **Layer.** Produce tier 0 map, tier 1 cards, tier 2 refs — each with `file:line` anchors, a token estimate, and a load-when trigger.
4. **Anchor-verify.** Adversarial agent: anchors resolve, claims match code, tier 0 within budget.
5. **Index.** Emit `index.json` — the machine-readable crawl surface.
6. **Place & report.** Write the docs, report coverage + the explicit not-documented list.

## 8. Boundary & series placement

```
/deep-plan ─▶ /deep-plan-review ─▶ /deep-implement ─▶ /deep-code-review ─▶ /deep-bug-fix
                                          └──────────────▶ /deep-docs  (any point post-build; or standalone on any repo)
```

- **Documents, never decides.** DeepDocs makes no plan/fix/triage decisions and changes no code — it produces a standing artifact *about* the system. It is the orientation layer the other skills (and fresh agents) read first.
- It runs **standalone** on any repo — mirroring how `/deep-code-review` runs on any PR/branch/diff, not just deep-* efforts. This is its primary mode: most codebases needing an AI-readable map were not built by the series.
- Carries the standard **directive-card loader stanza**. In the Deep-Learn topology it is primarily a *downstream consumer* of cards (apply doc-relevant ones while writing) and can feed a **doc-coverage** signal — distinct from the upstream prevention spokes.

## 9. Artifacts

The output's value is **standing**, so it most likely lives **in the target repo** (version-controlled alongside code), not in throwaway run artifacts — but this is an open question (§11). Proposed shape either way:

```
docs/ai-map/            (in-repo)   ── or ──   .deep-skills/<effort>/07-Docs/
  MAP.md            # tier 0 — the always-loadable index (hard token ceiling)
  index.json        # machine-readable: concept/symbol → doc + anchor + token cost + load-when
  subsystems/*.md   # tier 1 cards
  references/*.md    # tier 2 deep refs
  coverage.md       # what was documented, what was not, and why
```

When run inside an effort it also updates the effort manifest's status line.

## 10. Deep-Learn synergy

The map's **anchor-verification** pass produces a by-product the loop can use: a list of doc claims that *drifted* from code — i.e. evidence that some surface changed without its documentation following. Over time that is a **doc-coverage / drift** signal for the Pattern Ledger (which areas churn faster than their docs). Because Deep-Learn isn't built yet, this is a forward dependency — hence kept light.

## 11. Open questions (resolve in `/deep-plan`)

- **Doc location** — in-repo (`docs/ai-map/`, lives with code, diffs with PRs) vs effort-scoped `07-Docs/`. The standing value leans in-repo; the run-artifact convention leans effort-scoped. (Same repo-location tension noted in `DESIGN-OUTLINE.md` §9.)
- **Token estimation** — cheap char/line heuristic vs a real tokenizer for the per-doc cost in `index.json`.
- **Drift detection robustness** — anchoring by raw line number is fragile across edits; anchor by symbol name / content hash / nearest stable landmark?
- **Subsystem boundary discovery** — by directory vs import graph vs LSP. How coarse before the map is useless, how fine before it's a dump.
- **Refresh model** — regenerate whole vs incrementally update on a diff; can it stay fresh via a merge hook rather than a manual re-run?
- **One artifact or two** — does a single index serve both the agent crawler and a human reader, or are they two renderings of one source?

## 12. Build phasing (suggested)

1. **SKILL.md + the default spine** — intake → survey (fan-out) → three-tier layering → anchor-verify → `MAP.md` + `index.json`. Standalone + effort intake.
2. **Token budgeting** — per-doc estimates, tier-0 hard ceiling, load-when triggers.
3. **`--verify`** — freshness re-check that re-resolves every anchor and flags drift.
4. **Incremental refresh** — update only the subsystems a diff touched, instead of regenerating whole.
5. **Deep-Learn wiring** — emit the doc-coverage/drift signal; optional merge hook to keep the map fresh.

---

### Related artifacts
- `DEEP-BUG-FIX-DESIGN.md` — the sibling future deep-* skill; same standalone + directive-card-consumer placement.
- `DESIGN-OUTLINE.md` — the Deep-Learn self-improving directive loop (this skill is a downstream card-consumer / coverage-signal feeder).
- `DATA-FLOW-CONTRACT.md` — `DLC-001`; the `claim-vs-evidence` discipline that anchor-verification reuses.
- Series skills: `plugins/deep-skills/skills/deep-{plan,plan-review,implement,code-review}/SKILL.md`.
- Template precedent: Claude Code's own Skills architecture (`SKILL.md` card + `references/` on demand) — the proven progressive-disclosure split DeepDocs generalizes.
