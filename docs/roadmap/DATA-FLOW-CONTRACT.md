# DLC-001 — State / Data-Flow Contract (seed directive card)

> The first and highest-leverage directive in the Deep-Learn loop. Hand-authored from PR#65; would have surfaced ~100% of that review's severity at **plan** time.
> Category: `write-no-reader` · Owners: deep-plan (primary), deep-plan-review (check), deep-implement (validate).

## The artifact (added to the plan document)

A required section. **One row per piece of state the feature reads or writes at runtime.** A row is *resolved* only if the runtime reader resolves the **same source** the writer wrote to — otherwise it blocks plan completion unless explicitly marked Display-only and moved to Deferreds.

```markdown
## State / Data-Flow Contract   ← plan is NOT "done" with an unresolved row

| # | State (field / table / store) | Writer(s) path:line | Runtime reader(s) path:line | Same source? | Resolution / AC |
|---|---|---|---|---|---|
```

### Worked example — CR-001 (the Blocker) at plan time

| # | State | Writer | Runtime reader | Same? | Resolution / AC |
|---|---|---|---|---|---|
| 1 | stage prompts | tabs → `PUT /pipeline-stages/:id?pipelineId=<fork>` | `agentic-step-handler.assemble()` → `input.pipelineId ?? 'default'` | ❌ fork vs `'default'` | **UNRESOLVED** → thread track pipelineId into `assemble()` (both call sites); AC: a fork-row edit reaches the assembled prompt of an execution |

The row cannot be filled in honestly without discovering the bug: the writer column forces "where does the save land?", the reader column forces a runtime trace, and "Same?" is a binary you can't fudge.

## The four rules that give it teeth

1. Every new persisted column / store / localStorage key the plan introduces **must** appear as a writer row.
2. Every "single source of truth" claim in any AC must point to **exactly one** source. Two writers feeding one concept = a conflict row to resolve.
3. **Deletion-parity:** when the plan removes a surface, each behavior it provided becomes a row whose reader must be re-homed.
4. Reader = "none" or reader-source ≠ writer-source ⇒ **blocks plan completion** unless Display-only + listed in Deferreds.

## Insertion points (3 skill files)

- `deep-plan/SKILL.md` §6 *Design & write the plan* — contract is a required section of the artifact; §7 *Review* gate asserts every row resolved.
- `deep-plan-review/SKILL.md` §3 dispatch — add a check: contract present, every row resolved, AC sources singular.
- `deep-implement/SKILL.md` §4 *Validate* — exit invariant: each "runtime" row's reader is wired in code, plus a **contract probe** (write → execute → assert read) for it. Note: current `references/validation.md` is typecheck + scoped unit tests + prompt snapshot — it would have caught **none** of CR-001–006 (they typecheck clean and pass unit tests; the bug is cross-layer). The contract probe is the missing net.

## Coverage (PR#65)

Surfaces at plan time: CR-001 (Blocker), CR-002 (Major), CR-003, CR-004, CR-005, CR-006 (all Minor), CR-008, CR-009, CR-016 (nits) — i.e. **every severity-bearing finding**. The validation contract-probe is an independent second net on CR-001/002/003/004/006; combined-suite attribution (separate card, `test-hygiene`) covers CR-007.
