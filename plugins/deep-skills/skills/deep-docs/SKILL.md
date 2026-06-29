---
name: deep-docs
description: Generate context-window-aware, machine-readable documentation of what a codebase has built — a standing, queryable orientation map structured for progressive disclosure, with every claim anchored to file:line (symbol) and adversarially verified by fresh agents. Three independently-loadable tiers (tier-0 MAP.md + index.json always-loaded; tier-1 subsystem cards on touch; tier-2 deep references on demand) so a crawling agent loads only the slice its task needs. Use after /deep-implement, after /deep-code-review, or standalone on any repo to orient an agent. Triggers on /deep-docs and on requests to map, document, or generate an AI-readable map of a codebase. Documents only — it never edits application source.
---

# DeepDocs

Produce **context-window-aware documentation of what's been built** — the orientation layer the deep-* series was missing. Implement's hand-off notes are change-scoped and discarded; code-review emits defects, not orientation; conventional doc generators dump one exhaustive human altitude with no notion of "load only this layer." deep-docs writes a **standing, queryable map structured for Progressive Disclosure**: an agent crawling under a token budget loads only the slice its task needs.

**Documents, never decides — and changes no code in the target repo.** deep-docs makes no plan/fix/triage decisions. Its only writes are its own documentation artifacts (`docs/ai-map/**`), the effort manifest line (effort mode), and — series-wiring only, a later phase — cross-references inside this plugin. It never edits application source (see Guardrails).

## Core principle: anchored, tiered, verified

Its signature failure mode is the **dual failure of AI-facing docs**:

- the **stale map** — docs that describe intent, not the code as it is — defended by `path:line (symbol)` **anchoring** + always-on **anchor-verify**;
- the **bloated dump** — docs that must be loaded whole — defended by **three-tier layering** (and, in a later phase, a hard tier-0 token ceiling).

*Every claim is anchored or it's fiction.* No prose enters a trusted tier without a resolvable `file:line (symbol)` anchor. Pre-existing human docs are referenced but **never laundered** into a trusted tier (existing-docs quarantine, `references/intake-and-scope.md`).

## Directive cards (Deep-Learn)

Before you start, load this phase's active directive cards — learned, human-vetted improvements stored as **data**, never baked into this skill. Run the bundled script in this skill's `scripts/` directory and apply what it prints:

```bash
scripts/load-active-cards.sh deep-docs
```

