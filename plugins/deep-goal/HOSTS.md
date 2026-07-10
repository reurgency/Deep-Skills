# Hosts & distribution — deep-goal (paid add-on)

deep-goal is a **paid add-on** to the deep-skills plugin: one skill body (`skills/deep-goal/SKILL.md` + `references/` + `scripts/` + `templates/`), thin per-host manifests (`.claude-plugin/`, `.codex-plugin/`, `.cursor-plugin/`), never forked per host — the same packaging rules as its sibling (`plugins/deep-skills/HOSTS.md`). It **requires the deep-skills plugin ≥ 0.2.0 installed alongside** on every host; the launch version handshake (`skills/deep-goal/SKILL.md` § Launch) verifies this and refuses politely when it's absent or below minimum. Core never requires deep-goal back — coupling is strictly one-directional.

> **The host floor, stated plainly: Claude Code is the designed-and-verified floor.** The conductor's dispatch model — one fresh background subagent per autonomous stage, briefed with a rendered `stage-briefing.md` as its entire prompt — assumes Claude Code's subagent affordances. On **Codex, Cursor, and Copilot** deep-goal degrades to **inline sequential execution** (below): functional, honestly caveated, not yet gate-verified. If your pipeline matters, run it on Claude Code.

## The vendoring invariant (unchanged from core)

The Deep-Learn directive loader (`skills/deep-goal/scripts/load-active-cards.sh`) is **byte-identical to the six core copies** and self-locating: it resolves `skills/deep-goal/scripts/ → ../../../directives/cards/active` relative to its own file. The installed unit must therefore keep `skills/` and `directives/` as **siblings under this plugin root** — which is exactly why every per-host manifest lives inside `plugins/deep-goal/`. deep-goal reads only its **own** registry (empty in v1); it never reads the core deep-skills registry (cross-registry cards are a tracked deferred). Non-shell hosts: apply cards by hand per the core rule (`plugins/deep-skills/HOSTS.md` § vendoring invariant).

## Capability matrix (conductor-relevant; ✓ = designed/verified, ⚠ = degrade, gate = verify empirically)

| Capability | Claude Code | Codex | Cursor | Copilot / VS Code |
|---|---|---|---|---|
| `SKILL.md` skills (this skill loads) | ✓ | ✓ gate | ✓ gate | ✓ gate |
| **Per-stage fresh-subagent dispatch** | ✓ | ⚠ inline sequential | ⚠ inline sequential | ⚠ inline sequential |
| Structured questions (rigor selection, gates, resume/fresh) | ✓ `AskUserQuestion` | ⚠ numbered-list chat fallback | ⚠ numbered-list chat fallback | ⚠ numbered-list chat fallback |
| Notifications (halts, gates, budget pauses, completion) | ✓ `PushNotification` | ⚠ `osascript` → bold `ATTENTION:` line | ⚠ same fallback chain | ⚠ same fallback chain |
| deep-skills discovery for the version handshake | ✓ `~/.claude/plugins/installed_plugins.json` | ⚠ sibling-install check (RE-VERIFY) | ⚠ sibling-install check (RE-VERIFY) | ⚠ checkout-relative (CLI: same as Claude Code) |
| Artifact writes (`.deep-skills/**`, `pipeline.md`) | ✓ | ✓ | ✓ | ✓ |

Per-host discovery details live in `skills/deep-goal/references/conductor.md` § 1a. The stages deep-goal dispatches inherit their own host caveats from core — e.g. the fleet skills' single-agent fallback on Copilot/VS Code (`plugins/deep-skills/HOSTS.md` § capability matrix); deep-goal adds no requirement beyond what each core skill already needs on that host.

## Degradation: inline sequential execution (Codex / Cursor / Copilot)

On hosts without Claude Code's fresh-subagent dispatch, only the dispatch **mechanism** changes (`references/conductor.md` § 8) — the protocol does not:

