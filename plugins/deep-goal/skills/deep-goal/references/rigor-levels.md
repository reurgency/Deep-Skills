# Rigor levels — semantics and customization

Rigor is deep-goal's single quality dial. One level selects, **as data**, everything that varies between a throwaway spike and a production change: which stages run, how interactive planning is, how thorough reviews are, what auto-triage accepts, and how many review→fix rounds the loop may take.

**The data lives in `templates/rigor-map.json` — the single canonical source.** This document explains what the levels *mean* and how to customize them; it never restates a stage list, a threshold, or a cap. When this prose and the JSON disagree, the JSON wins. (If a repo override exists, the *merged* map wins — see § Customizing below.)

## What a level encodes

Each level in `rigor-map.json` carries:

| Field | Meaning |
|---|---|
| `stages[]` | Ordered stage list. Each entry names a stage from the `known_stages` roster plus its per-stage options. |
| `stages[].mode` | On `plan`: `autonomous` (dispatched, zero questions, self-answered decisions recorded as Assumptions) or `interactive` (run inline — the user is present by definition). On `plan-review` / `code-review`: `single-agent` or `multi-agent` (dispatched with `--multi-agent`). |
| `stages[].rounds` | On `plan`, interactive mode: front-loaded question rounds (`deep-plan --rounds=<n>`); interactive planning also offers optional gap rounds beyond the front-loaded count. `0` under autonomous. |
| `stages[].columbo` | On `plan`: whether the plan ends with a self-run columbo pass (`--columbo`). An option of the plan stage, **not** a dispatch stage. |
| `stages[].triage` | On `code-review`: `{"auto_accept_min": N}` → the conductor invokes `deep-code-review --triage --auto-accept-min=N`. Findings at/above severity `N` are auto-accepted; everything below is **auto-deferred** into the plan's Deferreds ledger and reported loudly in the run report — never auto-rejected. Blockers (9–10) auto-accept regardless. An option of the code-review stage, **not** a dispatch stage. |
| `re_review_cap` | Max re-review rounds in the code-review → triage → bugfix loop. Absent when the level runs no code review. The loop's exit semantics per level live in `references/conductor.md` / `loop-and-budget.md`; the cap number lives only here in the map. |

