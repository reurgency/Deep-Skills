# Multi-agent review (`--multi-agent` / `/multi-agent`)

The full-treatment review, in five stages: a **scripted setup stage** that does everything deterministic before (and alongside) the agents, a **finder fleet** of independent single-lens passes that deliberately overgenerates candidates, a dedup/decomposition pass, an **adversarial verification** stage that restores precision on the findings that matter, and a **script-assembled synthesis** into **one** report. Trades tokens for both recall (many narrow, independent passes out-find one broad pass) and precision (every surviving Minor+ finding has been attacked by a fresh skeptic). Use for large diffs, multi-phase implementations, pre-merge gates, or whenever the user asks (flag or in-session `/multi-agent` escalation).

**Token discipline is part of the contract.** Two measured baseline runs calibrated this mode. The first (80-file PR, 10 finders, verify-everything) spent ~57% of its tokens on finders re-reading their own large contexts and ~26% verifying nit-tier candidates that no verification ever changed — that bought the finder budgets and the sev ≥5 verification floor. The second (7 finders, floor in place) cut real cost ~37% and showed where the remainder goes: every finder independently ingested the full 15k-line diff (finders ≈ 58% of all spend), the pre-pass ran serially before finders that never consume its output (~13 min), synthesis hand-wrote ~103k output tokens that were mostly transcription of structured verdicts it already had, and the main-model verifier fleet spent itself mostly demoting marginal sev-5 candidates. The scripted stages, model tiers, and budgets below exist to keep the mode's cost proportional to its value — do not drop them when a run "feels important"; every one is calibrated from where the spend demonstrably did and didn't buy findings.

**Two configurations, one pipeline.** The stages below describe the **default** `--multi-agent` configuration. `--mega` (documented at the end) runs the same pipeline with the cost/accuracy dials at maximum — for release gates worth the spend. There is one skill with dials, not two divergent modes.

Under this mode the default four-lens pass does **not** additionally run as one combined agent — its four lenses run as four of the independent finder passes below, which is strictly stronger: a single agent's lenses anchor on each other; eight fresh agents can't.

## Stage 0 — Scripted setup (deterministic; before and alongside agents)

Three pieces of this mode are deterministic and MUST be scripted, never delegated to agents. Write small ad-hoc scripts in the session (host-project commands discovered per `references/deterministic-prepass.md`; the **never-read-`.env`** rule applies to scripts too).

1. **Diff pre-chunking.** Before launching finders, split the resolved diff **by script** into per-file chunk files under a temp dir, plus an index (one line per chunk: path, +/− counts, chunk filename). Finders are briefed with the index and read chunks per-file as their lens requires — never the monolithic diff. In the second baseline, six-plus agents independently re-derived this split (`grep -n '^diff --git'`), and full-diff ingestion by every finder was the single largest token sink. The index also lets a finder claim coverage honestly: it lists which chunks it read.
2. **Pre-pass launched in parallel, not before.** The deterministic pre-pass (lint, typecheck, tests) runs **concurrently with the finder fleet**: finders never consume its output (it joins at synthesis), so serializing it buys nothing but wall clock. Launch it scripted/in-background, then launch the finder batch immediately. Base-vs-head test attribution is also scripted — two worktrees, both suites concurrently, normalized outputs diffed — see `references/deterministic-prepass.md` § Scripted base-vs-head attribution.
3. **Verifier fact pre-harvest.** Before launching each verifier (Stage C), script the cheap lookups its brief will need: the cited evidence lines with surrounding context, definition sites of named symbols, and caller/reader lists (`grep -rn` per symbol). Inject the harvested facts into the verifier prompt. The verifier keeps codebase access for the actual refutation — the harvest just stops it spending its first several tool calls re-finding what a grep finds exactly.
4. **Situational-check matching.** Grep the chunk files for each catalog entry's Match pattern (`references/situational/index.md`) by script, and load the body of every check that hits. Each matched body is appended to the brief of the finder(s) it names in **Attaches to** (no new finder agents — the fleet stays eight). Record the fired checks for the report header's **Situational checks** line. Full mechanism: `references/situational-checks.md`.

## Stage A — Finder fleet (overgenerate, within budget)

### Model tier resolution — read this before launching anything

