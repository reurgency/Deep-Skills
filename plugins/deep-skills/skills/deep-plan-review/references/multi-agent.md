# Multi-agent review (`--multi-agent` / `/multi-agent`)

Parallel review: one fresh agent per dimension, then a synthesis pass. Trades tokens for breadth and independence - four agents can't anchor on each other the way one agent's single pass can. Use for large or multi-phase plans, or whenever the user asks.

## Fan-out

Before fan-out, read `references/model-map.md` (rules) and `references/model-map.json` (data, merged with any `.deep-skills/model-map.json` repo override) and bind each agent's tier (the **Tier** column below) to a concrete full model ID, set explicitly at launch with the host's launch value (`references/model-map.md` § Host binding; never a host default or a guessed alias) - the model-routing correctness guarantee in `references/host-affordances.md` applies to every fleet. Tiers use the map's fleet notation: **`stage`** = this review's stage tier (`stages.<max>.plan-review`, where `--max` defaults to base's tier - SKILL.md § Flags); **`one down`** = one tier below it, floor `smart`. These tiers are judgment calls, not yet benchmarked the way deep-code-review's finder tiers are.

Launch the dimension agents **in parallel** - one message, multiple `Agent` tool calls - each with the plan text, its single dimension brief, codebase read access, and the user-preference pointers. None of them gets the planning transcript.

| Agent | Dimension brief | Tier |
|---|---|---|
| **codebase-duplication** | Lens B #3-#5: duplicate behavior, overlapping behavior, conflicts. Heavy codebase exploration; name existing implementations with paths. | one down |
| **patterns-and-practices** | Lens B #1-#2: best-practices, conventions, off-pattern approaches vs how the repo already does similar things. | one down |
| **user-alignment** | Lens A: choice, taste, style, knowledge fit, coherence - against memory/`feedback_*`/CLAUDE.md and the plan. | stage |
| **coherence-conflicts** | Internal consistency: the plan contradicting itself, its stated goals, or earlier decisions; ordering/dependency conflicts across phases. | one down |
| *synthesis (only when delegated to an agent)* | See § Synthesis. | stage |

**Why user-alignment stays on the stage tier:** it is the one dimension that judges taste and intent against the user's recorded preferences - the judgment the review exists for. The other three are codebase sweeps and internal-consistency checks, where one tier down is enough.

Use the `Explore` agent type for the codebase-heavy dimensions; `general-purpose` for user-alignment and coherence if they need to reason. **Pass the tier's model explicitly on every launch, including `Explore`** - a built-in agent type that carries its own default model (Claude Code's `Explore` defaults to a small model) must still run on the resolved model (`references/model-map.md` § Binding rules). Each returns findings in `findings-format.md` shape.

Scale sensibly: a small plan may only warrant two agents (codebase-duplication + user-alignment); a large multi-phase plan warrants all four. Don't spawn agents with nothing to chew on.

## Synthesis

After the agents return, run one synthesis pass (the main session - which runs on base, the session model - or a final `general-purpose` agent on the `stage` tier, model set explicitly) that:

1. **Dedupes** - collapse findings multiple agents raised into one, keeping the strongest evidence.
2. **Resolves conflicts** - if two agents disagree (e.g. "reuse X" vs "X doesn't fit"), surface both sides and take a position.
3. **Ranks** - order by severity, then by lens.
4. **Produces one clean list** - the only thing the user sees; the per-agent raw output stays behind the curtain.

## Caution

Keep parallelism bounded - 2-4 agents. This skill is read/review-only, so worktree isolation is unnecessary. Per the user's standing guidance, avoid spawning many heavy explore+write agents at once; these are read-only review agents, which is the safe case, but still cap at four.
