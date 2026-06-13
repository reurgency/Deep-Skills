# Code Review Report — pipeline-consolidation

> **Scope:** `Reviewing PR #65 (feat/pipeline-consolidation → develop) at PR head 6879399 via local checkout (app code identical to PR head; post-PR commits touch only skills/docs) — 82 files, +9858/−4131, committed only.`
> **Reviewed:** 2026-06-12 · **Mode:** multi-agent (8 finder passes + 1 targeted gap-fill + adversarial verification; blind — prior review artifacts withheld from all agents)
> **Plan:** [Pipeline-Redesign-Plan.md](../../../.maudel/docs/_JB/_Config/Pipeline-Redesign-Plan.md) — reviewed against the **PR-head version** (phases 0–6 + Deferreds), not the working-tree copy carrying the prior run's fix-phase
> **Pre-pass:** lint: none found in host project · typecheck: UI **pass** (tsc + `ng build` clean) / API 302 errors vs 300 at base — all pre-existing TS6059 rootDir class, +2 from new shared files (→ CR-022) · tests: combined API suite **28 new failures at head vs base** (190 pre-existing noted, not findings; 6 fixed) — scripted two-worktree attribution → CR-007

## Severity rollup

| Tier | Count |
|---|---|
| Blocker (9–10) | 1 |
| Major (7–8) | 1 |
| Minor (5–6) | 5 |
| Nit (1–4) | 25 |

**Per-lens verdict:**
- Correctness: 11 findings (top: CR-005)
- Functional Completeness (Last-Mile): 6 findings (top: CR-001 — the Blocker)
- Plan Conformance: 4 findings (all nit-tier; phases 0–6 structurally conformant, per-phase verdicts all "conformant" from the dedicated pass)
- Coherence: 9 findings (all nit-tier type/pattern duplication)
- Pre-pass: 2 findings

**Verification (multi-agent):** ~47 raw candidates from 9 passes → merged/decomposed to 34 → **15 verified at the sev ≥5 floor: 10 confirmed · 3 plausible · 2 refuted** (see appendix) · 19 below-floor findings shipped `unverified`. Several verified candidates were demoted below the floor by their verifiers (severity recalibrated by trigger-path counting) — they remain in the nit tier with their verdicts.

---

### Blockers

> Blockers are auto-routed to the fix-phase — no triage needed; listed here so you're informed. **Phase 7 of the plan has been updated to carry this finding.**

- **[CR-001 · last-mile] Every edit on the /pipeline Prompts and Agents & Skills tabs is silently ignored at runtime — tabs write to the track's forked pipeline; every execution path reads hardcoded pipeline `'default'`** — severity 9/10 · verified: **confirmed**
  - Evidence (chain): both tabs receive `[pipelineId]="track.pipelineId"` (`track-pipeline-page.component.ts:399,409`), and every track's pipelineId is a fresh fork (`track.service.ts:280,421` → `pipeline.service.ts:109`) — never `'default'`. Saves land on the fork rows: prompts/gates via `PUT /api/pipeline-stages/:id?pipelineId=<fork>` (`track-stage-prompts-tab.component.ts:416` → `pipeline-stage.service.ts:152`), pipeline prompt via `PUT /api/pipelines/<fork>`, agents/skills via the same fork row (`track-stage-agents-tab.component.ts:315`). Runtime never looks there: `agentic-step-handler.ts:1255` and `review-stage-engine.service.ts:705` call `assemble()` with no pipelineId → `stage-prompt-assembler.service.ts:132` `input.pipelineId ?? 'default'`; `orchestrated-step-handler.ts:117` reads `stepInputs.pipelineId ?? 'default'` and **no producer of `stepInputs.pipelineId` exists repo-wide**; plus hardcoded `getStage(stageId,'default')` at `agentic-step-handler.ts:407,1564`. Affects all 11 edit surfaces on the two tabs (action prompt, collab/autonomous instructions, input/output gates, pipeline prompt, AI-chooses toggle, agents, skills, per-agent/per-skill special instructions) × ~13 stages × every track, on every agentic, orchestrated (gates + agent selection), and review-story run.
  - Impact: the page's central promise — edit prompts and agent/skill assignments where the pipeline is configured — is 100% inert, **silently** (saves succeed, survive reload, and the fork initially mirrors the defaults, so demos look right). The verifier additionally established this is a **regression**: the deleted drawer surface wrote to `'default'`, which runtime reads, so editing previously worked.
  - Recommendation: thread the executing workspace's track pipelineId into runtime stage reads — resolve the track (as `track-stage-config.service.ts:42-49` already does for stage gating) and pass pipelineId into `assemble()` at both call sites; set `stepInputs.pipelineId` at workflow launch (or resolve track-aware inside `orchestrated-step-handler.ts:117`); replace the two hardcoded `'default'` reads. Add a regression test asserting a fork-row edit reaches the assembled prompt of an execution.
  - Status: **accepted (auto — Blocker) → fix-phase** (plan Phase 7, refreshed by this run)

