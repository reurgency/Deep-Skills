# Intake — three input modes, one defect list

Every run starts by normalizing whatever the user brought into a **uniform defect list**, so clustering, diagnosis, and proof never care where a defect came from.

## The three input modes

| Invocation | Source |
|---|---|
| `/deep-bugfix` (no args) / "fix the triaged findings" | The most recent `.deep-skills/*/04-Code-Review/findings.json` containing `accepted` findings (explicit path always honored) |
| A pasted bug report / stack trace / "users report X breaks" | The report text itself |
| A failing-test reference ("`foo.test.ts` is red", a CI failure) | The test file + its captured failure output |

## The normalized defect shape

Field names mirror `finding.json` (deep-code-review's machine shape) so findings pass through **losslessly** — no remapping, no information dropped:

```json
{
  "id": "CR-001 | BF-001",
  "source": "findings | report | test",
  "severity": 7,
  "tier": "Major",
  "title": "one line, concrete",
  "evidence": { "path": "...", "line": 88, "symbol": "...", "observed": "..." },
  "recommendation_hypothesis": "the review's (or reporter's) suggested fix — carried as a HYPOTHESIS, never a spec"
}
```

- **findings.json mode:** copy `id`, `severity`, `tier`, `title`, `evidence` verbatim; the finding's `recommendation` lands in `recommendation_hypothesis` — renamed deliberately, so every downstream brief sees it labeled as the untrusted guess it is.
- **Raw report / failing test:** synthesize sequential ids `BF-001, BF-002, …` (stable within the run; recorded in `scope.json`). Extract `evidence` from the trace — the failing frame's `path:line`, the named symbol, the observed behavior (the assertion diff, the error message, the reported symptom). `severity`/`tier` are optional here — set them only when the report supports a judgment; clustering and proof do not require them (an unset severity gates proof to the high tier, per `references/model-map.md` — when in doubt, prove hard).
- A defect that arrives with no locatable evidence at all (a vague report) is not silently accepted: ask the user for a reproduction pointer, or record the diagnosis step as starting from symptom-search.

## Scope rules — what enters the round

- **Series mode (accepted findings exist):** load exactly the `accepted` set. Triage already decided; **never re-ask, never widen** into `open`/`deferred`/`rejected`. Already-`fixed` findings are excluded automatically — the duplicate-run guard that makes re-entry idempotent.
- **Only `open` findings exist** (review ran, triage didn't): present an interactive **scope pick**, findings grouped by tier (Blockers first), via the host's structured-question affordance or its numbered-list fallback (`references/host-affordances.md`). **Selection is scoping, not triage** — say so when asking. Selected findings enter the round; unselected findings keep status `open`, untouched.
- **No effort exists** (standalone bug report / failing test, mid-series entry): ask the user for an effort name, **defaulting to the slugified current branch name**; create `.deep-skills/<effort>/` and `00-Manifest/manifest.md` (any deep-* skill owns manifest creation on first write — see `references/artifact-structure.md`).

## Round start — persist `scope.json` before any cluster work

At round start (after the re-entry check in `references/commit-and-handoff.md`), write the round's resume record to `.deep-skills/<effort>/06-Bug-Fix/round-N/scope.json`:

```json
{
  "round": 1,
  "started": "<YYYY-MM-DD>",
  "source": "<findings.json path | report | test>",
  "defects": [ { "...": "the full normalized defect list selected for this round" } ],
  "clusters": [
    { "cluster_id": "CL-1", "defect_ids": ["CR-001", "CR-002"], "suspected_cause": "one line", "status": "planned" }
  ]
}
```

`defects` is the selection; `clusters` is the **provisional** cluster plan (clusters are hypotheses — splits/merges during diagnosis are appended as updated entries, never rewritten over). This file is what makes a crashed run recoverable: statuses alone cannot reconstruct scoped-in `open` findings or synthesized `BF-*` defects. Resume = `scope.json` minus defects already `fixed`.