The three tiers (**main**, **mid**, **cheap**) are abstract — they bind to concrete host model IDs through the model map. **Before launching anything, read `references/model-map.md` and bind each tier (main/mid/cheap) to its concrete host model ID; set the model explicitly on every agent launch — never an alias, never a host default. The map is a required input.**

Two binding rules:

1. **The main tier IS the orchestrator's (ceiling) model — never anything smaller.** The ceiling is the orchestrator's own model — the strongest the user can access. Tiers resolve **downward from the ceiling, never upward**, and **collapse up to it** when no cheaper reasoning model exists (a restricted Sonnet-4.6 ceiling binds main = mid = cheap = Sonnet 4.6 — see `references/model-map.md`).
2. **All three tiers are reasoning tiers — the host's small/utility models (on Claude Code, Haiku) never appear here, any tier, any stage, any agent.** Not because a model name is banned, but because every task in this pipeline — finding, verifying, synthesizing — is reasoning work, so a small model is never the right tool. A calibration run whose finders silently routed to Haiku produced 0 Blockers and 0 Majors on a diff with two known Criticals — output worse than none, because it ships false confidence.

**Set the model explicitly on every agent launch** (the Agent tool's `model` parameter / per-agent model setting) — never rely on inheritance or a default. That is exactly how the Haiku mis-route happened: tier labels like "main model" were left to implicit resolution. Before launching the fleet, resolve each tier to its concrete **full model ID** via `references/model-map.md` and use those IDs in every launch. If any agent's transcript or first response shows it running on a model below its assigned (ceiling-relative) tier, its output is invalid: discard it and relaunch that agent with the model set explicitly.

Eight independent finder passes, each a **fresh, read-only agent with exactly one lens**, model-tiered by what calibration showed each lens actually catches:

| # | Pass id | Lens brief | Nearest default lens | Model tier |
|---|---|---|---|---|
| 1 | `diff-scan` | Line-by-line correctness read of the diff — `references/review-lenses.md` § Correctness | `correctness` | mid |
| 2 | `removed-behavior` | Audit every deletion: where did the behavior go? — `references/dimensions.md` | `correctness` | main |
| 3 | `seam-trace` | Write-path → read-path tracing across files/layers — `references/dimensions.md` | `last-mile` | main |
| 4 | `last-mile` | Promised-behavior enumeration + hop-by-hop chain walk — `references/last-mile.md` | `last-mile` | main |
| 5 | `frozen-state-probe` | What does surviving code do at values frozen by deleted writers? — `references/dimensions.md` | `correctness` | main |
| 6 | `conformance` | Plan / PR-description conformance — `references/review-lenses.md` § Plan Conformance (incl. no-plan degradation) | `plan-conformance` | mid |
| 7 | `coherence` | One-mind's-work check — `references/review-lenses.md` § Coherence | `coherence` | mid |
| 8 | `quality` | Combined duplication / simplification / performance / conventions sweep — `references/dimensions.md`. **Severity-capped at ≤4.** | `coherence` | cheap |

**Tiering rationale (calibrated across both benchmark runs):** `seam-trace`, `last-mile`, and `removed-behavior` found every Blocker and Major in both runs — they stay on the main tier, as does `frozen-state-probe` (it hunts the same defect class). `diff-scan`, `conformance`, and `coherence` produced solid Minors and no Blockers in either run — the mid tier covers them. `quality` produces nit-tier output by design and is **capped at proposed severity ≤4** (a candidate it believes rates higher is filed at 4 with a believed-higher note — see `references/dimensions.md`); the cap means quality candidates never trigger verifiers — in the second baseline the quality pass was the cheapest finder, but every sev-5 it proposed died in verification, making refutation its main downstream cost.

Launch rules:

- **Cap: 8 concurrent agents** — the full fleet of eight launches as one parallel batch (one message, multiple Agent calls), while the Stage 0 pre-pass runs alongside.
- **Read-only finders.** No edits, no server starts, no writes anywhere — they read the diff chunks and the codebase and return candidates as structured text. This is what makes wide parallelism safe.
- **Brief per agent:** the **chunk index + pointers to the chunk files** (Stage 0), the verbatim stated-scope line, that agent's **single** lens brief (never two), **any situational-check bodies that matched and attach to this lens** (Stage 0 piece 4), and the preference sources (host CLAUDE.md / discovered conventions, the plan when one exists). **Never the implementation transcript.**
- **Changed test chunks are not an optional skip.** A finder may legitimately not read a chunk its lens doesn't touch — but **changed/added test files are exempt from that latitude for the `diff-scan` and `coherence` finders**, which must read them and apply `references/review-lenses.md` § Reading tests adversarially (does the assertion encode the intended contract, or codify whatever the code emits — especially a payload shape sent to an external consumer?). This is a calibrated fix: in the benchmark miss, every finder listed the vision contract-test chunk in `chunksSkipped`, so the one artifact in the diff that pointed at the wrong external shape was never read while the pre-pass reported the suite green. Skipping a test chunk is reported in the finder's coverage note like any skip — but for these two finders it is a defect, not a budget choice.
- **Tool budget: finders find, verifiers prove.** Each finder reads each relevant chunk **once**, then makes only targeted reads to establish that a candidate is evidence-backed — a soft cap of **~25 tool calls** per finder. One decisive trace per candidate suffices; do **not** exhaustively re-trace every path or build verification-grade proofs in the find stage (that is Stage C's job, and paying for it twice was the single largest cost in the first baseline run). A finder that hits its budget files what it has and notes which chunks it didn't get to.
- **Overgenerate — above the nit floor.** Each finder reports **every** candidate of proposed severity ≥4 its lens sees, subject only to the evidence rule (path:line, named symbol, or observed behavior). No self-filtering for plausibility, no caps, no severity anchoring against what other lenses might say. For sev ≤3 trivia, file the **~10 highest-impact** items individually and roll the remainder into one summary candidate (one line each). **A candidate proposed at exactly sev 5 must state in one line why it is not a 4** — the verification floor sits at 5, and the second baseline showed marginal candidates pile up exactly at the floor, where each one costs a verifier; nearly all were demoted.
- Each candidate uses the `references/findings-and-severity.md` shape with `dimension` set to the pass id, a *proposed* `lens` (nearest default lens, per the table), and a *proposed* severity on the 1–10 scale.

Scale down sensibly when the diff can't feed a lens (a purely additive diff may not need `removed-behavior` or `frozen-state-probe`; a tiny diff may not need `quality` at all) — but never scale **up** past the eight defined passes (the `--security` seam below is the one extension point).

## Stage B — Dedup + decomposition

The main session merges the raw candidate pool **by root cause**, applying two complementary rules:

1. **Merge** when one fix resolves both reports. One root cause surfacing in several passes becomes **ONE finding carrying multiple dimension tags** — e.g. a broken write path flagged by `seam-trace` and by `last-mile` is one finding, `dimension: ["seam-trace", "last-mile"]`, keeping the strongest evidence from each. Symptom-level matching isn't enough; ask whether one fix resolves both reports.
2. **Split (the converse — equally binding)** when one candidate bundles **independent sub-defects with different fix paths**: file them as separate findings, cross-referenced. "The cache is wrong" is not one finding if it contains a missing out-of-order guard, a missing invalidation on writes, and a bad fallback default — those are three fixes, so three findings. Likewise, **evidence cited inside one candidate that is itself a defect must be filed as its own finding** (a stub endpoint quoted as proof of a broader wiring gap is also, separately, a stub endpoint).

The test for both directions is the same question: *how many independent fixes does this describe?* One fix → one finding. N fixes → N findings.

**Stream, don't batch:** as a candidate clears dedup/decomposition at or above the verification floor, its verifier launches immediately (Stage C) — don't hold the full merged set for a single verification wave.

## Stage C — Adversarial verification (severity-gated, model-tiered, streamed)

**The verification floor: candidates with proposed severity ≥5 (Minor and up) get verified; sev ≤4 ships unverified.** In the first calibration run every verification outcome that changed anything happened at sev ≥4, and verifying the nit tail consumed ~a quarter of the run for zero changed verdicts. Below-floor findings carry `verification: unverified` into the report and findings.json, with their finder evidence intact; the report states the floor so readers know what "unverified" means. Two adjustments are allowed, both upward: a Stage B merge that raises a candidate's severity to ≥5 puts it above the floor, and synthesis may explicitly send a sev-4 candidate to verification when it looks load-bearing (state why — this is also the promotion path for the quality pass's believed-higher notes). Never lower the floor mid-run to "be thorough" — that decision was made when the mode was invoked.

**Verifiers are model-tiered by what their verdict gates.** In the second baseline, every sev-5 verification ended in a demotion or refutation — knocking down floor-gaming marginal findings is pattern-checking work a cheap model does well; the expensive skeptic is reserved for candidates whose confirmation would gate the merge:

- **Sev 5 candidates → `cheap`-tier verifier** (the cheapest *reasoning* model, e.g. Sonnet at an Opus/Fable ceiling — never a small model; resolve via `references/model-map.md`). If a cheap verifier *confirms* a sev-5 **and raises** its severity to ≥6, the raise doesn't stand on its own — a main-tier verifier re-checks before synthesis accepts it.
- **Sev ≥6 candidates → main-tier verifier** (the orchestrator's model, per `references/model-map.md` — set explicitly at launch).

**One streamed wave, not batched waves.** Verifiers launch as candidates clear Stage B, as a rolling window under the ≤8 concurrency cap — never accumulated into discrete waves with barriers between them (the second baseline's two-wave barrier idled the fleet between waves). Each verifier's prompt carries its Stage 0 fact pre-harvest.

Every candidate at or above the floor faces a **fresh verifier agent** (read-only, never shown the finder's reasoning beyond the candidate itself) whose brief is to **refute it**:

- **Burden of proof is on the finding.** The verifier's job is to prove the claim wrong against the actual code: read the cited evidence in context, trace the chains the finder claims are broken, look for the guard/reader/wiring the finder says is missing. If the evidence doesn't hold up under that attack, the candidate dies.
- **Verify sub-claims independently.** A candidate asserting three things gets three verdicts; partial survival is recorded (the confirmed sub-claims stand, the refuted ones are noted in the finding).
- **Verify the severity, not just the existence.** Severity must be justified by **counting independent, user-reachable trigger paths** to the failure (see `references/findings-and-severity.md` § Calibrating severity). The verifier confirms, raises, or lowers the proposed severity with a stated rationale — a defect reachable from three independent UI paths is not the same severity as one requiring a hand-crafted DB row.
- **Fixed verdict format — required.** Every verifier returns its result in exactly this structure, which is what makes Stage D's script assembly possible:

  ```
  VERDICT: confirmed | plausible | refuted
  SUB-CLAIMS:
  - <sub-claim, one line>: confirmed | plausible | refuted — <one-line basis>
  SEVERITY: <N>/10 — <one-line trigger-path rationale>
  RATIONALE: <≤3 lines>
  ```

  A verifier that returns free prose instead gets one retry with the format restated.
- **Verdict meanings:** `confirmed` (evidence independently reproduced) · `plausible` (couldn't refute, couldn't fully reproduce — kept, marked) · `refuted` (dropped). Below-floor findings keep `unverified`.
- **One verifier per finding, one finding per verifier.** Don't batch multiple findings into one verifier above the floor — shared context lets verdicts anchor on each other.

**Refuted candidates are dropped from the report body but never silently** — they are recorded in the report's **Refuted candidates** appendix with the refutation rationale (id, one-line claim, why it died). This audit trail is what licenses Stage A to overgenerate.

## Stage D — Synthesis (script-assembled; the model writes only the judgment)

Synthesis is split in two: **mechanical assembly is scripted; the model writes only what requires judgment.** In the second baseline, synthesis hand-wrote ~103k output tokens, most of it transcription of structured records it already had.

**By script** — assembled directly from the candidate records and the fixed-format verdicts:

- `findings.json` (ids assigned sequentially as `CR-NNN` across the merged set, `tier` derived from `severity`, `verification` taken from VERDICT lines);
- the severity rollup and the verification-funnel line (N candidates → N at sev ≥5 verified: N confirmed · N plausible · N refuted · N below the floor unverified);
- the nit-tier table (id, severity, one-line claim, evidence pointer);
- the Refuted-candidates appendix skeleton (pass id, claim, refutation rationale from RATIONALE lines);
- the `certificate.md` scaffold (verdict = fail iff unresolved Blockers exist).

**By the model** (the orchestrator itself, in-session — one pass over the verified set plus the pre-pass results; never delegated to a smaller model):

1. **Enforce the evidence rules.** Findings without evidence (path:line, named symbol, or observed behavior) are rejected here, and the **last-mile no-chain-no-finding rule** is enforced on anything last-mile-shaped: no cited hop-by-hop chain, no finding (`references/last-mile.md`). The probe lens's equivalent rule (no probed chain, no finding) is enforced the same way.
2. **Reconcile severities.** Where the finder's proposal and the verifier's calibration (or two merged passes) disagree, synthesis picks one severity **with a stated rationale** recorded in the finding (e.g. "finder said 7, verifier raised to 9 — three independent UI paths reach the broken read"). Never silently average.
3. **Own the merge/split decisions and final `lens` values** (nearest default lens). Id assignment itself is scripted; the model decides what merges, what splits, and what each finding is called.
4. **Write the prose that needs writing:** per-finding writeups for sev ≥5 (impact + recommendation), the per-lens verdict lines ("Coherence: clean"), and the report's top summary — into the script-assembled skeleton. Full writeups for sev ≥5 only; the nit tier stays a table (the first baseline's prose-for-everything report was 161KB, mostly nit writeups nobody triages individually).
5. **Merge into ONE report.** `report.md` / `findings.json` / `certificate.md` as usual, `mode: multi-agent`, findings carrying their dimension tags and verification verdicts, refuted candidates in the appendix. **Never per-dimension reports** — that splits triage across documents and was explicitly rejected in the plan; one aggregated, deduped, verified report is the contract. Per-agent raw output stays behind the curtain.

The multi-agent run ends at the assembled report, exactly like the default flow — all findings `open`, nothing written to the plan. Triage and fix routing are the separate `--triage` step (SKILL.md § 7); verified findings get no special handling there.

## `--mega` — the thorough tier

`--mega` runs the **same pipeline** with the cost/accuracy dials at the measured-baseline maximum. For release gates and pre-merge reviews of large, risky work where the user explicitly accepts roughly double the default's wall clock and rate-limit footprint:

- **All eight finder passes on the main tier** — the orchestrator's model, resolved per `references/model-map.md` and set explicitly per launch (`quality` may stay on the cheap tier, but its sev ≤4 cap is lifted — it proposes severities normally). Small models stay out here too — every pass still reasons.
- **All verification on the main tier**, floor still sev ≥5; the sev-5 cheap-tier routing does not apply.
- **Stage 0 stays fully scripted** (chunking, parallel pre-pass, fact harvest), and Stage D stays script-assembled — determinism trades no accuracy, so the thorough tier keeps it.

Everything else — budgets, floors, evidence rules, one report — is identical. If the user asks for "mega", "thorough", or "the full treatment", this is the tier they mean; confirm the cost before launching.

## The `--security` seam (documented, INERT)

**`--security` is a seam for the future `/deep-security` skill. It is inert until that skill exists — nothing executes under this flag today.** If invoked now: tell the user the seam is pending `/deep-security` and proceed with the review without it.

The contract, for when `/deep-security` lands (a separate effort):

- **Invocation:** under `--security`, deep-security's dimension agents join this review's finder fleet as additional specialist passes — **same read-only finder rules, same brief discipline (never the implementation transcript), same finding shape with `dimension` set, same 1–10 severity scale** mapped to the same tiers. Their candidates go through the same Stage B/C/D pipeline, including adversarial verification.
- **Merge, don't fork:** security findings merge into THIS report's **Security** section and go through the **single triage pass** with everything else — never a separate security report.
- **Artifacts:** when running under this flag, everything still lands in the effort's `04-Code-Review/`. Only when `/deep-security` runs **standalone** do its artifacts go to `05-Security/` (see `references/artifact-structure.md`).
- The 8-wide parallelism cap applies per batch; security passes run as their own batch if the finder fleet already fills a batch.

## Caution

Keep parallelism bounded — never more than 8 concurrent agents (finder batch, then the rolling verifier window). These are read-only review agents (the safe case for parallelism; no worktree isolation needed), but wide fan-outs of heavy agents still exhaust context: keep each brief tight (the chunk index, one lens, preference pointers — not the whole repo's documentation, never the monolithic diff), and keep verifier briefs tighter still (the candidate, its evidence, the fact pre-harvest, codebase access — not the finder's full output).
