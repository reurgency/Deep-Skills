# Specialist dimensions (`--multi-agent`)

Under `--multi-agent` (or the in-session `/multi-agent` escalation), the review fans out a **finder fleet of eight independent single-lens passes** (see `references/multi-agent.md` for the full roster, model tiers, budgets, batching, and the dedup → adversarial-verification → synthesis pipeline). Four of those passes run the default lenses — Correctness (`diff-scan`), Last-Mile, Plan Conformance (`conformance`), and Coherence — as **separate** agents, briefed from `references/review-lenses.md` and `references/last-mile.md`. This file holds the briefs for the **four specialist passes**: the three deletion/seam-hunting lenses (`removed-behavior`, `seam-trace`, `frozen-state-probe`) and the combined `quality` sweep (duplication, simplification, performance, conventions).

## The agent contract

One **fresh, read-only** agent per dimension. Each agent is briefed with exactly:

1. **The diff chunk index + chunk files** from the scripted pre-chunking (`references/multi-agent.md` § Stage 0) — read chunks per-file as the lens requires, never the monolithic diff — plus the verbatim stated-scope line.
2. **Its single dimension lens** from this file — one dimension per agent, never two.
3. **Preference sources** — the host project's CLAUDE.md / app guideline docs, conventions discoverable from neighboring code, and the plan when one exists.

**Never the implementation transcript.** Fresh eyes are the point — an agent that saw the implementation reasoning will rationalize the same gaps.

Agents are **finders, not fixers**: read-only codebase access, no edits, no server starts. Each returns findings as structured text in the shape of `references/findings-and-severity.md` with the **`dimension`** field set to its dimension id (below) and a *proposed* `lens` (the nearest default lens); synthesis owns final lens assignment, ids, dedupe, and severity reconciliation (see `references/multi-agent.md`). A dimension that finds nothing says so explicitly — clean is a valid, reportable verdict.

**Overgenerate — within budget, above the nit floor.** Finders report **every** candidate of proposed severity ≥4 their lens sees, subject only to the evidence rule — no self-filtering for plausibility, no caps. For sev ≤3 trivia: the ~10 highest-impact items individually, the rest as one summary candidate. A candidate proposed at **exactly sev 5** must state in one line why it is not a 4 — the verification floor sits at 5, and marginal candidates filed at the floor each cost a verifier. Each finder reads each relevant chunk once and works within a soft cap of ~25 tool calls — one decisive trace per candidate, not verification-grade proof (Stage C owns precision; see `references/multi-agent.md` § Stage A). A candidate withheld out of caution is a finding the review never gets to verify.

## The four specialist dimensions

### `removed-behavior`

**Asks:** for everything this diff *deletes*, where did the behavior go?

Deletions are where reviews that only read the diff forward go blind: removed code looks like cleanup, but it may have been the only thing managing some piece of state or fulfilling some contract. Audit every deletion. Hunt for:

- **Deleted UI affordances with no new home** — a removed button, drawer, dialog, or menu item whose function (editing a flag, triggering a repair, exposing a setting) is not reachable anywhere in the new UI. Name the replacement or flag the orphan.
- **Orphaned persisted state** — deleted code that was the only writer/manager of rows, flags, or columns. Data the removed code used to set, clear, or repair now sits frozen at its last value, and anything that still *reads* it inherits that frozen state with no recovery path (e.g. a removed config drawer leaving `enabled=0` rows that an assembler still hard-errors on).
- **Validation and error handling not re-established** — guards, normalizers, or failure branches that lived in deleted code, where the replacement path silently lacks them.
- **Migrations that don't clean up after the deletion** — a migration that moves data forward but leaves the removed code's state (flags, legacy columns, partial rows) untouched for surviving readers to trip over.
- **Callers and contracts of deleted symbols** — anything still importing or invoking the removed function; events the deleted code emitted or side effects it performed that surviving code still expects.
- **Coverage silently dropped** — tests deleted alongside code whose behavior still exists somewhere else.

### `seam-trace`

**Asks:** for every value this diff *writes*, who *reads* it — and does the read path actually consume the layer the write targets? **When the reader is *external* (a CLI/binary, third-party API, SDK, another service), does the serialized shape actually match what that consumer expects** — not just what the repo's own code and tests agree on?

This is cross-file caller/callee tracing in both directions, hunting integration-seam bugs invisible to per-file reading: each side looks complete alone; the seam doesn't carry the value across. Record the trace like a last-mile chain — path:line per hop. Hunt for:

- **Payloads serialized to an external consumer that no in-repo code can confirm** — when the read side is outside the repo, reading repo code (and repo tests) cannot prove the contract; both can be confidently, mutually wrong. Establish ground truth, in this order: (1) a **sibling implementation in-repo** that targets the same consumer — compare the serialized shape field-by-field; a lone divergence is the bug (the Ollama client sends `image_url: { url }`, the new Codex client sends bare `image_url: url` → the Codex shape is wrong). (2) The consumer's **documented or protocol schema** (docs, type stubs, the binary's own strings). (3) If neither is available, do **not** pass silently — file an **unverified external contract** finding naming the seam and the unproven shape, so the gap is visible at triage instead of shipping green. A passing contract test for this seam is *not* ground truth (see `references/review-lenses.md` § Reading tests adversarially).
- **Writes with no reader** — config, overrides, or state the diff persists that no runtime path ever consumes; settings that are display-only without anyone deciding they should be.
- **Reader/writer layer mismatch** — in layered or fork/override resolution systems, the UI writes to one layer (the fork, the override, the new column) while the runtime still resolves from another (the default, the base, the legacy column). Trace the *exact* layer each side touches, not just the entity.
- **Readers left on the old source** — a write path moved in this diff, but some consumer still reads from where the data used to land.
- **Caches not invalidated by new writers** — the diff adds or moves a write path without busting caches that existing readers consult; stale reads survive until an unrelated refresh.
- **Unguarded reads of new writes** — new columns/fields consumed without guards on the read side (`JSON.parse` without try/catch, type coercions, missing null handling), where one bad row poisons every read of the collection.
- **Backfill/compat shims wired to only some entry points** — a legacy-data carry-forward that runs on one route while other routes reach the same data cold.

