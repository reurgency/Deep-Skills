# Phase execution: sequential by default, parallel only on request

## Default — sequential, one fresh agent per phase

The orchestrator (main session) spawns **one fresh sub-agent per phase**, in order. Each agent is briefed with:
- the full plan (so it has Context, Constraints, Approach),
- **its phase only** (goal, prerequisites, files, steps, acceptance),
- the **Phase Summaries** appendix so far (what prior phases produced),
- the latest next-phase hand-off.

A fresh agent per phase keeps context lean over long multi-phase runs and matches the plan's "any phase executable cold" design. The orchestrator never implements directly — it briefs, validates, commits, and hands off.

## `--parallel` — opt-in, and only when provably safe

Parallel phase execution runs **only** when the user passes `--parallel` (or types `/multi-agent`). Even then, the orchestrator must first prove the candidate phases are independent. Run phases concurrently only if **all** hold:

1. **No shared files** — the phases' file sets (from each phase's *Files* list) do not intersect.
2. **No ordering dependency** — neither phase lists the other as a prerequisite.
3. **Contract is pre-defined** — any interface they share (e.g. API request/response types) is already specified in the plan, so each agent codes to the contract without waiting on the other.

The canonical safe case: **one agent builds the frontend, another builds the backend, both coding to a shared contract.** That is desirable parallelism.

If any check fails, **do not parallelize** — fall back to sequential and state which check failed. Never auto-parallelize to "save time"; the user must ask, and the safety checks must pass.

Concurrency is bounded (a small handful, never a swarm) per the user's standing rule against needless parallel token burn. After parallel phases complete, validate each and reconcile their summaries before moving on.

## Briefing a phase agent (prompt shape)

> You are implementing **one phase** of an approved plan. Plan: <path/inline>. Your phase: <phase block>. Already done: <Phase Summaries>. Implement only this phase, following the plan's Approach and Constraints. Reuse the named existing functions/utilities. Do not exceed this phase's scope. Return: files created/modified + a 3–5 line summary + any blocker. Do not commit.

The orchestrator handles validation, commits, summaries, and hand-offs — not the phase agent.
