# Multi-agent review (`--multi-agent` / `/multi-agent`)

Parallel review: one fresh agent per dimension, then a synthesis pass. Trades tokens for breadth and independence — four agents can't anchor on each other the way one agent's single pass can. Use for large or multi-phase plans, or whenever the user asks.

## Fan-out

Before fan-out, read `references/model-map.md` and bind each dimension agent's model to its concrete host ID, set explicitly at launch (never an alias or host default) — the model-routing correctness guarantee in `references/host-affordances.md` applies to every fleet.

Launch the dimension agents **in parallel** — one message, multiple `Agent` tool calls — each with the plan text, its single dimension brief, codebase read access, and the user-preference pointers. None of them gets the planning transcript.

| Agent | Dimension brief |
|---|---|
| **codebase-duplication** | Lens B #3–#5: duplicate behavior, overlapping behavior, conflicts. Heavy codebase exploration; name existing implementations with paths. |
| **patterns-and-practices** | Lens B #1–#2: best-practices, conventions, off-pattern approaches vs how the repo already does similar things. |
| **user-alignment** | Lens A: choice, taste, style, knowledge fit, coherence — against memory/`feedback_*`/CLAUDE.md and the plan. |
| **coherence-conflicts** | Internal consistency: the plan contradicting itself, its stated goals, or earlier decisions; ordering/dependency conflicts across phases. |

Use the `Explore` agent type for the codebase-heavy dimensions; `general-purpose` for user-alignment and coherence if they need to reason. Each returns findings in `findings-format.md` shape.

Scale sensibly: a small plan may only warrant two agents (codebase-duplication + user-alignment); a large multi-phase plan warrants all four. Don't spawn agents with nothing to chew on.

## Synthesis

After the agents return, run one synthesis pass (the main session, or a final `general-purpose` agent) that:

1. **Dedupes** — collapse findings multiple agents raised into one, keeping the strongest evidence.
2. **Resolves conflicts** — if two agents disagree (e.g. "reuse X" vs "X doesn't fit"), surface both sides and take a position.
3. **Ranks** — order by severity, then by lens.
4. **Produces one clean list** — the only thing the user sees; the per-agent raw output stays behind the curtain.

## Caution

Keep parallelism bounded — 2–4 agents. This skill is read/review-only, so worktree isolation is unnecessary. Per the user's standing guidance, avoid spawning many heavy explore+write agents at once; these are read-only review agents, which is the safe case, but still cap at four.
