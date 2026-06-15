# Deep Skills

A Claude Code plugin marketplace for the **Deep-\*** series — a steerable, fresh-agent-resumable workflow that takes a feature from idea to verified code:

```
/deep-plan  ──▶  /deep-plan-review  ──▶  /deep-implement  ──▶  /deep-code-review
  produce         critique                execute               verify
```

Plus a self-improving **directive loop** (in design): every `/deep-code-review` distills recurring issue classes into toggleable directive *cards* that the upstream skills load at runtime — so the same bug gets prevented earlier next time, without ever editing a skill by hand. See [`docs/roadmap/`](docs/roadmap/).

## What's in the box

One plugin, **`deep-skills`**, bundling four skills:

| Skill | Role |
|---|---|
| `/deep-plan` | Interactive feature planning → a self-contained, resumable plan artifact. Plan only. |
| `/deep-plan-review` | Independent, codebase-aware critique of a finished plan. Review only. |
| `/deep-implement` | Phase-by-phase execution: implement → validate → fix → commit → hand-off. |
| `/deep-code-review` | Multi-agent code review with severity-gated adversarial verification. |

## Install

```bash
# 1. Add this marketplace (from GitHub once published, or a local path while developing)
/plugin marketplace add reU/Deep-Skills          # or: /plugin marketplace add /path/to/Deep-Skills

# 2. Install the bundle
/plugin install deep-skills@deep-skills-by-reu
```

Update later with `/plugin marketplace update deep-skills-by-reu`.

## Repo layout

```
Deep-Skills/
├── .claude-plugin/
│   └── marketplace.json            # marketplace catalog (offers the deep-skills plugin)
├── plugins/
│   └── deep-skills/
│       ├── .claude-plugin/
│       │   └── plugin.json         # plugin manifest
│       └── skills/                 # auto-discovered
│           ├── deep-plan/          # SKILL.md + references/ + templates/
│           ├── deep-plan-review/
│           ├── deep-implement/
│           └── deep-code-review/
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
