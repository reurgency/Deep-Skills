# deep-docs — Design Rationale

> **Training material. Stage: planned, not yet built.** `deep-docs` has no skill tree under
> `plugins/deep-skills/skills/` yet — its design is fully resolved in a `/deep-plan` artifact.
> Per the task brief, this page derives from that plan's **Approach** section rather than
> re-deriving: `.deep-skills/deep-docs/01-Plan/plan.md` (the nine key decisions + rejected
> alternatives are recorded there), with the differentiation thesis in
> `docs/roadmap/DEEP-DOCS-DESIGN.md`. Anchors below point at the plan/design docs (where the
> decisions live today), not at skill files (which don't exist yet).
>
> **The skill's one job:** be the series' missing **orientation layer** — context-window-aware
> documentation of *what's been built*, structured for **Progressive Disclosure** so an agent
> crawling under a token budget loads only the slice its task needs
> (`.deep-skills/deep-docs/01-Plan/plan.md:7-9`). Its signature failure — the analogue of
> code-review's last-mile — is the **dual failure of AI-facing docs**: the *stale map* (describes
> intent, not the code as it is) and the *bloated dump* (must be loaded whole)
> (`.deep-skills/deep-docs/01-Plan/plan.md:9`).

## Decisions at a glance
- [1. Three independently-loadable tiers (progressive disclosure)](#1-three-independently-loadable-tiers)
- [2. Every claim is anchored or it's fiction (`path:line (symbol)`)](#2-every-claim-is-anchored-or-its-fiction)
- [3. Doc location: in-repo `docs/ai-map/`, effort-aware, overridable](#3-doc-location)
- [4. Token cost: `chars/4` heuristic, labeled an estimate everywhere](#4-token-cost-the-chars4-estimate)
- [5. Anchoring: `path:line (symbol)`, symbol-primary, re-snap on drift](#5-anchoring-symbol-primary-with-re-snap)
- [6. Boundary discovery: directory-primary + heuristic refine](#6-boundary-discovery-directory-primary)
- [7. Anchor-verify: fan-out per card, exhaustive, no sampling](#7-anchor-verify-exhaustive-no-sampling)
- [8. Tier-0 ceiling: fixed hard cap with grouped overflow](#8-tier-0-ceiling-grouped-overflow)
- [9. Refresh: one `--refresh`, dual git-free signal + convergence](#9-refresh-dual-signal--convergence)
- [10. Artifact ownership: `docs/ai-map/` is 100% machine-owned](#10-artifact-ownership-machine-owned)
- [11. Existing docs: quarantine as unverified references](#11-existing-docs-quarantine-not-launder)
- [12. Build by mirroring siblings; rationale stays in `docs/Training/`](#12-build-by-mirroring-siblings)
- [13. Cross-assistant portability: natural-language invocation is primary](#13-cross-assistant-portability)

---

## 1. Three independently-loadable tiers
**What it does.** deep-docs emits three tiers that can each be loaded on their own: tier-0
`MAP.md` + `index.json` (always-loaded, tiny), tier-1 subsystem cards (loaded on touch),
tier-2 deep references (on demand) (`.deep-skills/deep-docs/01-Plan/plan.md:9`).
**Alternatives considered / rejected.** A single exhaustive human-readable dump, the way
conventional generators (typedoc/sphinx/docusaurus) work — "one exhaustive altitude with no
notion of 'load only this layer,' costing an agent its whole context window to answer a
one-subsystem question" (`.deep-skills/deep-docs/01-Plan/plan.md:7`).
**Why this choice.** The product *is* context-window economy: an agent on a token budget
should pay only for the slice its task needs. Tiering is the structural defense against the
*bloated dump* half of the signature failure (`.deep-skills/deep-docs/01-Plan/plan.md:9`).

## 2. Every claim is anchored or it's fiction
**What it does.** No prose enters a trusted tier without a resolvable `file:line (symbol)`
anchor, and every anchor is adversarially verified
(`.deep-skills/deep-docs/01-Plan/plan.md:9,22`).
**Alternatives considered / rejected.** Free-prose documentation that describes intent — the
ordinary doc-generator output. Rejected because it produces the *stale map*: docs that drift
from the code as it actually is.
**Why this choice.** Anchoring + freshness re-check is the structural defense against the
*stale map* half of the signature failure; it is the doc-equivalent of the series' evidence
rule ("a `path:line`, a named symbol, or an observed behavior") and of an unresolved DLC-001
row blocking a plan (`.deep-skills/deep-docs/01-Plan/plan.md:22,67`).

## 3. Doc location
**What it does.** Output defaults to in-repo `docs/ai-map/`; in effort mode it *also* writes a
`07-Docs/` pointer + manifest line; the path is overridable by argument
(`.deep-skills/deep-docs/01-Plan/plan.md:41`).
**Alternatives considered / rejected.** A non-version-controlled or out-of-repo store. (The
design's §11 open question on doc location is resolved here in favor of in-repo.)
**Why this choice.** In-repo means the map is standing, version-controlled, and diffs with the
PR that changed the code — so doc drift is reviewable, not invisible
(`.deep-skills/deep-docs/01-Plan/plan.md:41`).

## 4. Token cost: the `chars/4` estimate
**What it does.** Token cost is a cheap `ceil(chars/4)` heuristic, **labeled an estimate
everywhere it appears** (e.g. `~450 est`) (`.deep-skills/deep-docs/01-Plan/plan.md:42`).
**Alternatives considered / rejected.** A real tokenizer dependency — "rejected for the
markdown-only/zero-dep baseline" (`.deep-skills/deep-docs/01-Plan/plan.md:51`).
**Why this choice.** Zero dependencies fits a markdown-only repo, and the estimate is accurate
enough to drive load/skip decisions; it is explicitly upgradeable to a real tokenizer later,
with the "estimate" label as the seam (`.deep-skills/deep-docs/01-Plan/plan.md:42,215-217`).

## 5. Anchoring: symbol-primary with re-snap
**What it does.** Anchors are `path:line (symbol)`, **symbol-primary**: verify re-resolves by
symbol first, re-snaps the line number if it drifted (benign), and flags `drifted` only if the
symbol is gone (`.deep-skills/deep-docs/01-Plan/plan.md:43`).
**Alternatives considered / rejected.** Content-hash anchoring — "rejected as noisy (flags
benign edits)" (`.deep-skills/deep-docs/01-Plan/plan.md:51`).
**Why this choice.** A raw line number is fragile (any edit above shifts it); a content hash is
*too* sensitive (every reformat trips it). Symbol-primary tolerates benign movement while still
catching real removal — the right sensitivity for "did the thing this doc describes still
exist?" (`.deep-skills/deep-docs/01-Plan/plan.md:205`).

## 6. Boundary discovery: directory-primary
**What it does.** Subsystem boundaries are discovered directory-primary with heuristic refine —
split huge dirs by entry-point, merge tiny siblings, cap the count
(`.deep-skills/deep-docs/01-Plan/plan.md:44,79`).
**Alternatives considered / rejected.** Import-graph / LSP boundary discovery — "rejected as
non-portable for the standalone-on-any-repo primary mode"; deferred as an opt-in refinement
(`.deep-skills/deep-docs/01-Plan/plan.md:51,218-220`).
**Why this choice.** Directory structure is universally available; an import graph or LSP is
language/tooling-specific and breaks the "runs standalone on any repo" promise. Semantic
discovery is kept as a future opt-in layer feeding the same boundary list
(`.deep-skills/deep-docs/01-Plan/plan.md:219-220`).

## 7. Anchor-verify: exhaustive, no sampling
**What it does.** Always-on, fan-out-per-card verification: one fresh adversarial verifier per
subsystem card re-resolves *every* anchor and returns `accurate | drifted | over-budget`;
bounded ~8 concurrency; any drifted/over-budget anchor blocks publish
(`.deep-skills/deep-docs/01-Plan/plan.md:45,81`).
**Alternatives considered / rejected.** Sampled/budgeted verification — "rejected because an
unverified anchor violates the core anchoring guarantee"
(`.deep-skills/deep-docs/01-Plan/plan.md:51,204`).
**Why this choice.** Symbol-grep is cheap, so exhaustive verification is affordable, and the
guarantee is binary: if even one anchor is unverified, the trusted tier can't be trusted. This
mirrors code-review's fresh-agent adversarial verification, with the verdict re-skinned for docs
(`.deep-skills/deep-docs/01-Plan/plan.md:33,45`).

## 8. Tier-0 ceiling: grouped overflow
**What it does.** Tier-0 has a fixed hard ceiling (~2,000 token-estimate); when subsystems
exceed it, `MAP.md` groups them by top-level area with per-group subtotals + load-when triggers,
and detail spills into the grouped index — **never silently truncated**
(`.deep-skills/deep-docs/01-Plan/plan.md:46`).
**Alternatives considered / rejected.** Silent truncation; or scaling the ceiling with repo size
(implied by the "fixed+group vs truncate vs scale" framing at
`.deep-skills/deep-docs/01-Plan/plan.md:130`).
**Why this choice.** A scaling ceiling defeats the purpose (tier-0 must stay tiny and always-
loadable); silent truncation reads as "covered everything" when it didn't. Grouping keeps tier-0
under budget while preserving an honest, navigable path to the spilled detail
(`.deep-skills/deep-docs/01-Plan/plan.md:46,203`).

## 9. Refresh: dual signal + convergence
**What it does.** A single `--refresh` consolidates the design's `--verify` + incremental:
(1) re-resolve all anchors → report drift; (2) diff the current source file-set against
`index.json` → catch undocumented additions; regenerate only stale + new subsystems. A git base
ref is an optional accelerator; on a brownfield/dirty/non-git tree the dual git-free signal still
drives the decision, and a stored alignment fingerprint drives a convergence model
(`.deep-skills/deep-docs/01-Plan/plan.md:47,137`).
**Alternatives considered / rejected.** Git-only or anchor-only refresh signals (the "dual
git-free vs git-only vs anchor-only" framing at
`.deep-skills/deep-docs/01-Plan/plan.md:140`).
**Why this choice.** Git-only breaks on non-git/dirty/shallow trees; anchor-only misses *new*
undocumented files. The dual signal catches both drift and additions without depending on git,
while still using git as a fast path when it's reliable — the two failure modes need two probes
(`.deep-skills/deep-docs/01-Plan/plan.md:137`).

## 10. Artifact ownership: machine-owned
**What it does.** `docs/ai-map/` is 100% machine-owned; every file carries a
`GENERATED — do not hand-edit; regenerate overwrites` header, and regen is a wholesale overwrite,
no merge (`.deep-skills/deep-docs/01-Plan/plan.md:48`).
**Alternatives considered / rejected.** A two-rendering output (an agent map *and* a separate
human site) — "rejected, markdown is already human-readable, a second rendering just drifts"
(`.deep-skills/deep-docs/01-Plan/plan.md:51`); and merge-on-regen instead of overwrite.
**Why this choice.** Docs here are an *index, not a narrative*, so regenerate-whole is correct
and merge would invite drift; humans annotate elsewhere. A single machine-owned rendering can't
fall out of sync with itself (`.deep-skills/deep-docs/01-Plan/plan.md:48`).

## 11. Existing docs: quarantine, not launder
**What it does.** Useful existing docs (README/design notes) are indexed in `index.json` as
external pointers marked `human-authored · not anchor-verified` so the crawler can find them, but
their prose is **never** absorbed into a trusted tier; `coverage.md` lists referenced-vs-ingested
(`.deep-skills/deep-docs/01-Plan/plan.md:49`).
**Alternatives considered / rejected.** Ingesting existing-doc prose into the trusted tiers
(laundering it) — rejected as a risk in its own right
(`.deep-skills/deep-docs/01-Plan/plan.md:208`).
**Why this choice.** Unverified human prose absorbed into a trusted tier silently breaks the
anchoring guarantee — the reader can no longer tell anchored fact from inherited claim.
Quarantine keeps the trust boundary visible (`.deep-skills/deep-docs/01-Plan/plan.md:22,49`).

## 12. Build by mirroring siblings
**What it does.** The skill is built by mirroring its two closest siblings — `deep-code-review`
(fan-out survey, fresh-agent adversarial verification, evidence/anchor discipline, host-convention
discovery) and `deep-plan`/`deep-bug-fix` (skill scaffold, directive-card stanza, artifact/manifest
conventions) — reusing host-agnostic machinery verbatim, including a **byte-identical** copy of
`scripts/load-active-cards.sh` from `deep-plan` and `references/artifact-structure.md` from any
sibling (`.deep-skills/deep-docs/01-Plan/plan.md:27-36,76-77`). The design-rationale write-up
(this page) lives under `docs/Training/`, **never** baked into the skill
(`.deep-skills/deep-docs/01-Plan/plan.md:11,40,175`).
**Alternatives considered / rejected.** Inventing new scaffolding; or shipping a
`references/design-rationale.md` inside the skill. The latter is explicitly rejected: "the skill
doesn't read it, so it would only bloat `references/`"
(`.deep-skills/deep-docs/01-Plan/plan.md:11`).
**Why this choice.** The series' standalone rule says each skill self-contains and only
`directives/` is shared, with the two host-agnostic files copied byte-identical — so reuse means
*copy*, not import. And rationale documentation justifies design to a *human*; the skill never
loads it, so it belongs in training material (`.deep-skills/deep-docs/01-Plan/plan.md:18,11`).

## 13. Cross-assistant portability
**What it does.** Natural-language invocation is the **primary** path; `--flags` are a convenience
layered on top, and `--refresh` plus every in-session interaction ships a plain-language trigger
from day one (e.g. "refresh the docs") (`.deep-skills/deep-docs/01-Plan/plan.md:21`).
**Alternatives considered / rejected.** Slash-command/CLI-flag-only invocation (the convention
the four built skills grew up with).
**Why this choice.** The series must be drivable by users on GitHub Copilot or Codex, who have
neither Claude-Code slash-commands nor a CLI-flag convention; deep-docs is built as the reference
implementation of this portability principle, with the retrofit of the older skills tracked as a
separate sweep (`.deep-skills/deep-docs/01-Plan/plan.md:21,227-229`; memory
`deep-skills-cross-assistant-portability`).

---

### Reflexive note (from the design doc)
The design observes that deep-docs "recreates Claude Code's own Skills architecture" — tier-0
`MAP.md` is a always-loaded index, tier-1 cards load on touch, tier-2 refs load on demand, exactly
the progressive-disclosure shape a SKILL.md + `references/` uses. The orientation layer for agents
is, structurally, the same idea as the skill format that produced it
(`docs/roadmap/DEEP-DOCS-DESIGN.md`; `.deep-skills/deep-docs/01-Plan/plan.md:10`).

### Where rationale was *not* recovered
None of the nine key decisions is unsourced — the plan records alternatives + rationale for each
(`.deep-skills/deep-docs/01-Plan/plan.md:40-51`). The only open items are the design's own
*deferred* upgrades (real tokenizer, import-graph/LSP discovery, content-hash anchoring), which are
recorded as deliberate future work, not missing rationale
(`.deep-skills/deep-docs/01-Plan/plan.md:210-223`).
