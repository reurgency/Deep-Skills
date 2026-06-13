# Deep-Learn — Self-Improving Directive Loop (Design Outline)

> **Status:** future dev — design note, not yet planned via `/deep-plan`.
> **Authored:** 2026-06-13 · seeded from the PR#65 (`feat/pipeline-consolidation`) code-review benchmark.
> **One-liner:** Every `/deep-code-review` run feeds a learning loop that turns recurring issue *classes* into toggleable **directive cards**, which the upstream deep-* skills load at runtime — so the same bug gets prevented earlier next time, without ever editing a SKILL.md.

---

## 1. Why this exists

The PR#65 benchmark showed that **every severity-bearing finding (CR-001 Blocker → CR-007) was the same class of bug**: a write path whose runtime reader resolves a *different* source ("execution is not config-aware"). None were in-function logic errors. Code-review caught them — late and expensively. The cheap kill is upstream, in planning/review/implementation/validation.

A one-time fix (add a data-flow contract to deep-plan) handles *this* class. But new classes will keep appearing. The goal is a **standing mechanism** that learns each recurring class once and pushes prevention upstream automatically — with a human gate and a kill-switch, so a bad lesson can't silently degrade the skills.

## 2. Core principle — **improvements are data, not prose**

A learning utility must **never edit a SKILL.md**. Prose edits cause: skill bloat, drift (three spokes phrasing one lesson three ways), merge conflicts, and — fatally — no clean on/off.

Instead, every learned improvement is a structured **directive card** in a registry. Each SKILL.md carries one stable stanza: *"load the active directive cards for your phase and apply them."* The skills stop changing; the registry changes. On/off becomes a status flip; provenance and effectiveness are built in.

## 3. Architecture — hub + taxonomy spine + spokes

```
   every /deep-code-review run
        findings.json
            │
            ▼
   ┌─────────────────┐      ┌──────────────────────┐
   │   DISTILLER      │────▶│   PATTERN LEDGER (hub) │   accumulating, NOT last-run:
   │ (post-review)    │      │  classes × freq × sev  │   root-cause-tagged issue classes
   └─────────────────┘      └──────────┬───────────┘
                                        │ promotes a class when it clears threshold
                                        ▼
                          ┌──────────────────────────┐
                          │  SHARED TAXONOMY (spine)   │  the lesson categories
                          │  write-no-reader, deletion │  — the contract between hub & spokes
                          │  -parity, claim-vs-evidence│
                          │  test-hygiene, reuse-dup…  │
                          └───┬─────────┬─────────┬────┘   many-to-many: one class → multiple spokes
                              ▼         ▼         ▼
                        deep-plan   deep-review  deep-implement   ← SPOKE UTILITIES
                          util        util          util          (draft cards for classes they own)
                              │         │         │
                              └─────────┴─────────┘
                                        ▼
                          ┌──────────────────────────┐
                          │   DIRECTIVES REGISTRY      │  the "central directive":
                          │  cards: candidate│active│  │  toggleable, provenance, telemetry
                          │         disabled           │
                          └──────────┬───────────────┘
                                     │ skills load ACTIVE cards at runtime
                                     ▼
                  deep-plan / deep-review / deep-implement apply them
                                     │
                                     ▼
                          next /deep-code-review run
                                     │
                          ┌──────────▼───────────────┐
                          │  EFFECTIVENESS MONITOR     │  post-review: did the class recur?
                          │  (data storage)            │  → updates each active card's outcome
                          └──────────────────────────┘   → drives auto-demote / flag false-positive
```

The loop closes: review → distill → propose → (human gate) → apply → review again → measure → prune.

## 4. Components

### 4.1 Pattern Ledger (the hub)
- **Accumulating**, not "the last run's issues." One Blocker should not rewrite deep-plan; a *recurring class* should.
- Stores root-cause-tagged **classes**, each with: frequency, max/avg severity, exemplar finding IDs (with the originating review), first-seen / last-seen, and which deep-* phase(s) could prevent it.
- Fed by every `findings.json`. Raw findings are *evidence*, not ledger entries.

### 4.2 Distiller (`/deep-learn`, post-review)
- Runs after `/deep-code-review` (skill or hook).
- Maps each new finding into the shared taxonomy; updates class frequencies; promotes a class to **actionable** only when it clears a threshold (**high severity OR recurrence across ≥2 distinct reviews**). This is the primary guard against overfitting to one PR's quirk.

### 4.3 Shared Taxonomy (the spine)
- The lesson categories — the contract between hub and spokes. Without it, each spoke re-derives its own categories and they drift.
- Seeded from PR#65 (see §7). A class maps **many-to-many** to spokes (e.g. `write-no-reader` → plan contract **and** implement invariant **and** validation probe).

### 4.4 Spoke utilities (one per upstream skill)
- For newly-actionable classes they own, each drafts a **candidate** directive card. They do **not** apply anything and do **not** touch SKILL.md.
- Each spoke knows its own leverage: deep-plan adds plan-artifact requirements; deep-review adds checks; deep-implement adds exit invariants + validation probes.

### 4.5 Directives Registry (the "central directive")
- Structured store of cards (file-per-card or a single JSON — decide in planning). Skills load **active** cards at runtime.
- This is where on/off, provenance, and effectiveness live.

### 4.6 Effectiveness Monitor (post-review, data storage)
- After each subsequent review, tags whether each class **recurred**. Updates the owning active card's outcome counters.
- Signals: a card that fires often but whose class keeps recurring is **not working** → flag for demotion. A card correlated with new review/plan friction (false positives) → flag.
- This is what makes the kill-switch *informed* instead of reactive whack-a-mole.

## 5. Directive card schema (draft)

