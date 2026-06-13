# Review dimensions (the two lenses)

Every `/deep-review` pass examines the plan through these lenses. In single-agent mode one agent covers both; in `--multi-agent` mode each numbered dimension below becomes its own fresh agent.

## Lens A — User alignment

Does the plan fit *this user*? Sources of truth: the memory directory's `MEMORY.md` and `feedback_*` memories, root `CLAUDE.md`, per-app `CLAUDE.md`/`Claude.md`, and decisions visible in the plan itself.

1. **Choice & preference** — does the plan contradict a stated choice or a recorded preference/feedback memory? (e.g. "prefer custom templates over built-ins", "never overwrite multi-phase plans".)
2. **Taste & style** — does the approach match how the user likes things done — naming, structure, conventions, tooling?
3. **Knowledge fit** — does it rely on something the user has said they avoid, or reinvent something they already have a preferred solution for?
4. **Coherence with prior decisions** — does it conflict with decisions made earlier in this plan or in related work?

## Lens B — Codebase alignment

Does the plan fit *this codebase*? Sources: the repo itself (explore it), `CLAUDE.md` / app guideline docs, existing patterns.

1. **Best-practices & conventions** — does it follow the repo's documented conventions and architectural norms (CLAUDE.md, app guideline docs, established layering)?
2. **Code patterns** — does it match how similar things are already built here, or introduce an off-pattern approach without justification?
3. **Duplicate behavior** — does it rebuild something that already exists? Name the existing implementation with its path.
4. **Overlapping behavior** — does it partially overlap an existing feature/utility in a way that should be consolidated rather than added alongside?
5. **Conflicts** — does it contradict, break, or fight existing behavior, contracts, or assumptions elsewhere in the codebase?

## What a good finding looks like

- Names the **lens** and dimension.
- Cites **evidence**: a plan section, a file path, or a named existing function/pattern.
- States the **impact** (why it matters) and a **concrete recommendation** (reuse X at `path`, follow pattern Y, drop step Z).
- Carries a **severity** (see `findings-format.md`).

Avoid manufacturing findings. If a lens is clean, say so.