- **Same stage order, same briefings, same advance tests, same `pipeline.md` records.** Each stage's rendered briefing is executed **inline in the main session, one stage at a time**, and the conductor still verifies artifacts + manifest flips before advancing. Resume, gates, budget checks, and the run report all work unchanged — they read `pipeline.md` and artifacts, not session state.
- **Honest caveat #1 — context.** Everything shares one context window. yolo/poc runs are comfortably inside it; **mvp and especially prod-rigor runs (multi-agent reviews × re-review rounds) may hit context limits** before the pipeline completes.
- **Honest caveat #2 — independence.** The series' fresh-eyes guarantee is weakened inline: a reviewer running in the same session has the upstream stages' history in context. The core skills' own sub-agent fan-out (where the host supports it) restores part of this, but the stage-level isolation Claude Code provides is not replicated.
- **The workable mitigation today:** `pipeline.md` makes every stage boundary a clean re-entry point — you can **end the session at a boundary and re-invoke deep-goal in a fresh session**; it resumes at the first incomplete stage with gates/budget/worktree intact. That manual per-stage restart recovers both fresh context and fresh eyes.
- **The documented deferred:** formal per-stage session-restart guidance (and full four-host parity for the fallback) is a tracked deferred — the conductor isolates dispatch behind one protocol section precisely so the fallback can replace only that section per host. None of these hosts has passed an empirical gate for deep-goal yet; treat all three as **functional, unverified**.

## Per-host install

Every install needs **both** plugins from the same store: deep-skills first (or already present), then deep-goal.

### Claude Code (reference host — shipped)
```
/plugin marketplace add reurgency/marketplace
/plugin install deep-skills@reurgency      # if not already installed (≥ 0.2.0)
/plugin install deep-goal@reurgency
```

### GitHub Copilot — CLI (reuses the Claude marketplace)
```
copilot plugin marketplace add reurgency/marketplace
copilot plugin install deep-skills@reurgency
copilot plugin install deep-goal@reurgency
```
Runs the inline-sequential fallback; structured questions and notifications use the chat fallbacks.

### Codex (manifest authored — gate pending)
Install both plugins from the store per `plugins/deep-skills/HOSTS.md` § Codex (RE-VERIFY the exact marketplace subcommand). Manifest: `plugins/deep-goal/.codex-plugin/plugin.json`. Inline-sequential fallback.

### Cursor (manifest authored — gate pending)
Install both plugins per `plugins/deep-skills/HOSTS.md` § Cursor (`/add-plugin` — RE-VERIFY; local dev: copy `plugins/deep-goal/` into `~/.cursor/plugins/local/deep-goal/`). Manifest: `plugins/deep-goal/.cursor-plugin/plugin.json`. Inline-sequential fallback.

### GitHub Copilot — VS Code editor (file-based; no marketplace)
Point `chat.agentSkillsLocations` at **both** `plugins/deep-skills/skills` and `plugins/deep-goal/skills` from one checkout of this repo (the handshake then finds deep-skills checkout-relative — `references/conductor.md` § 1a). Inline-sequential fallback + the no-shell directive fallback.

> **Distribution note:** deep-goal currently ships from the public `reurgency/marketplace` store; at launch, distribution may move to a **private channel** — the plugin boundary makes that a folder move, with nothing above changing except the marketplace-add line.

## Maintainer rules (inherited, plus one)

The core maintainer rules apply verbatim (`plugins/deep-skills/HOSTS.md` § Maintainer rules): one source of truth per skill body, byte-identical shared files, no Claude-only affordance at a call site, frontmatter discipline, M3 gate before committing a host. deep-goal adds one:

6. **`references/artifact-structure.md` is the seventh copy.** Any canonical edit to the series artifact contract is swept across **all six core copies + deep-goal's copy**, `cmp`-verified pairwise. Same for `references/host-affordances.md` and `scripts/load-active-cards.sh` (deep-goal's is the seventh byte-identical copy of each).
