# Deep Skills

A **cross-assistant** plugin marketplace for the **Deep-\*** series — one set of skills that installs natively on **Claude Code, Codex, Cursor, and GitHub Copilot** (see [`plugins/deep-skills/HOSTS.md`](plugins/deep-skills/HOSTS.md)). A steerable, fresh-agent-resumable workflow that takes a feature from idea to verified code:

```
/deep-plan  ──▶  /deep-plan-review  ──▶  /deep-implement  ──▶  /deep-code-review  ──▶  /deep-docs
                                                                                        ▲
                                                            (deep-docs also runs standalone on any repo)
```

Plus a self-improving **directive loop** (in design): every `/deep-code-review` distills recurring issue classes into toggleable directive *cards* that the upstream skills load at runtime — so the same bug gets prevented earlier next time, without ever editing a skill by hand. See [`docs/roadmap/`](docs/roadmap/).

## What's in the box

One plugin, **`deep-skills`**, bundling **five** skills:

| Skill | Role |
|---|---|
| `/deep-plan` | Interactive feature planning → a self-contained, resumable plan artifact. Plan only. |
| `/deep-plan-review` | Independent, codebase-aware critique of a finished plan. Review only. |
| `/deep-implement` | Phase-by-phase execution: implement → validate → fix → commit → hand-off. |
| `/deep-code-review` | Multi-agent code review with severity-gated adversarial verification. |
| `/deep-docs` | Context-window-aware, tiered, anchor-verified map of what a codebase has built — for agents crawling under a token budget. Documents, never decides. |

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
| **Claude Code** | ✓ | ✓ | ✓ | `/plugin marketplace add reU/Deep-Skills` → `/plugin install deep-skills@deep-skills-by-reu` |
| **Codex** | ✓ | ✓ | ✓ | `codex plugin marketplace add reU/Deep-Skills` → `/plugins` → install ¹ |
| **Cursor** | ✓ | ✓ | ✓ | `/add-plugin deep-skills` (or Customize → Marketplace) ¹ |
| **Copilot CLI** | ✓ | gate ² | ✓ | `copilot plugin marketplace add reU/Deep-Skills` → `copilot plugin install deep-skills@deep-skills-by-reu` |
| **Copilot / VS Code** | ✓ | ⚠ sequential ² | ✓ | file-based: set `chat.agentSkillsLocations` → `plugins/deep-skills/skills` (no marketplace) |

```bash
# Claude Code (reference host)
/plugin marketplace add reU/Deep-Skills          # or: /plugin marketplace add /path/to/Deep-Skills
/plugin install deep-skills@deep-skills-by-reu
```

Update later with `/plugin marketplace update deep-skills-by-reu`.

¹ Manifest authored; the empirical capability gate (install + run a full cycle, confirm fan-out + model binding) is **pending** — see `HOSTS.md`. Fast-moving schema/command details are marked **RE-VERIFY** there.
² VS Code Copilot's docs show only **sequential** handoffs. If the gate confirms no parallel fan-out, the single-agent skills (`deep-plan`, `deep-implement`, `deep-docs`) run fully and the fleet skills (`deep-code-review`, `deep-plan-review`) route to a single-agent fallback on that host only.

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