### Major

- **[CR-002 · last-mile] Config-tab overrides and the save-as-template repoint never reach workflow execution — template selection still resolves from workspace settings; `config_overrides` have zero runtime readers** — severity 7/10 · verified: **confirmed** (finder proposed 8; verifier trimmed to 7 — one of three claimed trigger paths collapses into another, and unsaved-override semantics are partially defensible as a Save-lifecycle design)
  - Evidence: overrides written by `PUT /api/tracks/:id/config-override` (`routes/tracks.ts:90`) into `pipelines.config_overrides`/`pipeline_stages.config_overrides` are read only by the track resolver (page display + save bake) and the informational bug plan. After Save, `pipelines.source_template_id` is repointed (`track-config-resolution.service.ts:374`) but execution still selects its template from workspace settings: `story-workflow-page.component.ts:2659` → `workspaces.ts:690` → `story-workflow.ts:269/877` builds stepConfigs from that template. `resolveTemplateForPipeline`'s only callers are inside the resolver itself. The new `execution-config-drawer.component.ts:72` even tells users "Set persistent model config on the Pipeline page."
  - Impact: overriding harness/tier/thinking/hitl/retry on any stage shows "overridden" and survives reload but never affects a run; saving a built-in-based track creates and repoints to a clone that no execution ever uses — runs keep the old workspace-default template indefinitely. Not declared in the Deferreds appendix; contradicts Phase 6's "single config source of truth" AC.
  - Recommendation: resolve the executing track's template server-side via the pipeline binding (`resolveTemplateForPipeline`) and overlay the two `config_overrides` layers at workflow creation; at minimum sync workspace `defaultTemplateId` on save-as-template and soften the drawer hint until overrides flow. (Same architectural fix family as CR-001 — both are "execution is not track-aware" — but distinct code surfaces and steps.)
  - Status: open

### Minor

- **[CR-003 · last-mile] Runtime review-stories gating reads raw `stage_state`/`stage_mode` columns, never the resolver — Save silently de-activates the gate; new/backfilled tracks never activate it; track-level mode overrides are invisible** — severity 6/10 · verified: **confirmed** (finder 7 → verifier 6: recoverable by re-toggling; sub-claim (c) is API-only)
  - Evidence: `saveAsTemplate` NULLs both columns in its transaction (`track-config-resolution.service.ts:388-390`) with no re-sync anywhere; `syncStageEnabledFromTemplate` writes only `enabled` (`track.service.ts:552`); the system default template **'mvp' does enable review-stories**, so the UI shows included-from-template while `isStageActivated` (`track-stage-config.service.ts:62`) returns false for the executor (`executor.ts:1891`) and story-generation engine (`:673,728`).
  - Impact: enabling review-stories then clicking Save turns the gate off while the page says it's on; autonomous mode reverts to collaborative the same way.
  - Recommendation: route `isStageActivated`/`getStageMode` through `resolveTrackConfig` (as `getBugTrackExecutionPlan` already does), or make `saveAsTemplate` re-sync the two columns to the baked values.
  - Status: open

- **[CR-004 · last-mile] Blueprint-owned Build Mode write has no runtime reader; bulk story generation is hard-locked to 'mvp'** — severity 6/10 · verified: **confirmed**
  - Evidence: write chain works (`track-stage-config-tab.component.ts:794-801` → `blueprint.ts:1377-1390` → `blueprint-registry.service.ts:194`); runtime resolves explicit → `project.buildMode` → default (`story-workflow.ts:97-115`), and `routes/story-generation.ts:45-56` never sets `buildMode` so `story-generation-engine.service.ts:483` always defaults `'mvp'`. Registry `meta.buildMode`: one writer, zero runtime readers. Contradicts plan §6 ("the blueprint is THE source of truth for build mode"); absent from Deferreds.
  - Recommendation: consult the executing track's blueprint `meta.buildMode` before project config in `resolveBuildMode`, and plumb buildMode into the /generate route — or declare the field display-only.
  - Status: open

