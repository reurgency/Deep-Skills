<!-- Slim next-phase hand-off. Appended to the plan (and optionally .maudel/handoffs/active/). Keep it short — the plan holds the detail. -->

### Hand-off → Phase <N+1>: <next phase title>

- **State:** Phase <N> complete and <committed @ short-sha | staged>. Branch: `<branch>`. Worktree: `<path or none>`.
- **What just landed:** <1–3 lines: files + behavior added in phase N>
- **Contract / interfaces to honor:** <shared types, endpoints, signatures the next phase depends on — with paths>
- **Start here:** <the first concrete action of phase N+1>
- **Watch out for:** <gotchas discovered, pre-existing noise to ignore, deferred items touching this area>
- **Validation to run:** <commands the next phase must pass>
