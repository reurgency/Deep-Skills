# Token budget — estimates everywhere, a hard tier-0 ceiling, grouped overflow

This is the **bloated-dump defense**. The map exists so a crawling agent loads only the slice its task needs; that promise breaks the moment tier-0 (`MAP.md` + the always-loaded part of `index.json`) grows large enough to cost an agent real context just to orient. So every doc carries a token **estimate**, and tier-0 is held under a **hard ceiling** by **grouped overflow** — never by silent truncation.

## The token-estimate heuristic — `ceil(chars/4)`

The cost of a doc is estimated as:

```
token_est = ceil(character_count / 4)
```

stored as a raw integer in `index.json`'s `token_est` field (Phase 1 already populates it; see `index-and-coverage.md`'s "Token-est ownership"). The `chars/4` ratio is the standard rough English-text token density; it needs **zero dependencies**, which fits the markdown-only, distributable-on-any-repo baseline. It is deliberately *not* a real tokenizer — a real tokenizer is a documented future upgrade (see the plan's Deferreds), swapped in behind the same `token_est` field when one is confirmed present.

Because it is a heuristic, **it is an estimate, and it is labeled as one everywhere it is shown.**

## The "estimate, not exact" labeling rule

This is the one authoritative statement of the rule. **Every surface that shows a token count MUST mark it an estimate** — there is no exception, no "obviously approximate" pass. The format:

| Magnitude | Format | Example |
|---|---|---|
| under 1,000 | `~<n> est` | `~450 est` |
| 1,000 and over | `~<n/1000, one decimal>k est` | `~1.2k est` |

Rendering rules:

- Always prefix `~` (approximate) and always suffix ` est` (estimate). Both are required — `~` alone or `est` alone is non-conforming.
- **< 1,000:** the integer as-is — `970` → `~970 est`.
- **≥ 1,000:** divide by 1,000, round to **one decimal**, drop a trailing `.0` — `1100` → `~1.1k est`, `1200` → `~1.2k est`, `2000` → `~2k est`.
- A **group subtotal** (see overflow below) is the sum of its members' raw `token_est`, then rendered through this same rule.

This matches the style already rendered in the repo's own dogfood map (`docs/ai-map/MAP.md`: `~970 est`, `~1.1k est`, `~1.2k est`). The raw integer lives only in `index.json` (`token_est`); every *human- or agent-facing* surface — `MAP.md` rows, group subtotals, external-reference rows — renders it through the rule above.

## The tier-0 hard ceiling — ~2,000 est

**Tier-0 is `MAP.md` plus the always-loaded part of `index.json`. Its total estimate must stay ≤ ~2,000 est.** This is the budget an agent pays *unconditionally* on every task, before it has loaded a single subsystem card, so it is kept deliberately tiny. The ceiling is a **fixed** number (not a fraction of the agent's window): the map is authored once and read by many different agents with different budgets, so a fixed, conservative ceiling is the portable choice.

The `over-budget` verdict in `anchor-verify.md` is this ceiling's gate: the orchestrator checks the assembled tier-0 estimate **once** against the ceiling. Over the ceiling ⇒ `over-budget` ⇒ **publish is blocked** until grouped overflow brings tier-0 back under. (It is not a permanent block — grouped overflow is the remedy that clears it; the map never ships over-ceiling and never ships truncated.)

## Grouped overflow — the algorithm

When the flat per-subsystem list would push tier-0 over the ceiling, **do not drop subsystems and do not shrink cards.** Collapse the flat list into groups so tier-0 shrinks while every subsystem stays reachable through `index.json` (the *grouped index* — it already carries one entry per subsystem; nothing is removed from it).

1. **Estimate tier-0 flat.** Render `MAP.md` with the flat subsystem table (`layering-and-anchors.md`); compute its `token_est` (`ceil(chars/4)`). If ≤ ceiling, ship flat — done.
2. **Over the ceiling ⇒ group by top-level area.** Group subsystems by their **top-level area** — the first path segment of each subsystem's primary directory (e.g. `services/`, `web/`, `lib/`), reusing the boundary grouping `survey.md` already produced. Each top-level area becomes one group.
3. **Render one row per group**, not per subsystem:
   - group name (the top-level area),
   - **per-group subtotal** = sum of member `token_est`, rendered `~Nk est` per the labeling rule,
   - a **group-level load-when** = a union/summary of the members' triggers, so the crawler can decide whether to expand the group at all,
   - a pointer telling the crawler that per-member detail (each subsystem's card + token-est + load-when) lives in `index.json`.
4. **Spill detail into the grouped index — never truncate.** The per-subsystem rows are *not deleted*; they move out of `MAP.md` into `index.json`, which still lists every subsystem with its own `doc`, `anchor`, `token_est`, and `load_when`. `MAP.md` shows groups; `index.json` is the full member roster.
5. **Re-estimate.** Recompute tier-0 with the grouped table. If now ≤ ceiling, ship grouped — done.
6. **Still over (too many groups) ⇒ second-level collapse.** Keep the largest/most-trafficked groups as their own rows and fold the smallest groups into a single **`other` group** with its own subtotal and load-when. Repeat until tier-0 ≤ ceiling. There is always a terminating state (everything in one `other` row) that fits — the ceiling is always reachable without dropping a subsystem.
7. **Log every grouping decision — always.** Every group formed, its members, and every second-level fold into `other` is recorded in `coverage.md`'s **boundary-decisions** section (the same section `survey.md`'s split/merge/cap decisions feed; see `index-and-coverage.md`). **Silence is forbidden:** a reader of `coverage.md` can always reconstruct which subsystems were grouped and why, so grouping is never mistaken for omission.

The invariant: **tier-0 ≤ ceiling AND every subsystem reachable via `index.json` AND every grouping logged.** Truncation violates the second; silent grouping violates the third; both are disallowed.

## Authoring a good `load_when`

`load_when` is the trigger phrase that tells a crawling agent *when this doc is worth its tokens*. The whole tiering economy rides on it being good, so:

- **Phrase it as the reader's task, not the doc's contents.** Write `working inside auth/session`, not `describes the session store`. The agent matches it against *what it is doing*.
- **Use concrete nouns the agent will actually have in its prompt** — file paths, feature names, error symptoms, domain verbs (`touching charges, invoices, or webhooks`). Avoid restating the subsystem name alone; that is what the `concept` field is for.
- **Keep it one line, natural-language-first.** No flags, no jargon a Copilot/Codex user wouldn't type.
- **Make triggers disjoint.** Two cards should rarely both match one narrow task; overlapping triggers cause false loads, which is exactly the cost tiering exists to avoid.
- **A group's load-when is the union of its members'**, phrased so the crawler can decide whether to expand the *group* at all (e.g. `anything under services/ — billing, notifications, or search`). It is intentionally broader than a single card's trigger.
