# Learn record — cause-truthed history for the future Pattern Ledger

`--learn` ("record the root cause") adds one artifact to the round: `.deep-skills/<effort>/06-Bug-Fix/round-N/root-causes.json`, shaped per `templates/root-causes.json`. It is the machine-readable twin of `fix-summary.md`'s cause story — same causes, stable fields — emitted so root-cause history accumulates run over run.

## Forward dependency — Display-only today

**The machine reader for this file does not exist yet.** Deep-Learn's Distiller / Pattern Ledger — the component that would ingest these records, spot recurring cause classes, and promote them into directive cards — is design-only. Per the series' state/data-flow discipline (DLC-001 rule 4: a store without a runtime reader ships Display-only), this file is **Display-only today**: humans read the same confirmed causes in `fix-summary.md`; nothing at runtime consumes `root-causes.json`. Emission ships now anyway — deliberately — so that when the Distiller lands, it finds an accumulated, proof-truthed history to ingest rather than starting cold. Do not build anything that *reads* this file from within this skill; that reader arrives with Deep-Learn.

## When to emit

- **Only under `--learn`** (or its natural-language form). Default runs never write the file.
- **One record per cluster that closes with proof verdict `fixed`** — appended incrementally as each such cluster closes, the same rhythm as `fix-summary.md`, never batched to run-end. The file is created (with its `effort`/`round` header) when the round's first proven cluster closes; a round where no cluster reaches `fixed` produces no file.
- **Never from unproven clusters.** Skipped, blocked, `unproven`, and `regressed` clusters produce no record — their story lives in `fix-summary.md` and the blocker report. Cause data here is **proof-truthed**: if the adversarial proof agent didn't return `fixed`, the "confirmed cause" is still a hypothesis and has no place in learning history.

## Where each field's truth comes from

| Field | Source of truth |
|---|---|
| `confirmed_cause`, `fix` | The **diagnose+fix agent's confirmed diagnosis** — never the review's recommendation, never the fixer's optimism pre-proof. |
| `review_hypothesis_upheld` | Compare the confirmed cause against the cluster's `recommendation_hypothesis` (already compared, in prose, in the cluster's `fix-summary.md` entry): `true` if the review's cause-guess named the confirmed cause, `false` if diagnosis rejected or materially corrected it, `null` when the cluster carried no hypothesis at all. This is the field the Pattern Ledger wants most — across efforts it measures how often review-time cause-guesses survive independent diagnosis, exactly the overfitting signal. |
| `taxonomy_class` | Classify the confirmed cause against the **shared directives registry's `taxonomy.md`** (`directives/taxonomy.md`, vendored alongside `skills/` — the same registry the card loader reads). Its class table is the authoritative slug list; use an exact slug, **never invent one**. A cause that fits no listed class records `null` — note the gap in the cluster's `fix-summary.md` entry so a human can judge whether it's promotable — because the taxonomy grows only through its own promotion rules, not from here. |
| `findings_resolved` | Exactly the ids the proof verdict covered — the same ids whose statuses flipped `accepted → fixed` (plus any `BF-*` ids, which have no status to flip). |
| `proof {tier, verdict}` | The **adversarial proof agent's** returned verdict shape (`references/proof-of-fix.md`) — `verdict` is always `fixed` here by the emission rule, carried explicitly so the future reader never infers it. |
| `provenance {effort, round, review}` | The run itself: effort name, round number, and the effort-relative path of the source `findings.json` (`null` for standalone bug reports / failing tests). Records are self-contained so ingestion never needs the surrounding file. |

## Re-entry and rounds

The file follows the round rules everywhere else in this skill: it lives in `round-N/`, rounds are append-only, and a resumed round appends to the existing file (a cluster already recorded there is, by construction, already `fixed` and excluded from resume scope — no duplicate records). `_`-prefixed annotation keys from the template never appear in emitted files.