```jsonc
{
  "id": "DLC-001",
  "category": "write-no-reader",          // from the shared taxonomy
  "owner_phase": "deep-plan",             // which spoke applies it (a class may spawn cards in several)
  "title": "Require a State / Data-Flow Contract",
  "trigger": "plan introduces/removes any persisted field, store, or runtime read",
  "instruction": "…the actual directive text the skill injects…",
  "status": "candidate",                  // candidate | shadow | active | disabled
  "provenance": {
    "findings": ["CR-001","CR-002","CR-003","CR-004","CR-005","CR-006"],
    "reviews":  ["pipeline-consolidation@6879399"],
    "added": "2026-06-13"
  },
  "promotion": {
    "human_approved_by": null,            // human gate — required before active
    "shadow_runs": 0,
    "recurrence_threshold_met": false
  },
  "outcome": {                            // maintained by the Effectiveness Monitor
    "class_recurrence_since_active": null,
    "friction_signals": 0,
    "verdict": "unproven"                 // unproven | working | ineffective | false-positive
  }
}
```

## 6. Card lifecycle (state machine + the gates you asked for)

```
 candidate ──(distiller: class clears threshold)──▶ shadow
   shadow ──(records "would this have changed the plan/blocked the phase?" — does NOT enforce)
   shadow ──(human gate: approve)──▶ active        ◀── HUMAN GATE (required)
   active ──(monitor: class recurrence drops)──▶ stays active, verdict=working
   active ──(monitor: class keeps recurring)──▶ flag ineffective ──▶ disabled   ◀── REMOVAL
   active ──(monitor: friction / false positives)──▶ flag false-positive ──▶ disabled
   disabled ──(kept with provenance; never silently deleted)
```

- **Human gate:** no card goes `active` without explicit approval. (Graduate to guarded-auto only once telemetry is trustworthy.)
- **Shadow mode:** candidates are evaluated, not enforced — they log what they *would* have done. Default OFF.
- **Removal mechanism (addition AND subtraction):** cards can be demoted/disabled, not only added. Prevents monotonic bloat.
- **False-positive detection:** the Monitor watches for cards that fire without reducing recurrence, or that correlate with new friction, and flags them for toggle-off.

## 7. Seed content — iteration zero (hand-authored from PR#65)

The first taxonomy + cards are authored by hand (this is the loop run manually once):

| Class | Owner spoke(s) | Seed card | From findings |
|---|---|---|---|
| `write-no-reader` (write path, no/other runtime reader; ≥2 sources of truth) | plan + implement + validation | **State / Data-Flow Contract** (see DATA-FLOW-CONTRACT spec) | CR-001,002,003,004,005,006,008,009,016 |
| `deletion-parity` (removing a surface orphans behavior / regresses a path) | plan + implement | Deletion/migration parity checklist | CR-001(regression),005,020,030 |
| `claim-vs-evidence` (AC over a stub; "exact baseline" false; stale plan text) | review | AC must map to verifiable evidence; no AC over a stub | CR-008,022,031,032 |
| `test-hygiene` (combined-suite failures; non-hermetic suites) | validation | Combined-suite base-vs-head attribution (two-worktree) | CR-007,022 |
| `reuse-dup` (re-implemented helpers, duplicated wire shapes) | implement (low ROI) | Search for existing shape before defining new | CR-010,012,013,019,023–027 |

The **Data-Flow Contract** card is the highest-leverage one — it would have surfaced ~100% of PR#65's severity at plan time. Its full spec lives alongside this note (see §10) and becomes `DLC-001`.

## 8. Failure modes & guards

| Risk | Guard |
|---|---|
| Overfit to one PR's quirk | Promote a class only after recurrence across ≥2 distinct reviews (or high severity). |
| Monotonic bloat | Removal/demotion is first-class; Monitor prunes ineffective cards. |
| Conflicting cards (opposite pushes) | Conflict/dedup check at promotion time. |
| Silent degradation of skills | Human gate + shadow mode + kill-switch + provenance. Cards are data, never prose. |
| Auto-application runaway | Stay human-gated until telemetry proven; only then guarded-auto. |
| Skill bloat / drift | SKILL.md carries one loader stanza; all variability lives in the registry. |

## 9. Open questions (resolve in `/deep-plan`)
- Registry storage: file-per-card vs single JSON vs SQLite? (Telemetry leans SQLite; provenance/diff leans files.)
- Does the Distiller belong as a `/deep-learn` skill, a post-review hook, or both?
- How is "class recurrence" matched across reviews — by taxonomy tag + file/region heuristic?
- Shadow-eval: how is "would this have changed the plan" measured cheaply?
- Cross-project: is the ledger global (learns across all repos) or per-repo? (See repo-location decision — this depends on extraction.)

## 10. Build phasing (suggested)
1. **Taxonomy + seed cards** (hand-authored from PR#65) + the loader stanza in each SKILL.md. Ship `DLC-001` (Data-Flow Contract) active immediately — it's already human-vetted.
2. **Directives Registry** + runtime loading. On/off proven manually.
3. **Distiller** (`/deep-learn`) — findings.json → Pattern Ledger → candidate cards.
4. **Effectiveness Monitor** — recurrence telemetry, demote/false-positive flags.
5. **Guarded auto-promotion** — only after (4) is trustworthy.

---

### Related artifacts
- `DATA-FLOW-CONTRACT.md` (the `DLC-001` spec — the worked first card). *(to be written alongside this note)*
- Benchmark provenance: `.deep-skills/pipeline-consolidation/04-Code-Review/report.md` (PR#65, the seed corpus).
- Skill definitions: `.claude/skills/deep-{plan,review,implement,code-review}/SKILL.md`.