### `frozen-state-probe`

**Asks:** for every persisted value whose writer, clearer, or repair path this diff deletes, what does surviving code actually **do** when fed the exact value now frozen in place?

This is the probe complement to the two lenses above: `removed-behavior` finds the orphaned state, `seam-trace` finds layer mismatches — this lens takes the **concrete frozen value** and runs the surviving readers against it. Reading the reader's code forward is not enough; both of this skill's longest-standing benchmark misses were exactly this shape (a reader that hard-errors on `enabled=0` rows whose only re-enable path was deleted; a normalizer that destructively "completes" a half-populated template subset whose filler was deleted). The code looked fine read forward; it failed only *at the frozen value*.

Method — all four steps, per value:

1. **Enumerate the frozen values.** Rows, flags, columns, config entries, cache keys whose only writer/clearer/repairer the diff removes. Include values **frozen mid-lifecycle**: a flag parked at its "temporary" state awaiting a transition that will now never run, a partial structure awaiting a filler that no longer exists.
2. **Pin the concrete value, not the type.** What will real databases/stores hold after this diff ships — `enabled=0`, `tracks='[]'`, a subset with 3 of 7 slots filled? If existing data can hold several such values, probe each.
3. **Probe every surviving reader at exactly that value.** Substitute the value into the read path line by line and derive what happens; where the host project offers a cheap runnable harness (a unit test, a pure function, a REPL), actually run it. Classify the outcome: hard error, silent skip, wrong output, or destructive "repair" (a normalizer that overwrites the frozen remainder).
4. **Cite the probed chain.** A finding requires: frozen value → reader path:line per hop → derived or observed behavior at that value. **No probed chain, no finding** — enforced at synthesis like the last-mile chain rule.

### `quality`

**Asks:** is this change clean code by *this* project's standards — no rebuilt wheels, no dead weight, no avoidable work, no broken conventions?

One pass covering four facets. This is pattern-matching work — run it on the **cheap model tier** (latest Sonnet — never Haiku) per the fleet table in `references/multi-agent.md`; calibration showed these facets produce almost exclusively nit-tier findings, so they share one budget rather than four.

**Severity cap: this pass proposes nothing above sev 4** (default configuration; the cap is lifted under `--mega`). A candidate it believes rates higher is filed at 4 with a `note: believed-higher (N)` — synthesis may promote it into verification when it looks load-bearing. The cap exists because quality candidates filed at the sev-5 verification floor consistently died under verification, making their refutation this pass's main downstream cost; its findings therefore never trigger verifiers on their own.

Hunt for, by facet:

- **Duplication / reuse** — re-implemented utilities that already exist in the codebase (**name the existing implementation with its path** — a duplication finding without the original named is not a finding); near-identical blocks pasted in two+ places; locally declared types duplicating shared contract types (drift between copies is also a last-mile risk — note it for synthesis); parallel infrastructure standing alongside an existing equivalent.
- **Simplification** — dead code nothing reaches (cross-flag with last-mile if it was *supposed* to be wired); leftovers (commented-out blocks, unused imports, debug logging, scaffolding TODOs, fixtures left switched on); abstraction with one caller and no second on the horizon; hand-rolled logic with a stdlib/framework equivalent.
- **Performance** — N+1 patterns (a query/call/read inside a loop where one batched call would do); work re-done per render/request/keystroke that depends on nothing that changed; missing memoization **where neighboring code practices it** (cite the neighbor; don't demand idioms the codebase doesn't use); unbounded growth (caches/arrays/listeners that only accumulate).
- **Conventions / architecture** — violations of documented rules (CLAUDE.md / app guidelines — cite the rule's source file); naming that breaks the project's established pattern; a different state-management idiom than the project's established one for the same job; logic in the wrong layer (business rules in components, HTTP outside services, shared types bypassed); files placed outside the pattern their siblings follow. Sources, in order: documented rules, then how the three nearest similar things are built — discover them, don't assume a universal style guide.

## Overlap is expected — synthesis resolves it

The dimensions deliberately overlap each other and the default lenses (a leftover mock is `quality` *and* a last-mile failure mode; a duplicated type is `quality` *and* contract-drift fuel; an orphaned flag is `removed-behavior` *and* a `frozen-state-probe` target *and* a `seam-trace` frozen read — the probe adds what the other two don't: the reader's behavior at the concrete value). Agents should report what their lens sees without worrying about overlap; **synthesis** dedupes one root cause into one finding with multiple dimension tags (`references/multi-agent.md`).
