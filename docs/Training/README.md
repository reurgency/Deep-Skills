# Deep Skills — Training Program

A self-paced curriculum for the **Deep-\*** series: a steerable, fresh-agent-resumable
workflow that takes a feature from idea to verified code. By the end you will be able to
drive each skill on real work, know *why* each guardrail exists, and chain all six — from one
clean idea→merge loop to a standing map of what you built.

```
/deep-plan ─▶ /deep-plan-review ─▶ /deep-implement ─▶ /deep-code-review ─▶ /deep-bugfix ─▶ /deep-docs
  produce      critique             execute            verify               remediate       orient
```

> The tight remediation loop lives inside this chain: **review → triage → bug-fix → re-review**.
> `/deep-bugfix` is the fifth skill — the dedicated executor for fixing defects, distinct from
> `/deep-implement` which only builds new features.

> **Prefer a browsable version?** An HTML edition of this whole program lives in
> [`html/`](html/index.html) — open [`html/index.html`](html/index.html) in a browser. It folds
> the curriculum *and* the [design rationale](design-rationale/index.md) into one styled
> page per skill.

---

## Who this is for

Engineers who will *use* the deep-skills on their own features, and maintainers who will
*extend* them. No prior exposure to the plugin is assumed. You should be comfortable with
Claude Code, git, and reading a codebase.

## How to use this program

Each skill has its own training page with **learning objectives**, a **mental model**, a
**module-by-module curriculum**, **hands-on exercises**, **common mistakes**, and a
**mastery checklist**. Work them in order — the skills compose, and later pages assume the
vocabulary from earlier ones.

| # | Skill | Training page | You'll be able to… |
|---|---|---|---|
| 1 | `/deep-plan` | [deep-plan.md](deep-plan.md) | Run a steerable planning session that produces a resumable plan artifact. |
| 2 | `/deep-plan-review` | [deep-plan-review.md](deep-plan-review.md) | Independently critique a plan with fresh, codebase-aware agents. |
| 3 | `/deep-implement` | [deep-implement.md](deep-implement.md) | Orchestrate phase-by-phase execution with bounded fix loops and checkpoints. |
| 4 | `/deep-code-review` | [deep-code-review.md](deep-code-review.md) | Run multi-agent, evidence-gated review that catches the last mile. |
| 5 | `/deep-bugfix` | [deep-bugfix.md](deep-bugfix.md) | Remediate defects diagnosis-first: cluster → diagnose → fix at the cause → prove → contain. |
| 6 | `/deep-docs` | [deep-docs.md](deep-docs.md) | Generate context-window-aware, anchored, verified documentation of what's been built. |

> **Optional add-on (paid, separate plugin):** [`/deep-goal`](deep-goal.md) — an autonomous,
> rigor-gated **conductor** that runs the whole six-skill relay from one invocation. It is
> **not a seventh bundled skill**: it ships as its own plugin, requires deep-skills ≥ 0.2.0,
> and the six core skills never require it. Learn the six by hand first — its page assumes
> all of them. (HTML edition: [`html/deep-goal.html`](html/deep-goal.html).)

> New to the repo? Read the root [`README.md`](../../README.md) first for install and layout,
> then come back here.

---

## The shared mental model (read this before any skill page)

Four ideas recur across every skill. Internalize them once and the rest follows.

### 1. Separation of concerns — one skill, one job
The pipeline is deliberately split so no skill does two things. `/deep-plan` **only**
plans (no code edits). `/deep-plan-review` **only** critiques the plan. `/deep-implement`
is the **only** skill that writes *new* source from a spec. `/deep-code-review` **only** reviews
code (and even splits *reviewing* from *triaging*). `/deep-bugfix` **only** remediates defects —
it fixes code but never makes a triage decision and never edits the plan. When a skill is
tempted to cross its boundary, it stops and points you to the right sibling. Learning the
boundaries is half of learning the system.

### 2. Fresh-agent resumability — write for someone with no memory
Every artifact is written so that **a fresh agent with only the artifact + the repo can
continue cold** — no conversation history required. That is why plans are self-contained,
why phases carry their own context, and why reviews never receive the planning or
implementation transcript. "Could a fresh agent pick this up?" is the acceptance test for
almost everything you produce.

