# Training: `/deep-bugfix`

> Part of the [Deep Skills Training Program](README.md). Skill 5 of 6 — **remediate**.
> Source: [`plugins/deep-skills/skills/deep-bugfix/SKILL.md`](../../plugins/deep-skills/skills/deep-bugfix/SKILL.md)
> Design rationale: [`design-rationale/deep-bug-fix.md`](design-rationale/deep-bug-fix.md)

`/deep-bugfix` remediates defects the way `/deep-implement` builds features — **but inverted**.
It clusters findings by shared root cause, **re-diagnoses** independently of the review's
hypothesis, fixes **minimally at the confirmed cause**, **proves** the fix with a fresh
adversarial agent, and **contains** the blast radius before committing. It runs after
`/deep-code-review --triage`, or standalone on any bug report / stack trace / failing test.
**Fixes code only — it never makes triage decisions and never edits the plan.**

---

## Learning objectives

By the end you can:

1. Explain why bug-fixing is the **inverse** of `/deep-implement` — no trusted spec, modifies
   *working* code, and "done" means *provably gone* — and why that earns a dedicated skill.
2. Treat the finding's recommendation as a **hypothesis, not a spec**, and re-diagnose to a
   confirmed root cause before touching code.
3. **Cluster** defects by shared cause so one fix closes a whole family — and catch the
   abandoned sibling.
4. Run the **prove-before-commit** order — apply → proof verdict → containment → commit — and
   know why an unproven fix never ships.
5. Choose the flags (`--reproduce`, `--worktree`, `--learn`, mode) correctly, and know the
   boundary: bug-fix executes, triage decides.

## Prerequisites

