# Last-mile verification — tracing promised behavior to the end of the chain

The last-mile problem, in the user's own words: implementations where *"the interface looks correct… the functionality appears to work on the surface but doesn't make it the last mile."* The app *looks* like it functions per the plan, but something is left out on the behavioral side. This reference is the methodology for catching it.

## Step 1 — Enumerate the promised behaviors

Build an explicit checklist before reading any code:

- From the **plan** (when one exists): every behavior implied by each phase's Goal, Steps, and Acceptance, plus the plan's top-level Verification section. "Saving a track persists it and updates the list" is *three* behaviors: the save call, the persistence, the list update.
- **No-plan mode:** enumerate from the PR description, commit messages, and the diff's apparent intent (a new form implies a working submit chain; a new endpoint implies a caller). State in the report that enumeration degraded to these sources (see `references/review-lenses.md`).
- Decompose compound promises. "User can delete a template" decomposes into: the affordance exists, it triggers the right call, the backend deletes, errors surface, the UI reflects the deletion (list updates, selection resets, dependent state clears).

## Step 2 — Walk each chain hop-by-hop, with evidence per hop

For each enumerated behavior, trace the **full chain** and record evidence (path:line or named symbol) at every hop. The canonical web-app chain:

```
UI event → component handler → service method → HTTP request
  → route registration → API handler → persistence
  → response → UI state update → secondary effects
```

Adapt the chain to the architecture under review (a CLI tool's chain might be arg-parse → command → side effect → output), but the discipline is the same: **a behavior is verified only when every hop is shown to exist and connect to the next**. A typical trace record:

> Behavior: "Saving a track persists it"
> `track-form.component.ts:142` (click → `onSave()`) → `track.service.ts:88` (`saveTrack()` builds POST) → `routes/tracks.ts:31` (route registered) → `track-handler.ts:57` (validates, calls repo) → `track.repository.ts:24` (INSERT) → handler returns 201 with entity → `track.service.ts:91` (response mapped) → `track-form.component.ts:147` (signal updated, list refreshes) ✓

A hop that cannot be evidenced is a **gap**, and a gap anywhere in the chain is a finding — even if every other hop is perfect.

## Step 3 — Verify the COMPLETE behavior, not the connected happy path

A fully connected chain can still fail the last mile. For each behavior, additionally check:

- **State transitions** — does the entity/UI actually end in the promised state (status flips, flags set, timestamps written), not just "a request succeeded"?
- **Secondary effects** — the parts plans promise and implementations forget: list refreshes, cache invalidation, notifications, manifest/status updates, dependent-component reactions.
- **Edge handling** — the empty case, the duplicate case, the failure case: does the chain do something *defined* off the happy path, and does the user see it?

## The named AI failure modes — hunt these explicitly

These are the recurring ways AI-built features fail the last mile. Check each one against the diff:

1. **Optimistic UI with no real call** — the component updates local state as if the operation succeeded, but the service call is missing, commented out, or never awaited. The demo looks perfect; nothing persists.
2. **Leftover mocks/stubs** — a hardcoded return, in-memory array, `// TODO: real implementation`, or fixture data still standing in for the real thing on one hop of the chain.
3. **Response ignored or errors swallowed** — the call fires but the result is discarded: no `.subscribe`/`await` consumer, `catch` that only logs, error states that never reach the UI.
4. **Contract drift vs shared types** — UI and API built to different payload shapes; a shared type updated on one side only; fields renamed in one layer; serialization mismatches that "work" because the field is silently `undefined`.
5. **Unregistered routes / unwired handlers** — handler written but route never added to the router; component written but never routed/rendered; event emitted with no listener.
6. **Two halves built to different understandings** — frontend and backend (or two phases/sessions) each implement *their* reading of the behavior; each looks complete alone, the seam doesn't carry the behavior across. Coherence-lens style discontinuities often mark where to look.

## Static-first; `--browser` escalation

This methodology is **static-first**: trace chains by reading code, and most last-mile gaps fall out of that reading. When static tracing leaves real doubt — a chain that looks connected but whose runtime behavior is uncertain (timing, real network payloads, framework wiring magic) — escalate with the `--browser` flag: exercise the behavior against an already-running dev server and watch real network traffic for observed evidence — the full flow, hard rules (never start a server; never read `.env` for port discovery), and `evidence.observed` citation format are in `references/browser-verification.md`.

## The synthesis rule (non-negotiable)

**A last-mile finding without a cited hop-by-hop chain is rejected at synthesis.** "Save might not work" is not a finding. "The chain breaks at hop 4: `track.service.ts:88` POSTs to `/api/tracks` but no such route is registered (`routes/` grep shows only `/api/track-templates`)" is a finding. This rule exists to prevent the shallow-checkbox failure mode — a reviewer ticking "traced it" without producing the trace. The same applies to *clean* verdicts: a behavior reported as verified must have its trace available on request, summarized or in full in the report's evidence.
