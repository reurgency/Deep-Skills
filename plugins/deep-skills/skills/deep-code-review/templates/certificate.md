<!-- Code review certificate — pass/fail + severity rollup, written to
     `.deep-skills/<effort>/04-Code-Review/certificate.md` after triage completes.
     Verdict rule: PASS only when no Blockers remain unresolved (every severity-9–10
     finding is fixed, or none existed). Scope line reproduced verbatim. -->

# Code Review Certificate — <effort-name>

> **Verdict: <PASS | FAIL>** — <no Blockers found | all Blockers resolved | N Blocker(s) unresolved>
> **Scope:** `<verbatim stated-scope line>`
> **Reviewed:** <YYYY-MM-DD> · **Mode:** <single-agent | multi-agent (N dimensions)><; no-plan mode, if applicable>

## Severity rollup

| Tier | Found |
|---|---|
| Blocker (9–10) | N |
| Major (7–8) | N |
| Minor (5–6) | N |
| Nit (1–4) | N |
| **Total** | N |

## Pre-pass summary

<one line per check: lint / typecheck / tests — pass, fail (→ finding CR-NNN), or not found in host project; pre-existing failures noted as not attributable to this diff>

## Triage outcomes

| Outcome | Count |
|---|---|
| Fixed / accepted → fix-phase | N |
| Deferred → Deferreds ledger | N |
| Rejected by user | N |

<one-line pointer: fix-phase appended to [plan.md](../01-Plan/plan.md) | report-only, no accepted findings>