### 3. Independence through fresh eyes
Both review skills run in **fresh agents that never see the upstream transcript**. The
planner and the implementer are too close to their own work to see its blind spots; the
reviewer is briefed with the artifact + codebase + your recorded preferences, but *not* the
argument that produced it. Independence is the source of the catch. `/deep-bugfix` **tunes**
this rule rather than dropping it: diagnosis and fix share one agent (bug-fixing needs
continuity — the agent that finds the cause authors the fix), but a **separate, fresh
adversarial agent** must prove the fix. The fixer never marks its own homework.

### 4. The last mile + evidence
The signature failure the system hunts is the **last-mile problem**: code where the
interface looks wired and the happy path appears connected, but the behavior doesn't make
it the last mile — optimistic UI with no real call, swallowed errors, half-wired chains,
silently dropped scope. Every finding must cite **evidence** (a `path:line`, a named symbol,
or an observed behavior). No vague "consider improving."

---

## The artifact tree (where everything lands)

Deep-skills runs write to the **target repo**, not to this plugin repo, under a per-effort
directory. Knowing this layout makes the whole pipeline legible:

```
.deep-skills/<effort-name>/
  00-Manifest/        manifest.md   ← stage statuses (any skill creates it on first write)
  01-Plan/            plan.md       ← /deep-plan  (and the --triage fix-phase append)
  02-Plan-Review/     review.md     ← /deep-plan-review
  03-Implementation/  summary.md    ← /deep-implement
  04-Code-Review/     report.md · findings.json · certificate.md  ← /deep-code-review
  05-Security/        (reserved for a future /deep-security)
  06-Bug-Fix/         round-N/ scope.json · fix-summary.md · (root-causes.json)  ← /deep-bugfix
  07-Docs/            pointer + manifest line  ← /deep-docs (effort mode)
```

`/deep-docs` is the exception to the per-effort tree: its real output is a standing
**`docs/ai-map/`** at the *target repo* root (machine-owned, regenerated wholesale); in effort
mode it additionally drops a `07-Docs/` pointer so the manifest links to it.

The **plan document is the durable spine** — it accumulates Phase Summaries, a Deferreds
ledger, review findings, and (after triage) a fix-phase. Learn to read it and you can resume
any effort.

---

## Deep-Learn — the self-improving directive loop

> **The full deep-dive lives on its own page:** [deep-learn.md](deep-learn.md) (HTML edition:
> [`html/deep-learn.html`](html/deep-learn.html)). Self-learning is how the series **adapts to
> your codebase, conventions, and stack** — it earns a dedicated page.

The skills themselves never change to encode a lesson. Instead, recurring issue classes are
distilled into toggleable **directive cards** — structured data in
[`plugins/deep-skills/directives/`](../../plugins/deep-skills/directives/) that the upstream
skills load at runtime via `scripts/load-active-cards.sh <phase>`. A card is human-gated
(nothing reaches `active/` without approval), has clean on/off (`toggle.sh <ID> on|off`), and
carries provenance and effectiveness telemetry — so the same bug gets prevented *earlier*
next time without editing a skill by hand.

The seed card, [`DLC-001`](../../plugins/deep-skills/directives/cards/active/DLC-001.md), adds
a **State / Data-Flow Contract** to plans — one row per piece of state read or written, where
"reader resolves the same source the writer wrote to" is a binary you can't fudge. It would
have surfaced ~100% of PR#65's review severity at *plan* time. The
[design notes](../../docs/roadmap/) explain the full loop.

> **Why this matters for trainees:** when a skill prints a directive at the start of a run,
> treat it as a hard requirement for that run. Don't edit cards or skills to silence one —
> toggle it.

---

## Recommended learning path

1. **Read this page** — the shared mental model and artifact tree above.
2. **[deep-plan](deep-plan.md)** — produce a plan for a small real feature.
3. **[deep-plan-review](deep-plan-review.md)** — review that plan; fold findings back in.
4. **[deep-implement](deep-implement.md)** — execute it in collaborative mode.
5. **[deep-code-review](deep-code-review.md)** — review the result; run `--triage`.
6. **[deep-bugfix](deep-bugfix.md)** — remediate the accepted findings; prove each fix; re-review.
7. **[deep-docs](deep-docs.md)** — map what you built; confirm every anchor verifies.
8. **Capstone** (below) — run all six end-to-end on one feature, unassisted.

