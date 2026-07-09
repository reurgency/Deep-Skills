# Deep Skills

A **cross-assistant** plugin marketplace for the **Deep-\*** series — one set of skills that installs natively on **Claude Code, Codex, Cursor, and GitHub Copilot** (see [`plugins/deep-skills/HOSTS.md`](plugins/deep-skills/HOSTS.md)). A steerable, fresh-agent-resumable workflow that takes a feature from idea to verified code:

```
/deep-plan  ──▶  /deep-plan-review  ──▶  /deep-implement  ──▶  /deep-code-review  ──▶  /deep-docs
                                                                  │         ▲             ▲
                                                                  ▼         │ (re-review)
                                                              /deep-bugfix ─┘   (deep-docs also runs
                                                                                  standalone on any repo)
```

Plus a self-improving **directive loop** (in design): every `/deep-code-review` distills recurring issue classes into toggleable directive *cards* that the upstream skills load at runtime — so the same bug gets prevented earlier next time, without ever editing a skill by hand. See [`docs/roadmap/`](docs/roadmap/).

## What's in the box

One plugin, **`deep-skills`**, bundling **six** skills:

| Skill | Role |
|---|---|
| `/deep-plan` | Interactive feature planning → a self-contained, resumable plan artifact. Plan only. |
| `/deep-plan-review` | Independent, codebase-aware critique of a finished plan. Review only. |
| `/deep-implement` | Phase-by-phase execution: implement → validate → fix → commit → hand-off. |
| `/deep-code-review` | Multi-agent code review with severity-gated adversarial verification. |
| `/deep-bugfix` | Diagnosis-first remediation of triaged findings (or any bug report / failing test): cluster by root cause, re-diagnose, fix minimally, prove the fix with a fresh adversarial agent, contain the blast radius. Fixes only. |
| `/deep-docs` | Context-window-aware, tiered, anchor-verified map of what a codebase has built — for agents crawling under a token budget. Documents, never decides. |

## Skill reference

Everything you can pass each skill (at invocation) and everything you can say while it runs (mid-session).

> **Natural-language-first.** Every `--flag` and `/command` below is a convenience on hosts that support them (Claude Code, Cursor). On **Copilot** and **Codex** you say the same thing in plain English — *"run a full multi-agent review,"* *"drill into the auth flow,"* *"refresh the docs."* The slash/flag form is never required.

### Arguments & inline flags

What each skill does with no argument, plus the flags it accepts at invocation.

