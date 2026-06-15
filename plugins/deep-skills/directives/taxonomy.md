# Deep-Learn — Shared Taxonomy (the spine)

The lesson categories are the **contract between the hub (Pattern Ledger) and the spokes** (deep-plan / deep-plan-review / deep-implement). Without one shared vocabulary, each spoke re-derives its own categories and they drift. A class maps **many-to-many** to spokes — one class can spawn directives in several phases.

Seeded by hand from the PR#65 (`feat/pipeline-consolidation`) code-review benchmark — "iteration zero," the loop run manually once. See `../../docs/roadmap/DESIGN-OUTLINE.md` §7 (repo root, not shipped with the plugin) for the full provenance.

## Categories

| Class | Definition | Owner spoke(s) | Seed card | From findings |
|---|---|---|---|---|
| `write-no-reader` | A write path whose runtime reader resolves a *different* source — or no reader at all; ≥2 sources of truth for one concept. The PR#65 through-line: *"the write path and the runtime read path disagree."* | deep-plan + deep-implement + validation | **DLC-001** — State / Data-Flow Contract | CR-001,002,003,004,005,006,008,009,016 |
| `deletion-parity` | Removing a surface orphans behavior or regresses a path that depended on it. | deep-plan + deep-implement | *(unwritten)* Deletion / migration parity checklist | CR-001(regression),005,020,030 |
| `claim-vs-evidence` | An acceptance criterion written over a stub; a false "exact baseline"; plan text that no longer matches reality. | deep-plan-review | *(unwritten)* AC must map to verifiable evidence; no AC over a stub | CR-008,022,031,032 |
| `test-hygiene` | Combined-suite base-vs-head misattribution; non-hermetic suites that pass/fail for reasons unrelated to the change. | validation (deep-implement) | *(unwritten)* Combined-suite base-vs-head attribution (two-worktree) | CR-007,022 |
| `reuse-dup` | Re-implemented helpers, duplicated wire shapes — low ROI; code-review stays the backstop. | deep-implement (low ROI) | *(unwritten)* Search for an existing shape before defining a new one | CR-010,012,013,019,023–027 |

## Rules for this file
- A class is added here only when it is **promotable**: high severity, or recurrence across **≥2 distinct reviews** (the overfitting guard).
- Each class names the phase(s) that can prevent it. A card in `cards/` references its class by the exact `category` slug above.
- This file is the authoritative list of slugs. Cards must not invent categories not listed here.
