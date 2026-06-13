# Code Review Design Notes

## Eco-Version v3
⏺ The efficiency redesign is implemented in the deep-code-review skill, mirrored, and memory is updated. Here's what changed:
 
 Skill changes (in Maudel/.claude/skills/deep-code-review/, rsync-mirrored to .agents/ and verified identical):
 - references/multi-agent.md — rewritten around five stages. 
 
 New Stage 0 (scripted setup): diff pre-chunking into per-file chunks + index (finders never ingest the monolithic diff), pre-pass launched in parallel with the finder fleet, and verifier fact pre-harvest. 
 
 Stage A is now eight finders with model tiering: removed-behavior/seam-trace/last-mile plus the new frozen-state-probe on the main model (Fable 5), diff-scan/conformance/coherence on the mid tier (Opus 4.8), quality on the cheap tier (Sonnet) capped at sev ≤4. 
 
 Stage C: sev-5 verifiers on Sonnet with a main-model re-check before any upward raise stands, sev ≥6 on the main model, one streamed wave off the merge instead of batched waves, and a required fixed VERDICT/SUB-CLAIMS/SEVERITY/RATIONALE format. 
 
 Stage D: findings.json, rollup, funnel line, nit table, and certificate scaffold are script-assembled; the model writes only judgment and per-finding prose. The "finders pile up at sev 5" problem also got a direct countermeasure: any sev-5 proposal must justify why it isn't a 4.
  - New --mega flag — the measured-baseline configuration (everything on the main model, quality cap lifted) preserved as the thorough tier; the tuned pipeline is now the default --multi-agent. The scripted stages stay in mega since determinism costs no accuracy.
  - New frozen-state-probe lens in references/dimensions.md — a four-step probe method (enumerate frozen values → pin the concrete value → probe every surviving reader at exactly that value → cite the probed chain, no-chain-no-finding). It directly targets the two blind spots that survived every benchmark run (orphaned enabled=0, subset-template clearing).
  - references/deterministic-prepass.md — parallel scheduling under multi-agent, plus scripted base-vs-head attribution: two worktrees run concurrently, outputs normalized, failure lists diffed by script (the thing that cost an agent ~13 minutes and 4+ suite runs in the eco run).
   - SKILL.md, findings-and-severity.md, and both templates updated to match (eight passes, new dimension id, sev-5 justification rule, script-assembly notes). finding.json still validates; no stale "seven-pass" references remain; SKILL.md is at 87 lines.
 
 Memory — pr65-review-benchmark.md now carries the measured numbers (9.18M weighted / 33% / 39m53s / ~280k per limit-point / rematch real ≈14.6M) and the redesign record; the token-discipline memory and MEMORY.md index reflect the new tiering and the dedupe-by-message.id forensics method.

 Still open from the snapshot's carried-over list (untouched today): comparisons.md's old 48/55 labels, triage of the 36 open PR-65 findings, CR-001 fix-phase execution, and the CR-004 repo-hygiene fix that would cheapen every future pre-pass. The natural next step for the redesign itself is a blind validation run against PR #65 to check the ~17–20 min / 16–20% projection — and whether frozen-state-probe finally lands rows 3 and 7.

## Eco-Version v2: the multi-agent upgrade

