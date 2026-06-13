# <Feature Name>

> **Status:** ready to review · **Risk:** <low|medium|high> · **Mode:** <single-phase|multi-phase> · **Primary file(s):** <path(s)>

## Context

Why this change is being made — the problem or need, what prompted it, and the intended outcome. Self-contained: a fresh agent reads only this doc + the repo.

## Constraints

Performance, compatibility, security, scope, deadline, platform constraints that the design must honor. (Populated by `/constraints`; omit the section if none.)

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

## Risks

Material risks and their mitigations/fallbacks. (Populated by `/risks`; omit if none.)

## Deferreds

Items consciously deferred — never dropped into prose. One entry each:

- **What:** <the deferred item, one line>
  **Why deferred:** <reason / dependency>
  **Integration:** <how it must connect back to the completed work when done>

## Phase Summaries  <!-- multi-phase only; left EMPTY at planning time -->

*Execution agents (`/deep-implement`) append one summary per completed phase below. Do not fill during planning.*
