# Review lenses — the default four-lens pass

The default review is **one fresh agent, four lenses**: the "would a senior engineer approve this PR" pass. The agent receives the diff, the plan (when one exists), and codebase access — never the implementation transcript. Each lens below states what it asks and what to hunt for. Findings from every lens follow `references/findings-and-severity.md`: evidence required, 1–10 severity, concrete recommendation. If a lens finds nothing, the report says that lens is clean — do not invent findings to fill space.

## 1. Correctness

**Asks:** does this code do what it is written to do, under all the inputs and timings it will actually see?

Hunt for:

- **Logic errors** — inverted conditions, wrong operator, branches that can never run, conditions that are always true/false against the actual data shapes.
- **Null/undefined handling** — optional chains that silently produce `undefined` and feed it onward; missing guards on params, API responses, lookups that can miss; non-null assertions papering over a real possibility.
- **Race conditions** — concurrent writers to shared state; stale-closure reads; check-then-act gaps (existence check, then create); UI events firing again before the first handler finishes.
- **Broken error paths** — `catch` blocks that swallow, log-and-continue where the caller needs the failure, error states the UI never renders, rollback/cleanup missing on the failure branch.
- **Off-by-one** — boundary indices, slice/substring ends, `<` vs `<=` on loops and ranges, pagination math, fence-post counts.
- **Resource leaks** — subscriptions/listeners/intervals never torn down, file handles or child processes not closed on the error path, abort controllers created but never signaled.
- **Wrong async handling** — missing `await` (especially in `try` blocks, where the rejection escapes the catch); fire-and-forget promises whose result mattered; sequential awaits that race in the UI; `Promise.all` where one rejection should not kill the batch (or vice versa); async work after a response was already sent.

## 2. Functional Completeness (Last-Mile)

**Asks:** does every behavior the plan promises *actually happen, completely* — not just appear wired?

This is the skill's signature lens, aimed at the failure where *the interface looks correct and the happy path appears connected, but the behavior doesn't make it the last mile*. The method, in brief:

1. **Enumerate** every behavior the plan promises (each phase's Goal/Steps/Acceptance, plus the plan's Verification section).
2. **Trace** each behavior through its full chain — UI event → service → HTTP call → route → handler → persistence → response → UI state — hop by hop, with evidence at every hop.
3. **Verify the COMPLETE behavior**: state transitions, secondary effects (notifications, cache invalidation, status updates, list refreshes), and edge handling — not merely a connected happy path.

The full methodology — chain-walking procedure, the named AI failure modes to hunt, and the evidence rule — lives in `references/last-mile.md`. Read it before running this lens. Last-mile findings **must cite the traced chain**; findings without one are rejected at synthesis.

## 3. Plan Conformance

**Asks:** is everything the plan said actually *present* in the diff?

Hunt for:

- **Silently dropped scope** — a plan step, file, or behavior with no corresponding code and no explanation anywhere.
- **Undeclared deviations** — the code solves the problem a different way than the plan specifies, with no note in a Phase Summary or hand-off recording the decision.
- **Deferred work not in the ledger** — anything the implementation skipped "for later" must appear in the plan's **Deferreds** ledger; a TODO comment or a phase-summary aside is not the ledger.
- **Verification section unsatisfied** — walk the plan's Verification/Acceptance items one by one; each is either demonstrably met by the diff or flagged.
- **Files mismatch** — the plan's Files list vs the files actually touched: unexplained extras and unexplained absences both warrant a look (extras are often fine; absences usually mean dropped scope).

## 4. Coherence

**Asks:** does the change read as **one mind's work**?

Multi-session and multi-agent implementations drift; this lens catches the seams. Hunt for:

- **Same problem, different solutions** — the same need (e.g. debouncing, ID generation, error display) solved two different ways within the diff.
- **Inconsistent terminology across layers** — the UI calls it a "track", the API calls it a "lane", the DB column says "channel"; renames applied to some layers but not others.
- **Contradictory patterns** — e.g. signals in one component, BehaviorSubject in its sibling doing the same job; one new endpoint using the project's result-wrapper convention, the next returning bare JSON.
- **Half-migrated approaches** — a refactor applied to some call sites and not others; old and new helper coexisting with no deprecation note; dead code left behind by a direction change mid-implementation.
- **Style discontinuities that signal a deeper seam** — abrupt changes in naming convention, file organization, or comment voice mid-feature often mark the boundary where two sessions built to different understandings (cross-check with the last-mile lens at that boundary).

## No-plan degradation (PR mode / arbitrary diff)

When no deep-* plan exists, lenses 2 and 3 lose their source of promised behavior and **degrade**:

- **Plan Conformance** → **PR-description / commit-message conformance**: the declared intent is whatever the PR description and commit messages claim. Verify the diff delivers what *they* promise, flag scope present in the description but absent in the code (and significant code with no declared intent).
- **Functional Completeness** → behaviors are enumerated from the PR description, commit messages, and the diff's own apparent intent (a new button implies a working click chain) instead of from a plan.
- Correctness and Coherence run unchanged.

**The report must say it degraded.** The report header's Mode line and the relevant lens sections state explicitly that no plan existed and conformance was checked against PR description / commit messages — a weaker guarantee the reader needs to know about.
