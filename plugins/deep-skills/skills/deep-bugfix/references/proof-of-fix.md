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

## The dynamic red→green tier (`--reproduce`)

`--reproduce` ("fix it with a reproducing test") upgrades the proof from a static trace to an executed demonstration: the bug reproduced as a failing test, then shown to pass **with the fix, and only with the fix**. Chain-trace remains the default tier; this tier replaces it when the flag (or its natural-language form) is in effect.

**The protocol — red is observed before the fix is applied:**

1. **Write the reproducing test first.** Before applying its fix, the diagnose+fix agent writes a test that exercises the broken chain at the confirmed cause — asserting the correct *observable outcome* the defect's evidence says is missing, not merely the symptom's absence. The test goes in the host suite's **discovered test location**: discover the suite's conventions and runner the same way containment discovers commands (`package.json` / build configs / `CLAUDE.md` — never `.env`/secrets; see `references/containment.md`).
2. **Observe red, record it, pre-fix.** Run the test against the unfixed code and record the failure output in the proof record **before the fix lands**. A test that was never seen red proves nothing — it may pass vacuously. No recorded pre-fix red ⇒ the red→green claim is void for that defect.
3. **Apply the fix; observe green.** The same test now passes; record the passing run.
4. **The proof agent re-runs both directions itself.** The fresh adversarial agent does **not** trust the fixer's transcript or its recorded outputs — it re-derives the evidence: with the fix in place, run the test and observe **green**; temporarily revert the fix diff (e.g. `git stash` / `git apply -R` — the reproduction test stays in place), run the test and observe **red**; restore the fix. Both directions must hold. A test green in both directions is vacuous; a direction the prover could not re-run is an unevidenced hop — either way, verdict `unproven`.
5. **The test ships with the fix.** The reproduction test **rides the cluster's fix commit** — same commit, permanent regression guard. Post-run, the test exists in the fix branch's suite and fails if the fix is reverted; on merge, that guarantee transfers to mainline.

The per-defect evidence bar carries over from the static tier: every defect in the cluster needs its own red→green observation (one test may assert several defects' observables; it may not hand-wave any).

**Genuinely unreproducible ⇒ a reported finding + chain-trace fallback — never a silent skip.** When a defect cannot be reproduced in a test after a genuine attempt (production-only state, an unmockable third party, nondeterminism beyond the harness's control), record a **reproduction-failed finding** in the proof record and the cluster's `fix-summary.md` entry — naming exactly what was tried and why it cannot reproduce — then prove that defect with the **static chain-trace tier** at its full evidence bar. The verdict for that defect rests on the trace; the fallback is visible in the record, never implied by omission.

## The verdict — machine-readable, three values

The proof agent returns a fixed shape:

```
verdict: fixed | unproven | regressed
defects: [ { id, chain: "<hop-by-hop with citations — or, under --reproduce, test path + the prover's own red/green observations>", holds: true|false } ]
rationale: <one paragraph — for unproven/regressed, exactly what could not be established or what broke>
```

- **`fixed`** — every defect in the cluster has a complete, cited chain showing the corrected behavior (under `--reproduce`: a committed test the proof agent itself observed red without the fix and green with it — or, for a reported-unreproducible defect, its fallback chain).
- **`unproven`** — at least one chain has an unevidenced hop, an unexplained cluster member, or a happy-path-only trace; under `--reproduce`, also a missing pre-fix red, a direction the prover could not re-run, or a test green in both directions. Not an accusation — an absence of proof.
- **`regressed`** — the trace shows the fix *broke* previously-correct behavior (or containment evidence in hand shows it).

## Failed-proof policy

- **`regressed` ⇒ revert immediately.** No retry from the regressed state; the diagnose+fix agent may re-attempt from clean (counts against the cap).
- **`unproven` ⇒ one more diagnose→fix attempt** — the same cluster agent, given the prover's rationale (**cap: 2 attempts total per cluster**) — then re-prove with a fresh proof agent. Still not `fixed` at the cap ⇒ **revert + blocker report** (`templates/blocker-report.md`) + notify.
- **Statuses flip only on `fixed`.** `unproven`/`regressed` never touch `findings.json`; nothing unproven is ever committed (prove-before-commit ordering in `references/commit-and-handoff.md`).