| Skill | Argument / flag | What it does |
|---|---|---|
| `/deep-plan` | <feature/task> | The argument is the feature to plan. Fully interactive; no inline flags. |
| `/deep-plan-review` |  | Reviews the most recent plan (`.deep-skills/*/01-Plan/plan.md`); or pass an explicit plan path. |
| | `--multi-agent` | Parallel review — one fresh agent per dimension, then a synthesis pass. |
| `/deep-implement` |  | Implements the most recent plan; or pass an explicit plan path. |
| | `--autonomous` / `--collaborative` | Run unattended end-to-end, or pause for approval at each phase. (Asks if omitted on a multi-phase plan.) |
| | `--worktree` | Do the work in an isolated git worktree (default: the current branch). |
| | `--parallel` | Run provably-independent phases concurrently (falls back to sequential otherwise). |
| `/deep-code-review` |  | Reviews the current feature branch against the base it was cut from. |
| | *PR / file or folder paths* | Pass `PR65`, `#65`, or a PR URL to review a PR; pass file or folder paths to scope the review. |
| | `--multi-agent` | Full fleet review — eight model-tiered single-lens finders, adversarial verification of survivors, scripted synthesis into one report. |
| | `--mega` | Maximum review — every finder/verifier on the top model, quality caps lifted (~2× cost; for release gates). |
| | `--triage` | Opt-in pass over an existing review's findings (fix / defer / reject); routes accepted findings to `/deep-bugfix` (plan fix-phase as the fallback). The only mode that edits the plan. |
| | `--fix` | With `--triage`: chain straight into an autonomous `/deep-bugfix` run on the accepted findings (no-op with a pointer when `/deep-bugfix` isn't installed). |
| | `--browser` | Live last-mile checks against an already-running dev server (never starts one; never reads `.env`). |
| | `--security` | Reserved seam for a future `/deep-security` pass; inert until that skill ships. |
| `/deep-bugfix` |  | Fixes the latest triaged findings (the most recent `findings.json` with `accepted` findings). |
| | *findings.json / bug report / failing test* | Pass an explicit findings path, a pasted bug report / stack trace, or a failing-test reference. |
| | `--autonomous` / `--collaborative` | Run the whole defect list unattended with per-cluster green-only commits, or gate at each cluster. (Asks if omitted on a multi-cluster run.) |
| | `--reproduce` | Upgrade proof from static chain-trace to a red→green reproduction test, committed with the fix. |
| | `--worktree` | Isolate fix work in a git worktree (default: the current branch). |
| | `--learn` | Emit a per-round root-cause record (`round-N/root-causes.json`) for the future Deep-Learn Pattern Ledger. |
| `/deep-docs` |  | Documents the whole repo — the full tiered, anchor-verified pipeline. |
| | *\<path>* | Scope to a subsystem, or *"put the map under \<path>"* to relocate output from the default `docs/ai-map/`. |
| | `--refresh` | Re-resolve anchors + diff the file-set, then regenerate only the stale/new subsystems (no git required). |

### In-session commands

Say these any time *while a skill is running*; it services the command and returns to where it was. `/deep-implement` and `/deep-docs` have none.

| Skill | Command | What it does |
|---|---|---|
| `/deep-plan` | `/drill <note>` | Deepen the current question in-session (shared context), then resume. |
| | `/breakout <note>` | Hand a compact briefing to an isolated fresh subagent; return only its distilled answer (protects main context). |
| | `/gaps` | Run a gap-analysis round; surface gaps, conflicts, and assumptions as follow-up questions (repeatable). |
| | `/risks` | Produce a risk assessment of the emerging plan. |
| | `/constraints` | Suggest likely constraints and ask for yours; fold accepted ones into the plan. |
| | `/columbo` | Fresh-agent "one more thing" completeness gut check on the written plan. |
| `/deep-plan-review` | `/multi-agent` | Escalate the current review to parallel mode (same as the `--multi-agent` flag). |
| | `/columbo` | Optional fresh-agent completeness check — *"could a fresh agent execute this plan?"* |
| `/deep-code-review` | `/multi-agent` | Escalate the current review to the full fleet (same as the `--multi-agent` flag). |
| `/deep-bugfix` | `/skip-cluster` | Close the current cluster without fixing: revert its edits, leave statuses untouched, record it as skipped, move on. |
| | `/show-proof` | Print the current cluster's proof verdict with its full hop-by-hop chain (or test evidence). |
| | `/widen` | Escalate the current cluster's containment from 1 hop to 2 hops and re-run it. |

## Learn the skills

New to the Deep-\* series? Work through the **[Training Program](docs/Training/README.md)** —
an overall curriculum plus a hands-on page for each skill
([`/deep-plan`](docs/Training/deep-plan.md) ·
[`/deep-plan-review`](docs/Training/deep-plan-review.md) ·
[`/deep-implement`](docs/Training/deep-implement.md) ·
[`/deep-code-review`](docs/Training/deep-code-review.md)) with objectives, exercises, and
mastery checklists.

## Install

The same skills install natively on each host. Full commands, the capability matrix, and per-host caveats live in **[`plugins/deep-skills/HOSTS.md`](plugins/deep-skills/HOSTS.md)**.

| Host | Skills | Parallel fan-out | Per-agent model | Install |
|---|---|---|---|---|
| **Claude Code** | ✓ | ✓ | ✓ | `/plugin marketplace add reurgency/marketplace` → `/plugin install deep-skills@reurgency` |
| **Codex** | ✓ | ✓ | ✓ | `codex plugin marketplace add reurgency/marketplace` → `/plugins` → install ¹ |
| **Cursor** | ✓ | ✓ | ✓ | `/add-plugin deep-skills` (or Customize → Marketplace) ¹ |
| **Copilot CLI** | ✓ | gate ² | ✓ | `copilot plugin marketplace add reurgency/marketplace` → `copilot plugin install deep-skills@reurgency` |
| **Copilot / VS Code** | ✓ | ⚠ sequential ² | ✓ | file-based: set `chat.agentSkillsLocations` → `plugins/deep-skills/skills` (no marketplace) |

```bash
# Claude Code (reference host)
/plugin marketplace add reurgency/marketplace
/plugin install deep-skills@reurgency
```

Update later with `/plugin marketplace update reurgency`.

¹ Manifest authored; the empirical capability gate (install + run a full cycle, confirm fan-out + model binding) is **pending** — see `HOSTS.md`. Fast-moving schema/command details are marked **RE-VERIFY** there.
² VS Code Copilot's docs show only **sequential** handoffs. If the gate confirms no parallel fan-out, the single-agent skills (`deep-plan`, `deep-implement`, `deep-docs`) run fully and the fleet skills (`deep-code-review`, `deep-plan-review`, `deep-bugfix` — the latter fans out per-cluster diagnose+fix agents plus fresh proof agents) route to a single-agent fallback on that host only.

## Repo layout

```
Deep-Skills/
├── .claude-plugin/
│   └── marketplace.json            # marketplace catalog (offers the deep-skills plugin)
├── plugins/
│   └── deep-skills/
│       ├── .claude-plugin/plugin.json   # Claude Code manifest
│       ├── .codex-plugin/plugin.json    # Codex manifest        ┐ thin per-host manifests,
│       ├── .cursor-plugin/plugin.json   # Cursor manifest       ┘ one shared skills/ tree
│       ├── HOSTS.md                # per-host install + capability matrix + maintainer rules
│       ├── skills/                 # auto-discovered (the single source of truth)
│       │   ├── deep-plan/          # SKILL.md + references/ + scripts/ + templates/
│       │   ├── deep-plan-review/
│       │   ├── deep-implement/
│       │   ├── deep-code-review/
│       │   ├── deep-bugfix/
│       │   └── deep-docs/
│       └── directives/             # Deep-Learn registry — sibling of skills/ so the
│                                   #   self-locating loader resolves it on every host
├── docs/
│   └── roadmap/                    # self-learning directive-loop design notes
└── README.md
```

## Development

- **Validate before distributing:** `claude plugin validate .`
- **Versioning:** `plugin.json` pins `version`. While iterating, you can *remove* the `version` field so every commit auto-updates installs (Claude Code falls back to the git commit SHA); for releases, bump semver and tag.
- **Dogfooding:** developed and exercised against the Maûdel codebase; run artifacts (`.deep-skills/<feature>/…`) live in the *target* repo, not here.

## License

MIT
