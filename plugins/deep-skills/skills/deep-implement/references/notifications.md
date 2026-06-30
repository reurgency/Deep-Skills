# Notifications

Pull the user's attention only when it's worth it. **Notify on: a blocker (fix cap hit) and autonomous full-run completion.** Do **not** notify on routine per-phase progress — over-notifying erodes trust in the signal.

## Mechanism

Use the host's notification affordance, with the native → shell `osascript` → bold `ATTENTION:` text-line fallback ladder defined once in `references/host-affordances.md`. The message contract is unchanged: one line, < 200 chars, lead with the actionable fact. Examples:

- Blocker: `deep-implement blocked: Phase 3 (auth) failing typecheck after 2 fixes — needs you`
- Done: `deep-implement done: 5/5 phases committed, 2 deferreds still open`

## When NOT to notify

- Between successful phases in either mode.
- In collaborative mode generally (the user is present at the gate).
- For anything the user is clearly watching in real time.
