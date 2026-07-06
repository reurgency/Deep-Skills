# Training: `/deep-code-review`

> Part of the [Deep Skills Training Program](README.md). Skill 4 of 6 — **verify**.
> Source: [`plugins/deep-skills/skills/deep-code-review/SKILL.md`](../../plugins/deep-skills/skills/deep-code-review/SKILL.md)

`/deep-code-review` independently reviews **implemented code** the way `/deep-plan-review`
reviews a plan: fresh agents, evidence-required findings, a clean review report. Its signature
concern is the **last-mile problem**. **Review only — never edits application source.**
**Triage is a separate, opt-in step** (`--triage`) — the review run itself makes no
fix/defer/reject decisions and never edits the plan.

This is the skill that closes the loop: the gate between *"the implementation agent says it's
done"* and *"this is actually done."*

---

## Learning objectives

By the end you can:

1. **Resolve and state the scope** of a diff before launching anything, asking on ambiguity.
2. Run the **deterministic pre-pass** (lint/typecheck/tests) as tools, never agents.
3. Review across the **four lenses** and apply the **last-mile** methodology (chain-tracing
   with per-hop evidence).
4. Produce a correct **findings.json + report.md + certificate.md**, all findings `open`.
5. Choose between **default / `--multi-agent` / `--mega`** and understand the finder-fleet,
   adversarial-verification, and **model-tier** discipline.
6. Run the decoupled **`--triage`** step — the only mode that writes to the plan.

## Prerequisites

