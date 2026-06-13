# Findings format

Every review agent returns findings in this shape; the synthesis/presentation uses the same.

## Severity

| Severity | Meaning |
|---|---|
| **Blocker** | The plan will produce a wrong, conflicting, or duplicate result if executed as written. Must fix before `/deep-implement`. |
| **Major** | Real misalignment with the user or codebase that should be fixed, but isn't strictly fatal. |
| **Minor** | Worth addressing — a pattern deviation or smaller overlap — but the plan would still work. |
| **Nit** | Taste/polish; take it or leave it. |

## Finding fields

- **Severity** — one of the above.
- **Lens** — `User alignment` or `Codebase alignment` (or `Coherence`).
- **Title** — one line.
- **Evidence** — the plan section being critiqued + any codebase path / existing function / pattern it conflicts with or duplicates.
- **Impact** — why it matters.
- **Recommendation** — concrete: reuse `path:symbol`, follow pattern Y, merge with existing feature Z, drop/replace step N.

## Example

> **[Blocker · Codebase alignment] Plan rebuilds existing port-allocation logic**
> Evidence: Plan §"Phase 2 — assign dev port" proposes a new `pickPort()`; the repo already has `PORT_SAFETY_RULE` + dynamic allocation in `apps/api/src/.../agentic-step-handler.ts`.
> Impact: Duplicate, drift-prone logic that bypasses the safety rule (4200/5200 reserved).
> Recommendation: Reuse the existing rule/allocator instead of a new function; cite it in the plan's Files section.

## Presentation order

Group by severity (Blockers first), then by lens within each group. End with a one-line verdict per lens — e.g. "User alignment: clean. Codebase alignment: 1 blocker, 2 minor." If a lens is clean, say so explicitly rather than padding the list.