- **[CR-005 · correctness] Backfill carries the legacy full-snapshot stage states as stage-layer overrides on all 13 stages — Save permanently lit, 'Overridden' provenance everywhere, and unit-test/code-review stages force-enabled against the MVP template** — severity 5/10 · verified: **confirmed** (finder 6 → verifier 5: blast radius is workspaces that ever **interacted** with the old page — the deleted UI persisted only on user toggles/runs, not page-open)
  - Evidence: the deleted `persist()` always PUT the full merged stageStates (chunk 062); `carryLegacyStageConfig` (`track.service.ts:330-352`) writes `stage_state` unfiltered for every mapped key ('execution' expands to 10 stages) + `stage_mode` 'collaborative'; resolver: `stage_state !== null` ⇒ source 'stage' ⇒ `divergesFromTemplate=true` ⇒ Save enabled (`track-pipeline-page.component.ts:175,1254`). Real value flip: carried `execution:'included'` force-enables unit-testing and code-review stages the 'mvp' template disables.
  - Recommendation: during carry, write `stage_state`/`stage_mode` only where the legacy value differs from the template-resolved value.
  - Status: open

- **[CR-006 · last-mile] UI TrackConfigService stage state/mode cache is never invalidated by track-page config writes — stories pages read stale review-stories mode/activation for the rest of the session** — severity 5/10 · verified: **confirmed**
  - Evidence: saves go through `TrackConfigResolutionService` (own signal only); `TrackConfigService.loadForWorkspace` guard (`track-config.service.ts:93-95`) means /pipeline → /stories in the same workspace never reloads; force-reload exists only on track CRUD/reorder. Manual review starts POST the client-read mode verbatim (`review-stage.ts:122`).
  - Recommendation: `trackConfig.loadForWorkspace(wsId, true)` after `saveOverride`/`saveAsTemplate` succeed.
  - Status: open

- **[CR-007 · pre-pass] 28 new combined-run test failures at head vs base — pre-existing order-dependent suites flipped by the PR's three new test files** — severity 5/10 (deterministic observation)
  - Evidence: scripted two-worktree attribution (combined `bun test src/tests/` at base d79aa633 and head 6879399, normalized failure lists diffed): head 218 vs base 196 — 28 new (us-061 story-dependency, us-124 base-prompt, US-071/phase2-templates partial), 190 pre-existing, 6 fixed. The newly-failing suites fail **identically in isolation at both base and head** (us-061: 20/20; us-124: 19 vs 18), proving the suites are inherently order-dependent (shared DB init) and the PR's new test files changed combined-run interaction — product code is not shown broken.
  - Recommendation: make the three new track suites hermetic (own DB init/teardown) or fix the brittle suites' missing initialization; confirm combined run returns to ≤196.
  - Status: open

### Nit

> Compact table — full records in findings.json. `verified` column: verifier verdict where one ran (several were demoted below the floor by verification); blank = below-floor, shipped unverified.

