# Situational checks — progressive-disclosure bug hunts

Some bug classes are high-value but **only matter for diffs that touch a specific surface**: file uploads, payments, time zones, websockets, migrations, auth, caching. Baking every one into the always-on lenses would bloat every finder brief with hunts that are dead weight on the 90% of diffs that don't touch that surface. Situational checks solve this the way the skill system solves it: a **sparse catalog** loaded every run, and a **full check body** loaded *only when the diff plausibly matches it*. Dozens of checks can exist; a given review pays for only the few that fire.

## The mechanism (progressive disclosure)

1. **Always loaded — the catalog only.** `references/situational/index.md` is the one situational file read on every review. Each entry is a few lines: an id, a one-line trigger, a machine-matchable **Match** pattern, the lens(es) it **attaches to**, and one line on what it catches. The bodies are *not* read yet.

2. **Match against the resolved diff.** After scope is resolved (and, in `--multi-agent`, after Stage-0 pre-chunking), grep the diff — chunk files in multi-agent mode, the raw diff otherwise — for each entry's **Match** pattern. Matching is cheap and deterministic (path globs + content regexes), so it runs as a small script, never an agent, and never loads a body speculatively. A pattern that doesn't hit means that check's body is never read.

3. **Load only what matched; inject into the named briefs.** For each *matched* entry, read its body file (`references/situational/<id>.md`) and append it to the brief of the lens/finder named in **Attaches to** — the single review agent in default mode, or the specific finder(s) in `--multi-agent`. **Situational checks never add agents** — they augment the briefs of the existing fleet, so the ≤8-concurrent cap and the token budgets are untouched. A check attached to a lens whose finder was scaled out of this run (e.g. `removed-behavior` on a purely additive diff) attaches to the nearest running lens instead.

4. **Disclose what fired.** The report names the situational checks that matched and ran (the report header's `Situational checks:` line, e.g. `file-upload-pipeline`), the same way no-plan degradation is disclosed. A reader needs to know which specialized hunts were and weren't in play. Checks that didn't match are not listed — their absence is the default.

## Matching discipline

- **Triggers err toward loading.** A false match costs one body-read appended to one brief; a false *miss* costs the whole bug class. When unsure whether a pattern is broad enough, broaden it — the cost asymmetry favors over-firing.
- **Match on the diff, not the whole repo.** A check fires because *this change* touches the surface, not because the repo happens to contain an uploader somewhere. Grep the resolved diff/chunks.
- **No body is read unless its entry matched.** This is the whole point — keep it true. Don't pre-read bodies "to see if they're relevant"; the Match pattern is the relevance test.

## Authoring a new situational check

Two edits, no code:

1. **Add a catalog entry** to `references/situational/index.md` in the format every entry uses (id · Loads when · Match · Attaches to · Catches). Keep it to ~5 lines — the catalog is read every run and must stay sparse.
2. **Write the body** at `references/situational/<id>.md`: the hunt-list for that surface, with the concrete failure modes, what ground truth to check against, and when to escalate to a live smoke (`--browser`). Write it like a lens brief — evidence-required, named failure modes, no vague advice.

Good situational checks are **surface-specific and statically findable from the diff**, with a clear trigger. Candidates worth authoring as the library grows: payment/refund flows, timezone/DST math, websocket reconnect/backpressure, DB migrations (up without down, non-idempotent), auth/permission boundary changes, cache invalidation surfaces, pagination/cursor math, retry/idempotency keys, i18n/locale formatting. Author them on demand — when a review misses a bug whose class would recur, add the check rather than widening an always-on lens.
