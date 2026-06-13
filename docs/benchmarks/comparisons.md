# Code Review Comparison — track-pipeline-redesign-48 vs track-pipeline-redesign-55

Both reviews cover **PR #65** (`feat/pipeline-consolidation` → `develop`) at the same head commit (`6879399`), reviewed on 2026-06-11.

| | Review 48 | Review 55 |
|---|---|---|
| Mode | Multi-agent (4 specialist dimensions + core four-lens pass) | Single-agent, four lenses |
| Scope | Pipeline code only — 52 `apps/**` files (deep-* skills excluded by user decision) | Full PR — 82 files |
| Findings | 6 (0 Blocker, 0 Major, 2 Minor, 4 Nit) | 11 (0 Blocker, 2 Major, 2 Minor, 7 Nit) |

---

## All items from Review 48

| ID | Severity | Summary |
|---|---|---|
| CR-001 | 6 (Minor) | Bug-execute AC overstates: pipeline is *resolved* but never *executed* — `/api/bugs/:id/execute` only logs and echoes the plan |
| CR-002 | 6 (Minor) | New track test suites not isolated — fail together with "Cannot use a closed database" (`closeDatabase()` in `afterAll` vs shared singletons) |
| CR-003 | 4 (Nit) | `tierOrModelOptions` option builder duplicated between track-stage-config-tab and templates step-config-editor |
| CR-004 | 3 (Nit) | `THINKING_OPTIONS` array — 4th hand-copy added (canonical source is `VALID_THINKING_LEVELS` in shared types) |
| CR-005 | 3 (Nit) | N+1 query on workspace tracks-list endpoint (`withStageConfig` per track) |
| CR-006 | 2 (Nit) | By-design `placeholderOnly` "not-yet-built" config fields (`storyScope`, `bulkReviewLimit`) shipped as disabled affordances |

## All items from Review 55

