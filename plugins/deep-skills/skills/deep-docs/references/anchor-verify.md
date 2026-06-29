# Anchor-verify — always-on, fan-out per card, exhaustive

Anchor-verify is the **stale-map defense** and it is **always on** — never sampled, never skipped. It is the doc-analogue of `deep-code-review`'s adversarial verification (`references/multi-agent.md` Stage A/C): a fresh skeptic re-checks the claims before they're trusted. An unverified anchor can't be trusted, so **every** anchor is re-resolved.

## The model — one fresh verifier per card, exhaustive

- **Fan-out per card:** launch **one fresh adversarial verifier per subsystem card** (tier-1) and per tier-2 ref, **≤8 concurrent** (the same concurrency cap as the survey fleet; cards beyond 8 run in successive batches).
- **Fresh and read-only:** each verifier is briefed only with its card/ref + codebase access — never the survey agent's reasoning, never another verifier's output, never an implementation transcript. Its job is to **refute** the anchors, not to trust them.
- **Exhaustive:** the verifier re-resolves **every** anchor in its card — no sampling, no budget. Symbol grep is cheap, so exhaustiveness is affordable, and the anchoring guarantee ("every claim is anchored or it's fiction") forbids leaving any anchor unchecked.

## Per-anchor re-resolution (the procedure)

For each anchor `path:line (symbol)`, the verifier:

1. Greps the `symbol` name in `path`.
2. **Found within ±5 lines** of the recorded line → `accurate`.
3. **Found, but the line moved** (benign drift, e.g. code inserted above) → **re-snap** the recorded line to the symbol's current line; the anchor stays `accurate (re-snapped)`. The re-snapped line is written back into the card/`index.json`.
4. **Symbol absent** from the file → the anchor is `drifted`.

(The line tolerance, symbol-primary rule, and textual-landmark fallback are defined in `layering-and-anchors.md`.)

## Machine-readable verdict

Each verifier returns a per-card verdict in a fixed format so the orchestrator can assemble results deterministically (cf. `multi-agent.md` Stage C's fixed verdict format):

```
CARD: subsystems/auth.md
VERDICT: accurate | drifted | over-budget
ANCHORS:
- src/auth/session.ts:88 (SessionStore.resolve): accurate
- src/auth/mfa.ts:40 (verifyTotp): drifted — symbol not found in file
RESNAPPED:
- src/auth/token.ts:12 (signToken): 12 -> 19
```

- **`accurate`** — every anchor re-resolved (some possibly re-snapped); the card is publishable.
- **`drifted`** — at least one anchor's symbol is gone; the card is stale.
- **`over-budget`** — the card's token-estimate exceeds the tier-0 budget the orchestrator checks (the budget rule and ceiling are owned by Phase 2; Phase 1 surfaces the verdict value so the contract is complete from day one).

## Publish gate

The orchestrator checks the **tier-0 budget once** across the assembled set (Phase 2 owns the ceiling itself), then applies the gate:

**A card with any `drifted` or `over-budget` anchor blocks publish.** This is the doc-analogue of an unresolved State/Data-Flow contract row — the map does not ship stale. The blocked card is regenerated (re-survey + re-anchor that boundary) and re-verified before the atomic `mv` in `place-and-report.md` lands. The drift list also feeds `coverage.md` (and, in a later phase, the Deep-Learn signal).

## Fact pre-harvest for verifier briefs

Before launching each verifier, script the cheap lookups its brief needs (cf. `multi-agent.md` Stage 0): the file contents around each cited anchor and a `grep -n` for each symbol. Inject the harvest into the verifier prompt so it spends its calls refuting, not re-finding. The verifier keeps codebase access for the actual re-resolution.

## Progress feedback

Report cards verified and a running drift count (e.g. `Verified 7/9 cards — 1 drifted`) as the fleet returns, so the long-running verify stage never reads as silent.
