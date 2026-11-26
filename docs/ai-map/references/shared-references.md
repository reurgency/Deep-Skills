# shared-references - model resolution trace

<!-- GENERATED - do not hand-edit; regenerate overwrites. Source: deep-docs. -->
<!-- tier-2 deep reference. Paths below are under plugins/deep-skills/skills/deep-code-review/references/. -->

## Flow 1: --max to a recorded model

1. Base = session model; matched against every ladder list (case/space/hyphen-insensitive, suffix ignored); unknown -> smart + warning - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:52 (Base-tier lookup)`
2. Default `--max` = base tier; stage tier = `stages.<max>.<stage>` from the merged JSON - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:73 (--max)`; `plugins/deep-skills/skills/deep-code-review/references/model-map.json:12 ("stages")`
3. Merge: shipped JSON, then `.deep-skills/model-map.json` (validated), unless a named snapshot replaces both - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:138 (Repo override)`; `plugins/deep-skills/skills/deep-code-review/references/model-map.md:136 (## Repo override)`
4. Agent tier = stage / one down / two down / max (floor smart), taken in base's family - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:88 (Fleet notation)`; `plugins/deep-skills/skills/deep-code-review/references/model-map.md:29 (Column = base's family)`
5. Candidate order: current gen, previous gen, step down a tier, else collapse up; try-and-fall-back, never pre-guess - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:101 (Access fallback)`; `plugins/deep-skills/skills/deep-code-review/references/model-map.md:111 (Detection is try-and-fall-back)`
6. Launch value: Claude Code = family word of ID (never haiku); others = full ID - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:119 (Host binding)`
7. Brief ends with `MODEL:` line, stripped before parsing the output format - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:122 (Model report)`
8. Reported != resolved: alias host classifies at once; exact-ID host relaunches once (rule 5) then classifies: same tier valid, lower valid only if next fallback, higher valid only if <= `--max`, small/off-ladder = candidate inaccessible (off-ladder output set aside for step 5) - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:128 (Binding rules)`; `plugins/deep-skills/skills/deep-code-review/references/model-map.md:126 (Verified-ID classification)`
9. Run header records `Base · Max · Models`, with `(fallback from)` / `(host substituted for)` / `(unverified ...)` notes - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:113 (Record the model actually used)`

## Flow 2: override, snapshot, and sync

1. Repo owner edits sparse override; ladder list replaces whole, stage value singly - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:148 (Merge at key granularity)`
2. Each skill validates at launch (six rules) and refuses with key, file and valid values - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:154 (Validate at launch)`; maintainers' mirror of the rules in Python - `scripts/check-shared.sh:75 (validate_model_map)`
3. deep-goal freezes the merged map to `00-Manifest/model-map.resolved.json` and names it to stages; stages skip re-merge - `plugins/deep-skills/skills/deep-code-review/references/artifact-structure.md:68 (Add-on extensions)`; `plugins/deep-skills/skills/deep-code-review/references/model-map.md:136 (## Repo override)`
4. Maintainer release: edit canonical ladder, `check-shared.sh --sync`, `--all` - `plugins/deep-skills/skills/deep-code-review/references/model-map.md:169 (Updating for a new release)`
