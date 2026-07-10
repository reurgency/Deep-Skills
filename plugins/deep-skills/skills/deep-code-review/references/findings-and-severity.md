# Findings and severity — shape, scale, and routing

Every finding — agent-produced or pre-pass-produced — uses one shape, one severity scale, and one routing model. Templates: `templates/finding.json` (the machine shape stored in `findings.json`), `templates/report.md` (human presentation), `templates/certificate.md` (rollup).

## Finding shape

| Field | Required | Content |
|---|---|---|
| **id** | yes | `CR-NNN`, sequential within the review (`CR-001`, `CR-002`, …). Stable across report/findings.json/certificate. |
| **lens** | yes | The lens that produced it: `correctness` · `last-mile` · `plan-conformance` · `coherence` · `pre-pass`. |
| **dimension** | yes (nullable) | `null` in the default single-agent review; under `--multi-agent`, the finder pass id (`diff-scan` · `removed-behavior` · `seam-trace` · `frozen-state-probe` · `quality` — see `references/dimensions.md`; the four lens passes keep `null` since their `lens` already names them) — an **array of ids** when synthesis merges one root cause raised by several passes. |
| **severity** | yes | Numeric **1–10** — see scale and calibration below. |
| **tier** | yes | The mapped presentation tier (derived from severity; stored for convenience). |
| **title** | yes | One line, concrete. |
| **evidence** | yes — **REQUIRED, no exceptions** | At least one of: `path:line`, a **named symbol** (`TrackService.saveTrack`), or an **observed behavior** (pre-pass output, browser-observed traffic). Last-mile findings cite the hop-by-hop chain (see `references/last-mile.md`). A finding without evidence is rejected at synthesis. |
| **recommendation** | yes | Concrete: what to change, where, toward what. Never "consider improving." |
| **status** | yes | Triage lifecycle — see Policy actions below. |
| **verification** | multi-agent only | Adversarial-verification verdict: `confirmed` (evidence independently reproduced) · `plausible` (couldn't refute, couldn't fully reproduce) · `unverified` (no verifier ran — single-agent mode, or the finding sits below multi-agent's **sev ≥5 verification floor**). `refuted` candidates never appear as findings; they go to the report's Refuted-candidates appendix with their rationale. See `references/multi-agent.md` § Stage C. |

## Severity scale and tier mapping

Severity is judged on a **1–10 numeric scale**, mapped to four presentation tiers:

| Numeric | Tier | Meaning |
|---|---|---|
| **9–10** | **Blocker** | The change is wrong, broken, or materially incomplete as shipped — a promised behavior doesn't happen, data is corrupted/lost, the chain is severed. Must be fixed before this work is considered done. |
| **7–8** | **Major** | A real defect or real misalignment that should be fixed — a failing test over changed code, a broken edge path, silently dropped plan scope — but the core change still functions. |
| **5–6** | **Minor** | Worth addressing — a type error at the boundary, a pattern deviation, an incomplete secondary effect — but the change works. |
| **1–4** | **Nit** | Polish: lint-level issues, naming, small coherence wrinkles. Take it or leave it. |

### Calibrating severity — count the trigger paths

A severity claim must be **justified by enumerating the independent, user-reachable paths** that trigger the failure, cited in the evidence or recommendation. More independent paths to the same broken outcome ⇒ higher severity; a defect reachable from three separate UI flows is not the same rating as one requiring a hand-crafted database row. The converse holds too: a scary-looking gap with no reachable trigger rates lower than its symptom suggests. Under `--multi-agent`, the verification stage checks this calibration explicitly — a verifier may raise or lower the proposed severity, with the path count as the stated rationale. Two multi-agent floor rules also apply: a finder proposing **exactly sev 5** must state why it isn't a 4 (5 is the verification floor, and marginal floor-riding candidates each cost a verifier), and the `quality` pass proposes nothing above 4 (see `references/dimensions.md`).

Conventional starting points for **deterministic pre-pass** results (must match `references/deterministic-prepass.md`; judgment applies — a lint rule guarding a real bug class can rate higher):

| Pre-pass result | Severity |
|---|---|
| Test failure in/over changed code | 7–8 (Major) |
| Type error in changed code | ≈ 6 (Minor/Major boundary) |
| Lint issue in changed code | 3–4 (Nit) |

### What's canonical, and how this relates to the in-app model

**The numeric 1–10 severity is canonical and is what `findings.json` stores. Blocker/Major/Minor/Nit are the series' presentation/triage vocabulary** — the words humans triage with, derived from the number, never the other way around. **The relation to in-app policy actions (auto-accept / notify-only / human-decision / block-and-fix) is conceptual, not literal — Blocker ≈ block-and-fix — and the simplified triage model below is a deliberate choice for terminal use.** Keeping the numeric scale canonical is also what keeps a future in-app interop bridge thin (a findings.json importer, no remapping).

## Policy actions — what happens per tier

**These actions belong to the separate `--triage` step, not the review run.** A finished review leaves *every* finding at status `open` and writes nothing to the plan; the table below describes what `/deep-code-review --triage` does later, once the user invokes it.

| Tier | Action |
|---|---|
| **Blocker** (9–10) | **Auto-accept at triage — no decision needed.** A Blocker is by definition not optional. When `--triage` runs, its status is set to `accepted` and it joins the set routed to `/deep-bugfix` (or, fallback only when that skill isn't installed, the fix-phase appended to the plan / the no-plan plan stub), and the **user is informed** that this happened. (The review run itself only flags it as a Blocker in the certificate verdict — it does not route or write the plan.) |
| **Major / Minor / Nit** (1–8) | **HITL triage**, finding by finding, with exactly three outcomes (below). |

Triage outcomes for non-Blockers:

- **fix** → status `accepted`; the accepted set hands off to `/deep-bugfix` (fallback only, when it isn't installed: the finding joins the fix-phase appended to the plan for `/deep-implement`).
- **defer** → the finding is added to the plan's **Deferreds** ledger (What / Why deferred / Integration); status `deferred`.
- **reject** → the finding stays in the report and findings.json with status **`rejected by user`** — the decision stays on record; it is not silently dropped.

Statuses through the lifecycle: `open` (pre-triage) → `accepted` | `deferred` | `rejected by user`; after `/deep-bugfix` proves a fix (or, on the fallback route, `/deep-implement` executes the fix-phase), accepted findings are marked `fixed`.

## Auto-policy triage — `--triage --auto-accept-min=<severity>`

*Natural-language trigger: say "accept majors and up," "auto-triage, accept severity 7 and above."*

With the numeric threshold argument, the HITL loop is replaced by a deterministic, **zero-prompt** policy over the `open` findings in the latest `findings.json`:

| Finding | Outcome |
|---|---|
| **Blocker (9–10)** | `accepted` — **always, regardless of the threshold** (a Blocker is by definition not optional; identical to HITL triage). |
| severity ≥ threshold | `accepted` — joins the `/deep-bugfix` hand-off (or the fix-phase fallback) exactly like a HITL "fix." |
| severity < threshold | **auto-DEFER** — status `deferred` **and a new row in the plan's Deferreds ledger** (What = the finding, one line with its id and severity · Why deferred = below the auto-accept threshold `<severity>` this run · Integration = re-triage or fix in a later round; the finding stays on record in findings.json). |
| already `deferred` / `rejected by user` / `fixed` (prior rounds) | **Untouched** — status and any existing ledger row are preserved. Auto-policy acts only on `open` findings, so no dedupe pass is needed: re-review rounds emit fresh CR ids for fresh findings only (see § Re-review rounds). |

Two invariants: **nothing is ever auto-rejected** — `rejected by user` means exactly that, a human said no — and **nothing is dropped**: every below-threshold finding is loudly deferred (ledger row + `deferred` status), never silently discarded. Everything else in the triage step is unchanged: rewrite `findings.json` statuses, fill the certificate's Triage-outcomes table, update the effort manifest, route the accepted set.

Threshold values are the same canonical 1–10 numeric severities findings carry (tier names are presentation vocabulary): `--auto-accept-min=9` accepts Blockers only; `=7` Blocker + Major; `=5` Blocker + Major + Minor.

## Re-review rounds — append semantics (canonical)

A **re-review** — a fresh `/deep-code-review` run on the same effort after a fix round — does not start a new findings file; it **appends to the existing one**. Canonical rules (deep-bugfix's hand-off pointer, "a re-review re-diffs and appends new findings under fresh IDs," summarizes this section):

- **Fresh CR ids, appended.** The re-review re-diffs and writes every new finding under a fresh sequential id (next = max existing `CR-NNN` + 1), appended to the same `findings.json` `findings` array. Ids are never reused or renumbered.
- **Prior statuses preserved.** Existing findings keep their statuses exactly — `fixed` stays `fixed`, `deferred` stays `deferred`, `rejected by user` stays `rejected by user`. A re-review never resets anything to `open`; only its own fresh findings are born `open`.
- **`reviewed` date updated.** The file's top-level `reviewed` field is set to the re-review date (this, plus the fresh ids, is how a consumer distinguishes "a new round ran" from "nothing happened").
- `report.md` and `certificate.md` are rewritten for the current round as usual; the round's rollup and verdict consider unresolved findings (a `fixed` or `rejected by user` Blocker no longer fails the certificate; see Presentation order below).

This is what makes round accounting possible for any consumer of `findings.json`: the non-`fixed` count per round is meaningful only because prior verdicts survive the append.

## Presentation order (report.md)

Group by tier, Blockers first; within a tier, by lens. Lead with the severity rollup. End each lens with a one-line verdict ("Coherence: clean") — say clean explicitly rather than padding. The certificate's verdict is **pass only when no Blockers remain unresolved** (every 9–10 finding is `fixed`, or none existed).
