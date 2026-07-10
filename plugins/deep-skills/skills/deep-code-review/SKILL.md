---
name: deep-code-review
description: Independently review implemented code with fresh, evidence-driven agents — correctness bugs, last-mile functional gaps (UI that looks wired but isn't), plan conformance, and coherence — and produce a review report with every finding left open. Triage (fix/defer/reject) and routing accepted findings to /deep-bugfix (fix-phase + /deep-implement as the fallback) are a separate, opt-in step (--triage; add --fix to chain into an autonomous bugfix run), so the review itself runs autonomously and never edits the plan. Use after /deep-implement, before merge, or on any branch/PR/diff. Triggers on /deep-code-review and on requests to deep-review code, a PR, a branch, or a diff. Reviews code only — it never edits application source.
argument-hint: branch/PR/diff/folder, or Enter for current branch · --multi-agent · --triage [--auto-accept-min=<severity>] · --fix
---

# DeepCodeReview

Independently review **implemented code** the way `/deep-plan-review` reviews a *plan*: fresh agents, evidence-required findings, and a clean review report. **Triage is a separate, opt-in step** (`--triage`) — the review run itself makes no fix/defer/reject decisions, asks no triage questions, and **never edits the plan**. **Review only — never edit source** (see Guardrails for what "source" means).

This is the fourth skill of the `deep-*` series: `/deep-plan` (produce) → `/deep-plan-review` (critique the plan) → `/deep-implement` (execute) → **`/deep-code-review` (critique the code)** (→ `/deep-bugfix` (remediate) → re-review) → `/deep-docs` (map what's built). It closes the loop: the gate between "the implementation agent says it's done" and "this is actually done."

## Core principle: independence + the last mile

The implementer is too close to the code to see what it left out. The review runs in **fresh agent(s)** that receive the diff + the plan + codebase access — **but never the implementation transcript**. Its signature concern is the **last-mile problem**: code where the interface looks correct and the happy path appears connected, but the behavior doesn't make it the last mile — optimistic UI with no real call, swallowed errors, half-wired chains, silently dropped plan scope.

## Directive cards (Deep-Learn)

Before you start, load this phase's active directive cards — learned, human-vetted improvements stored as **data**, never baked into this skill. Run the bundled script in this skill's `scripts/` directory and apply what it prints:

```bash
scripts/load-active-cards.sh deep-code-review
```

**Treat every directive it prints as a hard requirement for this run**, applying the section addressed to your phase. If it prints "no active directive cards," proceed normally. Cards are human-gated — never edit a card or this skill to turn one off; toggle with `directives/toggle.sh <ID> off` (see the registry's `directives/README.md`). On a host without a reliable shell, apply the cards by hand instead — read the directives registry's `cards/active/` and apply each card whose `owner_phases` lists this phase as an exact token (see `references/host-affordances.md`).

## The deep-* series (separation of concerns)

| Skill | Job | This skill's boundary |
|---|---|---|
| `/deep-plan` | Frame → explore → question → write the plan (resumable phases + deferreds). | Out of scope here. |
| `/deep-plan-review` | Independently review the finished plan with fresh agents. | Out of scope here. |
| `/deep-implement` | Execute the plan: implement → validate → fix → commit → hand-off. The only skill that writes source as forward construction from a plan. | Out of scope here. |
| `/deep-code-review` (you) | Independently review implemented code; emit findings. | Independently review implemented code; emit severity-gated, adversarially-verified findings. **Reports, never fixes.** |
| `/deep-bugfix` | Remediate defects: cluster → diagnose → fix at the cause → prove → contain → commit. | Out of scope here — accepted findings route there at `--triage` (Workflow § 7); **triage decisions stay here.** |
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

> *Review complete — N findings (status: open). Run `/deep-code-review --triage` to decide fix / defer / reject and route accepted findings to `/deep-bugfix` (fix-phase fallback when it isn't installed).*

### 7. Triage & fix routing — a separate, opt-in step (`--triage`)
Triage is **decoupled from the review** so the review never blocks on a human and never edits the plan. It runs only when the user invokes `/deep-code-review --triage` (or asks to triage the findings), operating on the `open` findings in the latest `04-Code-Review/findings.json`:

- **Blockers auto-accept — no decision needed, user informed.** Status → `accepted`.
- **Major / Minor / Nit → HITL**, finding by finding, exactly three outcomes: **fix** (status `accepted`) / **defer** (→ plan's Deferreds ledger, status `deferred`) / **reject** (status `rejected by user`).
- **Accepted findings hand off to `/deep-bugfix`** — the series' dedicated remediation executor (diagnosis-first, proof-of-fix, blast-radius containment). When it is installed, this is the route: it consumes the `accepted` set from `findings.json` directly, and **no fix-phase is appended to the plan** — exactly one executor owns the accepted set, so skipping the append means the same findings can never be remediated twice. Close triage by pointing at `/deep-bugfix` (or, under `--fix`, chaining into it — see Flags).
- **Fallback only — `/deep-bugfix` not installed:** accepted findings become a **fix-phase appended to the plan**, structured per deep-plan's phase conventions — Goal / Prerequisites / Files / Steps (one per accepted finding, citing its evidence) / Acceptance — so `/deep-implement` can execute it cold. In no-plan mode, generate a **minimal fix-phase plan stub** at `.deep-skills/<effort>/01-Plan/plan.md` (Context + the fix-phase only) so the implement loop stays available.
- Then rewrite `findings.json` statuses, fill the certificate's **Triage outcomes** table, and update the effort manifest's Code Review status.

This is the **only** step that writes to the plan or the Deferreds ledger (deferrals always; the fix-phase append and its no-plan stub only on the fallback route). The review run that produced the findings did none of that.

**Auto-policy (`--triage --auto-accept-min=<severity>`)** — say *"accept majors and up," "triage automatically, accept severity 7 and above."* When the numeric threshold argument is present, the HITL loop above is replaced by a zero-prompt threshold policy over the same `open` set:

- severity **at/above** the threshold → status `accepted` (joins the `/deep-bugfix` hand-off as usual);
- severity **below** the threshold → **auto-DEFER**: status `deferred` + a **new** row in the plan's Deferreds ledger — **never auto-reject** (`rejected by user` requires a human);
- **Blockers (9–10) are always auto-accepted regardless of the threshold** — same as HITL triage;
- findings already `deferred` from a prior round **keep their status and their existing ledger row** (auto-triage acts only on `open` findings, so no dedupe pass is needed);
- everything else in this step is unchanged: rewrite `findings.json`, fill the certificate's Triage-outcomes table, update the manifest, close by routing the accepted set (or chaining under `--fix`).

Semantics and full policy table: `references/findings-and-severity.md` § Auto-policy triage. Without the argument, `--triage` runs the HITL loop exactly as above.

## Flags

Per the cross-assistant **Portability** rule, every flag is **natural-language-first** — the plain-language trigger is the primary path (users on Copilot/Codex have no slash-commands or CLI flags); the `--flag` is a convenience layered on top. Always accept the natural-language form.

- **Run a full multi-agent review** (`--multi-agent` / `/multi-agent`) — say *"run a full multi-agent review," "do the thorough fleet review."* The full-treatment review, in five stages, with **token discipline built in** (budgets, floors, and model tiers below are calibrated from two measured baseline runs — don't relax them mid-run). **(0) Scripted setup:** the deterministic work runs as scripts, never agents — the diff is **pre-chunked** per-file with an index (finders never ingest the monolithic diff), the pre-pass launches **in parallel** with the finder fleet, and verifier briefs get a scripted **fact pre-harvest** (evidence lines, symbol definitions, caller lists). **(A) Finder fleet:** eight independent **single-lens** finder passes, **model-tiered by what each lens catches** — tiers (main/mid/cheap) resolve from the orchestrator's own (ceiling) model and bind to concrete host IDs via `references/model-map.md`, a required launch input (**all three are reasoning tiers — `cheap` is the cheapest *reasoning* model, never a small one; a host's small/utility models like Haiku never appear, since every pass reasons**), and the resolved model is **set explicitly on every agent launch as a pinned FULL model ID** — never inherited, never a bare alias like `opus`, which the harness may resolve below the mandated tier (mechanics in `references/multi-agent.md` § Model tier resolution). The Blocker/Major-finding lenses (`removed-behavior`, `seam-trace`, `last-mile`, `frozen-state-probe`) run on the main tier; `diff-scan`, `conformance`, `coherence` on the mid tier; the combined `quality` sweep (duplication/simplification/performance/conventions) on the cheap tier, **severity-capped at ≤4** — **read-only, one parallel batch, capped at 8 concurrent**. Finders are **budgeted** (read each chunk once, ~25 tool calls, one decisive trace per candidate — verification owns proof) and **overgenerate above the nit floor** (every evidenced sev ≥4 candidate, no caps; sev ≤3 capped at ~10 + a one-line summary of the rest; a sev-5 proposal must justify why it isn't a 4). **(B) Dedup + decomposition:** merge by root cause when one fix resolves both reports; **split** when one candidate bundles sub-defects with independent fix paths — N fixes → N findings. **(C) Adversarial verification, severity-gated and tiered:** candidates at **sev ≥5** get a fresh verifier briefed to **refute** them (burden of proof on the finding; sub-claims verified independently; severity checked by counting independent user-reachable trigger paths; verdict returned in a fixed machine-readable format) — **sev-5 verifiers run on the cheap tier, sev ≥6 on the main tier**, launched as **one streamed wave** off the merge, not batched waves; verdicts `confirmed`/`plausible`/`refuted`; refuted candidates land in a report appendix with rationale, never silently dropped; sev ≤4 ships `unverified` with finder evidence. **(D) Script-assembled synthesis:** findings.json, rollup, funnel line, nit table, and certificate scaffold are assembled **by script** from the structured verdicts; the model writes only the judgment — evidence-rule enforcement, severity reconciliation, merge/split calls, and per-finding prose for sev ≥5. One report; full writeups for Minor+, a compact table for the nit tier. Under this flag the combined single-agent pass does not additionally run — its lenses run as independent finders. Briefs: `references/dimensions.md` + `references/review-lenses.md`; mechanics: `references/multi-agent.md`.
- **Run the mega / maximum review** (`--mega`) — say *"run the mega / maximum review."* The thorough tier: the same five-stage pipeline with the cost/accuracy dials at maximum — **all eight finders and all verifiers on the main tier** (the orchestrator's model, set explicitly per launch), quality's sev cap lifted — at roughly double the default's wall clock and rate-limit footprint. The scripted stages (chunking, parallel pre-pass, fact harvest, report assembly) stay: determinism trades no accuracy. For release gates and large risky merges; confirm the cost with the user before launching. See `references/multi-agent.md` § `--mega`.
- **Include the security pass** (`--security`) — say *"include the security pass."* A documented seam, **inert until `/deep-security` exists** (a separate effort; nothing executes under this flag today — if invoked, say so and proceed without it). The contract for when it lands: deep-security's dimension agents join this review's fan-out under the same read-only finder rules, same finding shape (`dimension` set) and same 1–10 severity scale; their findings merge into THIS report's **Security** section for a **single triage pass** (never a separate report); artifacts still land in this effort's `04-Code-Review/` (only standalone `/deep-security` runs write to `05-Security/`, per `references/artifact-structure.md`). Full seam contract: `references/multi-agent.md` § The `--security` seam.
- **Triage the findings** (`--triage`) — say *"triage the findings," "route the findings for fixing."* Run **only** the triage step (Workflow § 7) over the latest review's `open` findings: Blockers auto-accept; Major/Minor/Nit get fix/defer/reject; accepted findings route to `/deep-bugfix` (fix-phase append + `/deep-implement`, fallback only, when it isn't installed) and deferreds into the plan's ledger. This is the **one mode that writes to the plan** — the review modes never do. Invoke it after a review, when you're ready to decide; it never re-runs the review.
- **Auto-triage at a threshold** (`--triage --auto-accept-min=<severity>`) — say *"accept majors and up," "auto-triage, accept severity 7 and above."* Replace `--triage`'s HITL loop with a zero-prompt policy: findings at/above the numeric threshold are `accepted`, everything below is auto-**deferred** (status `deferred` + a new Deferreds-ledger row — never auto-rejected), Blockers (9–10) always accepted regardless. Full semantics: Workflow § 7 and `references/findings-and-severity.md` § Auto-policy triage. Without this argument, `--triage`'s HITL behavior is unchanged.
- **Triage, then fix** (`--fix`) — say *"triage and fix," "fix whatever we accept."* Only meaningful with `--triage`: after triage completes, chain straight into an **autonomous `/deep-bugfix` run** on the accepted set (the § 7 primary route, invoked rather than pointed at). When `/deep-bugfix` isn't installed, this flag is a **no-op with a pointer** — triage completes normally on the fallback route and tells the user to run the fix-phase via `/deep-implement`.
- **Review with browser verification** (`--browser`) — say *"review with browser verification."* Live last-mile verification: exercise the plan's promised behaviors against an **already-running** dev server via browser tools, watching real network traffic; findings feed the last-mile lens with observed evidence (`evidence.observed` cites request URL/method/status/payload as seen, never inferred). **Never starts a server; never reads `.env` for port discovery** (package.json / angular.json / CLAUDE.md, else ask). See `references/browser-verification.md`.

## Guardrails

- **Review only — never edit source, where "source" = application code.** The **review run** writes exactly one place: its own `.deep-skills/<effort>/04-Code-Review/` artifacts (`report.md`, `findings.json`, `certificate.md`) plus the effort manifest. It **never edits the plan, the Deferreds ledger, or any doc outside `04-Code-Review/`** — not even to record deferreds. Writing the fix-phase append to the plan and the no-plan-mode plan stub happens **only in the separate `--triage` step** (Workflow § 7), only on findings the user has triaged, and only on the fallback route. If the user wants fixes built, point them to `/deep-bugfix` (or, when it isn't installed, the fix-phase fallback via `/deep-implement`).
- **State the resolved scope before launching any agent**, and **ask the user on any ambiguity** about what is being diffed — never guess a base branch.
- **Never read `.env` or secrets files** during host-project discovery (commands, ports, anything). Use package.json / angular.json / CLAUDE.md; ask the user if a needed value isn't there.
- Findings must cite evidence — a path:line, a named symbol, or an observed behavior. No vague "consider improving."
- Never pass the implementation transcript to review agents — fresh eyes only.
- If a lens finds nothing, say the diff is clean on that lens rather than inventing findings.
- Under `--multi-agent`, finders overgenerate above the nit floor and the verification stage owns precision — never cap sev ≥4 finding counts or let a finder self-filter beyond the evidence rule (the `quality` pass's sev ≤4 cap is the one designed exception). The flip side is equally binding: respect the token discipline (finder tool budgets, the sev ≥5 verification floor, the sev ≤3 top-10 cap, the model tiers, the scripted stages) — don't relax it mid-run because the diff "feels important"; escalating to `--mega` is the user's call, made before launch.
- **Model routing is load-bearing: set the model explicitly on every agent launch, resolved from `references/model-map.md` (a required launch input); all three tiers are reasoning tiers, so a host's small/utility models (Claude: Haiku) never appear anywhere in this pipeline.** A run whose main-tier lenses silently fell to Haiku produced zero Blockers/Majors on a diff with two known Criticals — if any agent turns out to have run below its assigned (ceiling-relative) tier, its output is invalid; discard and relaunch it.

<!-- Authoring note: this SKILL.md stays under 500 lines with detail in references/, per the
     skill-creator skill's authoring rules (the source of the <500-line limit — distinct from
     the .maudel skill guidelines, which govern Maudel-runtime skills and state a different rule). -->