### Capstone exercise

Pick a small, real feature in a repo you know. Run the full six-skill loop:

- `/deep-plan` it (choose an effort name; produce a resumable plan with a Data-Flow Contract).
- `/deep-plan-review` it in `--multi-agent` mode; apply accepted fixes to the plan.
- `/deep-implement` it collaboratively, one phase at a time.
- `/deep-code-review` the branch, then `/deep-code-review --triage`.
- `/deep-bugfix` the accepted findings — cluster, diagnose, prove each fix, contain — then
  `/deep-code-review` again to confirm the re-review is clean.
- `/deep-docs` the result — generate the `docs/ai-map/` and confirm every anchor verifies.

**You've mastered the system when:** a teammate can open only your
`.deep-skills/<effort>/` directory — no chat history — and reconstruct what was built, why,
what was reviewed, and what remains deferred.

> **Add-on shortcut:** or run the capstone with one command via
> [`deep-goal`](deep-goal.md) — *"run deep-goal at mvp rigor"* conducts the same six-skill
> loop end-to-end (optional paid add-on; do it by hand at least once first — the run report
> only means something if you know what each stage should have produced).

---

## Glossary

| Term | Meaning |
|---|---|
| **Effort name** | Kebab-case slug for one piece of work; names its `.deep-skills/<effort>/` dir. |
| **Fresh agent** | A subagent briefed only with artifacts + codebase, never the upstream transcript. |
| **Phase** | A self-contained, cold-executable unit of a multi-phase plan. |
| **Deferreds ledger** | Plan section tracking deferred work: What / Why deferred / Integration. |
| **Last mile** | The gap between "looks wired" and "actually behaves correctly end-to-end." |
| **Lens** | One review perspective (e.g. Correctness, Plan Conformance, Coherence). |
| **Directive card** | A human-gated, toggleable learned improvement loaded as data at runtime. |
| **Manifest** | `00-Manifest/manifest.md`, the per-effort stage-status index. |
| **Triage** | The opt-in `--triage` step that decides fix/defer/reject and writes to the plan. |
| **Cluster** | A group of defects sharing one root cause, fixed by a single change (deep-bugfix). |
| **Proof-of-fix** | A fresh adversarial agent's verdict (`fixed`/`unproven`/`regressed`) — static chain-trace by default, red→green test under `--reproduce`. |
| **Containment** | Blast-radius check: run the changed symbols' dependents' tests; block only on *new* failures. |
| **Claimed fix** | deep-bugfix's signature failure: a change that silences the symptom without addressing the cause, or abandons a cluster sibling. |
| **AI map** | `docs/ai-map/`, deep-docs' standing, machine-owned, tiered documentation of what's built. |
| **Anchor** | A `path:line (symbol)` reference backing a doc claim; symbol-primary, verified before publish. |
| **Tier-0** | deep-docs' always-loaded `MAP.md` + `index.json`, held under a hard token ceiling. |
| **Rigor** | deep-goal's single quality dial (`yolo`/`poc`/`mvp`/`prod`): selects, as data, the stage list, planning interactivity, triage threshold, and re-review cap. |
| **Conductor** | deep-goal's role: a thin pipeline walker that sequences and verifies the six skills, never doing their jobs. |
| **pipeline.md** | `00-Manifest/pipeline.md` — the conductor's state file, updated at every stage boundary; re-invoking deep-goal resumes from it. |
| **Advance test** | The conductor's verification before advancing: expected artifact exists at its canonical path AND the skill flipped its own manifest line. |
| **Gate** | A user-injected human checkpoint (`--gate=<stage>`, "pause before implement") before a named stage in an otherwise autonomous run. |
| **Budget band** | An approximate token ceiling (`--budget`) checked between stages only; crossing it pauses the run at the boundary. |
| **Run report** | `00-Manifest/run-report.md` — the completion artifact surfacing everything an autonomous run decided alone (Assumptions verbatim, auto-deferrals, blockers, spend). |
| **Assumptions ledger** | Plan section written by `deep-plan --autonomous`: one row per self-answered planning question (question · chosen answer · why). |
