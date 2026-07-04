# Notifications

Pull the user's attention only when it's worth it. **Notify on: a blocker (a cluster reverted at the fix cap or on regression) and autonomous full-run completion.** Do **not** notify on routine per-cluster progress — over-notifying erodes trust in the signal.

## Mechanism

Use the host's notification affordance, with the native → shell `osascript` → bold `ATTENTION:` text-line fallback ladder defined once in `references/host-affordances.md`. The message contract is unchanged: one line, < 200 chars, lead with the actionable fact. Examples:

- Blocker: `deep-bugfix blocked: cluster CL-2 (CR-003, CR-004) unproven after 2 attempts — reverted, needs you`
- Done: `deep-bugfix done: 5/6 findings fixed in 2 clusters, 1 cluster blocked (see round-1/fix-summary.md)`

## When NOT to notify

- Between successfully closed clusters in either mode.
- In collaborative mode generally (the user is present at the gates).
- For anything the user is clearly watching in real time.
