# Deep-Learn — the self-improving directive loop

> Part of the [Deep Skills Training Program](README.md). A **system feature** that spans the
> whole series, not a single skill.
> Sources: [`plugins/deep-skills/directives/README.md`](../../plugins/deep-skills/directives/README.md) ·
> [`directives/taxonomy.md`](../../plugins/deep-skills/directives/taxonomy.md) ·
> [`docs/roadmap/DESIGN-OUTLINE.md`](../roadmap/DESIGN-OUTLINE.md)

Every review the series runs feeds a learning loop that turns **recurring bug classes** into
toggleable **directive cards** — structured data, **never a prose edit to a skill** — which the
upstream skills load at runtime to prevent the same bug **earlier next time**. It is
human-gated, has a one-command kill-switch, and carries full provenance. Self-learning is what
lets the series **adapt to your codebase, your conventions, and your stack** instead of shipping
generic advice.

```
review → distill → propose → (human gate) → apply → review again → measure → prune
```

---

## Why it exists

The benchmark that seeded the series had a lesson in it: **every severity-bearing finding was
the same class of bug** — a write path whose runtime reader resolved a *different* source
("execution is not config-aware"). None were in-function logic errors. Code-review caught them,
**late and expensively**.

A one-time fix handles *that* class. But new classes keep appearing. The goal is a **standing
mechanism** that learns each recurring class **once** and pushes prevention upstream
automatically — with a human gate and a kill-switch, so a bad lesson can't silently degrade the
skills. Three ideas do the work:

- **Cheap kills are upstream.** The same bug is cheapest to prevent at plan time, next at
  implement time, most expensive at review time. Deep-Learn moves each lesson as far upstream as
  it can go.
- **Classes, not findings.** One Blocker shouldn't rewrite a skill; a *recurring class* should.
  The loop accumulates root-cause-tagged classes across runs — raw findings are evidence, not
  lessons.
- **Never silent, never stuck.** Nothing is enforced without approval, anything can be switched
  off in one command, and every card records where it came from and whether it's working.

## The core principle — improvements are data, not prose

A learning utility must **never edit a `SKILL.md`**. Prose edits cause skill bloat, drift (three
skills phrasing one lesson three ways), merge conflicts, and — fatally — **no clean on/off**.

So every learned improvement is a structured **directive card** in a shared registry. Each skill
carries one stable stanza: *"load the active cards for your phase and apply them."* The skills
stop changing; the registry changes. On/off becomes a status flip; provenance and effectiveness
are built in.

## How it adapts to *your* codebase

The taxonomy and cards are not generic best-practices lifted from a blog — they are **distilled
from your own reviews**, so the system learns the way *your* code actually breaks:

- **Your failure shapes.** Each class is a root-cause pattern that recurred in *your* reviews.
  The ledger tags and counts the shapes your codebase actually produces.
- **Your conventions.** A card like "search for an existing helper before defining a new one"
  enforces *your* reuse norms; a data-flow contract enforces *your* state-management discipline.
- **Your stack.** A card's `trigger` keys off the surfaces in your repo — the stores, config,
  routes, and library seams you actually use — so a lesson loads only when a change touches the
  thing it protects.

Whether a future ledger is shared across all your repos or kept strictly per-repo is an open
design question, but the animating idea is the same: **the system gets sharper the more you use
it on your code.**

## The architecture — hub, spine, spokes

```
   every /deep-code-review run  →  findings.json
                     │
                     ▼
   ┌──────────────┐      ┌───────────────────────┐
   │  DISTILLER    │────▶│   PATTERN LEDGER (hub)  │  accumulating, not last-run:
   │ (post-review) │      │  classes × freq × sev   │  root-cause-tagged issue classes
   └──────────────┘      └──────────┬────────────┘
                                     │ promotes a class when it clears threshold
                                     ▼
                       ┌───────────────────────────┐
                       │   SHARED TAXONOMY (spine)   │  the lesson categories —
                       │   the hub↔spoke contract     │  a class maps to many spokes
                       └──┬─────────┬─────────┬──────┘
                          ▼         ▼         ▼
                    deep-plan  deep-plan-review  deep-implement  … ← SPOKES
                          │         │         │      (draft cards for classes they own)
                          └─────────┴─────────┘
                                    ▼
                       ┌───────────────────────────┐
                       │    DIRECTIVES REGISTRY      │  candidate · shadow · active · disabled
                       └──────────┬────────────────┘  provenance + telemetry
                                  │ skills load ACTIVE cards at runtime
                                  ▼
              upstream skills apply them  →  next /deep-code-review run
                                  │
                       ┌──────────▼────────────────┐
                       │  EFFECTIVENESS MONITOR      │  did the class recur? →
                       │  (post-review telemetry)    │  auto-demote / flag false-positive
                       └───────────────────────────┘
```

