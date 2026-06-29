# deep-code-review — Design Rationale

> deep-code-review is the fourth skill in the series (`/deep-plan` → `/deep-plan-review` → `/deep-implement` → **`/deep-code-review`**). Its single job is to **review implemented code** with fresh, evidence-driven agents — and, deliberately, *only* to review: deciding what to do about findings (fix/defer/reject) and routing them into the plan is split out into a separate, opt-in `--triage` step. Its signature concern is the **last-mile problem** — code where the interface looks wired and the happy path appears connected, but the behavior doesn't make it the last mile. It is also the **data source for Deep-Learn**: its `findings.json` feeds the directive-card distiller, which is why the machine record is a first-class, stable artifact.
>
> Rationale here was recovered from `SKILL.md`, the eleven `references/` files, the three `templates/`, git history (commits `de51e21`, `2a3686b`, `3be1254`, `a9732b4`), and the roadmap/benchmark docs (`docs/roadmap/DESIGN-OUTLINE.md`, `docs/benchmarks/code-review-design/Design-Notes.md`). Where a decision's rationale was not stated in any source it is marked `rationale: not recovered from sources` rather than invented.

## Decisions at a glance
- [1. Review / triage separation — the run never edits the plan](#1-review--triage-separation--the-run-never-edits-the-plan)
- [2. "Findings stay open" — the review writes no verdicts](#2-findings-stay-open--the-review-writes-no-verdicts)
- [3. Independence: fresh agents, never the implementation transcript](#3-independence-fresh-agents-never-the-implementation-transcript)
- [4. The last-mile lens as the signature concern](#4-the-last-mile-lens-as-the-signature-concern)
- [5. Interaction-edge, re-entry, and external-consumer additions (commit 2a3686b)](#5-interaction-edge-re-entry-and-external-consumer-additions-commit-2a3686b)
- [6. Adversarial test-reading + the Coherence divergent-sibling hunt](#6-adversarial-test-reading--the-coherence-divergent-sibling-hunt)
- [7. The multi-agent finder fan-out (eight single-lens passes)](#7-the-multi-agent-finder-fan-out-eight-single-lens-passes)
- [8. Severity model + the sev ≥5 verification floor](#8-severity-model--the-sev-5-verification-floor)
- [9. Model-tier resolution and the Haiku ban](#9-model-tier-resolution-and-the-haiku-ban)
- [10. Stage 0 scripted setup + script-assembled synthesis](#10-stage-0-scripted-setup--script-assembled-synthesis)
- [11. Deterministic pre-pass — tools, not agents](#11-deterministic-pre-pass--tools-not-agents)
- [12. seam-trace and frozen-state-probe specialist dimensions](#12-seam-trace-and-frozen-state-probe-specialist-dimensions)
- [13. Situational checks — progressive disclosure](#13-situational-checks--progressive-disclosure)
- [14. Scope resolution — ask on any ambiguity](#14-scope-resolution--ask-on-any-ambiguity)
- [15. Browser verification — observed, never inferred](#15-browser-verification--observed-never-inferred)
- [16. Machine-readable finding.json, certificate, report](#16-machine-readable-findingjson-certificate-report)
- [17. No `scripts/load-active-cards.sh` — code-review is a producer, not a consumer](#17-no-scriptsload-active-cardssh--code-review-is-a-producer-not-a-consumer)
- [18. The `--security` seam — documented but inert](#18-the-security-seam--documented-but-inert)

---

## 1. Review / triage separation — the run never edits the plan

**What it does.** A finished review leaves *every* finding at status `open` and writes to exactly one place — its own `04-Code-Review/` artifacts plus the effort manifest. All routing/acceptance (fix/defer/reject, Blocker auto-accept, appending a fix-phase to the plan) is moved into a separate, opt-in `--triage` step. Stated in the `description` front matter and reinforced at `SKILL.md:8`, `SKILL.md:66-78`, and the guardrail `SKILL.md:90`. The triage step itself is the "**only** step that writes to the plan" (`SKILL.md:78`, `SKILL.md:85`). This was introduced by commit `de51e21` ("separate the review run from `--triage`").

**Alternatives considered / rejected.** The pre-`de51e21` design had the review run perform triage inline — routing acceptance into the plan and auto-accepting Blockers *during the run*. The commit explicitly rejects "review writes acceptance into the plan during the run": "A finished review now leaves every finding `open` and writes nothing to the plan; all routing/acceptance moves to the separate `--triage` step (Blockers auto-accept there, not during the run)."

**Why this choice.** So "the review never blocks on a human and never edits the plan" (`SKILL.md:71`) — the review can "run autonomously" (front matter) as an unattended gate, while the human-in-the-loop triage decisions happen on the user's schedule. Decoupling also keeps the producer (review) and the plan-mutating consumer (triage) cleanly separable, matching the guardrail that the review touches only `04-Code-Review/` "not even to record deferreds" (`SKILL.md:90`).

## 2. "Findings stay open" — the review writes no verdicts

**What it does.** Every finding is written with status `open` in `report.md`, `findings.json`, and the certificate, with triage outcomes "left pending" (`SKILL.md:60-62`; `templates/finding.json:30-31`; `templates/certificate.md:1-5,29-30`). Even Blockers — which are "by definition not optional" — stay `open` during the run; the review only *flags* a Blocker in the certificate verdict, it does not route it (`references/findings-and-severity.md:49-53`). The status lifecycle is `open` → `accepted | deferred | rejected by user` → (later) `fixed` (`references/findings-and-severity.md:62`).

**Alternatives considered / rejected.** The natural alternative — auto-accepting Blockers and writing their fix-phase as part of producing the review — is exactly what `de51e21` pulled out. `findings-and-severity.md:49` now states the policy-actions table "belong[s] to the separate `--triage` step, not the review run."

**Why this choice.** A consistent `open`-everywhere state is what makes the review run a pure, side-effect-free producer (decision 1) and keeps `findings.json` a clean snapshot the Deep-Learn distiller can consume without first untangling which findings the run already acted on (decision 16/17).

## 3. Independence: fresh agents, never the implementation transcript

**What it does.** The review runs in fresh agent(s) that receive the diff + the plan + codebase access "but never the implementation transcript" (`SKILL.md:14`, restated as a guardrail at `SKILL.md:94` and in every finder brief at `references/multi-agent.md:59` and `references/dimensions.md:13`).

**Alternatives considered / rejected.** Passing the implementer's reasoning/transcript to the reviewer (cheaper context priming) is explicitly rejected: "an agent that saw the implementation reasoning will rationalize the same gaps" (`references/dimensions.md:13`).

**Why this choice.** "The implementer is too close to the code to see what it left out" (`SKILL.md:14`). This is cross-cutting series principle #1 — independence through fresh eyes — and is the mechanism that makes the last-mile hunt credible: a reviewer who never absorbed the implementer's mental model is the one positioned to notice the half-wired chain.

## 4. The last-mile lens as the signature concern

**What it does.** Functional Completeness (Last-Mile) is one of the default four lenses (`SKILL.md:49`) and the "skill's signature lens" (`references/review-lenses.md:24`). Its methodology (`references/last-mile.md`): (1) enumerate every promised behavior, decomposing compound promises (`last-mile.md:5-12`); (2) walk each chain hop-by-hop with evidence at every hop — the canonical `UI event → handler → service → HTTP → route → handler → persistence → response → UI update → secondary effects` chain (`last-mile.md:14-28`); (3) verify the *complete* behavior — state transitions, secondary effects, edge handling — not just a connected happy path (`last-mile.md:30-37`). Six named AI failure modes are hunted explicitly (optimistic UI, leftover mocks, swallowed errors, contract drift, unregistered routes, two-halves-different-understandings) (`last-mile.md:38-47`). The non-negotiable synthesis rule: "A last-mile finding without a cited hop-by-hop chain is rejected at synthesis" (`last-mile.md:69-71`).

**Alternatives considered / rejected.** The shallow-checkbox alternative — a reviewer ticking "traced it" without producing the trace — is the exact failure mode the no-chain-no-finding rule exists to prevent (`last-mile.md:71`). "Save might not work" is rejected; only a cited break ("the chain breaks at hop 4…") qualifies.

**Why this choice.** The last-mile problem is the series' signature failure, stated in the user's own words: implementations where "the interface looks correct… the functionality appears to work on the surface but doesn't make it the last mile" (`last-mile.md:3`). Requiring a cited chain forces the reviewer to actually trace rather than gesture, which is what catches the gap.

## 5. Interaction-edge, re-entry, and external-consumer additions (commit 2a3686b)

**What it does.** Commit `2a3686b` added three new bodies of last-mile hunting, each mapped to a real benchmark bug the review had *missed*:
- **External-consumer contract drift** — failure mode #4 now "extends past the repo's own seams": a payload serialized to an external consumer (CLI/binary, third-party API, SDK) can drift from what that consumer accepts while every in-repo check stays green; "neither repo code nor a repo contract test is ground truth for an external shape" (`last-mile.md:45`).
- **Interaction-edge checks** — double-submit/in-flight guard, visible processing feedback, navigation-target robustness/`**` fallback (`last-mile.md:49-55`).
- **Re-entry & idempotency checks** — stale artifacts from a prior run, no "a prior run exists" signal, duplicated side effects on re-run (`last-mile.md:57-63`).
The synthesis rule was extended so these satisfy the chain requirement in their own shape: cited action-site + missing-mechanism + consequence (`last-mile.md:71`).

**Alternatives considered / rejected.** Leaving the last-mile lens at "trace the happy-path chain" — rejected because that lens, as it stood, missed all five manually-found bugs in the calibration benchmark. The commit message names them: "Codex vision 500, double-submit button, NG04002 crash, stale-docs restart, no-feedback," with root causes "no external-contract oracle, no interaction/re-entry probing."

**Why this choice.** Each addition is calibrated to a specific miss with an in-text exemplar: the "Use This Intake" button that spawned a fresh background run on every one of four clicks (`last-mile.md:53`); the abandoned blueprint leaving documents on disk with no restart reconciliation (`last-mile.md:61`); the NG04002-class navigation crash without a fallback route (`last-mile.md:55`). Two of these three principles were later shift-left ported upstream (`3be1254`).

## 6. Adversarial test-reading + the Coherence divergent-sibling hunt

**What it does.** Two always-on lens hardenings from `2a3686b`:
- **Reading tests adversarially** (`references/review-lenses.md:57-67`): changed test files are "suspects, not oracles" and "never an optional skip." A **tautological test** — one whose assertion encodes the code's *current* output rather than the *intended* contract — ships the bug with a passing checkmark. For every changed test, ask whether the assertion encodes the intended contract or just locks in what the code emits, whether the asserted value is an external-consumer payload (then check against ground truth), and whether coverage was deleted.
- **Coherence divergent-sibling hunt** (`review-lenses.md:53`): enumerate parallel implementations of one outbound contract field-by-field; "a lone divergence in an external-facing payload is a correctness signal — escalate it to the correctness/seam-trace lens rather than filing it as a coherence nit."

**Alternatives considered / rejected.** Treating a green test suite as evidence of correctness — explicitly rejected: "Do not let a passing pre-pass stand in for this reading. The pre-pass reports *that* the suite is green; this lens asks whether green *means* correct" (`review-lenses.md:67`). Filing a lone wire-shape divergence as a style nit is rejected — it's a "likely bug, not a style nit" because siblings targeting the same consumer are each other's ground truth (`review-lenses.md:53`).

**Why this choice.** The benchmark miss this rule exists for, stated verbatim: a vision client serialized an image as `image_url: "<data-url>"`, a new contract test asserted exactly that shape, the suite passed 24/24, and the real external consumer (Codex) rejected it with a 500 (`review-lenses.md:59`). The test had "codified the bug and the pre-pass read green" — the canonical divergent-sibling case is the three streaming clients where two send `image_url: { url }` and the odd one out is the bug (`review-lenses.md:53`).

## 7. The multi-agent finder fan-out (eight single-lens passes)

**What it does.** `--multi-agent` runs a five-stage pipeline (`references/multi-agent.md`). **Stage A** is a fleet of **eight independent, fresh, read-only, single-lens finder passes** launched as one parallel batch, **capped at 8 concurrent** (`multi-agent.md:40-57`): `diff-scan`, `removed-behavior`, `seam-trace`, `last-mile`, `frozen-state-probe`, `conformance`, `coherence`, and a combined `quality` sweep (the roster table at `multi-agent.md:42-51`). Finders **overgenerate** above the nit floor — every evidenced sev ≥4 candidate, no caps — but are **budgeted**: read each chunk once, ~25 tool calls, one decisive trace per candidate ("finders find, verifiers prove") (`multi-agent.md:61-62`). Under this flag the combined single-agent four-lens pass does **not** also run — its lenses run as four of the independent finders (`multi-agent.md:9`).

**Alternatives considered / rejected.** (a) One broad combined agent — rejected because "a single agent's lenses anchor on each other; eight fresh agents can't" (`multi-agent.md:9`); independence between lenses is "strictly stronger." (b) Earlier designs used **ten** then **seven** finders (`docs/benchmarks/code-review-design/Design-Notes.md:25-31`); the current eight is the tuned roster. (c) Letting finders build verification-grade proofs — rejected: "paying for it twice was the single largest cost in the first baseline run" (`multi-agent.md:61`). (d) Capping sev ≥4 finding counts or letting finders self-filter — rejected; overgeneration is the contract and "the verification stage owns precision" (`SKILL.md:96`).

**Why this choice.** Calibrated from two measured baseline runs (`multi-agent.md:5`). Many narrow independent passes out-find one broad pass (recall), and the cheap-find / expensive-verify split keeps cost proportional. The benchmark rematch showed the fleet covering 20 of 24 matrix rows, beating the prior best of 15 (`Design-Notes.md:92`).

## 8. Severity model + the sev ≥5 verification floor

**What it does.** Severity is a canonical **1–10 numeric scale** stored in `findings.json`, mapped to four presentation tiers (9–10 Blocker · 7–8 Major · 5–6 Minor · 1–4 Nit) (`references/findings-and-severity.md:20-29`; `SKILL.md:56`). Severity must be justified by **counting independent, user-reachable trigger paths** to the failure (`findings-and-severity.md:31-33`). Under `--multi-agent` there is a **verification floor at sev ≥5**: candidates at Minor and up get a fresh adversarial verifier briefed to *refute* them (burden of proof on the finding); sev ≤4 ships `unverified` with finder evidence intact (`multi-agent.md:80`; `findings-and-severity.md:18`). A finder proposing **exactly sev 5** must state in one line why it isn't a 4, because the floor sits at 5 and marginal candidates pile up there, each costing a verifier (`multi-agent.md:62`; `findings-and-severity.md:33`).

**Alternatives considered / rejected.** (a) Verifying everything including the nit tail — rejected: in the first calibration run "verifying the nit tail consumed ~a quarter of the run for zero changed verdicts" (`multi-agent.md:80`). (b) Lowering the floor mid-run "to be thorough" — explicitly banned: "that decision was made when the mode was invoked" (`multi-agent.md:80`; guardrail `SKILL.md:96`). (c) Words-as-canonical — rejected; the number is canonical and the words are "derived from the number, never the other way around" (`findings-and-severity.md:43-45`), which also keeps a future in-app interop bridge thin.

**Why this choice.** "Every verification outcome that changed anything happened at sev ≥4" in the first run (`multi-agent.md:80`), so the floor restores precision exactly where it pays and stops spend exactly where it didn't. Trigger-path counting gives severity an objective, checkable basis (a defect reachable from three UI flows ≠ one needing a hand-crafted DB row) (`findings-and-severity.md:31`).

## 9. Model-tier resolution and the Haiku ban

**What it does.** Three tiers (main/mid/cheap) resolve from the **orchestrator's own model** at launch (`multi-agent.md:24-31`): Fable 5 → main=Fable 5, mid=Opus 4.8, cheap=Sonnet; Opus 4.8 → main=mid=Opus 4.8, cheap=Sonnet. The Blocker/Major-finding lenses (`removed-behavior`, `seam-trace`, `last-mile`, `frozen-state-probe`) run on main; `diff-scan`/`conformance`/`coherence` on mid; `quality` on cheap, sev-capped ≤4 (`multi-agent.md:42-53`, `SKILL.md:82`). The model is **set explicitly on every launch as a pinned FULL model ID** (`claude-fable-5` / `claude-opus-4-8` / latest `claude-sonnet-*`) — never an alias, never inherited. **Haiku is never used — any tier, any stage** (`multi-agent.md:33-38`, guardrail `SKILL.md:97`).

> Note on the task prompt's "model-tier resolution that bans Haiku" claim: **this exists and is anchored above** — `references/multi-agent.md:33-38` and `SKILL.md:97`. (The phrasing "bans Haiku" is accurate; the ban is absolute across all tiers and stages, not a per-tier floor.)

**Alternatives considered / rejected.** (a) Bare aliases like `opus` — rejected: "a calibration run that launched mid-tier finders with the `opus` alias got Opus 4.6, silently below the tier the table mandates" (`multi-agent.md:31`). (b) Implicit/inherited model resolution — rejected: "that is exactly how the Haiku mis-route happened" (`multi-agent.md:38`). (c) Using Haiku anywhere to save cost — rejected because "Haiku output in this pipeline is worse than no output, because it ships false confidence."

**Why this choice.** Stated empirically twice: a run whose main-tier lenses silently fell to Haiku "produced 0 Blockers and 0 Majors on a diff with two known Criticals" (`multi-agent.md:36`, `SKILL.md:97`). Tiering is calibrated by what each lens catches — `seam-trace`/`last-mile`/`removed-behavior` found every Blocker and Major in both runs (stay on main); `diff-scan`/`conformance`/`coherence` produced only Minors (mid); `quality` produces nit-tier output by design (cheap) (`multi-agent.md:53`). The remediation rule: any agent shown running below tier "is invalid; discard and relaunch it" (`multi-agent.md:38`, `SKILL.md:97`).

## 10. Stage 0 scripted setup + script-assembled synthesis

**What it does.** Everything deterministic is scripted, never delegated to agents. **Stage 0** (`multi-agent.md:11-18`): diff **pre-chunking** per-file with an index (finders never ingest the monolithic diff); the pre-pass launched **in parallel** with finders; verifier **fact pre-harvest** (evidence lines, symbol definitions, caller lists); situational-check matching by grep. **Stage D synthesis** (`multi-agent.md:110-128`): `findings.json`, the severity rollup, the verification-funnel line, the nit table, the refuted-candidates appendix, and the certificate scaffold are all **script-assembled** from the fixed-format verdicts; "the model writes only the judgment" — evidence-rule enforcement, severity reconciliation, merge/split calls, and per-finding prose for sev ≥5.

**Alternatives considered / rejected.** (a) Each finder re-deriving the chunk split — observed and rejected: "six-plus agents independently re-derived this split… full-diff ingestion by every finder was the single largest token sink" (`multi-agent.md:15`). (b) Running the pre-pass serially before finders — rejected: it "buys nothing but wall clock" (~13 min idle) since finders never consume its output (`multi-agent.md:16`, `deterministic-prepass.md:7`). (c) Hand-writing the whole report — rejected: synthesis "hand-wrote ~103k output tokens, most of it transcription of structured records it already had" (`multi-agent.md:112`); the prose-for-everything baseline report was 161 KB (`multi-agent.md:127`). (d) Per-dimension reports — "explicitly rejected in the plan; one aggregated, deduped, verified report is the contract" (`multi-agent.md:128`).

**Why this choice.** "Determinism trades no accuracy" (`SKILL.md:83`, `multi-agent.md:138`), so deterministic work belongs in scripts where it's cheaper, exact, and frees the model's tokens for the judgment only it can make. Every scripted stage is calibrated from a place the spend "demonstrably did and didn't buy findings" (`multi-agent.md:5`).

## 11. Deterministic pre-pass — tools, not agents

**What it does.** Lint, typecheck, and tests run as **deterministic tools, never agents** (`SKILL.md:40`, `references/deterministic-prepass.md:3`). Results feed the report as findings with conventional severities (test failure 7–8, type error ≈6, lint 3–4) (`deterministic-prepass.md:49-55`). Commands are **discovered** from the host project (package.json scripts → CLAUDE.md → tool configs), with no hardcoded commands and the hard rule to **never read `.env`/secrets** (`deterministic-prepass.md:18-25`). Two calibrated requirements: always run the affected suite as **one combined invocation** (cross-file interference only reproduces there) (`deterministic-prepass.md:35-37`), and attribute failures by a **scripted base-vs-head two-worktree diff** of normalized failure lists (`deterministic-prepass.md:9-15`).

**Alternatives considered / rejected.** (a) Linting as an LLM review dimension — rejected: "compilers and linters are faster, cheaper, and exact at this job," and offloading it "frees the review agents to hunt what tools can't see" (`deterministic-prepass.md:3`). (b) An agent reasoning out which failures are pre-existing — rejected: a baseline agent "spent ~13 minutes and four-plus suite runs attributing 199 pre-existing failures that one scripted comparison classifies exactly" (`deterministic-prepass.md:15`). (c) Per-file-only test runs — rejected: they "can report green over a suite that fails on a fresh checkout" (`deterministic-prepass.md:37`) — the "closed database" class of bug (`Design-Notes.md:29`).

**Why this choice.** Determinism, cost, and exactness; the combined-run rule and base-vs-head attribution each close a specific real miss the benchmark exposed.

## 12. seam-trace and frozen-state-probe specialist dimensions

**What it does.** Two of the four specialist passes (`references/dimensions.md`):
- **`seam-trace`** (`dimensions.md:34-46`): for every value the diff writes, who reads it — and when the reader is *external*, does the serialized shape match what that consumer expects, "not just what the repo's own code and tests agree on"? Establish external ground truth in order: (1) a sibling in-repo implementation targeting the same consumer (a lone field divergence is the bug — the Ollama `image_url: { url }` vs the new Codex bare `image_url: url` example), (2) the consumer's documented/protocol schema, (3) else file an **unverified external contract** finding rather than passing silently (`dimensions.md:40`).
- **`frozen-state-probe`** (`dimensions.md:48-59`): for every persisted value whose writer/clearer/repair path the diff deletes, run surviving readers against the *concrete* frozen value. Four steps — enumerate frozen values, pin the concrete value (not the type), probe every surviving reader at exactly that value, cite the probed chain. "No probed chain, no finding."

**Alternatives considered / rejected.** Reading the reader's code forward only — rejected: "both of this skill's longest-standing benchmark misses were exactly this shape… The code looked fine read forward; it failed only *at the frozen value*" (`dimensions.md:52`) — the orphaned `enabled=0` rows and the destructively-completed subset template. Trusting a passing contract test as ground truth for an external shape — rejected (`dimensions.md:40`).

**Why this choice.** `removed-behavior` finds the orphaned state and `seam-trace` finds layer mismatches; `frozen-state-probe` "adds what the other two don't: the reader's behavior at the concrete value" (`dimensions.md:78`). The probe was added specifically to land the two rows (orphaned `enabled=0`, subset-template clearing) that "survived every benchmark run" (`Design-Notes.md:17`). Overlap among the dimensions is deliberate; "synthesis resolves it" by deduping one root cause into one finding with multiple dimension tags (`dimensions.md:76-78`).

## 13. Situational checks — progressive disclosure

**What it does.** A **sparse catalog** (`references/situational/index.md`) is read every run; each entry is ~5 lines (id, trigger, machine-matchable Match regex, the lens(es) it Attaches to, what it catches). A check's **full body** (`references/situational/<id>.md`) is read **only when its Match pattern hits the resolved diff**, then appended to the brief of the named lens/finder (`references/situational-checks.md:6-13`). Matching is a cheap deterministic grep against the diff/chunks, never an agent, and **never adds agents** — matched bodies augment existing briefs, so the ≤8 cap and budgets are untouched (`situational-checks.md:9-11`; `SKILL.md:43`). Fired checks are disclosed in the report header's `Situational checks:` line. The first (and only) check is `file-upload-pipeline` (`situational/index.md:9-13`, body `situational/file-upload-pipeline.md`). Triggers "err toward loading" — a false match costs one body-read, a false miss "costs the whole bug class" (`situational-checks.md:17`).

**Alternatives considered / rejected.** (a) Baking every surface-specific hunt into the always-on lenses — rejected: it "would bloat every finder brief with hunts that are dead weight on the 90% of diffs that don't touch that surface" (`situational-checks.md:3`). (b) Pre-reading bodies "to see if they're relevant" — rejected: "the Match pattern is the relevance test" (`situational-checks.md:19`). (c) Porting the mechanism upstream to plan/implement — **deliberately NOT done** (commit `3be1254`): "only one proven check exists and each phase would grep a different artifact; revisit when a second check justifies the shared infra."

**Why this choice.** Mirrors how the skill system itself manages context — "a sparse catalog loaded every run, and a full check body loaded *only when the diff plausibly matches it*… a given review pays for only the few that fire" (`situational-checks.md:3`). It scales to dozens of checks at near-zero standing cost. The single check is calibrated to the Codex vision-500 / advertised-but-unparsed-PDF benchmark misses (`situational/file-upload-pipeline.md:18,21`).

## 14. Scope resolution — ask on any ambiguity

**What it does.** Three input modes — no-arg (feature branch vs detected base), PR argument (resolved via `gh`), explicit paths (`references/scope-resolution.md:10-16`). Base detection order: PR-declared base → merge-base comparison against candidate bases → **ask the user on ANY ambiguity** (`scope-resolution.md:18-24`). Working tree + staged changes are included by default on the no-arg flow (`scope-resolution.md:26-28`). The **resolved scope is printed as one verbatim line before any agent or pre-pass launches** (`SKILL.md:31`, `scope-resolution.md:31-38`), and that line is reproduced verbatim into report/certificate/findings.json. Host discovery never reads `.env` (`SKILL.md:92`).

**Alternatives considered / rejected.** Guessing a base branch — rejected, in the user's verbatim words: "If there's ever any question whatsoever, the skill should raise the question to the user" / "Do not pick 'probably main'" (`scope-resolution.md:6,23`). Disturbing the user's checkout to review a PR — preferred path is `gh pr diff` + read-only access at PR head; check out only if the pre-pass needs a real tree *and* the user confirms (`scope-resolution.md:49`).

**Why this choice.** "Wrong scope poisons everything downstream" (`scope-resolution.md:3`); the scope line "is the contract for the whole review; everything downstream cites it" (`scope-resolution.md:38`).

## 15. Browser verification — observed, never inferred

**What it does.** `--browser` escalates the last-mile lens from static tracing to **observation**: exercise the plan's promised behaviors against an already-running dev server and watch real network traffic, citing `evidence.observed` (request URL/method/status/payload as seen) (`SKILL.md:86`, `references/browser-verification.md:3,28-35`). Three hard rules: **never start a server**, **never read `.env` for port discovery**, **confirm before mutating** (`browser-verification.md:5-13`). The methodology is **static-first**; `--browser` is the escalation when static tracing "leaves real doubt" (`last-mile.md:65-67`).

**Alternatives considered / rejected.** Starting a dev server if none is running — rejected absolutely ("Not 'start one if missing' — never"), because it "collides with the user's running processes, ports, and watchers"; if none is found, skip gracefully and fall back to static tracing (`browser-verification.md:7`). Inferred claims as browser evidence — rejected: "'The save probably doesn't hit the API' is not browser evidence; the network log line that isn't there is" (`browser-verification.md:35`).

**Why this choice.** Observed traffic is "the strongest evidence the review can produce" (`browser-verification.md:3`) — it's where the named last-mile failure modes "die or get caught" (optimistic UI shows an interaction with no request) (`browser-verification.md:23`). Static-first keeps the common case cheap and reserves the live smoke for genuine runtime doubt.

## 16. Machine-readable finding.json, certificate, report

**What it does.** Three artifacts land in `04-Code-Review/`: `report.md` (human triage doc), `findings.json` (the machine record), `certificate.md` (pass/fail verdict, pass = no Blockers) (`SKILL.md:58-62`). `findings.json` is a JSON object with a `findings` array; numeric `severity` is **canonical**, `tier` derived; annotations live in `_doc`-prefixed keys that real files omit (`templates/finding.json:1-2`). The shape is "kept compatible with a thin future bridge to an in-app finding importer — no app coupling here, just stable fields" (`finding.json:2`; `findings-and-severity.md:45`).

**Alternatives considered / rejected.** A separate annotation file or inline comments in a stripped JSON — the `_doc`-key convention instead keeps the documented template and the real schema in one file while guaranteeing real outputs stay machine-clean (omit every `_`-prefixed key). A words-first severity model — rejected (decision 8).

**Why this choice.** The machine-readable file is **the data source for Deep-Learn**: "Every `/deep-code-review` run feeds a learning loop… Fed by every `findings.json`. Raw findings are *evidence*" (`docs/roadmap/DESIGN-OUTLINE.md:5,72`). Keeping severity numeric and the shape stable is what lets the distiller and a future in-app bridge consume the file "with no remapping" (`findings-and-severity.md:45`). The PR#65 corpus that seeded the loop *is* a set of these `findings.json` records (`DESIGN-OUTLINE.md:146-152`, archived by `a9732b4`).

## 17. No `scripts/load-active-cards.sh` — code-review is a producer, not a consumer

**What it does.** deep-code-review has **no `scripts/` directory** (verified by listing — it does not exist). The other three built skills each carry `scripts/load-active-cards.sh` (verified present in `deep-plan`, `deep-plan-review`, `deep-implement`). So deep-code-review is the one built skill that does **not** load directive cards at runtime.

**Alternatives considered / rejected.** Giving code-review a loader stanza like its siblings — implicitly rejected by its absence. The Deep-Learn architecture diagram (`DESIGN-OUTLINE.md:23-64`) shows the directive-applying spokes as **deep-plan / deep-plan-review / deep-implement only**; code-review sits at the *top* of the loop as the findings source, not among the spokes that apply cards.

**Why this choice.** Recovered by inference from the Deep-Learn design, not from an explicit "code-review must not load cards" sentence. In the hub-and-spoke model, code-review is the **producer of lessons** (its `findings.json` feeds the distiller → pattern ledger → cards) while the upstream skills are the **consumers/appliers** that load active cards to prevent the bug earlier (`DESIGN-OUTLINE.md:24-64`). A reviewer that applied prevention cards would also blur its role as the independent measurement point of the loop (the Effectiveness Monitor judges recurrence from code-review's later findings, `DESIGN-OUTLINE.md:89-92`). The directional logic is strongly supported by the roadmap; an explicit prohibition sentence in deep-code-review's own files was **not recovered from sources**.

## 18. The `--security` seam — documented but inert

**What it does.** `--security` is "a documented seam, **inert until `/deep-security` exists**" — nothing executes under it today; if invoked, the skill says so and proceeds without it (`SKILL.md:84`, `multi-agent.md:142-151`). The contract for when it lands: deep-security's dimension agents join this review's fan-out under the same read-only finder rules, same finding shape, same 1–10 scale; findings **merge** into this report's Security section for a single triage pass (never a separate report); artifacts stay in `04-Code-Review/`.

**Alternatives considered / rejected.** A separate security report / separate triage pass — explicitly rejected: "Merge, don't fork… never a separate security report" (`multi-agent.md:149`). Implementing the flag now — rejected; it's a forward-declared seam, not live behavior.

**Why this choice.** Documenting the integration contract up front means the future `/deep-security` skill plugs into a fixed shape (same finder rules, same merge-into-one-report discipline) rather than forcing a redesign later — consistent with the series' "one aggregated, deduped report" contract (decision 10). The seam is honest about being inert so a user invoking it today isn't misled.

---

### Cross-references to shared series context
- **Independence through fresh eyes** (decision 3) is series principle #1, shared with deep-plan-review.
- **The last-mile problem** (decisions 4–5) is the signature failure the whole series hunts.
- **Evidence required** (decisions 4, 8, every lens) — `path:line`, named symbol, or observed behavior; no vague "consider improving" (guardrail `SKILL.md:93`).
- **Deep-Learn data source** (decision 16) — code-review's `findings.json` is the loop's input; the upstream skills consume the resulting cards (decision 17).
