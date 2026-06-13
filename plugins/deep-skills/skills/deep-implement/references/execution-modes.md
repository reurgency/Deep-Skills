# Execution modes: collaborative vs autonomous

For multi-phase plans, ask which mode if not passed as a flag. Single-phase plans run one implement→validate→fix pass; the mode only changes whether you gate before committing.

## Collaborative

A **review gate between phases**. The user stays in the loop.

Per phase:
1. Implement (fresh phase agent) → validate → fix loop (cap 2).
2. **Present**: the diff, the validation result, and a short phase summary.
3. **Gate**: user approves or requests a fix.
   - *Request fix* → relay to the phase agent, re-validate, re-present.
   - *Approve* → append the phase summary to the plan, write the next-phase hand-off, commit **only if the user asks**, then continue to the next phase.
4. No notifications needed — the user is present.

## Autonomous

**Continuous** execution. The user has stepped away (and typically enabled bypass-permissions).

Per phase:
1. Implement → validate → fix loop (cap 2).
2. On green: **commit a per-phase checkpoint** (see `commit-and-handoff.md`).
3. Append phase summary → write next-phase hand-off → continue automatically.
4. On a blocker (fix cap hit): **stop**, write `templates/blocker-report.md`, **notify** (`notifications.md`), do not commit broken code, do not proceed.
5. On full completion: reconcile Deferreds, **notify** completion.

Autonomous never force-pushes, never deletes user data, and never proceeds past a blocker. It is "uninterrupted on success, hard-stop on failure."

## Switching mid-run

The user can switch modes between phases (e.g., autonomous until a risky phase, then collaborative). Honor the switch at the next phase boundary.
