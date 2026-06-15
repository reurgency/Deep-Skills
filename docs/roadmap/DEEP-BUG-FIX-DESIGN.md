# DeepBugFix — Design Outline

> **Status:** future dev — design note, not yet planned via `/deep-plan`.
> **Authored:** 2026-06-15 · seeded from the discussion that asked "what makes a DeepBugFix more valuable than re-running DeepImplement on the findings?"
> **One-liner:** A 5th deep-* skill that does **diagnosis-first remediation of existing behavior under regression risk** — root-cause clustering, proof-of-fix, and blast-radius containment that `/deep-implement` structurally lacks.

---

## 1. Why this exists

The series already has a bug-fix path: `/deep-code-review --triage` routes accepted findings into a **fix-phase appended to the plan**, and `/deep-implement` executes that fix-phase cold. So "re-run DeepImplement on the findings" is not a strawman — it is the *current* design.

For a dedicated skill to earn its place it must do what DeepImplement is **structurally incapable of**, not merely wrap it more nicely. DeepImplement is **forward construction from a trusted spec**: it executes known steps, adds code, and gates on *new* failures in changed files. Bug-fixing inverts every one of those assumptions:

- The spec is **unknown** — you must diagnose *why* the bug exists before touching code.
- You **modify working code** — the highest-risk edit class — so the danger is regressing the three things that depended on the buggy behavior.
- The findings often **share one root cause** — fixing them one-by-one yields symptom patches.
- "Done" means **the bug is provably gone**, not "the step ran."

Pointing a fresh agent at `findings.json` and saying "fix these" gets you N plausible symptom patches with no proof and no regression guard. That is the gap DeepBugFix fills.

## 2. Core principle — diagnosis before remediation, proof before "fixed"

Two disciplines the rest of the design hangs from:

1. **The finding's recommendation is a hypothesis, not a spec.** Real findings hedge their own cause (corpus example CR-001: *"Register the route **or** correct the service URL"*). DeepBugFix re-diagnoses independently and may reject the suggested fix. This is the inverse of code-review's independence rule: don't anchor on the proposed remedy.
2. **No proof of fix ⇒ not fixed.** Regression containment proves you *didn't break* working code; it does **not** prove you *fixed* the bug. Every fix carries a proof-of-fix artifact (see §4).

## 3. The four disciplines (and what's default vs opt-in)

| # | Discipline | Why DeepImplement can't | Mode |
|---|---|---|---|
| 1 | **Root-cause clustering** — group distinct findings by *shared underlying cause*; one fix per cause. | DeepImplement executes a flat step list; it has no cause model. | **Default** |
| 2 | **Reproduce-before-fix** — a test that fails pre-fix, passes post-fix (red→green). | DeepImplement gates on *new* failures, never demands a reproduction. | **Opt-in** (`--reproduce`) |
| 3 | **Regression containment** — verify the callers/dependents of changed symbols didn't regress. | DeepImplement validates the changed file's imports, not its dependents. | **Default** |
| 4 | **Deep-Learn root-cause record** — emit a cause-truthed record to the Pattern Ledger. | Fix-time is where cause becomes ground truth; review can only guess. | **Opt-in** (`--learn`) |
| 5 | **Documentation trail** — fix summary, results, and a list of produced artifacts. | — (table stakes for a deep-* skill; always on) | **Default** |

### Why clustering is not redundant with code-review's dedup

Code-review already "merges by root cause when one fix resolves both reports." But the Deep-Learn seed corpus is the proof that's insufficient: PR#65's CR-001…006 survived as **six distinct findings** that shared **one** cause ("a write path whose runtime reader resolves a different source"). Review-time dedup merges *duplicate reports of the same defect*; bug-fix clustering is a **coarser, cause-level grouping across genuinely-distinct defects**. Different altitude — and the altitude where the real fix lives.

## 4. Proof-of-fix — two tiers, always a real guarantee

The skill never ships a "claimed fix." Proof scales with the mode chosen at invocation:

