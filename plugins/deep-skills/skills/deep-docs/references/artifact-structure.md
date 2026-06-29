# Artifact structure — the `.deep-skills/` convention

> **Series-shared reference.** This file is copied **verbatim** into every deep-* skill's `references/` directory (the series standalone rule forbids cross-skill references). All copies must stay byte-identical, or be intentionally marked divergent at the top of the changed copy. A series consistency sweep verifies this.

All deep-* skills read and write their **artifacts** under the host project's `.deep-skills/` directory, one subdirectory per effort. **Skills** themselves stay wherever they are installed (e.g. `.claude/skills/`); only artifacts live here.

## Directory layout

```
.deep-skills/<effort-name>/
  00-Manifest/        manifest + summary + status for the effort
  01-Plan/            deep-plan output
  02-Plan-Review/     deep-plan-review output
  03-Implementation/  deep-implement work summary + acceptance check-off
  04-Code-Review/     deep-code-review report, findings.json, certificate
  05-Security/        deep-security artifacts (future effort)
  06-Bug-Fix/         deep-bug-fix report + fix artifacts (when that skill ships)
  07-Docs/            deep-docs pointer → in-repo docs/ai-map/ (the canonical map output)
  08–09               reserved
```

Canonical file names per stage:

- `01-Plan/plan.md` — the plan document (deep-plan).
- `02-Plan-Review/review.md` — the full review report (deep-plan-review).
- `03-Implementation/summary.md` — work summary + acceptance check-off (deep-implement).
- `04-Code-Review/report.md`, `findings.json`, `certificate.md` — code review artifacts (deep-code-review).
- `06-Bug-Fix/report.md` — root-cause + fix record (deep-bug-fix, when that skill ships).
- `07-Docs/` — in effort mode, a **pointer** to the canonical in-repo `docs/ai-map/` (deep-docs writes the map to `docs/ai-map/`, not into the effort dir): `MAP.md`, `index.json`, `subsystems/`, `references/`, `coverage.md`, `learn-signal.json`.

## `00-Manifest/manifest.md` format

One status line per stage, each linking to that stage's artifacts:

```markdown
# <effort-name>

| Stage | Status | Artifact |
|---|---|---|
| 01 Plan | <pending | in progress | complete> | [plan.md](../01-Plan/plan.md) |
| 02 Plan Review | <pending | in progress | complete> | [review.md](../02-Plan-Review/review.md) |
| 03 Implementation | <pending | in progress | complete> | [summary.md](../03-Implementation/summary.md) |
| 04 Code Review | <pending | in progress | complete> | [report.md](../04-Code-Review/report.md) |
| 06 Bug Fix | <pending | in progress | complete> | [report.md](../06-Bug-Fix/report.md) |
| 07 Docs | <pending | in progress | complete> | [docs/ai-map/](../../docs/ai-map/) |

<one-paragraph effort summary>
```

Each skill updates its own stage's status line (and the summary, if it changes the picture) when it finishes.

## Manifest creation rule

**Any deep-* skill creates `00-Manifest/manifest.md` if it is absent** when the skill first writes to the effort directory. Manifest creation is *not* deep-plan-exclusive — a mid-series entry (e.g. reviewing code on a branch that never had a deep-plan) creates the manifest itself, with earlier stages marked `pending` or `n/a`.

## Effort-name rules

- `<effort-name>` is a **kebab-case slug**.
- **deep-plan** proposes the slug derived from the feature name; the **user confirms** (or supplies their own) before anything is written.
- **Mid-series entry without a plan** (any other deep-* skill starting fresh): ask the user for the effort name, **defaulting to the current branch name** (slugified).

## Legacy note

Pre-retrofit plans (e.g. under `~/.claude/plans/`) remain reachable via an **explicit path argument** to any deep-* skill. Only the *defaults* moved to `.deep-skills/`; explicit paths are always honored.