⏺ Done — the deep-code-review skill's --multi-agent mode is now the finder-fleet + adversarial-verification process, applied to both copies (.claude/skills/ and .agents/skills/, verified identical).
 What changed:
 - references/multi-agent.md (rewritten) — four-stage pipeline: (A) ten independent single-lens finder passes (the 7 fab-solo lenses plus the 3 fab-deep-only lenses it lacked: last-mile, plan/PR conformance, coherence), read-only, batched at the new cap of 8, with an explicit overgenerate rule (no self-filtering, no finding caps); (B) dedup with the new converse split rule — N independent fixes → N findings, and defects cited as evidence get filed separately (the bug-execute-stub case); (C) adversarial verification — a fresh verifier per candidate briefed to refute it, sub-claims verified independently, severity checked by counting user-reachable trigger paths, verdicts confirmed/plausible/refuted; (D) synthesis into one report, refuted candidates kept in an auditable appendix. - references/dimensions.md — full hunt-list briefs for the two genuinely new lenses: removed-behavior (orphaned persisted state, deleted affordances with no new home — what found the orphaned enabled=0) and seam-trace (write-path→read-path layer tracing, cache invalidation, unguarded reads — what found fork-vs-default and the unguarded JSON.parse). - references/deterministic-prepass.md — closes fab solo's only real miss: the pre-pass must run the test suite as one combined invocation, not only per-file, and file combined-run failures as findings (the "closed database" class of bug). - references/findings-and-severity.md + templates — verification field on findings, trigger-path severity calibration (the rule behind the correct 9-vs-7 gating rating), report template gets a verification funnel line and the refuted-candidates appendix. - SKILL.md — flag/command descriptions updated; new guardrail: finders overgenerate, verification owns precision. Note one behavior change: under --multi-agent the combined single-agent pass no longer runs additionally — its four lenses run as independent finders, which removes the anchoring problem.
 Static checks pass: mirror identical, SKILL.md at 86 lines, all cross-references resolve, no stale "cap 4"/"four dimensions" text, finding.json still valid JSON. The default single-agent review is untouched, as you chose.
 The real test would be a benchmark rematch — re-run /deep-code-review --multi-agent PR65 in the Maudel repo and score it against the 24-row matrix (expect fab solo's 8 uniques and fab deep's 6). It's a token-heavy run, so I've left it for you to trigger when you want it.

✻ Crunched for 10m 49s

※ recap: Goal: upgrade the deep-code-review skill's --multi-agent mode to fab-solo's finder-fleet plus adversarial-verification process  while keeping fab-deep's lenses. All edits are done and verified in both skill copies. Next action: rerun the PR #65 benchmark if you want proof. (disable recaps in /config) 
❯ Run the benchmark rematch on PR65                                                                                                         

⏺ The rematch means executing the upgraded --multi-agent process against PR #65 in the Maudel repo, then scoring the output against the 24-row matrix. First, setup: resolve the PR scope and prepare a clean checkout of the PR head for the agents and the pre-pass.

--------------