| Piece | Role |
|---|---|
| **Pattern Ledger (hub)** | Accumulating, not "the last run's issues." Classes with frequency, severity, exemplar finding IDs, first/last-seen, and the preventing phase(s). Fed by every `findings.json`. |
| **Shared Taxonomy (spine)** | The category vocabulary — the contract between hub and spokes. Without it each spoke re-derives categories and they drift. A class maps **many-to-many** to spokes. |
| **Spoke utilities** | The upstream skills. For classes they own, each drafts a **candidate** card using its own leverage. They apply nothing and touch no skill. |
| **Directives Registry** | File-per-card, **directory-as-lifecycle-state** (`active/` · `shadow/` · `candidate/` · `disabled/`). Where on/off, provenance, and effectiveness live. |

## Card lifecycle — nothing enforced without a human

A card's **directory is its lifecycle state**; a `status:` field mirrors it. Cards move only
through gates.

```
candidate ──(distiller: class clears threshold)──▶ shadow
  shadow  ── evaluated, NOT enforced — logs "would this have changed the plan?"
  shadow  ──(human gate: approve)──────────────▶ active     ◀── HUMAN GATE (required)
  active  ──(monitor: recurrence drops)────────▶ stays active, verdict = working
  active  ──(monitor: class keeps recurring)───▶ disabled (ineffective)    ◀── REMOVAL
  active  ──(monitor: friction / false pos.)───▶ disabled (false-positive)
  disabled ─ kept with full provenance — never silently deleted
```

- **Human gate** — no card reaches `active/` without explicit approval, recorded in
  `promotion.human_approved_by`.
- **Shadow mode** — candidates can be evaluated without being enforced; they log what they
  *would* have done. Default off.
- **Removal is first-class** — cards can be demoted, not only added; the guard against monotonic
  bloat. Disabled cards keep their provenance.

**One command, no skill edits:** `./toggle.sh DLC-001 off` stops applying a card (moves it to
`disabled/`, flips `status:`); `on` re-applies it; bare `./toggle.sh` lists every card and its
state. The move and the status field change together so they never drift, and `git diff` shows
exactly what flipped.

## Anatomy of a directive card

A card is a Markdown file: **YAML frontmatter** (metadata the loop reasons over) + a **Markdown
body** (the directive an LLM injects). One card can carry a **phase-scoped section per owner
phase** — each skill applies only its own.

```yaml
id: DLC-001
category: write-no-reader            # a slug from the shared taxonomy
owner_phases: [deep-plan, deep-plan-review, deep-implement, deep-bugfix]
title: Require a State / Data-Flow Contract
trigger: The plan introduces/removes/changes any persisted field, store, config, or runtime read.
status: active
provenance: { findings: [CR-001…CR-016], reviews: ["pipeline-consolidation@6879399"] }
promotion:  { human_approved_by: "…", recurrence_threshold_met: true }   # the required gate
outcome:    { verdict: unproven }    # maintained by the Effectiveness Monitor
```

| Field | What it's for |
|---|---|
| `category` | The taxonomy slug — a card must not invent a category. The hub↔spoke contract. |
| `owner_phases` | Which skills apply the card. Matched by **exact token** so `deep-plan` never matches `deep-plan-review`. |
| `trigger` | The change shape that makes the lesson relevant — keyed to surfaces in your repo. |
| `provenance` | The findings and review the lesson came from — the audit trail. |
| `promotion` | The gate record: who approved it, whether the recurrence threshold was met. |
| `outcome` | Effectiveness telemetry: did the class recur since the card went active? |

