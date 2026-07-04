<!-- Code review report — the human triage document.
     Written to `.deep-skills/<effort>/04-Code-Review/report.md`, alongside findings.json and certificate.md.
     Dates in absolute form. Scope line reproduced VERBATIM as stated before agents launched. -->

# Code Review Report — <effort-name>

> **Scope:** `<verbatim stated-scope line, e.g. Diffing feat/x against develop (working tree included) — 14 files, +812/−214>`
> **Reviewed:** <YYYY-MM-DD> · **Mode:** <single-agent, four lenses | multi-agent (N finder passes + adversarial verification)><; no plan — conformance degraded to PR-description/commit-message conformance, if applicable>
> **Plan:** <[plan.md](../01-Plan/plan.md) | none (no-plan mode)>
> **Pre-pass:** <lint: pass/fail/none found · typecheck: pass/fail · tests: pass/fail/skipped — one line each; pre-existing failures noted as such, not findings>
> **Situational checks:** <comma-separated ids that matched the diff and ran, e.g. `file-upload-pipeline` · omit the line if none matched>

## Severity rollup

| Tier | Count |
|---|---|
| Blocker (9–10) | N |
| Major (7–8) | N |
| Minor (5–6) | N |
| Nit (1–4) | N |

**Per-lens verdict** — say "clean" explicitly when a lens found nothing:
- Correctness: <clean | N findings>
- Functional Completeness (Last-Mile): <clean | N findings>
- Plan Conformance: <clean | N findings> <(degraded — no plan)>
- Coherence: <clean | N findings>
- Pre-pass: <clean | N findings>

<!-- Multi-agent mode only — one line summarizing the verification funnel; state the floor so "unverified" is interpretable.
     In multi-agent mode the mechanical parts of this report (rollup, funnel line, nit table, refuted appendix,
     and findings.json/certificate.md) are SCRIPT-ASSEMBLED from the structured verdicts; the model writes only
     the per-finding prose and summaries — see references/multi-agent.md § Stage D. -->
**Verification (multi-agent):** <N candidates → N at sev ≥5 verified: N confirmed · N plausible · N refuted (see appendix) · N below the sev ≥5 floor shipped unverified>

### Blockers

> A fresh review leaves Blockers at status `open` like everything else; they auto-accept (no decision) when `/deep-code-review --triage` is run. Flagged here, and in the certificate verdict, so the user knows a fix is owed.

- **[CR-NNN · <lens>] <title>** — severity N/10
  - Evidence: <path:line / symbol / observed behavior; last-mile findings include the hop-by-hop chain>
  - Impact: <why it matters>
  - Recommendation: <concrete fix>
  - Status: open (auto-accepts at `--triage`)

### Major

- **[CR-NNN · <lens>] <title>** — severity N/10
  - Evidence: <…>
  - Impact: <…>
  - Recommendation: <…>
  - Status: open  <!-- review run writes `open`; --triage changes it to accepted → /deep-bugfix (fix-phase fallback) | deferred → Deferreds ledger | rejected by user -->

### Minor

- ... (same shape)

### Nit

- ... (same shape in single-agent mode)

<!-- Multi-agent mode: the Nit tier renders as a compact table instead of full writeups —
     full prose for dozens of nits is what made baseline reports unreadable (and expensive).
     findings.json stays complete either way.

| ID | Sev | Claim (one line) | Evidence |
|---|---|---|---|
| CR-NNN | N | <one-line claim> | <path:line> |
-->

<!-- Finding lines in multi-agent mode also carry the verification verdict, e.g.:
- **[CR-NNN · <lens>] <title>** — severity N/10 · verified: <confirmed | plausible>
Minor+ findings carry a verdict; sev ≤4 findings are unverified (below the verification floor).
-->

### Refuted candidates (multi-agent only)

> Candidates dropped by adversarial verification — recorded so the decision is auditable. These are NOT findings and need no triage. Omit this section in single-agent mode or when nothing was refuted.

- **[<finder pass id>] <one-line claim>** — refuted: <rationale, e.g. "the new Goto correctly routes to the creator — traced at path:line">

<!--
Triage-resolution rules:
- Blockers (severity 9–10) skip triage: status "accepted (auto — Blocker)"; the user is informed, not asked.
- Every other finding is triaged with the user, three outcomes:
  - fix    → status "accepted"; the accepted set hands off to /deep-bugfix (the primary remediation
             executor). Fallback only, when /deep-bugfix isn't installed: a fix-phase is appended to
             the plan for /deep-implement; status "accepted → fix-phase".
  - defer  → added to the plan's Deferreds ledger (What / Why deferred / Integration); status "deferred → Deferreds ledger".
  - reject → stays listed with status "rejected by user" so the decision is on record.
- Statuses here mirror findings.json (numeric severity is canonical there; tiers are presentation vocabulary).
- After /deep-bugfix proves a fix (or, on the fallback route, /deep-implement executes the fix-phase),
  accepted findings are updated to "fixed".
-->
