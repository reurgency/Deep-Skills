# <Feature Name>

> **Status:** ready to review · **Risk:** <low|medium|high> · **Mode:** <single-phase|multi-phase> · **Primary file(s):** <path(s)>

## Context

Why this change is being made — the problem or need, what prompted it, and the intended outcome. Self-contained: a fresh agent reads only this doc + the repo.

## Constraints

Performance, compatibility, security, scope, deadline, platform constraints that the design must honor. (Populated by `/constraints`; omit the section if none.)

## Assumptions  <!-- autonomous runs (`--autonomous`) only; omit in interactive sessions -->

One row per planning question the session answered **itself** instead of asking the user (see `references/autonomous-mode.md`). Every self-answered question lands here — none are silently absorbed into prose.

| # | Question | Chosen answer | Why |
|---|---|---|---|
| 1 | <the question that would have been asked> | <the answer chosen> | <one-line rationale — evidence from exploration, convention, or stated best judgment> |

## Approach

The recommended approach in a few sentences. Note any rejected alternative and why, briefly. Name existing functions/utilities/patterns to reuse, with their paths.

## Steps  <!-- single-phase plans -->

1. <step> — files touched, functions reused.
2. <step>
3. ...

## Phases  <!-- multi-phase plans; replaces Steps. See references/phase-structuring.md -->

### Phase 1 — <title>
- **Goal:** <one sentence>
- **Prerequisites / inputs:** <or "none">
- **Files:** <paths>
- **Steps:**
  1. <action>
  2. <action>
- **Acceptance / validation:** <commands / tests / observable behavior>

### Phase 2 — <title>
- ... (same shape)

## Files

Files to create/modify. For a pattern repeated across many files, describe the pattern once and list a few representative paths.

## Verification

How to prove the change works end-to-end: run the app, MCP tools, tests, observable behavior. State what "done" looks like.

### Interaction & re-entry  <!-- include ONLY if the feature adds a user-triggered action/submit/navigation or a stateful/resumable flow; omit otherwise -->

For features that add a user-triggered action (button/submit/navigation) or a stateful flow a user can abandon and restart, the plan must **specify**, not leave implicit:

- **Double-submit / in-flight handling** — what suppresses a second click (or a click while the first is in flight); name the guard. An action with no in-flight state can fire twice — and if it kicks off a backend run, each click spawns a duplicate run.
- **Processing feedback** — what the user sees during the async handoff (spinner / disabled / "Launching…"). A handler that does real work but renders nothing reads as "the button does nothing," driving the repeat-click.
- **Navigation fallback** — every introduced route resolves, and a `**`/wildcard fallback exists so an unmatched URL degrades gracefully instead of hard-crashing.
- **Re-entry story** — start → abandon → restart: are stale artifacts from a prior run detected and reconciled, does re-entry signal "a prior run exists" (resume/overwrite/fresh), and is a re-run idempotent (no duplicated side effects)?

## Risks

Material risks and their mitigations/fallbacks. (Populated by `/risks`; omit if none.)

## Deferreds

Items consciously deferred — never dropped into prose. One entry each:

- **What:** <the deferred item, one line>
  **Why deferred:** <reason / dependency>
  **Integration:** <how it must connect back to the completed work when done>

## Phase Summaries  <!-- multi-phase only; left EMPTY at planning time -->

*Execution agents (`/deep-implement`) append one summary per completed phase below. Do not fill during planning.*