**Treat every directive it prints as a hard requirement for this run**, applying the section addressed to your phase. If it prints "no active directive cards," proceed normally. deep-docs is a directive-card **consumer**, not an owner. Cards are human-gated — never edit a card or this skill to turn one off; toggle with `directives/toggle.sh <ID> off` (see the registry's `directives/README.md`).

## The deep-* series (separation of concerns)

<!-- A quintet today (deep-plan, deep-plan-review, deep-implement, deep-code-review, deep-docs).
     It becomes a sextet once deep-bug-fix ships — the series-wiring phase reconciles the count
     and sweeps the reciprocal table edits into the sibling skills. -->

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-plan` | Frame → explore → question → write the plan (resumable phases + deferreds). | Out of scope here. |
| `/deep-plan-review` | Independently review the finished plan with fresh agents. | Out of scope here. |
| `/deep-implement` | Execute the plan: implement → validate → fix → commit → hand-off. The only skill that writes source. | Out of scope here. |
| `/deep-code-review` | Independently review implemented code; emit findings. | Out of scope here. |
| `/deep-docs` (you) | Map what's built: survey → tier → anchor → verify → index → place a standing `docs/ai-map/`. | **Documents, never decides — changes no code in the target repo.** Runs post-build (after implement/code-review) or standalone on any repo. |

## Default-mode workflow

Run the pipeline end-to-end. Each stage has a spine reference; read it before executing that stage.

### 1. Intake & scope
Resolve the input mode (effort diff / named subsystem / whole repo), standalone-vs-effort home, and host conventions (source dirs, language, test layout) — never reading `.env`/secrets. Apply the existing-docs **quarantine** (index human docs as `human-authored · not anchor-verified`; never ingest their prose). State the resolved scope in one line before launching anything. Whole-repo runs cap scale with interactive scoping and a `coverage.md` note when capped. See `references/intake-and-scope.md`.

### 2. Survey (fan-out per boundary)
Discover boundaries **directory-primary + heuristic refine** (skip vendored/build dirs; split huge dirs by entry-point; merge tiny siblings; cap ~12 boundaries). Launch **one fresh read-only agent per boundary** (≤8 concurrent), each blind to the others and briefed only with its slice, to discover entry points, public surface, key types, invariants, and data flows. Tier-2 chain-traces reuse `references/last-mile.md` methodology. Every split/merge/cap decision is recorded in `coverage.md`. See `references/survey.md`.

### 3. Three-tier layering with anchors
Lay the survey output into three tiers — tier-0 `MAP.md`, tier-1 subsystem cards, tier-2 deep references (earned only by real cross-layer data-flow or a non-obvious invariant; card-only otherwise). Every claim carries a `path:line (symbol)` anchor; the symbol is the nearest preceding declaration matching the language-agnostic keyword set. Every emitted file carries the `GENERATED — do not hand-edit; regenerate overwrites` header. See `references/layering-and-anchors.md`.

### 4. Anchor-verify (always-on, fan-out per card)
Launch **one fresh adversarial verifier per card** (≤8 concurrent) that re-resolves **every** anchor by symbol grep, re-snapping the line on benign drift and returning a machine-readable verdict `accurate | drifted | over-budget`. No sampling — an unverified anchor can't be trusted. **A card with any `drifted`/`over-budget` anchor blocks publish** (the doc-analogue of an unresolved State/Data-Flow contract row). See `references/anchor-verify.md`.

### 5. Index & coverage
Emit `index.json` (concept/symbol → doc + anchor + token-est + load-when + trust), the machine index the crawling agent reads; populate `token_est` inline with `ceil(chars/4)`. Emit `coverage.md` — the doc-coverage honesty artifact (documented / not-documented + why / card-only / referenced-vs-ingested / capped boundaries). See `references/index-and-coverage.md`.

### 6. Place (staging + atomic mv) & report
Generate into the sibling staging dir `docs/.ai-map.staging/` with an `.in-progress` marker; on success (verify passed) atomically replace `docs/ai-map/` via `mv`. A run that finds an existing marker **refuses**, naming the in-flight run. Effort mode also writes a `07-Docs/` pointer + the manifest line. Default output is `docs/ai-map/`; the path is overridable. Close with the coverage summary + the explicit not-documented list. See `references/place-and-report.md`.

## Flags

Per the cross-assistant **Portability** rule, every flag is **natural-language-first** — the plain-language trigger is the primary path (users on Copilot/Codex have no slash-commands or CLI flags); the `--flag` is a convenience layered on top. Always accept the natural-language form.

- **Generate / map the codebase** (default; no flag) — say *"map this codebase," "document what's built," "generate the AI map."* Runs the full default-mode pipeline above.
- **Put the map under \<path>** — say *"put the map under docs/foo," "write the map to \<path>."* Overrides the default `docs/ai-map/` output location (`references/place-and-report.md`).
- **`--refresh`** — say *"refresh the docs," "regenerate the map."* Re-resolves every anchor against current code, reports drift, detects undocumented additions, and regenerates only stale + new subsystems. **Stubbed — lands in a later phase (Phase 3).** Today, a refresh request runs a full regeneration (the staging + atomic-mv path makes that safe and idempotent).

## Guardrails

- **Documents, never decides — changes no code in the target repo.** deep-docs writes only `docs/ai-map/**` (via staging + atomic `mv`), the effort manifest line in effort mode, and the `07-Docs/` pointer in effort mode. It makes no plan/fix/triage decisions and **never edits application source** or any non-`ai-map` doc. It owns `docs/ai-map/` exclusively and never overwrites other docs.
- **Every claim is anchored or it's fiction.** No prose enters a trusted tier (tier-0/1/2) without a resolvable `path:line (symbol)` anchor. A drifted/over-budget anchor blocks publish.
- **Existing-docs quarantine.** Pre-existing human docs are indexed as `external-unverified` pointers only — their prose is never absorbed into a trusted tier. `coverage.md` lists referenced-vs-ingested.
- **Never read `.env` or secrets** during host-convention discovery (source dirs, language, tests, anything). Use `package.json` / `angular.json` / `CLAUDE.md` (or equivalents); ask the user if a needed value isn't there. Degrade gracefully when an optional host helper is absent — no Maûdel-specific or host-specific commands hardcoded.
- **Fresh eyes only.** Survey and verifier agents are fresh and read-only; never pass them the implementation transcript or each other's output.
- **Generated artifacts are machine-owned.** Every emitted file carries the `GENERATED — do not hand-edit; regenerate overwrites` header. Regen is wholesale overwrite, no merge. Humans annotate elsewhere.
- **Never half-write the map.** All generation goes through `docs/.ai-map.staging/` + `.in-progress` marker; `docs/ai-map/` is replaced only by atomic `mv` after verify passes. A second run while a marker exists refuses rather than interleaving.
- **Report progress, don't go silent.** Survey/verify fan-out is long-running; surface boundaries discovered, cards verified, and drift count as it goes.

<!-- Authoring note: this SKILL.md stays under 500 lines with detail in references/, per the
     skill-creator skill's authoring rules (the source of the <500-line limit). Rationale is
     training-program material under docs/Training/ — never baked into this skill. -->
