# Question cadence

Ask the user how they want questions delivered, then hold to it for the session (they can change it any time).

| Cadence | When to recommend | How to run it |
|---|---|---|
| **1-at-a-time** | Complex/ambiguous features where each answer reshapes the next question. | Ask one question, wait, adapt, ask the next. Most conversational; best paired with `/drill` and `/breakout`. |
| **3-at-a-time** | Medium features with a few independent decision areas. | Batch three related questions per round via the host's structured-question tool (see `references/host-affordances.md`). |
| **all-at-once** | Small, well-scoped features. **Default recommendation for small work.** | Render the full question set in as few structured-question calls as possible. |

Notes:
- the structured-question tool supports up to 4 questions per call (numbered-chat fallback otherwise — see `references/host-affordances.md`) — for 3-at-a-time use one call; for all-at-once use as few calls as needed.
- Skip any question you can answer yourself from exploration. Cadence governs *delivery*, not *volume* — keep total questions decision-relevant.
- Gap/constraint follow-ups (`/gaps`, `/constraints`) can arrive in their own rounds regardless of the base cadence.