- **Default — static chain-trace proof.** Diagnose walks the root-cause chain hop-by-hop (reusing `/deep-code-review`'s last-mile methodology) and asserts the *corrected* behavior at the changed site, with cited evidence per hop. This is the bug-fix analogue of the last-mile lens: a fix without a traced, evidenced chain is rejected.
- **`--reproduce` — upgrade to red→green.** The static proof is replaced/augmented by a dynamic test that **fails before the fix and passes after**. If a bug genuinely can't be reproduced, that is itself a reported finding — never a silent skip.

Both tiers are gated by an **adversarial proof agent** (see §6): the fixer does not mark its own homework.

## 5. Signature concern — "the claimed fix" (symptom vs cause)

Every deep-* skill has one signature failure mode it hunts. DeepBugFix's is the **claimed fix**:

- a change that makes the *reproduction* stop without addressing the root cause (whack-a-mole), or
- a change that fixes one symptom of a cluster and silently leaves its siblings.

The defenses are structural: clustering (catches abandoned siblings) + proof-of-fix (catches symptom-patching) + adversarial proof agent (refutes "looks fixed").

## 6. Independence model — where the series' fresh-agent DNA does and doesn't apply

The series enforces independence by withholding prior transcripts. DeepBugFix tunes this per stage:

- **Diagnose + Fix = one agent per cluster.** Unlike review/implement, bug-fixing *needs continuity* — the agent that found the cause should author the fix. It receives the finding **evidence** + codebase + plan (for conformance context), but **not** the implementer's transcript nor the code-review agent's reasoning, and the recommendation is passed flagged *"hypothesis — do not trust."*
- **Proof = a fresh, adversarial agent.** Mirroring code-review's verification stage: a separate agent carries the burden of proof, tries to *refute* "fixed," runs the chain-trace or the repro, and returns a machine-readable verdict (`fixed` / `unproven` / `regressed`). This is what stops the fixer grading itself.
- Clusters are independent ⇒ diagnose/fix agents **parallelize** (one batch), proof agents stream off each completed fix.

## 7. Workflow (sketch)

1. **Intake & normalize.** Accept any of: a `04-Code-Review/findings.json` (statuses `accepted`, or `open` standalone), a pasted bug report / stack trace, or a failing-test reference. Normalize into an internal defect list with evidence. (Standalone with no prior effort ⇒ create the effort + manifest, effort name defaulting to the slugified branch — the shared mid-series-entry rule.)
2. **Cluster** by suspected shared root cause.
3. **Diagnose + fix** — fresh agent per cluster; root-cause independently, fix minimally at the cause, one fix per cluster.
4. **Prove** — adversarial proof agent: static chain-trace (default) or red→green (`--reproduce`).
5. **Contain** — identify changed symbols, find their callers/dependents, re-run their tests (reuse `test-runner` + DeepImplement's validation machinery; `--worktree` to isolate).
6. **Report + feed the loop** — write the fix summary + artifact list; flip the originating findings `accepted → fixed`; under `--learn`, emit the root-cause record. The tightened loop is **review → triage → bug-fix → re-review**.

## 8. Boundary & series placement

```
/deep-plan ─▶ /deep-plan-review ─▶ /deep-implement ─▶ /deep-code-review ─▶ /deep-bug-fix
                                                            └────────── re-review loop ─────────┘
```

- **Triage stays the decision step** (fix / defer / reject). DeepBugFix is the **specialized executor** for the `accepted` set — it makes no triage decisions and touches neither `deferred` nor `rejected` findings.
- It **replaces `/deep-implement` as the fix-phase executor**, keeping DeepImplement a pure feature-builder. (DeepImplement's fix-phase append path can be deprecated in favor of routing accepted findings to DeepBugFix.)
- It also runs **standalone** on a raw bug report / trace / failing test — mirroring how `/deep-code-review` runs on any PR/branch/diff, not just deep-* efforts.
- Carries the standard **directive-card loader stanza** like every deep-* skill. In the Deep-Learn topology it is primarily a *downstream consumer* of cards (apply relevant ones while fixing) and, via `--learn`, a *feeder* of cause-truthed signal — distinct from the upstream prevention spokes (plan / plan-review / implement).

## 9. Artifacts

Proposed stage folder (number to settle in `/deep-plan` — `05-Security` is reserved, `06–09` are free):

```
.deep-skills/<effort>/06-Bug-Fix/
  fix-summary.md     # per-cluster: cause, fix, proof verdict, regression result, artifact list
  root-causes.json   # cluster → confirmed cause → taxonomy class → fix → findings resolved (the --learn payload)
```

It also **updates the originating `04-Code-Review/findings.json`** statuses (`accepted → fixed`) and the effort manifest's status line. Multiple remediation rounds ⇒ round-scoped files (decide naming in planning).

## 10. Deep-Learn synergy (`--learn`)

The Distiller currently ingests `findings.json` — which carries the review's *guess* at root cause. `root-causes.json` carries the **confirmed** cause (proven by the fix), the taxonomy class, and which findings collapsed into one cluster. That is strictly better signal for the Pattern Ledger's recurrence and overfitting guards. Because Deep-Learn isn't built yet, this is a **forward dependency** — hence opt-in.

## 11. Open questions (resolve in `/deep-plan`)

- **Stage number / round model** — `06-Bug-Fix/` vs reusing an implementation round; how multiple review→fix→re-review rounds are named and accumulated.
- **Intake contract** — exact normalized defect shape across the three standalone inputs (findings.json / bug report / failing test).
- **Fix-phase deprecation** — do we remove DeepImplement's triage-routed fix-phase path, or keep it as a fallback when DeepBugFix isn't installed?
- **Regression scope discovery** — caller/dependent discovery by grep vs LSP vs reusing an existing project util; how wide the blast-radius re-run goes before it's "enough."
- **Proof agent reuse** — can it literally reuse `/deep-code-review`'s last-mile verifier brief, or does it need its own?

## 12. Build phasing (suggested)

1. **SKILL.md + the default spine** — intake → cluster → diagnose/fix → static chain-trace proof → regression containment → documentation trail. Standalone + findings.json intake.
2. **`--reproduce`** — red→green upgrade to the proof tier.
3. **`--worktree`** — isolation, reusing DeepImplement's machinery.
4. **`--learn`** — `root-causes.json` emission (lands with, or just before, Deep-Learn's Pattern Ledger).
5. **Triage wiring** — route `accepted` findings here by default; deprecate the DeepImplement fix-phase path.

---

### Related artifacts
- `DESIGN-OUTLINE.md` — the Deep-Learn self-improving directive loop (this skill is a downstream card-consumer / `--learn` feeder).
- `DATA-FLOW-CONTRACT.md` — `DLC-001`; the `write-no-reader` class that clustering and proof-of-fix most directly target.
- Series skills: `plugins/deep-skills/skills/deep-{plan,plan-review,implement,code-review}/SKILL.md`.
- Benchmark provenance: `docs/benchmarks/pr65-v4-findings/04-Code-Review/` (the seed corpus).
