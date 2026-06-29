<!-- GENERATED — do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-1 subsystem card: loaded on touch. One per boundary. Every claim carries a path:line (symbol) anchor. -->

# <subsystem name>

> **Load when:** <trigger phrase, e.g. "working inside auth/session"> · **~tokens:** ~450 est
> **Deep ref:** [references/<name>.md](../references/<name>.md) *(omit this line if card-only — no tier-2 earned)*

## Purpose

<One or two sentences: what this subsystem does and why it exists.> — `src/auth/session.ts:12 (SessionStore)`

## Entry points

How code enters this subsystem (public functions, routes, CLI commands, exported API):

- `<entry>` — `src/auth/session.ts:88 (SessionStore.resolve)`
- `<entry>` — `src/auth/routes.ts:14 (registerAuthRoutes)`

## Key types

The central data structures / interfaces / models:

- `<Type>` — `src/auth/types.ts:5 (Session)`
- `<Type>` — `src/auth/types.ts:22 (AuthContext)`

## Invariants

The rules this subsystem assumes and enforces:

- <invariant, stated plainly> — `src/auth/session.ts:101 (SessionStore.assertFresh)`

## Data-flow summary

How data moves through the subsystem and across its seams (one-line-per-hop; full hop-by-hop trace lives in the tier-2 ref when earned):

- <flow, e.g. "login → token mint → session persist → cookie set"> — `src/auth/login.ts:40 (login)` → `src/auth/token.ts:12 (signToken)` → `src/auth/session.ts:88 (SessionStore.resolve)`

## Anchors

<!-- Every anchor above is re-resolved by anchor-verify (symbol-primary, ±5-line re-snap).
     A drifted/over-budget anchor blocks publish. This list is the card's full anchor set. -->
| Claim | Anchor |
|---|---|
| <purpose> | `src/auth/session.ts:12 (SessionStore)` |
| <entry: resolve> | `src/auth/session.ts:88 (SessionStore.resolve)` |