## How each skill applies its cards

Every deep-* skill carries one stable loader stanza — it runs a bundled script and treats what
prints as a hard requirement for that run:

```bash
scripts/load-active-cards.sh deep-plan     # each skill passes its own phase
```

- **Lazy & scoped** — cards reach a skill only when it runs, and only for that phase. A card
  applies to `deep-implement` only if its `owner_phases` lists that exact token.
- **Self-locating** — the script finds the shared registry relative to its own path, so it works
  wherever the plugin is installed. It is copied byte-identically into each skill; only the
  registry is shared.
- **Apply, don't edit** — the skill applies the section addressed to its phase. "No active
  cards" ⇒ proceed normally. On a host with no reliable shell, apply cards by hand from
  `cards/active/`.
- **Toggle, don't silence** — if a card is wrong or noisy, `toggle.sh <ID> off`, never a prose
  edit. Editing to silence a lesson is exactly what "data, not prose" exists to prevent.

> **Code-review is the producer, not a consumer.** The upstream skills load cards.
> `/deep-code-review` is the one built skill with no loader — it is the **producer of lessons**
> (its `findings.json` feeds the loop) and the independent measurement point. A reviewer that
> applied prevention cards would blur that role.

## DLC-001 — the seed card (State / Data-Flow Contract)

The seed card, shipped **active**, is the loop run by hand once. It would have surfaced **~100%
of the benchmark review's severity at plan time**. One card, four phases:

- **`deep-plan`** — a required plan section: one row per piece of state read/written, with writer
  `path:line`, runtime reader `path:line`, and a **"same source?"** column you can't fudge. A row
  with no reader, or a reader resolving a different source, **blocks plan completion**.
- **`deep-plan-review`** — assert the section is present, **every row resolved**, every "single
  source of truth" claim names exactly one source. An unresolved, non-Deferred row blocks the plan.
- **`deep-implement`** — for each runtime row the reader is wired to the writer's source, then a
  **write → execute → assert read** probe — the net typecheck and unit tests miss.
- **`deep-bugfix`** — when the defect is this class, the proof-of-fix chain must terminate in
  *reader resolves writer's source*. A proof that stops at "the write happens" leaves it `unproven`.

Why the row can't be filled without finding the bug: the writer column forces "where does the
save land?", the reader column forces a runtime trace, and "same source?" is a binary you cannot
fudge.

## Failure modes & guards

| Risk | Guard |
|---|---|
| Overfitting to one PR's quirk | Promote a class only after recurrence across **≥2 distinct reviews** — or high severity. |
| Monotonic bloat | Removal/demotion is **first-class**; the Monitor prunes ineffective cards. |
| Conflicting cards | A conflict/dedup check at promotion time. |
| Silent degradation of skills | **Human gate + shadow mode + kill-switch + provenance.** Cards are data, never prose. |
| Auto-application runaway | Stay human-gated until telemetry is proven; only then guarded-auto. |
| Skill bloat / drift | One loader stanza per skill; all variability lives in the registry. |

## What's live · what's next

- **Live now (Phase 1):** the shared **taxonomy**, the **directives registry** with lifecycle
  directories, the **DLC-001** seed card shipped active, and the **loader stanza** in all six
  skills. On/off works by hand today via `toggle.sh`.
- **Planned:** the **Distiller** (`/deep-learn`) — `findings.json` → Pattern Ledger → candidate
  cards; the **Effectiveness Monitor** — recurrence telemetry driving demote / false-positive
  flags; then **guarded auto-promotion**, only once telemetry is trustworthy.

`outcome.verdict` reads `unproven` today because the Monitor is a later phase; until it exists,
humans read the same recurrence signal by hand. The seam is honest about being inert.

---

## The trainee rule

When a skill prints a directive at the start of a run, treat it as a **hard requirement** for
that run. Don't edit cards or skills to silence one — **toggle it**. That single discipline is
what keeps the loop trustworthy.

⬅ **Back to:** [Training overview](README.md)