Severities are **numeric 1–10, canonical** (per deep-code-review's `references/findings-and-severity.md`); Blocker (9–10) / Major (7–8) / Minor (5–6) / Nit (1–4) are presentation vocabulary only. `auto_accept_min` is always the number, never a tier name.

## The four shipped levels — intent

Exact stage lists, modes, thresholds, and caps: read them from `rigor-map.json`. The intent behind each:

- **`yolo`** — trust the model end-to-end. Autonomous plan, build, stop. No review of any kind, no docs. For spikes, throwaways, and "just show me something."
- **`poc`** — fast but sanity-checked. Autonomous planning (with a columbo pass to catch the plan's own loose threads), one light review, and auto-triage that only accepts what is outright broken — everything else is deferred, on the record. For prototypes you might keep.
- **`mvp`** — the recommended default. You stay in the loop for planning; independent eyes check both the plan and the code; Majors get fixed, Minors get deferred visibly; exactly one re-review proves the fixes; docs land. The best cost/confidence trade for most real features.
- **`prod`** — full rigor. Deep interactive planning, multi-agent reviews on both plan and code, triage accepts down to Minors, and the review→fix loop must actually *converge* (certificate passes with no Blockers AND strictly fewer findings each round) before docs — capped by the map's `re_review_cap`, after which the conductor halts as a convergence failure. For changes where being wrong is expensive.

## Cost bands (heuristic — uncalibrated)

`--dry-run` and the rigor-selection question show a rough per-stage cost band. These are **heuristic estimates, not measured baselines** (calibration from recorded runs is a tracked deferred; `pipeline.md` records per-stage spend for exactly that purpose). Bands are in total tokens consumed by the stage's session, keyed by stage + mode:

| Stage | Band |
|---|---|
| plan (autonomous) | ~40–90k |
| plan (interactive) | ~60–150k, user-paced |
| — columbo option | +10–25k |
| plan-review (single-agent) | ~60–120k |
| plan-review (multi-agent) | ~150–300k |
| implement | ~80–300k+ (scales with plan phase count) |
| code-review (single-agent) | ~80–150k |
| code-review (multi-agent) | ~200–400k |
| — auto-triage option | +5–15k |
| bugfix (per round) | ~60–200k |
| docs | ~60–150k |

A level's rough total = the sum of its stages' bands, with the loop stages (`code-review` + `bugfix`) potentially repeating up to `re_review_cap` additional times. State bands as ranges and label them estimates — never present them as measurements.

## Customizing rigor — the repo override

A repository can reshape or extend the rigor map without touching the plugin: create **`.deep-skills/rigor-map.json`** at the repo root (beside the effort directories). At launch the conductor reads the shipped map, then merges the override over it. The override is also an **add-on extension point** documented in the series' `artifact-structure.md`.

### Merge semantics (level granularity)

- `levels`: a level named in the override **replaces the shipped level entirely** (no per-field merging inside a level — an override level must be complete: full `stages[]` list plus `re_review_cap` if it runs a code review). A level name not in the shipped map **adds a new level**. Shipped levels the override doesn't name remain available unchanged.
- `known_stages`: entries in the override **extend** the merged roster (use this only when a genuinely new sibling skill exists to dispatch; a roster entry must name its `skill` and set `available`).
- Keys starting with `_` are documentation and ignored everywhere.
- There is no way to *remove* a shipped level; to discourage one, override it with a `_doc` note or simply don't use it.

### Example — adding a fifth level

`.deep-skills/rigor-map.json`:

```json
{
  "levels": {
    "poc-reviewed": {
      "_doc": "poc speed, but a human plans and a plan review runs.",
      "stages": [
        { "stage": "plan", "mode": "interactive", "rounds": 1, "columbo": true },
        { "stage": "plan-review", "mode": "single-agent" },
        { "stage": "implement" },
        { "stage": "code-review", "mode": "single-agent", "triage": { "auto_accept_min": 9 } },
        { "stage": "bugfix" }
      ],
      "re_review_cap": 0
    }
  }
}
```

`--rigor=poc-reviewed` (or "run deep-goal at poc-reviewed rigor") now resolves like any shipped level, appears in `--dry-run`, and is offered in the rigor-selection question alongside the shipped four.

### Validation rules — checked at launch, never mid-run

The conductor validates the override **at launch, before any dispatch**, and refuses with a message that **names the offending key/value and the file** (`.deep-skills/rigor-map.json`) plus the valid alternatives. Rules:

1. **JSON must parse.** A parse error names the file and the parser's error.
2. **Stage names** — every `stages[].stage` must exist in the merged `known_stages` roster. Unknown → refuse, naming the level, the bad stage name, and the roster. A roster entry with `available: false` (e.g. the reserved `security` slot for the future `/deep-security` skill) → refuse as "reserved, not yet shipped", naming the stage.
3. **Stage list shape** — `stages` must be a non-empty array; the **first stage must be `plan`** (the pipeline builds on a plan; the interactivity boundary is defined by it).
4. **Options belong to their owner** — `mode`/`rounds`/`columbo` only on `plan` (`mode` ∈ `autonomous`|`interactive`; `rounds` integer ≥ 0; `columbo` boolean); `mode` on `plan-review`/`code-review` ∈ `single-agent`|`multi-agent`; `triage` only on `code-review` with `auto_accept_min` an integer 1–10. An option on the wrong stage, an unknown option key, or an out-of-range value → refuse, naming the key.
5. **Caps** — `re_review_cap` integer ≥ 0; required when the level's list contains `code-review`, meaningless (refused) when it doesn't.
6. **Level names** — non-empty strings; a level must be an object with a valid `stages` array.

A valid override is then the resolved map for everything downstream: `--rigor` parsing, the rigor-selection question, `--dry-run`, and the conductor's stage walk all read the same merged result (resolved once at launch).

### Authoring tips

- Start by copying a shipped level from `templates/rigor-map.json` and editing — override levels replace whole, so partial levels are the most common authoring mistake.
- Keep `auto_accept_min` aligned with tier boundaries (9, 7, 5) unless you have a reason: mid-tier thresholds (e.g. 8) are legal but split a presentation tier across accept/defer.
- Pairing `"mode": "autonomous"` planning **with** a `plan-review` stage is legal and activates plan-review's conformance lens on the plan's Assumptions section — no shipped level does this; it's a supported custom-override pattern.