[`/deep-code-review`](deep-code-review.md) — you consume its `accepted` findings (and inherit
its evidence/last-mile discipline). Comfort with git branching and your project's test runner.
The [shared mental model](README.md#the-shared-mental-model-read-this-before-any-skill-page),
especially **independence through fresh eyes** — deep-bugfix *tunes* that rule rather than
applying it uniformly.

---

## Mental model

**Bug-fixing is forward construction run backwards.** `/deep-implement` executes a *trusted
spec*: known steps, adds code, gates on new failures in changed files. Bug-fixing inverts all
four assumptions — the spec is **unknown** (you must diagnose the cause first), you modify
**working code** (the highest-risk edit class), findings often **share one root cause**, and
"done" means the bug is **provably gone**, not "the step ran." Pointing a fresh agent at
`findings.json` and saying "fix these" yields N symptom patches with no proof and no regression
guard. deep-bugfix is the dedicated executor for that inverted problem.

Two disciplines everything hangs from:

1. **The recommendation is a hypothesis, not a spec.** Real findings hedge their own cause
   ("register the route **or** correct the service URL"). deep-bugfix re-diagnoses
   independently and may reject the suggested fix — the inverse of code-review's independence
   rule: *don't anchor on the proposed remedy.*
2. **No proof of fix ⇒ not fixed.** Containment proves you *didn't break* working code; it does
   not prove you *fixed the bug*. Every fix carries a proof-of-fix verdict from a **fresh
   adversarial agent** — the fixer never marks its own homework.

Its signature failure mode — the analogue of code-review's last-mile lens — is the **claimed
fix**: a change that silences the symptom without addressing the cause, or fixes one member of
a cluster and silently abandons its siblings. The defenses are structural: **clustering**
(catches abandoned siblings) + **chain-trace proof** (catches symptom-patching) + the
**adversarial proof agent** (refutes "looks fixed").

---

## Curriculum

### Module 1 — Inputs & flags
Every flag is **natural-language-first** — the plain-language trigger is the primary path
(Copilot/Codex users have no CLI flags); the `--flag` is a convenience layered on top.
- **input** — a `findings.json` path or "the triaged findings" (default: the most recent
  `.deep-skills/*/04-Code-Review/findings.json` with `accepted` findings), a pasted bug report /
  stack trace, or a failing-test reference. Normalization: `references/intake.md`.
- **"just fix them all" / `--autonomous`** vs **"check in per cluster" / `--collaborative`** —
  execution mode. If omitted on a multi-cluster run, **ask**.
- **"fix it with a reproducing test" / `--reproduce`** — upgrade proof from static chain-trace
  to a dynamic **red→green** test written *before* the fix.
- **"fix in a worktree" / `--worktree`** — isolate fix work in a git worktree.
- **"record the root cause" / `--learn`** — emit `root-causes.json` for the future Deep-Learn
  Pattern Ledger.

### Module 2 — Directive cards (Deep-Learn)
Run `scripts/load-active-cards.sh deep-bugfix` at the start; treat each printed directive as a
hard requirement for the run. Cards are human-gated — toggle, never edit. On a host without a
reliable shell, apply cards by hand from the registry's `cards/active/`.

### Module 3 — Intake & scope
Normalize inputs into a uniform defect list (findings pass through losslessly; raw reports /
failing tests get synthesized `BF-001…` ids with evidence extracted from the trace). Resolve
the effort home; no effort ⇒ ask for a name (default: slugified branch), create it + the
manifest. **Series mode loads the `accepted` set — triage already decided; don't re-ask.** Only
`open` findings present ⇒ an interactive **scope pick** grouped by tier — *scoping is selection,
not triage;* unselected findings stay `open`. **Re-entry check first**, then write
`round-N/scope.json` (selection + provisional cluster plan) **before any cluster work** —
that's the resume record.

### Module 4 — Cluster by suspected shared cause
Group defects whose evidence points at one underlying cause (same subsystem + same failure
shape + overlapping evidence paths). **Clusters are hypotheses** — diagnosis *splits* a cluster
on divergent causes and *merges* two on a proven single cause. Review-time dedup merges
*duplicate reports of one defect*; cluster grouping is a coarser, **cause-level** grouping
across genuinely-distinct defects — a different altitude.

### Module 5 — Per cluster: diagnose + fix (one fresh agent)
**One fresh agent per cluster** — remediation needs continuity: the agent that finds the cause
authors the fix. Brief it with the finding **evidence** + repo access + the plan (context
only) — **never** the implementer's or reviewer's transcripts — and the recommendation flagged
**"hypothesis — do not trust."** It diagnoses to a confirmed root cause, then fixes **minimally
at the cause.** Attempt cap: **2**. Collaborative mode gates here: present diagnosis + proposed
fix for approval **before applying.**

### Module 6 — Adversarial proof
A **separate fresh agent** carries the burden of *refuting* "fixed." Default tier is the
**static chain-trace** — walk the corrected chain hop-by-hop with a cited `path:line` per hop;
a fix without a traced chain is rejected (`--reproduce` upgrades this to a dynamic red→green
test the proof agent re-runs both directions itself). It must show **every finding in the
cluster** resolved by the one fix, and returns `fixed | unproven | regressed`. **`regressed`
⇒ revert immediately. `unproven` ⇒ one more diagnose→fix attempt (cap 2 total), then revert +
blocker report.**

### Module 7 — Containment (blast radius)
Extract changed symbols from the diff → discover their **direct dependents** (1 hop; LSP/host
index when present, degrade to grep/import-walk) → run the dependents' tests + a full
typecheck. **Block only on *new* failures.** Exported/shared symbol ⇒ escalate to **2 hops**.
Commands are discovered from the host project — **never** `.env`/secrets.

### Module 8 — Gate / commit (prove-before-commit)
Order per cluster, **never reordered**: **apply fix → proof verdict → containment → commit.**
- **Collaborative:** present fix + proof + containment; commit only if the user wants.
- **Autonomous:** on `fixed` + clean containment, commit the cluster —
  `fix(<scope>): <cause> — resolves CR-00X, CR-00Y` + host-aware attribution trailer.

Nothing unproven ever ships.

### Module 9 — Statuses & round artifacts
On `fixed` (and only then): flip each of the cluster's findings `accepted → fixed` **in place**
in `04-Code-Review/findings.json` (deep-bugfix owns that transition and no other field), and
append the cluster's record to `round-N/fix-summary.md` — confirmed cause explicitly compared
against the review's hypothesis. Under `--learn`, also append the cluster's `root-causes.json`
record. Skipped/blocked clusters get an entry too; their statuses stay untouched.

### Module 10 — Finish & hand off to re-review
Update the manifest's `06 Bug Fix` row (link: `[06-Bug-Fix/](../06-Bug-Fix/)`). Report the
round: clusters fixed / skipped / blocked, statuses flipped, commits made. In autonomous mode,
**notify** completion. Close by pointing at the loop's next step — run
[`/deep-code-review`](deep-code-review.md) to re-review; a re-review re-diffs and appends new
findings under fresh IDs. The tightened loop is **review → triage → bug-fix → re-review.**

---

## In-session commands

| Command | Natural-language trigger | Behavior |
|---|---|---|
| `/skip-cluster` | "skip this cluster" | Close the current cluster unfixed: revert applied edits, leave its findings' statuses untouched, record a skipped entry, move on. |
| `/show-proof` | "show me the proof" | Print the current/most-recent cluster's proof verdict with its full hop-by-hop chain (or test evidence). |
| `/widen` | "widen the containment" | Escalate the current cluster's containment from 1 hop to 2 hops and re-run it. |

---

## Directive cards

Run `scripts/load-active-cards.sh deep-bugfix` at the start; treat each printed directive as a
hard requirement, applying the section addressed to your phase. "No active directive cards" ⇒
proceed normally. Never edit a card or the skill to turn one off — `directives/toggle.sh <ID> off`.

---

## Artifact wiring

Artifacts live in `.deep-skills/<effort>/06-Bug-Fix/round-N/` — rounds are **append-only**
(next round = max existing round + 1):

```
.deep-skills/<effort>/06-Bug-Fix/
  round-N/
    scope.json        ← selected defect ids + provisional cluster plan (resume record)
    fix-summary.md     ← one record per cluster, appended as each cluster closes
    root-causes.json  ← (--learn only) one cause-truthed record per proven cluster
```

`04-Code-Review/findings.json` statuses flip `accepted → fixed` **in place**, only on a `fixed`
verdict. `00-Manifest/manifest.md` gets a `06 Bug Fix` row (created if absent) whose link is the
literal `[06-Bug-Fix/](../06-Bug-Fix/)` — a static manifest can't point at "latest round."

---

## Hands-on exercises

1. **Inversion drill:** given a `findings.json` with CR-001…006, write why re-running
   `/deep-implement` on it would produce six symptom patches — name each inverted assumption.
2. **Hypothesis rejection:** take a finding that says "register the route **or** fix the URL,"
   diagnose which is the real cause, and justify rejecting the other half.
3. **Clustering:** given six distinct findings that share one write/read mismatch, group them
   and predict the one fix that closes all six — then name the sibling you'd check wasn't
   abandoned.
4. **Proof order:** simulate a cluster where containment is clean but the proof agent returns
   `unproven`. State what happens next (and what must *not* happen).
5. **Regression:** the proof agent returns `regressed`. Write the exact next action.

---

## Common mistakes

- **Anchoring on the recommendation** instead of re-diagnosing — it enters the brief flagged
  "hypothesis — do not trust."
- **Committing a symptom patch** — a fix without a traced chain (or red→green test) is rejected.
- **Fixing one cluster member** and silently abandoning its siblings — clustering exists to
  catch exactly this.
- **Reordering the gate** — proof and containment both come *before* commit; nothing unproven
  ships; `regressed` reverts immediately.
- **Making a triage decision** — fix/defer/reject belongs to `/deep-code-review --triage`.
  Scoping `open` findings is selection, not triage.
- **Editing the plan or a drive-by refactor** — minimal fix at the cause; a gap that needs
  re-planning goes back to `/deep-plan`.
- **Passing implementer/reviewer transcripts** to any agent — evidence only, fresh eyes.
- **Committing on `main`/`develop`**, or reading `.env` during host-command discovery.

## Mastery checklist

- [ ] Loaded active directive cards; wrote `round-N/scope.json` before any cluster work.
- [ ] Re-diagnosed each cluster to a confirmed cause; treated the recommendation as a hypothesis.
- [ ] Clustered by shared cause; every finding in a cluster resolved by the one fix.
- [ ] Ran apply → proof → containment → commit, in that order; nothing unproven shipped.
- [ ] Flipped statuses `accepted → fixed` only on a `fixed` verdict; appended fix-summary records.
- [ ] Made no triage decision, edited no plan; handed off to `/deep-code-review` for re-review.

## Quick reference

| | |
|---|---|
| Input | `accepted` findings (default), a bug report / stack trace, or a failing test |
| Output | `06-Bug-Fix/round-N/` → `scope.json` · `fix-summary.md` · (`--learn`) `root-causes.json`; findings flipped `fixed` |
| Order | apply → proof → containment → commit (never reordered) |
| Proof | static chain-trace (default) · red→green test (`--reproduce`); a fresh adversarial agent verdict `fixed \| unproven \| regressed` |
| Hard rules | Fix code only; never triage; never edit the plan; prove before commit; never commit on main/develop |
| Hand-off to | [`/deep-code-review`](deep-code-review.md) (re-review) |

➡ **Next:** [Training: `/deep-docs`](deep-docs.md)
