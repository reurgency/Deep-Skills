# Notifications

Pull the user's attention only when it's worth it. **Notify on: a blocker (fix cap hit) and autonomous full-run completion.** Do **not** notify on routine per-phase progress — over-notifying erodes trust in the signal.

## Mechanisms (in order of preference)

1. **`PushNotification` tool** — fires a desktop notification in the user's terminal, and pushes to their **phone** when Remote Control is connected. One line, < 200 chars, lead with the actionable fact. Examples:
   - Blocker: `deep-implement blocked: Phase 3 (auth) failing typecheck after 2 fixes — needs you`
   - Done: `deep-implement done: 5/5 phases committed, 2 deferreds still open`
   If the result says the push wasn't sent, that's expected — no action needed.

2. **Native macOS banner (fallback / in addition)** — on darwin:
   ```
   osascript -e 'display notification "<msg>" with title "deep-implement"'
   ```

3. **Custom `Notification` hook (user-extensible)** — the user can register a `Notification` hook in `.claude/settings.json` to run their own handler (Slack, custom push, sound) whenever the session notifies. `deep-implement` only needs to *emit* the notification; the hook is the seam for custom handling. Offer to scaffold a starter hook via the `update-config` skill — do not add it silently.

## When NOT to notify

- Between successful phases in either mode.
- In collaborative mode generally (the user is present at the gate).
- For anything the user is clearly watching in real time.