| ID | Severity | Summary |
|---|---|---|
| CR-001 | 7 (Major) | Save-as-template silently deactivates review-stories runtime gating and resets its mode — `isStageActivated`/`getStageMode` never read the template layer after `stage_state`/`stage_mode` are NULLed |
| CR-002 | 7 (Major) | Track-page config overrides (HITL, retry, harness, tier/model, thinking) and the pipeline's template binding are never consumed by actual workflow execution — write-and-display-only |
| CR-003 | 6 (Minor) | New track test suites fail (3 failures) when run together in one bun invocation — cross-file DB-handle interference; "Cannot use a closed database" + FK cleanup failure |
| CR-004 | 5 (Minor) | Phase 5 AC "executing a bug runs the bug track's pipeline" only informationally met — execute endpoint resolves/reports the plan but executes nothing; gap not in Deferreds ledger |
| CR-005 | 4 (Nit) | PUT tracks endpoint does not enforce track-type invariants; `blueprintId` accepted unvalidated (POST validates, PUT doesn't) |
| CR-006 | 4 (Nit) | Details-tab "execution history" is the global recent-executions list — not filtered by workspace, track, or stage |
| CR-007 | 3 (Nit) | Resolved-config load failure leaves Config tab's Common settings in a permanent spinner — no error, no retry |
| CR-008 | 3 (Nit) | `TrackConfigService.stageMode`/`isStageActivated` async-backed where deleted localStorage mirror was synchronous — early reads return system defaults |
| CR-009 | 3 (Nit) | §8 Details "runs dropdown" items degraded to "not yet available" notes without ✱ marking or a Deferreds-ledger entry |
| CR-010 | 3 (Nit) | PR includes ~29 files of unrelated deep-* skills work not declared in the PR description |
| CR-011 | 2 (Nit) | Provenance-badge UI duplicated — Build Mode hand-rolls badge markup/styles instead of reusing `ConfigFieldComponent`'s identical `.provenance-badge` |

---

## Items that are the SAME in both reports

### 1. Bug-execute endpoint resolves but never executes the pipeline
- **48/CR-001** (severity 6, Minor) ↔ **55/CR-004** (severity 5, Minor)
- Identical finding: the same chain `POST /api/bugs/:id/execute` → `getBugTrackExecutionPlan` (`track-stage-config.service.ts:112`) → plan only stamped into the activity log and echoed in the JSON response; no executor hop. Both flag the Phase 5 acceptance-criteria wording ("executing a bug runs the bug track's pipeline") as overstated.
- Difference in framing: 48 classifies it under last-mile/quality and notes it is decorative-by-design (the plan says not to build a new bug execution path); 55 classifies it under plan-conformance and emphasizes the missing Deferreds-ledger entry.

### 2. Track test suites fail when run together (closed-database interference)
- **48/CR-002** (severity 6, Minor) ↔ **55/CR-003** (severity 6, Minor)
- Identical finding: same error (`RangeError: Cannot use a closed database` at `pipeline.service.ts:204`), same root cause (suites call `closeDatabase()` in `afterAll` while process-global service singletons retain the closed handle), same impact (per-file runs pass — masking the issue — but the combined `bun test src/tests/` invocation fails 3), and substantially the same recommendation (stop closing the shared connection / re-acquire per file).
- 55 additionally reports a related `FOREIGN KEY constraint failed` cleanup-order failure in `track-management.test.ts:103-108` that 48 does not mention.

---

## Items that are SIMILAR (related theme, different specifics)

### 3. Not-yet-built placeholder affordances shipped in the UI
- **48/CR-006** (severity 2) ~ **55/CR-009** (severity 3)
- Same theme — "not-yet-built" features visible as inert placeholders — but different concrete items. 48 flags the `placeholderOnly` config fields `storyScope` and `bulkReviewLimit` in `track-stage-registry.ts` (and judges them intentional, plan-documented scaffolding). 55 flags the §8 Details "runs dropdown" items (Blueprint, Create Stories, Review Stories) rendered as "not yet available" notes *without* the plan's ✱ marking or a Deferreds-ledger entry — i.e., 55's complaint is about undocumented degradation, while 48's item is about documented scaffolding.

### 4. UI code duplication in the new track-stage-config component
- **48/CR-003 + CR-004** (severities 4, 3) ~ **55/CR-011** (severity 2)
- Same theme — the new `track-stage-config-tab.component.ts` copy-pastes UI code instead of reusing shared sources — but each report caught **different** duplications. 48 found the `tierOrModelOptions` builder and the `THINKING_OPTIONS` array duplications; 55 found the provenance-badge markup/styles duplication. None of the three specific duplications appears in both reports.

### 5. Bundled deep-* skills files in the PR
- **48 scope note** (header, not a numbered finding) ~ **55/CR-010** (severity 3)
- Both reports observed the same fact: PR #65 bundles ~27-29 unrelated `.claude/skills/deep-*` and `.claude/commands/*.md` files. 55 raises it as a formal finding (undeclared in the PR description; rebase out or declare). 48 records it only as a scope note because the user had already decided to exclude those files from that review.

---

## Items unique to one report

**Only in Review 48:**
- CR-005 — N+1 query on the workspace tracks-list endpoint (performance dimension).

**Only in Review 55:**
- CR-001 (Major 7) — Save-as-template breaks runtime stage gating/mode (gating helpers read raw columns, never the template layer).
- CR-002 (Major 7) — Track-page config overrides and template binding never consumed by actual workflow execution.
- CR-005 — PUT tracks endpoint missing track-type/blueprintId validation.
- CR-006 — Details-tab execution history unscoped (global list, no workspace/track/stage filter).
- CR-007 — Permanent spinner on resolved-config load failure.
- CR-008 — Async-backed `stageMode`/`isStageActivated` race (early reads return defaults).

---

## Summary

- **2 findings are effectively the same** in both reports: the bug-execute stub (48/CR-001 ↔ 55/CR-004) and the cross-suite test failure (48/CR-002 ↔ 55/CR-003). These are the only two findings the multi-agent review (48) and the single-agent review (55) independently converged on as numbered items.
- **3 areas are thematically similar but cite different specifics**: placeholder/not-yet-built affordances, UI duplication in the new config tab, and the bundled deep-* skills files (a finding in 55, a scope note in 48).
- The biggest divergence: **55's two Major findings (CR-001, CR-002)** — both about resolved configuration never being consumed at runtime — have no counterpart in 48, which declared its Correctness and Last-Mile lenses essentially clean. Conversely, 48's performance finding (N+1) and its two specific duplication findings are absent from 55.
