---
name: deep-code-review
description: Independently review implemented code with fresh, evidence-driven agents — correctness bugs, last-mile functional gaps (UI that looks wired but isn't), plan conformance, and coherence — and produce a review report with every finding left open. Triage (fix/defer/reject) and routing accepted fixes into the plan for /deep-implement are a separate, opt-in step (--triage), so the review itself runs autonomously and never edits the plan. Use after /deep-implement, before merge, or on any branch/PR/diff. Triggers on /deep-code-review and on requests to deep-review code, a PR, a branch, or a diff. Reviews code only — it never edits application source.
---

# DeepCodeReview

Independently review **implemented code** the way `/deep-plan-review` reviews a *plan*: fresh agents, evidence-required findings, and a clean review report. **Triage is a separate, opt-in step** (`--triage`) — the review run itself makes no fix/defer/reject decisions, asks no triage questions, and **never edits the plan**. **Review only — never edit source** (see Guardrails for what "source" means).

This is the fourth skill of the `deep-*` series: `/deep-plan` (produce) → `/deep-plan-review` (critique the plan) → `/deep-implement` (execute) → **`/deep-code-review` (critique the code)** → `/deep-docs` (map what's built). It closes the loop: the gate between "the implementation agent says it's done" and "this is actually done."

## Core principle: independence + the last mile

The implementer is too close to the code to see what it left out. The review runs in **fresh agent(s)** that receive the diff + the plan + codebase access — **but never the implementation transcript**. Its signature concern is the **last-mile problem**: code where the interface looks correct and the happy path appears connected, but the behavior doesn't make it the last mile — optimistic UI with no real call, swallowed errors, half-wired chains, silently dropped plan scope.

## The deep-* series (separation of concerns)

<!-- Quintet today; becomes a sextet when deep-bug-fix ships — that skill's own series-wiring adds its row here. -->

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-plan` | Frame → explore → question → write the plan (resumable phases + deferreds). | Out of scope here. |
| `/deep-plan-review` | Independently review the finished plan with fresh agents. | Out of scope here. |
| `/deep-implement` | Execute the plan: implement → validate → fix → commit → hand-off. The only skill that writes source. | Out of scope here. |
| `/deep-code-review` (you) | Independently review implemented code; emit findings. | Independently review implemented code; emit severity-gated, adversarially-verified findings. **Reports, never fixes.** |
| `/deep-docs` | Map what's built: survey → tier → anchor → verify → index → place a standing `docs/ai-map/`. | Out of scope here. |

## In-session commands

| Command | Behavior |
|---|---|
| `/multi-agent` | Escalate the current review to **parallel** mode — script the deterministic setup, fan out the finder fleet (eight budgeted, model-tiered single-lens passes), adversarially verify the Minor+ survivors, then synthesize. Same effect as the `--multi-agent` flag (see Flags). |

## Workflow

### 1. Resolve scope — and state it
Determine *what diff* is under review, per `references/scope-resolution.md`:

- **No args (default):** current feature branch vs the base it was cut from (PR-declared base → merge-base candidates → **ask the user on any ambiguity**). Working tree + staged changes are included by default.
- **PR argument** (`PR65`, `#65`, or a PR URL): resolve via `gh`.
- **Explicit paths:** review just those files/dirs.

**Before launching anything**, print the resolved scope in one line — e.g. `Diffing feat/x against develop (working tree included) — 14 files, +812/−214` — and, in collaborative settings, give the user a beat to correct it.

### 2. Resolve the effort and artifact home
Per `references/artifact-structure.md`:

- **A deep-* plan exists** for this work → artifacts go to that effort's `.deep-skills/<effort>/04-Code-Review/`; read the plan in full (it drives the Plan Conformance and Last-Mile lenses).
- **No plan** (PR mode / arbitrary diff) → ask the user for an effort name, **defaulting to the slugified branch name**; create `.deep-skills/<effort>/` and `00-Manifest/manifest.md` if absent (any deep-* skill owns manifest creation on first write).

### 3. Deterministic pre-pass
Run lint, typecheck, and tests as **deterministic tools, never agents** — linting is deliberately not an LLM job. Commands are discovered from the host project (never from `.env`/secrets); results feed the report as findings. In the default flow the pre-pass runs before the review agent; under `--multi-agent` it runs **in parallel with the finder fleet** (finders never consume its output), with base-vs-head test attribution scripted via two concurrent worktree runs. See `references/deterministic-prepass.md`.

### 4. Match situational checks
Before building review briefs, match the resolved diff against the **situational-check catalog** (`references/situational/index.md`) — a sparse, always-loaded index of surface-specific bug hunts (file uploads, payments, migrations, …) whose full bodies load **only when the diff matches their trigger**. Grep the diff (chunk files under `--multi-agent`, raw diff otherwise) for each entry's Match pattern by script; for every hit, load that body and append it to the brief of the lens it attaches to (no new agents — matched checks augment the existing pass/finder briefs). Disclose the checks that fired in the report header's **Situational checks** line. Full mechanism and authoring rules: `references/situational-checks.md`.

### 5. Review the diff
Default: **one fresh agent, four lenses** — the "would a senior engineer approve this PR" pass:

1. **Correctness** — logic errors, null handling, race conditions, broken error paths.
2. **Functional Completeness (Last-Mile)** — every behavior the plan promises, traced hop-by-hop through the full chain; not merely a connected happy path.
3. **Plan Conformance** — everything the plan said is present; no silently dropped scope or undeclared deviations.
4. **Coherence** — the change reads as one mind's work; no contradictory patterns or half-migrated approaches.

The lens briefs — hunt-lists per lens, and the no-plan degradation rule (conformance lenses degrade to PR-description/commit-message conformance, and the report must say so) — live in `references/review-lenses.md`. The last-mile lens has its own methodology in `references/last-mile.md`: enumerate promised behaviors, walk each chain hop-by-hop with evidence per hop, hunt the named AI failure modes; **findings without a cited chain are rejected at synthesis**.

### 6. Findings & report — the review run stops here
Findings carry evidence (path:line, named symbol, or observed behavior — **required**), a 1–10 severity (**canonical**, stored in findings.json) mapped to presentation tiers (9–10 Blocker · 7–8 Major · 5–6 Minor · 1–4 Nit), and a concrete recommendation — full shape and scale in `references/findings-and-severity.md`.

Artifacts land in `.deep-skills/<effort>/04-Code-Review/`, shaped by `templates/`:

- `report.md` (← `templates/report.md`) — the review report (and, later, the doc you triage from): verbatim scope line, pre-pass results, severity rollup, findings grouped by tier with lens tags. **Every finding is written with status `open`.**
- `findings.json` (← `templates/finding.json`) — the machine record; numeric severity canonical; **all statuses `open`**.
- `certificate.md` (← `templates/certificate.md`) — pass/fail verdict (pass = no Blockers) + rollup; **triage outcomes left pending** until the triage step runs.

Update the effort manifest (created if absent — any deep-* skill owns manifest creation on first write).

**The review run ends here.** It makes **no fix/defer/reject decisions, asks no triage questions, and writes nothing outside `04-Code-Review/`** — in particular it never edits the plan or the Deferreds ledger, not even to record deferreds. It closes by printing the rollup and a one-line pointer:

> *Review complete — N findings (status: open). Run `/deep-code-review --triage` to decide fix / defer / reject and route accepted fixes into the plan.*

### 7. Triage & fix-phase routing — a separate, opt-in step (`--triage`)
Triage is **decoupled from the review** so the review never blocks on a human and never edits the plan. It runs only when the user invokes `/deep-code-review --triage` (or asks to triage the findings), operating on the `open` findings in the latest `04-Code-Review/findings.json`:

- **Blockers auto-accept — no decision needed, user informed.** Status → `accepted`.
- **Major / Minor / Nit → HITL**, finding by finding, exactly three outcomes: **fix** (→ fix-phase, status `accepted`) / **defer** (→ plan's Deferreds ledger, status `deferred`) / **reject** (status `rejected by user`).
- Accepted findings become a **fix-phase appended to the plan**, structured per deep-plan's phase conventions — Goal / Prerequisites / Files / Steps (one per accepted finding, citing its evidence) / Acceptance — so `/deep-implement` can execute it cold. In no-plan mode, generate a **minimal fix-phase plan stub** at `.deep-skills/<effort>/01-Plan/plan.md` (Context + the fix-phase only) so the implement loop stays available.
- Then rewrite `findings.json` statuses, fill the certificate's **Triage outcomes** table, and update the effort manifest's Code Review status.

This is the **only** step that writes to the plan, the Deferreds ledger, or the fix-phase stub. The review run that produced the findings did none of that.

## Flags

- **`--multi-agent`** — the full-treatment review, in five stages, with **token discipline built in** (budgets, floors, and model tiers below are calibrated from two measured baseline runs — don't relax them mid-run). **(0) Scripted setup:** the deterministic work runs as scripts, never agents — the diff is **pre-chunked** per-file with an index (finders never ingest the monolithic diff), the pre-pass launches **in parallel** with the finder fleet, and verifier briefs get a scripted **fact pre-harvest** (evidence lines, symbol definitions, caller lists). **(A) Finder fleet:** eight independent **single-lens** finder passes, **model-tiered by what each lens catches** — tiers resolve from the orchestrator's own model (Fable 5 run: main=Fable 5 / mid=Opus 4.8 / cheap=Sonnet latest; Opus 4.8 run: main=mid=Opus 4.8 / cheap=Sonnet latest; **Haiku is never used — any tier, any stage**) and the resolved model is **set explicitly on every agent launch as a pinned FULL model ID** (`claude-fable-5` / `claude-opus-4-8` / latest `claude-sonnet-*`) — never inherited, never a bare alias like `opus`, which the harness may resolve below the mandated tier (see `references/multi-agent.md` § Model tier resolution). The Blocker/Major-finding lenses (`removed-behavior`, `seam-trace`, `last-mile`, `frozen-state-probe`) run on the main tier; `diff-scan`, `conformance`, `coherence` on the mid tier; the combined `quality` sweep (duplication/simplification/performance/conventions) on the cheap tier, **severity-capped at ≤4** — **read-only, one parallel batch, capped at 8 concurrent**. Finders are **budgeted** (read each chunk once, ~25 tool calls, one decisive trace per candidate — verification owns proof) and **overgenerate above the nit floor** (every evidenced sev ≥4 candidate, no caps; sev ≤3 capped at ~10 + a one-line summary of the rest; a sev-5 proposal must justify why it isn't a 4). **(B) Dedup + decomposition:** merge by root cause when one fix resolves both reports; **split** when one candidate bundles sub-defects with independent fix paths — N fixes → N findings. **(C) Adversarial verification, severity-gated and tiered:** candidates at **sev ≥5** get a fresh verifier briefed to **refute** them (burden of proof on the finding; sub-claims verified independently; severity checked by counting independent user-reachable trigger paths; verdict returned in a fixed machine-readable format) — **sev-5 verifiers run on the cheap tier, sev ≥6 on the main tier**, launched as **one streamed wave** off the merge, not batched waves; verdicts `confirmed`/`plausible`/`refuted`; refuted candidates land in a report appendix with rationale, never silently dropped; sev ≤4 ships `unverified` with finder evidence. **(D) Script-assembled synthesis:** findings.json, rollup, funnel line, nit table, and certificate scaffold are assembled **by script** from the structured verdicts; the model writes only the judgment — evidence-rule enforcement, severity reconciliation, merge/split calls, and per-finding prose for sev ≥5. One report; full writeups for Minor+, a compact table for the nit tier. Under this flag the combined single-agent pass does not additionally run — its lenses run as independent finders. Briefs: `references/dimensions.md` + `references/review-lenses.md`; mechanics: `references/multi-agent.md`.
- **`--mega`** — the thorough tier: the same five-stage pipeline with the cost/accuracy dials at maximum — **all eight finders and all verifiers on the main tier** (the orchestrator's model, set explicitly per launch), quality's sev cap lifted — at roughly double the default's wall clock and rate-limit footprint. The scripted stages (chunking, parallel pre-pass, fact harvest, report assembly) stay: determinism trades no accuracy. For release gates and large risky merges; confirm the cost with the user before launching. See `references/multi-agent.md` § `--mega`.
- **`--security`** — a documented seam, **inert until `/deep-security` exists** (a separate effort; nothing executes under this flag today — if invoked, say so and proceed without it). The contract for when it lands: deep-security's dimension agents join this review's fan-out under the same read-only finder rules, same finding shape (`dimension` set) and same 1–10 severity scale; their findings merge into THIS report's **Security** section for a **single triage pass** (never a separate report); artifacts still land in this effort's `04-Code-Review/` (only standalone `/deep-security` runs write to `05-Security/`, per `references/artifact-structure.md`). Full seam contract: `references/multi-agent.md` § The `--security` seam.
- **`--triage`** — run **only** the triage step (Workflow § 7) over the latest review's `open` findings: Blockers auto-accept; Major/Minor/Nit get fix/defer/reject; accepted fixes route into the plan's fix-phase and deferreds into its ledger. This is the **one mode that writes to the plan** — the review modes never do. Invoke it after a review, when you're ready to decide; it never re-runs the review.
- **`--browser`** — live last-mile verification: exercise the plan's promised behaviors against an **already-running** dev server via browser tools, watching real network traffic; findings feed the last-mile lens with observed evidence (`evidence.observed` cites request URL/method/status/payload as seen, never inferred). **Never starts a server; never reads `.env` for port discovery** (package.json / angular.json / CLAUDE.md, else ask). See `references/browser-verification.md`.

## Guardrails

- **Review only — never edit source, where "source" = application code.** The **review run** writes exactly one place: its own `.deep-skills/<effort>/04-Code-Review/` artifacts (`report.md`, `findings.json`, `certificate.md`) plus the effort manifest. It **never edits the plan, the Deferreds ledger, or any doc outside `04-Code-Review/`** — not even to record deferreds. Writing the fix-phase append to the plan and the no-plan-mode plan stub happens **only in the separate `--triage` step** (Workflow § 7), and only on findings the user has triaged. If the user wants fixes built, point them to `/deep-implement`.
- **State the resolved scope before launching any agent**, and **ask the user on any ambiguity** about what is being diffed — never guess a base branch.
- **Never read `.env` or secrets files** during host-project discovery (commands, ports, anything). Use package.json / angular.json / CLAUDE.md; ask the user if a needed value isn't there.
- Findings must cite evidence — a path:line, a named symbol, or an observed behavior. No vague "consider improving."
- Never pass the implementation transcript to review agents — fresh eyes only.
- If a lens finds nothing, say the diff is clean on that lens rather than inventing findings.
- Under `--multi-agent`, finders overgenerate above the nit floor and the verification stage owns precision — never cap sev ≥4 finding counts or let a finder self-filter beyond the evidence rule (the `quality` pass's sev ≤4 cap is the one designed exception). The flip side is equally binding: respect the token discipline (finder tool budgets, the sev ≥5 verification floor, the sev ≤3 top-10 cap, the model tiers, the scripted stages) — don't relax it mid-run because the diff "feels important"; escalating to `--mega` is the user's call, made before launch.
- **Model routing is load-bearing: set the model explicitly on every agent launch, and never use Haiku anywhere in this pipeline.** A run whose main-tier lenses silently fell to Haiku produced zero Blockers/Majors on a diff with two known Criticals — if any agent turns out to have run below its assigned tier, its output is invalid; discard and relaunch it.

<!-- Authoring note: this SKILL.md stays under 500 lines with detail in references/, per the
     skill-creator skill's authoring rules (the source of the <500-line limit — distinct from
     the .maudel skill guidelines, which govern Maudel-runtime skills and state a different rule). -->