| ID | Sev | Verified | Claim (one line) | Evidence |
|---|---|---|---|---|
| CR-008 | 4 | confirmed | Bug execute computes the track plan but nothing executes it; Phase 5 AC says "runs" — undisclosed deferral (stub is pre-existing) | `routes/bugs.ts:120` |
| CR-009 | 4 | | Manual "Generate Stories from blueprint" affordance orphaned; `/stories?generate=true` has zero producers left | `stories-list.component.ts:1038` |
| CR-010 | 4 | confirmed | TrackDto hand-rolls the shared TrackWithStageConfig wire shape (latent drift; convention exists next door) | `track-config.service.ts:14` |
| CR-011 | 4 | | Unguarded `JSON.parse(config_overrides)` in rowToStage — one bad row 500s the pipeline's stage reads | `pipeline-stage.service.ts:107` |
| CR-012 | 4 | | CreateTrackInput/UpdateTrackInput duplicated API+UI with divergent shapes | `track.service.ts:127` |
| CR-013 | 4 | | Bug-execute response bare JSON vs tracks' `{data}` envelope — same track data, two wire shapes | `routes/bugs.ts:135` |
| CR-014 | 4 | | deleteTrack promotion tiebreaker (created_at) vs UI displayOrder-only sort can disagree on ties | `track.service.ts:615` |
| CR-015 | 4 | | resolveStageIds silently returns identity for unknown ids — typos read as "not activated" | `track.service.ts:118` |
| CR-016 | 3 | plausible | Un-backfilled workspaces lose review-stories gating on non-UI paths (mechanisms confirmed; reach demoted — executor hook is dead code on the live route; stories launcher self-backfills) | `track-stage-config.service.ts:43` |
| CR-017 | 3 | confirmed | Sync `stageMode()` default until /tracks loads — regression vs localStorage mirror, but warm-load closes the race; fails toward the conservative mode | `track-config.service.ts:167` |
| CR-018 | 3 | confirmed | moveTrack two-PUT swap can persist duplicate displayOrder — cosmetic, self-healing | `track-pipeline-page.component.ts:1517` |
| CR-019 | 3 | plausible | New gating service imports PipelineStageMode from the legacy module it replaces (shared StageExecutionMode identical) | `track-stage-config.service.ts:23` |
| CR-020 | 3 | | Stage Knowledge Base panel dropped with the drawer; no new home | deleted `stage-config-drawer.component.ts:259-277` |
| CR-021 | 3 | | 22 undeclared .claude tooling files ride in the PR (+1377 lines) | chunks 001–027 |
| CR-022 | 3 | | API tsc 302 vs 300 at base (+2 instances of the pre-existing TS6059 rootDir class); PR claims "exact baseline" | scripted tsc diff |
| CR-023 | 3 | | Stage-id translation maps fragmented across three modules/layers | `track.service.ts:57` |
| CR-024 | 3 | | Local StageMode alias duplicates shared StageExecutionMode | `track-config.service.ts:7` |
| CR-025 | 3 | | generateCustomTemplateId re-implements generateCloneId byte-for-byte | `track-config-resolution.service.ts:175` |
| CR-026 | 3 | | resolveTrackConfig double DB fetch on stageId-filtered calls | `track-config-resolution.service.ts:236` |
| CR-027 | 3 | | Blueprint list fetched/cached independently in 3 places | `track-pipeline-page.component.ts:1393` |
| CR-028 | 2 | plausible | Destroy-time flush save reaches the server (loss claim refuted); only the error is unsurfaceable | `track-stage-config-tab.component.ts:714` |
| CR-029 | 2 | | Provenance mislabel: enabled-column fallback tagged source 'system'; such stages can never register diverged | `track-config-resolution.service.ts` resolveStage |
| CR-030 | 2 | | Orphaned `maudel_pipeline_*` localStorage blobs (incl. runStatus 'running'), no cleanup | deleted `pipeline-config.service.ts:27,149` |
| CR-031 | 2 | | Stale comments: migration 046 "falls back to legacy layer" (false post-Phase-6) + gating service header | `migrations.ts` (046) |
| CR-032 | 2 | | Plan §3a/§9 still say REUSE for the drawer that was extracted-and-deleted (declared in summaries) | plan §3a/§9 |
| — | ≤2 | | 15 further one-liners (console.logs, dead featureFlags property, unvalidated displayOrder body, first-bug-track-only execution, default-track-only gating semantics, spinner/var/quote nits) | findings.json `nit_overflow_summary` |

### Refuted candidates

> Dropped by adversarial verification — recorded so the decision is auditable. Not findings; no triage needed.

- **[diff-scan] `savedTemplate` non-null assertion after transaction could observe undefined (proposed sev 6)** — refuted: bun:sqlite `transaction()` rethrows synchronously on callback throw, so the `!` accesses at `track-config-resolution.service.ts:394-395` are unreachable on every failure path; both assigning calls return non-nullable. Zero reachable trigger paths; defensive-style preference at most.
- **[diff-scan] `queryParams` subscription in constructor never unsubscribed — leak (proposed sev 5)** — refuted: Angular's router completes ActivatedRoute observables on route destruction, and the component is provably router-only (selector never stamped in any template; single lazy route). No leak path exists; no codebase convention violated.
- *(Sub-claim refutations recorded inside surviving findings: the destroy-time HTTP-cancellation claim in CR-028; the "every workspace that opened the old page" universality premise in CR-005; two of CR-016's three trigger paths.)*

---

## Triage

CR-001 (Blocker) is auto-accepted into the plan's fix-phase (Phase 7, refreshed). **CR-002 through CR-032 await your triage** — fix (→ fix-phase) / defer (→ plan Deferreds ledger) / reject (recorded) — finding by finding. Suggested batch: triage CR-002–CR-007 individually; the nit tier can be bulk-deferred or bulk-rejected if you prefer.
