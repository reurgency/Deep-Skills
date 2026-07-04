# Proof-of-fix — the fix is not fixed until an adversary fails to refute it

The skill never ships a "claimed fix." Containment (`references/containment.md`) proves the fix *didn't break* working code; **this protocol proves the bug is gone** — a separate question, answered by a separate agent.

## The proof agent — fresh, adversarial, severity-gated

After the diagnose+fix agent applies its fix, launch a **fresh agent** whose burden of proof is inverted: it is briefed to **refute "fixed."** It receives the cluster's defects (evidence blocks), the confirmed-cause statement, and the diff — never the fixer's transcript or reasoning. It re-derives everything itself.

- **Model tier** (per `references/model-map.md`, set explicitly at launch): clusters containing any defect at **severity ≥5** get the **high (main) tier**; below that, the **mid tier**. An unset severity (synthesized `BF-*` defects without a judgment) gates to the high tier — when in doubt, prove hard.
- The proof agent may **raise its hand on the cluster itself**: if the fix resolves some members but its trace cannot connect others to the confirmed cause, that is a false merge — verdict `unproven` with the unexplained members named, and the cluster splits.

## The static chain-trace tier (default)

The default proof is a **hop-by-hop chain trace** through the corrected mechanism — the bug-fix analogue of code-review's last-mile discipline. For each defect in the cluster:

1. **State the broken chain** — the trigger→effect (or writer→reader) path the defect's evidence describes, as it was before the fix.
2. **Walk the corrected chain hop-by-hop**, recording a cited `path:line` (or named symbol) at **every** hop. The canonical shapes:
   - *writer → reader:* write site → persistence/store → resolution logic → runtime read site → consumed value.
   - *trigger → effect:* user/system trigger → handler → the changed site → downstream effect → observable outcome.
3. **Assert the corrected behavior at the changed site** — the hop the fix modified must be shown, with evidence, to now produce the correct value/branch/registration, and every subsequent hop shown to carry it through. A trace that stops at "the code looks right" is not a trace.
4. **Probe off the happy path** — does the corrected chain also hold for the empty case, the failure case, the state the bug left behind (stale rows, caches, localStorage)? A fix that only holds on fresh state is `unproven`.

A typical proof record:

> Defect CR-00X: "fork-row edits never reach execution"
> Fix site `stage-prompt-assembler.service.ts:132` now resolves `input.pipelineId` (threaded from `agentic-step-handler.ts:1255`, resolved from the executing track at `:1248`) → `getStage(stageId, <fork>)` reads the fork row the tabs wrote (`pipeline-stage.service.ts:152` UPDATE WHERE pipeline_id=<fork>) → assembled prompt consumes the edited value ✓ — reader now resolves the writer's source.

**A fix without a traced, evidenced chain is rejected** — verdict `unproven`, regardless of how plausible the diff looks. This is the rule that stops the shallow-checkbox failure: a prover ticking "traced it" without producing the trace. The same evidence bar applies per defect: every member of the cluster needs its own traced chain (chains may share hops; they may not share a hand-wave).

**Write-no-reader-class defects (the DLC-001 family):** when the defect is *a write path whose runtime reader resolves a different source*, the proof chain **must terminate in the reader resolving the writer's source** — the final hop is the runtime read site shown, with cited evidence, to consume exactly what the write site produced. Any trace for this class that ends earlier (e.g. at "the value is now passed") is `unproven`.

While tracing, the prover also hunts the claimed-fix signatures: the symptom silenced downstream of an untouched cause; a guard added around the broken mechanism instead of a correction of it; a fix to the exemplar whose siblings' chains still break.

*(`--reproduce`, landing in Phase 2, upgrades this tier to a dynamic red→green test — observed failing pre-fix, passing post-fix. Until then, chain-trace is the proof.)*

## The verdict — machine-readable, three values

The proof agent returns a fixed shape:

```
verdict: fixed | unproven | regressed
defects: [ { id, chain: "<hop-by-hop with citations>", holds: true|false } ]
rationale: <one paragraph — for unproven/regressed, exactly what could not be established or what broke>
```

- **`fixed`** — every defect in the cluster has a complete, cited chain showing the corrected behavior.
- **`unproven`** — at least one chain has an unevidenced hop, an unexplained cluster member, or a happy-path-only trace. Not an accusation — an absence of proof.
- **`regressed`** — the trace shows the fix *broke* previously-correct behavior (or containment evidence in hand shows it).

## Failed-proof policy

- **`regressed` ⇒ revert immediately.** No retry from the regressed state; the diagnose+fix agent may re-attempt from clean (counts against the cap).
- **`unproven` ⇒ one more diagnose→fix attempt** — the same cluster agent, given the prover's rationale (**cap: 2 attempts total per cluster**) — then re-prove with a fresh proof agent. Still not `fixed` at the cap ⇒ **revert + blocker report** (`templates/blocker-report.md`) + notify.
- **Statuses flip only on `fixed`.** `unproven`/`regressed` never touch `findings.json`; nothing unproven is ever committed (prove-before-commit ordering in `references/commit-and-handoff.md`).
