# Browser verification (`--browser`) — live last-mile evidence

`--browser` escalates the last-mile lens from static tracing to **observation**: exercise the plan's promised behaviors in the actually-running app and watch the real network traffic. Its findings are the strongest evidence the review can produce — what was *seen*, not what was *inferred*.

## Hard rules (non-negotiable)

1. **Never start a dev server.** Not "start one if missing" — never. Starting servers collides with the user's running processes, ports, and watchers. `--browser` requires an **already-running** server on a project-configured port. If no running server is found, **skip browser verification gracefully**: say so in the report, fall back to static last-mile tracing, and recommend the user re-run with the server up. Do not start, restart, or stop anything.
2. **Never read `.env` or any secrets file to discover the port** (or anything else). Discover the port from, in order: **package.json scripts** (serve/dev/start commands often carry `--port`), **angular.json** (or the framework's equivalent serve config), **CLAUDE.md / project docs**. If none of those yields it, **ask the user** — never guess and never open `.env`.

   *Host-project discovery example — explicitly not skill behavior:* in the repo this skill was developed in, discovery via CLAUDE.md/docs yields UI on `4200` and API on `5200`, both reserved for the host app there. Those numbers mean nothing anywhere else; the skill carries **no** port numbers, only the discovery procedure.
3. **Confirm before mutating.** Promised behaviors often include writes — that's legitimate verification — but exercise mutating flows only against disposable/dev data and **ask the user before any interaction that mutates state they might care about; never exercise destructive flows (deletes, irreversible transitions) without explicit approval.** Read-only flows (navigation, loads, expansions) need no confirmation.

## Preflight

1. Discover the configured port(s) per rule 2.
2. Probe the server (a simple HTTP GET to the discovered URL). Responding → proceed. Not responding → rule 1's graceful skip.
3. State what's being verified against what: `Browser verification against http://localhost:<port> (already running)`.

## Flow

1. **Enumerate the promised behaviors** — the same checklist `references/last-mile.md` Step 1 builds (plan phases' Goals/Steps/Acceptance + Verification section; PR description/commits in no-plan mode). Prioritize the behaviors static tracing left in doubt — runtime wiring, timing, real payload shapes — then key user-facing flows.
2. **Exercise each behavior via browser tools** — navigate to the page, snapshot to locate the affordance, click / fill / select exactly as a user would. Drive the *behavior*, not the DOM: if the plan promises "saving a track persists it," click the actual Save button rather than calling the API directly — the point is verifying the whole chain including the UI hop.
3. **Watch the real network requests.** After each interaction, read the browser's network log and confirm the promised call **actually fired** — URL, method, status — and that the payload/response shapes match the contract (shared types, API handler expectations). This is where the named failure modes die or get caught: optimistic UI with no real call shows an interaction with **no** request; contract drift shows a request whose payload doesn't match what the handler reads.
4. **Verify the complete behavior on screen** — after the response, snapshot again: did the UI reach the promised state (list refreshed, status flipped, error surfaced)? A 200 response with a stale UI is still a last-mile finding.
5. **Close the browser** when done.

## Evidence: observed, never inferred

Browser findings feed the **last-mile lens** and use the standard finding shape with the evidence in **`evidence.observed`**, citing exactly what was seen:

- A verified behavior: `observed: "Clicked 'Save Track' → POST /api/tracks → 201; response body included id+updatedAt; track list re-rendered with the new row"`.
- A gap: `observed: "Clicked 'Save Track' → no network request fired within 5s (network log empty); UI showed success toast regardless"` — optimistic UI, severity per `references/findings-and-severity.md` (a severed promised behavior is Blocker territory).
- Contract drift: `observed: "POST /api/tracks payload used {trackName}; handler reads body.name (apps/api/.../tracks.ts:31) — field arrives undefined, row persisted with null name"` — pair the observed request with the static evidence.

The rule: **cite the request URL, method, status, and relevant payload/response shape as observed.** "The save probably doesn't hit the API" is not browser evidence; the network log line that isn't there is. Verified-clean behaviors are recorded too (the trace summary in the report's evidence), per last-mile's clean-verdict rule.
