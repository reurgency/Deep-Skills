# Deep-* Series — Design Rationale

> **Training material.** This is the *why* companion to the curriculum in
> [`../README.md`](../README.md). The curriculum teaches you to **drive** each skill; these pages
> recover the **design decisions** baked into each one — what the skill does, what else could have
> been done, and why this choice was made — with `file:line` anchors back to where each decision
> lives. Where a rationale could not be recovered from the sources, the pages say so rather than
> invent one.
>
> **Sources mined:** each skill's `SKILL.md` + `references/` + `templates/`; the roadmap design
> notes (`docs/roadmap/*.md`); the deep-docs `/deep-plan` artifact
> (`.deep-skills/deep-docs/01-Plan/plan.md`); the code-review benchmark notes
> (`docs/benchmarks/code-review-design/Design-Notes.md`); and git history — commit messages on this
> series state rejected alternatives explicitly.

## The pages

| Skill | Stage | Page | The one job it does |
|---|---|---|---|
| `/deep-plan` | built | [deep-plan.md](deep-plan.md) | Produce a steerable, resumable plan artifact — the durable spine. Plans only; writes no code. |
| `/deep-plan-review` | built | [deep-plan-review.md](deep-plan-review.md) | Independently critique the plan with fresh, codebase-aware agents that never saw the planning transcript. |
| `/deep-implement` | built | [deep-implement.md](deep-implement.md) | The only skill that writes source — phase by phase, bounded fix loops, checkpoints. |
| `/deep-code-review` | built | [deep-code-review.md](deep-code-review.md) | Multi-agent, evidence-gated review (split from triage) that catches the last mile. |
| `/deep-bug-fix` | **design outline** | [deep-bug-fix.md](deep-bug-fix.md) | Diagnosis-first remediation under regression risk — clustering, proof-of-fix, containment. *(5th skill; design note only.)* |
| `/deep-docs` | built | [deep-docs.md](deep-docs.md) | Context-window-aware orientation layer — three loadable tiers, every claim anchored. *(Built — and the reference implementation for the cross-host portability principle, §8.)* |

> **Stage matters.** The five built skills' rationale is anchored to live skill files + git history.
> `deep-bug-fix` is anchored to its design note (`docs/roadmap/DEEP-BUG-FIX-DESIGN.md`) — its open
> questions are unresolved *by design*, flagged on its page, not papered over.

---

## Cross-cutting decisions (the shape of the whole series)

Several decisions aren't owned by any single skill — they recur across all of them, and recur as
themes in the pages above. Learn these and the per-skill choices read as instances of a few ideas.

### 1. One skill, one job — separation of concerns
The pipeline is split so no skill does two things: plan **only** plans, plan-review **only**
critiques, implement is the **only** writer of source, code-review **only** reviews — and even
splits *reviewing* from *triaging*. The cleanest evidence is `deep-code-review` commit `de51e21`,
which pulled all routing/acceptance out of the review run into a separate `--triage` step so a
finished review writes nothing to the plan and leaves every finding `open`. `deep-bug-fix`'s design
keeps triage as the decision step and makes bug-fix a pure executor for the same reason
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:85-87`). See the per-skill pages for where each boundary is
enforced.

### 2. Fresh-agent resumability — write for someone with no memory
Every artifact is written so a fresh agent with **only the artifact + the repo** can continue cold.
This is why the plan is a durable spine accumulating phase summaries, a Deferreds ledger, findings,
and a triage fix-phase; why implement carries per-phase handoff + summary; and why the deep-docs
tiers are independently loadable. The acceptance test for almost everything the series produces is
"could a fresh agent pick this up?"

### 3. Independence through fresh eyes
Both review skills run in fresh agents that **never see the upstream transcript** — they get the
artifact + codebase + recorded preferences, but not the argument that produced it. `deep-bug-fix`
*tunes* this rather than inheriting it wholesale: continuity for diagnose→fix (one agent per
cluster), a fresh adversarial agent for proof so the fixer can't grade itself
(`docs/roadmap/DEEP-BUG-FIX-DESIGN.md:61-67`). Independence is the source of the catch.

### 4. The last mile + evidence
The signature failure the series hunts is the **last-mile problem**: code where the interface looks
wired and the happy path appears connected, but the behavior doesn't make it the last mile. Each
skill has its own dialect of it — implement's cross-layer/out-of-repo "green ≠ verified," code-
review's last-mile lens, bug-fix's "claimed fix," deep-docs's "stale map." Every finding/claim must
cite **evidence** (a `path:line`, a named symbol, or an observed behavior); no vague "consider
improving."

### 5. Improvements are data, not prose — the Deep-Learn directive loop
Recurring bug *classes* become toggleable **directive cards** in
`plugins/deep-skills/directives/`, loaded at runtime via `scripts/load-active-cards.sh <phase>`. A
SKILL.md is never edited to encode a lesson — that would cause bloat, drift across the spokes, merge
conflicts, and (fatally) no clean on/off (`docs/roadmap/DESIGN-OUTLINE.md:15-19`). The seed card
**DLC-001** (State / Data-Flow Contract) is a many-to-many class: deep-plan *requires* the contract,
deep-plan-review *checks* it, deep-implement *validates* it with a contract probe
(`docs/roadmap/DATA-FLOW-CONTRACT.md:32-36`). **deep-code-review carries no `scripts/` directory** —
it is the *producer* of the lessons (its `findings.json` feeds the distiller), not a consumer that
applies them; see its page for the nuance and what was/wasn't recovered.

### 6. Standalone, with two byte-identical shared files
Each skill self-contains; the only shared resource is the `directives/` registry. The two host-
agnostic files — `scripts/load-active-cards.sh` and `references/artifact-structure.md` — are copied
**byte-identical** into each skill rather than imported, with a consistency sweep verifying it
(`.deep-skills/deep-docs/01-Plan/plan.md:18`). "Reuse" in this series means *copy*, not *link*.

### 7. Shift-left — port a late catch into an early gate
When code-review proves it catches a class only late and expensively, the fix is to push prevention
upstream. Commit `3be1254` is the worked example: it ported two code-review hardening principles
into early gates — interaction-edge + re-entry became a deep-plan **REQUIRES** / deep-plan-review
**CONFIRMS** pair, and external-contract + adversarial-test became deep-implement construction
rules. The same commit message records what was **deliberately not ported** (the situational-check
mechanism — "only one proven check exists"; cross-sibling consistency — "already covered"), a clean
window into rejected alternatives.

### 8. Natural-language invocation is the primary path (the portability principle)
The series must be drivable by users on GitHub Copilot or Codex, who have neither slash-commands nor
a CLI-flag convention — so natural-language invocation is primary and `--flags` are a convenience on
top. `deep-docs` was built as the reference implementation; the retrofit of the four older skills
**shipped** — every flag and the six in-session commands gained a natural-language trigger, and the
non-portable UX surface (questions, notifications, model routing, attribution) was neutralized once
in `references/host-affordances.md` + `references/model-map.md`, with per-host install via
`plugins/deep-skills/HOSTS.md` (memory `deep-skills-cross-assistant-portability`). One concrete wart
this surfaced — the `.claude/commands/` references in `deep-plan/references/in-session-commands.md` —
was **clarified** (Claude-Code slash shortcut vs. keyword/NL invocation on other hosts), not deleted.

---

### How to read a page
Each page opens with the skill's one job + signature concern, a "decisions at a glance" list, then
numbered decisions in the form **What it does** (with a verified `file:line`) → **Alternatives
considered / rejected** → **Why this choice**. The anchors are clickable and were verified against
the actual lines; follow them when you want to see the decision in situ.