⏺ Workflow(Run 10 independent single-lens code-review finder passes over PR #65 (deep-code-review --multi-agent Stage A)) ⎿  Running in background · /workflows to monitor and save

⏺ The finder fleet is running in the background (10 read-only single-lens agents over PR #65, blind to all prior reviews). I'll continue when it completes.
 Status so far:
 - Scope: PR #65 head 6879399 in an isolated worktree; full 15k-line diff and PR description captured for the agents. - Pre-pass results (deterministic, before any agent): UI typecheck clean; API typecheck errors are pre-existing config noise (300 on base vs 302 on head, same rootDir class). The combined-suite rule already paid off: the PR's three new track test files pass solo (28/28) but fail with RangeError: Cannot use a closed database at pipeline.service.ts:204 when the whole suite runs together — that's the finding fab solo missed last time, now caught deterministically. The broader suite is heavily broken on the base too (~226 pre-existing failures), which will be noted as pre-existing, not attributed.
 Next, when the finders return: dedup/split in the main session, then the adversarial verifier fan-out, then synthesis and scoring against the 24-row matrix.

----

Waiting for 1 dynamic workflow to finish

※ recap: Benchmark rematch of the upgraded multi-agent deep-code-review on PR #65: pre-pass done, 10 finder agents are running in the  background now. Next, I dedup their candidates and launch adversarial verifiers, then synthesize and score against the comparison matrix.  (disable recaps in /config)  background now. Next, I dedup their candidates and launch adversarial verifiers, then synthesize and score against the comparison matrix. (disable recaps in /config)

⏺ Dynamic workflow "Run 10 independent single-lens code-review finder passes over PR #65 (deep-code-review --multi-agent Stage A)" completed
· 17m 42s

⏺ The finder fleet is done — 10 passes, ~1.7M tokens of search. Let me pull the full candidate list and start Stage B (dedup + decomposition).

⏺ Bash(python3 -c "     import json,re…) ⎿  == diff-scan: 16 candidates      [diff-scan-0] sev7: Runtime stage gating ignores template inheritance — Save-as-template / reset-to-inherited silently disables    Re    … +117 lines (ctrl+o to expand)

⏺ 113 raw candidates across 10 passes — strong overgeneration. Now Stage B: I'll save the pool to a working file and inspect the clusters that need merge/split decisions.


⏺ Workflow(Adversarially verify 86 deduped PR-65 review findings with refute-by-default verifiers (deep-code-review --multi-agent StageC)) ⎿  ✘ Failed in 0s

⏺ Dynamic workflow "Adversarially verify 86 deduped PR-65 review findings with refute-by-default verifiers (deep-code-review --multi-agent ⎿  /workflows to view dynamic workflow runs

⏺ Dynamic workflow "Adversarially verify 86 deduped PR-65 review findings with refute-by-default verifiers (deep-code-review --multi-agent
Stage C)" failed: Error: undefined is not an object (evaluating 'fs.filter')   at &lt;anonymous&gt; (workflow.js:42:16)   at workflow.js:67:1275   at runInContext (native)   at T0K (/$bunfs/root/src/entrypoints/cli.js:3682:6115)   at processTicksAndRejections (native) · 0s

---

⏺ The verification stage is now running — 26 individual verifiers for the severity ≥4 findings plus 12 grouped verifiers covering the 60 smaller items (38 agents total, refute-by-default). I'll synthesize the report and score against the matrix when it completes. ⎿  Stop says: ⚠ Context at 106% of the 200k window (threshold 75%). Consider running /overton-snapshot to checkpoint this session before     auto-compaction.

✻ Waiting for 1 dynamic workflow to finish    
※ recap: Benchmark rematch of the upgraded multi-agent code review on PR #65: pre-pass and 10 finder passes are done (113 candidates,  deduped to 86), adversarial verification agents are running now. Next: synthesize the report and score it against the 24-row matrix.  (disable recaps in /config) 
⏺ Dynamic workflow "Adversarially verify 86 deduped PR-65 review findings with refute-by-default verifiers (deep-code-review --multi-agent
Stage C)" completed · 15m 39s    
⏺ Verification complete — 38 verifiers, all 86 findings judged. Now Stage D: synthesis and scoring.

⏺ Bash(python3 << 'EOF'     import json…)

⏺ Bash(python3 << 'EOF'     import json…) ⎿  counts: {'confirmed': 84, 'plausible': 0, 'refuted': 2} total verdicts: 86    missing verdicts: []    … +7 lines (ctrl+o to expand)

⏺ 84 confirmed, 2 refuted. Checking the refutation rationales before synthesis:

⏺ Bash(python3 -c "     import json…) ⎿  ====================================================================================================    V-020 refuted sev_final 2    RATIONALE: Zero user-reachable trigger paths today: the lost-update interleaving requires either an await inside the read-merge-wr    … +29 lines (ctrl+o to expand)

---

⏺ The rematch is done, and the upgraded skill won the benchmark: 20 of 24 matrix rows covered (16 ✓ + 4 ◐), beating fab solo's previous best of 15 — while retaining nearly all of fab deep's unique finds (5.5/6). Full artifacts are in _temp-Code-Reviews/track-pipeline-redesign-rematch/04-Code-Review/ (report.md, findings.json, certificate.md, and benchmark-scorecard.md with the row-by-row mapping).
 How it ran (blind — agents saw only the PR-head worktree, diff, and PR description, never the prior reviews): deterministic pre-pass → 10 single-lens finders produced 113 candidates → dedup to 86 → 38 adversarial verifiers confirmed 84 and refuted 2 → synthesized to 85 findings (1 Blocker, 4 Major, 11 Minor, 69 Nit). Total: ~3.1M subagent tokens across 48 agents.
 The goal check:
 - Fab deep's uniques retained: bug-execute stub filed as its own finding, execution-history unfiltered, deep-skills bundling, provenance-badge duplication all ✓ — and the cross-suite test failure was caught deterministically by the new full-suite pre-pass rule, with base-vs-head attribution (the three new track suites pass solo, die together at pipeline.service.ts:204). - Fab solo's results: captured its two biggest exclusives — the fork-vs-'default' edit gap is our sole Blocker (CR-001, sev 9, four verified trigger paths) and the unguarded JSON.parse — but missed rows 3 (orphaned enabled=0) and 7 (subset-template override clearing), plus two of its three cleanup items. Those two remain fab-solo-only across every run ever made of this PR. - New ground: ~10 Medium+ findings no prior review had, all adversarially confirmed — the Coverage Check/Create Test Cases regression, the deleted bulk 'Generate Stories' flow, backfill flipping MVP-disabled stages on, the review→autonomous mode inversion, severed testFramework editing, fork re-seed staleness, and more.
 85 findings (1 Blocker, 4 Major, 11 Minor, 69 Nit). Total: ~3.1M subagent tokens across 48 agents.
 The goal check:
 - Fab deep's uniques retained: bug-execute stub filed as its own finding, execution-history unfiltered, deep-skills bundling, provenance-badge duplication all ✓ — and the cross-suite test failure was caught deterministically by the new full-suite pre-pass rule, with base-vs-head attribution (the three new track suites pass solo, die together at pipeline.service.ts:204).
 How it ran (blind — agents saw only the PR-head worktree, diff, and PR description, never the prior reviews): deterministic pre-pass → 10 single-lens finders produced 113 candidates → dedup to 86 → 38 adversarial verifiers confirmed 84 and refuted 2 → synthesized to 85 findings (1 Blocker, 4 Major, 11 Minor, 69 Nit). Total: ~3.1M subagent tokens across 48 agents.
 The goal check:
 - Fab deep's uniques retained: bug-execute stub filed as its own finding, execution-history unfiltered, deep-skills bundling, provenance-badge duplication all ✓ — and the cross-suite test failure was caught deterministically by the new full-suite pre-pass rule, with base-vs-head attribution (the three new track suites pass solo, die together at pipeline.service.ts:204). - Fab solo's results: captured its two biggest exclusives — the fork-vs-'default' edit gap is our sole Blocker (CR-001, sev 9, four verified trigger paths) and the unguarded JSON.parse — but missed rows 3 (orphaned enabled=0) and 7 (subset-template override clearing), plus two of its three cleanup items. Those two remain fab-solo-only across every run ever made of this PR. - New ground: ~10 Medium+ findings no prior review had, all adversarially confirmed — the Coverage Check/Create Test Cases regression, the deleted bulk 'Generate Stories' flow, backfill flipping MVP-disabled stages on, the review→autonomous mode inversion, severed testFramework editing, fork re-seed staleness, and more.
 The verification stage earned its keep twice: it refuted a plausible-looking race claim (the write path is fully synchronous, single-process — concrete counter-evidence cited) and refuted 48-deep's old "undeclared placeholders" finding (they're declared three ways, including UI badges) — and it downgraded the backfill-one-route finding from 7 to 4 with a trace showing every normal UI flow hits the backfill first, a calibration both fab solo and 55-solo arguably got wrong.
 Two honest process notes: one dedup flaw (the tooling-bundling item appeared twice — V-077 should have merged into V-011), and I batched the severity ≤3 nits five-per-verifier instead of one each, which is noted as a deviation in the report.
 If you want, I can add a "rematch" column to 3-way-comparison.html following the established round pattern — it would also add ~10 new rows for the confirmed items no prior review found. ⎿  Stop says: ⚠ Context at 121% of the 200k window (threshold 75%). Consider running /overton-snapshot to checkpoint this session    before auto-compaction.

✻ Baked for 52m 26s

※ recap: We benchmarked the upgraded deep-code-review multi-agent skill by re-reviewing PR #65; it covered 20 of 24 matrix rows, beating all prior reviews. Next action: tell me if you want a rematch column added to 3-way-comparison.html.






