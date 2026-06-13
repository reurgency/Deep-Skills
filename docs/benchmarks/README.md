# Benchmarks — PR#65 code-review harness comparison

Archived 2026-06-13 from the (untracked, now-deletable) scratch dir
`Maudel/_temp-Code-Reviews/`. This is the empirical record behind the
`deep-code-review` tuning and the [self-learning roadmap](../roadmap/) —
the **seed corpus** the Deep-Learn directive loop is designed around.

All runs target **reurgency/maudel PR #65** (`feat/pipeline-consolidation` →
`develop`, head `6879399`).

| Path | What it is |
|---|---|
| `3-way-comparison.html` | The benchmark matrix — 9 review configs × 52 findings, with measured token/time costs. Open in a browser. |
| `pr65-v4-findings/04-Code-Review/` | The **eco-v4** review output: `report.md`, `findings.json` (32 findings — CR-001 Blocker … CR-032), `certificate.md`. The corpus referenced by `DATA-FLOW-CONTRACT.md` ("would have caught ~100% of PR#65 severity at plan time"). |
| `pr65-v4-findings/00-Manifest/manifest.md` | Stage manifest for the v4 run. |
| `code-review-design/index.html` + `Design-Notes.md` | The design explainer page (the 8-dial multi-agent architecture, at-a-glance diagram). |
| `comparisons.md` | Cross-run comparison notes (labels may be stale — see Run-Notes). |
| `Run-Notes.md` | Raw run notes. |

> Not archived (intentionally dropped): the intermediate run folders
> (`Eco-*`, `pipeline-consolidation-v2/v3`, `track-pipeline-redesign-*`) and the
> `3-way-comparison.html.bak*` snapshots — superseded scratch.
