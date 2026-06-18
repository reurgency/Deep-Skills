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
- **Tests that codify the bug** — a new/changed test whose assertion encodes the code's *current* output rather than the *intended* contract, so a green suite certifies the defect. Especially: a test asserting a payload shape sent to an external consumer (the assertion and the producing code were authored together, both wrong, mutually confirming). Read changed test files; treat their assertions as claims to check, not as evidence of correctness — full discipline in **Reading tests adversarially** below.

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
- **Divergent sibling implementations of one outbound contract** — two or more implementations of the *same* serialization/integration job that disagree on the wire shape. The canonical case: three streaming clients each build an image block, two send `image_url: { url }` and the third sends a bare `image_url: url` — the odd one out is a **likely bug, not a style nit**, because the siblings targeting the same consumer are each other's ground truth. Enumerate the parallel implementations explicitly and compare them field-by-field; a lone divergence in an external-facing payload is a correctness signal — escalate it to the correctness/seam-trace lens rather than filing it as a coherence nit.
- **Half-migrated approaches** — a refactor applied to some call sites and not others; old and new helper coexisting with no deprecation note; dead code left behind by a direction change mid-implementation.
- **Style discontinuities that signal a deeper seam** — abrupt changes in naming convention, file organization, or comment voice mid-feature often mark the boundary where two sessions built to different understandings (cross-check with the last-mile lens at that boundary).

## Reading tests adversarially

Changed test files in the diff are **suspects, not oracles** — and they are never an optional skip. A green suite proves the code matches the test's assertion; it says nothing about whether the assertion matches reality. When the test and the code under test were authored together (the normal case for AI-built features), they confirm *each other*, not the real contract — a **tautological test** that ships the bug with a passing checkmark. The benchmark miss this rule exists for: a vision client serialized an image as `image_url: "<data-url>"`, a new contract test asserted exactly that shape, the suite passed 24/24, and the real external consumer rejected it with a 500 — the test had codified the bug and the pre-pass read green.

For every added or changed test, ask:

- **Does this assertion encode the *intended* contract, or just lock in whatever the code currently emits?** An assertion that mirrors the implementation line-for-line verifies nothing.
- **Is the asserted value a payload sent to an external consumer** (a CLI/binary, third-party API, SDK, another service)? If so, the assertion is only as trustworthy as its source of truth. Check it against ground truth the same way you'd check the producing code: a sibling implementation in-repo that targets the same consumer, the consumer's documented/protocol schema, or — failing both — flag it as an **unverified external contract** (cross-ref the `seam-trace` external-consumer hunt in `references/dimensions.md`).
- **Was coverage deleted?** A test removed alongside code whose behavior still exists elsewhere is dropped coverage (also a `removed-behavior` signal).

Do not let a passing pre-pass stand in for this reading. The pre-pass reports *that* the suite is green; this lens asks whether green *means* correct.

## No-plan degradation (PR mode / arbitrary diff)

When no deep-* plan exists, lenses 2 and 3 lose their source of promised behavior and **degrade**:

- **Plan Conformance** → **PR-description / commit-message conformance**: the declared intent is whatever the PR description and commit messages claim. Verify the diff delivers what *they* promise, flag scope present in the description but absent in the code (and significant code with no declared intent).
- **Functional Completeness** → behaviors are enumerated from the PR description, commit messages, and the diff's own apparent intent (a new button implies a working click chain) instead of from a plan.
- Correctness and Coherence run unchanged.

**The report must say it degraded.** The report header's Mode line and the relevant lens sections state explicitly that no plan existed and conformance was checked against PR description / commit messages — a weaker guarantee the reader needs to know about.