The whole pipeline — especially [`/deep-plan-review`](deep-plan-review.md) (same independence
principle) and the [shared mental model](README.md#the-shared-mental-model-read-this-before-any-skill-page)’s
*last mile + evidence*.

---

## Mental model

**The implementer is too close to the code to see what it left out.** The review runs in fresh
agent(s) that receive the diff + the plan + codebase access — **but never the implementation
transcript.** Its signature concern is the **last mile**: code where the interface looks
correct and the happy path appears connected, but the behavior doesn't make it the last mile —
optimistic UI with no real call, swallowed errors, half-wired chains, silently dropped plan
scope.

Two structural separations make it trustworthy:
- **Review ≠ triage.** The review autonomously produces findings (all `open`) and stops. A
  human decides fix/defer/reject later, under `--triage`.
- **Determinism ≠ judgment.** Lint/typecheck/tests run as scripts; agents do the reasoning.

---

## Curriculum

### Module 1 — Resolve scope, and state it
Per `references/scope-resolution.md`:
- **No args (default):** current feature branch vs the base it was cut from (PR-declared base →
  merge-base candidates → **ask on any ambiguity**). Working tree + staged changes included.
- **PR argument** (`PR65`, `#65`, a URL): resolve via `gh`.
- **Explicit paths:** review just those.

**Before launching anything**, print the resolved scope in one line — e.g.
`Diffing feat/x against develop (working tree included) — 14 files, +812/−214` — and in
collaborative settings give the user a beat to correct it. **Never guess a base branch.**

### Module 2 — Resolve the effort & artifact home
- **A deep-\* plan exists** → artifacts go to that effort's `04-Code-Review/`; **read the plan
  in full** (it drives the Plan-Conformance and Last-Mile lenses).
- **No plan** (PR / arbitrary diff) → ask for an effort name, defaulting to the slugified
  branch name; create the dir + manifest if absent.

### Module 3 — Deterministic pre-pass
Run lint, typecheck, and tests as **deterministic tools, never agents** — linting is
deliberately not an LLM job. Discover commands from the host project — **never from
`.env`/secrets**. Results feed the report as findings. (`references/deterministic-prepass.md`)

### Module 4 — Match situational checks
Match the diff against the **situational-check catalog**
(`references/situational/index.md`) — surface-specific bug hunts (file uploads, payments,
migrations, …) whose bodies load **only when the diff matches their trigger**. Append each
matched body to the brief of the lens it attaches to (no new agents). **Disclose which checks
fired** in the report header's *Situational checks* line.

### Module 5 — The four lenses
Default: **one fresh agent, four lenses** — the "would a senior engineer approve this PR" pass:

1. **Correctness** — logic errors, null handling, race conditions, broken error paths.
2. **Functional Completeness (Last-Mile)** — every behavior the plan promises, traced
   hop-by-hop through the full chain; not merely a connected happy path.
3. **Plan Conformance** — everything the plan said is present; no silently dropped scope or
   undeclared deviations.
4. **Coherence** — the change reads as one mind's work; no contradictory or half-migrated
   patterns.

With no plan, the conformance lenses **degrade** to PR-description/commit-message conformance,
and the report must **say so**.

### Module 6 — The last-mile methodology
From `references/last-mile.md`: **enumerate** the promised behaviors, **walk each chain
hop-by-hop with evidence per hop**, and hunt the named AI failure modes. **Findings without a
cited chain are rejected at synthesis.** This is the heart of the skill — practice it directly.

### Module 7 — Findings & report (the review run stops here)
Findings carry **evidence** (path:line, named symbol, or observed behavior — **required**), a
**1–10 severity** (canonical, in findings.json) mapped to tiers (9–10 Blocker · 7–8 Major ·
5–6 Minor · 1–4 Nit), and a concrete recommendation. Artifacts land in `04-Code-Review/`:

- `report.md` — scope line, pre-pass results, rollup, findings by tier with lens tags. **Every
  finding `open`.**
- `findings.json` — machine record; numeric severity canonical; **all `open`.**
- `certificate.md` — pass/fail (pass = no Blockers); **triage outcomes pending.**

The review **ends here** — no triage decisions, no questions, **nothing written outside
`04-Code-Review/`** (in particular it never edits the plan). It closes with:
> *Review complete — N findings (status: open). Run `/deep-code-review --triage` …*

### Module 8 — Triage (`--triage`, the only mode that writes to the plan)
Decoupled so the review never blocks on a human. On the latest `open` findings:
- **Blockers auto-accept** (user informed) → `accepted`.
- **Major / Minor / Nit → HITL**, finding by finding: **fix** / **defer** (→ Deferreds ledger)
  / **reject**.
- Accepted findings become a **fix-phase appended to the plan** (Goal / Prerequisites / Files /
  Steps / Acceptance) so `/deep-implement` can execute it cold. No-plan mode generates a
  minimal plan stub.

---

## Flags (know which to reach for)

| Flag | When | What it changes |
|---|---|---|
| *(default)* | Most reviews | One fresh agent, four lenses + deterministic pre-pass. |
| `--multi-agent` / `/multi-agent` | Large/risky diffs | Five-stage pipeline: scripted setup → **8 model-tiered single-lens finders** → dedup/decompose → **severity-gated adversarial verification** → script-assembled synthesis. Token-disciplined. |
| `--mega` | Release gates, big risky merges | Same pipeline with dials at max — all finders/verifiers on the main tier; ~2× wall clock. **Confirm cost with the user first.** |
| `--browser` | Live last-mile proof | Exercises promised behaviors against an **already-running** dev server; cites observed request/response. Never starts a server; never reads `.env`. |
| `--security` | (future) | Inert until `/deep-security` exists — a documented seam. |
| `--triage` | After a review | Runs only the triage step; the one mode that writes to the plan. |

### The model-tier discipline (multi-agent / mega)
Finders are **model-tiered by what each lens catches**, and the model is **set explicitly on
every agent launch as a pinned full ID** (`claude-fable-5` / `claude-opus-4-8` / latest
`claude-sonnet-*`) — never a bare alias, **never Haiku, any tier, any stage.** Blocker/Major
lenses run on the main tier; `diff-scan`/`conformance`/`coherence` on mid; the combined
`quality` sweep on cheap, severity-capped ≤4. Adversarial verification is **severity-gated**:
sev ≥5 candidates get a fresh verifier briefed to **refute** them. *Model routing is
load-bearing — a run that silently fell to Haiku produced zero findings on a diff with two
known Criticals.* If any agent ran below its tier, discard and relaunch it.

---

## Directive cards

`/deep-code-review` is the **distiller source** for the Deep-Learn loop — recurring issue
classes from reviews become directive cards that harden the *upstream* skills. (It does not
itself load cards at runtime the way the first three do.) See the
[Deep-Learn overview](README.md#deep-learn--the-self-improving-directive-loop).

---

## Hands-on exercises

1. **Scope statement:** for a branch with working-tree changes, write the exact one-line scope
   you'd print before launching — and name what you'd ask the user if the base is ambiguous.
2. **Chain trace:** pick one promised behavior and walk it hop-by-hop, citing evidence per hop;
   find where (if anywhere) it stops short of the last mile.
3. **Evidence discipline:** rewrite a vague "error handling could be better" into an
   evidence-cited finding with a severity and a concrete recommendation.
4. **Flag call:** choose default vs `--multi-agent` vs `--mega` for a 3-file fix vs a 40-file
   release merge; justify the cost.
5. **Triage:** take a findings.json with 1 Blocker and 3 Minors and walk the fix/defer/reject
   loop, producing the fix-phase append.

---

## Common mistakes

- **Launching before stating scope** — or guessing a base branch. State it; ask on ambiguity.
- **Passing the implementation transcript** — fresh eyes only.
- **Reviewing the happy path** and calling it complete — that's exactly the last-mile trap.
- **A finding without a cited chain/evidence** — rejected at synthesis.
- **Letting the review triage** — it never decides fix/defer/reject or edits the plan; that's
  `--triage`.
- **Reading `.env` for commands/ports** — never. Use package.json / angular.json / CLAUDE.md, else ask.
- **Relaxing token discipline** mid-run because the diff "feels important" — escalating to
  `--mega` is the user's call, before launch.
- **A bare model alias** (or Haiku) in the multi-agent pipeline — pin the full ID per launch.

## Mastery checklist

- [ ] Stated resolved scope in one line before any agent; asked on ambiguity.
- [ ] Ran the deterministic pre-pass as tools, not agents; never touched `.env`.
- [ ] Reviewed all four lenses; traced each promised behavior hop-by-hop with evidence.
- [ ] Produced report.md + findings.json + certificate.md with **all findings `open`**, nothing written outside `04-Code-Review/`.
- [ ] Chose the right flag for the diff's risk and respected the model-tier discipline.
- [ ] Ran `--triage` as a separate step and routed accepted fixes into a cold-executable fix-phase.

## Quick reference

| | |
|---|---|
| Input | A diff: default branch-vs-base, a PR, or explicit paths |
| Output | `04-Code-Review/` → `report.md` · `findings.json` · `certificate.md` (all `open`) |
| Lenses | Correctness · Last-Mile · Plan Conformance · Coherence |
| Pass | No Blockers |
| Hard rules | Review never edits source or the plan; only `--triage` writes to the plan; never Haiku in the pipeline |
| Loops back to | [`/deep-bugfix`](deep-bugfix.md) (remediates the accepted findings) |

➡ **Next:** [Training: `/deep-bugfix`](deep-bugfix.md)
