<!-- Code review certificate — pass/fail + severity rollup, written to
     `.deep-skills/<effort>/04-Code-Review/certificate.md` by the REVIEW RUN, with the
     Triage outcomes table left pending. The separate `--triage` step fills that table.
     Verdict rule: PASS only when no Blockers exist (a fresh review with any Blocker is
     FAIL until --triage routes it and /deep-implement fixes it). Scope line verbatim. -->

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

<!-- Left as "Triage pending — run /deep-code-review --triage" by the review run.
     The --triage step replaces this block with the filled table below. -->

| Outcome | Count |
|---|---|
| Fixed / accepted → fix-phase | N |
| Deferred → Deferreds ledger | N |
| Rejected by user | N |

<one-line pointer: fix-phase appended to [plan.md](../01-Plan/plan.md) | report-only, no accepted findings>
