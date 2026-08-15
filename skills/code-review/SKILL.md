---
name: code-review
description: >-
  Review the current diff, or a PR number/branch/path target, for correctness bugs and reuse/simplification/efficiency cleanups at the given effort level (low/medium: fewer, high-confidence findings; high→max: broader coverage, may include uncertain findings). With no level given, reuse the level explicitly selected most recently in the conversation; if none was selected, use the agent's current effort level, falling back to medium. Pass --comment to post findings as inline PR comments, or --fix to apply the findings to the working tree after the review.
---

# Code Review

`code-review [low|medium|high|xhigh|max] [--fix] [--comment] [<pr#>|<branch>|<path>]`

## Arguments and routing

Remove standalone `--comment` and `--fix` flags wherever they appear and record the requested actions. Then match the first remaining word case-insensitively against `low`, `medium` (`med`), `high`, `xhigh`, or `max`. On a match, use that level, remember it as the most recently explicitly selected level in the conversation, and use the rest as the target. Otherwise keep all remaining text as the target and reuse the most recently explicitly selected level in the conversation; if none was selected, use the agent's current effort level, falling back to `medium`.

If an unmatched first word is alphabetic and starts with `low`, `med`, `hig`, `xhi`, or `max`, print `(Ignoring unrecognized effort "<word>"; valid: low, medium, high, xhigh, max. Using <level>.)`. Route every recognized level to its matching inline cell, using its no-subagent fallback when the agent has no subagent mechanism.

When no explicit level was given and a previously selected level is reused, tell the user in one short line as the review begins: `No effort level given — reusing <level>, the level you selected last time. Select a level like code-review high to change it.` If an effort-like word was unrecognized and a previously selected level is being reused, combine the warning, the reuse source, and how to change it into that one line. When no previously selected level exists and the agent fallback is used, do not print this notice. If the review runs in a fork or background task, put the notice at the start of the report instead.

An agent-selected internal `minimal` mode overrides the parsed level and uses `Minimal`; do not expose it as an argument or infer it from a product or model name.

For a non-empty target, remove all backticks and one leading `#` from its first word, rejoin it with the remaining words, and pass it as ``Review target: `<target>` ``. Include any scope restrictions, focus files, or exclusions stated elsewhere in the conversation.

## Shared review scope

## Phase 0 — Gather the diff

Run `git diff @{upstream}...HEAD` (or `git diff main...HEAD` / `git diff HEAD~1` if there's no upstream) to get the unified diff under review. If there are uncommitted changes, or the range diff is empty, also run `git diff HEAD` and include the working-tree changes in scope — the review often runs before the commit. If a PR number, branch name, or file path was passed as an argument, review that target instead. Treat this diff as the review scope.

## Correctness angles

### Angle A — line-by-line diff scan

Read every hunk in the diff, line by line. Then read the enclosing function for each hunk — bugs in unchanged lines of a touched function are in scope (the PR re-exposes or fails to fix them). For every line ask: what input, state, timing, or platform makes this line wrong? Look for inverted/wrong conditions, off-by-one, null/undefined deref, missing `await`, falsy-zero checks, wrong-variable copy-paste, error swallowed in catch, unescaped regex metachars.

### Angle B — removed-behavior auditor

For every line the diff DELETES or replaces, name the invariant or behavior it enforced, then search the new code for where that invariant is re-established. If you can't find it, that's a candidate: a removed guard, a dropped error path, a narrowed validation, a deleted test that was covering a real case.

### Angle C — cross-file tracer

For each function the diff changes, find its callers (search for the symbol) and check whether the change breaks any call site: a new precondition, a changed return shape, a new exception, a timing/ordering dependency. Also check callees: does a parallel change in the same PR make a call unsafe?

### Angle D — language-pitfall specialist

Scan for the classic pitfalls of the diff's language/framework — for example: JS falsy-zero, `==` coercion, closure-captured loop var; Python mutable default args, late-binding closures; Go nil-map write, range-var capture; SQL injection; timezone/DST drift; float equality. Flag any instance the diff introduces.

### Angle E — wrapper/proxy correctness

When the PR adds or modifies a type that wraps another (cache, proxy, decorator, adapter): check that every method routes to the wrapped instance and not back through a registry/session/global — e.g. a caching provider holding a `delegate` field that resolves IDs via `session.get(...)` instead of `delegate.get(...)` will re-enter the cache or recurse. Also check that the wrapper forwards all the methods the callers actually use.

## Cleanup angles

### Reuse

The angles above hunt for bugs; this one and the next two hunt for cleanup in the changed code. Flag new code that re-implements something the codebase already has — search shared/utility modules and files adjacent to the change, and name the existing helper to call instead.

### Simplification

Flag unnecessary complexity the diff adds: redundant or derivable state, copy-paste with slight variation, deep nesting, dead code left behind. Name the simpler form that does the same job.

### Efficiency

Flag wasted work the diff introduces: redundant computation or repeated I/O, independent operations run sequentially, blocking work added to startup or hot paths. Also flag long-lived objects built from closures or captured environments — they keep the entire enclosing scope alive for the object's lifetime (a memory leak when that scope holds large values); prefer a class/struct that copies only the fields it needs. Name the cheaper alternative.

### Altitude

Check that each change is implemented at the right depth, not as a fragile bandaid. Special cases layered on shared infrastructure are a sign the fix isn't deep enough — prefer generalizing the underlying mechanism over adding special cases.

### Conventions (agent instructions)

Find the agent instruction files that govern the changed code: user-level instructions when available, the repository-root instruction file, plus any instruction file in a directory that is an ancestor of a changed file (a directory's instructions only apply to files at or below it). Read each one that exists, then check the diff for clear violations of the rules they state.

Only flag a violation when you can quote the exact rule and the exact line that breaks it — no style preferences, no vague "spirit of the doc" inferences. In the finding, name the instruction-file path and quote the rule so the report can cite it. If no instruction file applies, return nothing for this angle.

Cleanup, altitude, and conventions candidates use the same `file`/`line`/`summary` shape; in `failure_scenario`, state the concrete cost (what is duplicated, wasted, harder to maintain, or which instruction rule is broken) instead of a crash. Correctness bugs always outrank cleanup, altitude, and conventions findings when the output cap forces a cut.

## Verdicts

- **CONFIRMED** — can name the inputs/state that trigger it and the wrong output or crash. Quote the line.
- **PLAUSIBLE** — mechanism is real, trigger is uncertain (timing, env, config). State what would confirm it.
- **REFUTED** — factually wrong (code doesn't say that) or guarded elsewhere. Quote the line that proves it.

For recall-biased verification, use **PLAUSIBLE by default** — do not refute a candidate for being "speculative" or "depends on runtime state" when the state is realistic: concurrency races, nil/undefined on a rare-but-reachable path (error handler, cold cache, missing optional field), falsy-zero treated as missing, off-by-one on a boundary the code does not exclude, retry storms / partial failures, regex/allowlist that lost an anchor. These are PLAUSIBLE.

**REFUTED** only when constructible from the code: factually wrong (quote the actual line); provably impossible (type/constant/invariant — show it); already handled in this diff (cite the guard); or pure style with no observable effect.

## Inline cells

### Minimal

`minimal prompt → single careful diff pass → ≤15 findings`

Gather the diff exactly as Phase 0 describes.

Review every hunk as a careful senior engineer. Open surrounding files for context as needed using available file-reading and search capabilities plus `git log`, `git blame`, and `git show`. Hunt for correctness issues — wrong or inverted conditions, off-by-one errors, null/undefined dereferences, missing `await`, dropped error handling, removed guards or validations, broken callers of changed functions, and races. Prefer real failure modes over style; every finding needs a concrete scenario in which the code misbehaves.

Return at most 15 findings, most-severe first, as Markdown once. Under `## Findings`, write one bullet per finding as ``- `path/to/file.ext:123` — **<severity>** — <issue and concrete failure scenario>``. If nothing qualifies, return `## Findings` followed by `(none)`.

### Low

`low effort → 1 diff pass → no verify → ≤4 findings`

## Turn 1 — read

One tool call: read the unified diff (`git diff @{upstream}...HEAD; git diff HEAD` to cover both committed and uncommitted changes, or `git diff main...HEAD` / the target passed as an argument). Skip test/fixture hunks (`test/`, `spec/`, `__tests__/`, `*_test.*`, `*.test.*`, `fixtures/`, `testdata/`) — test-file changes are not reviewed at this level. No subagents, no full-file reads.

## Turn 2 — findings

Flag runtime-correctness bugs visible from the hunk alone: inverted/wrong condition, off-by-one, null/undefined deref where adjacent lines show the value can be absent, removed guard, falsy-zero check, missing `await`, wrong-variable copy-paste, error swallowed in a catch that should propagate. Also flag — still from the hunk alone — new code that duplicates an existing helper visible in the diff context, and dead code the diff leaves behind.

Do **not** flag style, naming, perf, missing tests, or anything outside the hunk.

Output at most **4 findings**, most-severe first, one line each: `path/to/file.ext:123 — what's wrong and the concrete failure`. If nothing qualifies, output exactly `(none)`.

### Medium

`medium effort → 3+5 angles × 6 candidates → 1-vote verify → ≤8 findings`

You are reviewing for **precision** at medium effort: every finding you surface should be one a maintainer would act on.

Run **8 independent finder angles** via the available subagent mechanism. Each surfaces **up to 6 candidate findings** with `file`, `line`, a one-line `summary`, and a concrete `failure_scenario`. If the subagent mechanism is not available in your current tool set, do not error — perform each angle (and each verification) yourself, sequentially, in this context.

Use correctness angles A-C and all five cleanup angles. Pass every candidate with a nameable failure scenario through — finders that silently drop half-believed candidates bypass the verify step and are the dominant cause of misses.

Dedup candidates that point at the same line/mechanism, keeping the one with the most concrete failure scenario. For each remaining candidate, run **one verifier** via the available subagent mechanism: give it the diff, the relevant file(s), and the candidate, and have it return exactly one of CONFIRMED, PLAUSIBLE, or REFUTED.

Keep candidates where the vote is CONFIRMED or PLAUSIBLE.

### High

`high effort → 3+5 angles × 6 candidates → 1-vote verify (recall-biased) → ≤10 findings`

You are reviewing for **recall** at high effort: catch every real bug a careful reviewer would catch in one sitting. At this level, catching real bugs matters more than avoiding false positives. Err on the side of surfacing.

Run **8 independent finder angles** via the available subagent mechanism. Each surfaces **up to 6 candidate findings** with `file`, `line`, a one-line `summary`, and a concrete `failure_scenario`. If the subagent mechanism is not available in your current tool set, do not error — perform each angle (and each verification) yourself, sequentially, in this context.

Use correctness angles A-C and all five cleanup angles. Pass every candidate with a nameable failure scenario through — finders that silently drop half-believed candidates bypass the verify step and are the dominant cause of misses.

Dedup near-duplicates (same defect, same location, same reason → keep one). For each remaining candidate, run **one verifier** via the available subagent mechanism: give it the diff, the relevant file(s), and the candidate; it returns exactly one of CONFIRMED, PLAUSIBLE, or REFUTED.

Use recall-biased verification. Keep **CONFIRMED and PLAUSIBLE**. Drop REFUTED.

### Xhigh

`xhigh effort → 5+5 angles × 8 candidates → 1-vote verify → sweep → ≤15 findings`

You are reviewing for **recall** at extra-high effort: catch every real bug. At this level, catching real bugs matters more than avoiding false positives — a missed bug ships. Err on the side of surfacing.

### Max

`max effort → 5+5 angles × 8 candidates → 1-vote verify → sweep → ≤15 findings`

You are reviewing for **recall** at maximum effort: catch every real bug. At this level, catching real bugs matters more than avoiding false positives — a missed bug ships. Err on the side of surfacing.

### Shared xhigh/max phases

Run **10 independent finder angles** via the available subagent mechanism. Each surfaces **up to 8 candidate findings**. Do NOT let one angle's conclusions suppress another's — if two angles flag the same line for different reasons, record both. If the subagent mechanism is not available in your current tool set, do not error — perform each angle (and each verification) yourself, sequentially, in this context.

Use correctness angles A-E and all five cleanup angles. Pass every candidate with a nameable failure scenario through — finders that silently drop half-believed candidates bypass the verify step and are the dominant cause of misses.

Dedup candidates that point at the same line/mechanism, keeping the one with the most concrete failure scenario. For each remaining candidate, run **one verifier** via the available subagent mechanism: give it the diff, the relevant file(s), and the candidate, and have it return exactly one of CONFIRMED, PLAUSIBLE, or REFUTED.

Keep candidates where the vote is CONFIRMED or PLAUSIBLE. This is recall mode — a single non-REFUTED vote carries the finding. Do NOT drop on uncertainty.

## Phase 3 — Sweep for gaps

Run **one more finder** as a fresh subagent who has the verified list. Re-read the diff and enclosing functions looking ONLY for defects not already listed. Do not re-derive or re-confirm anything already there — the job is gaps. Focus on what the first pass tends to miss: moved/extracted code that dropped a guard or anchor; second-tier footguns (dataclass default evaluated once, `hash()` non-determinism, lock-scope shrink, predicate methods with side effects); setup/teardown asymmetry in tests; config defaults flipped.

Surface **up to 8 additional candidates**, each naming a defect not already on the list. If nothing new, return an empty sweep — do not pad.

### No-subagent fallback (medium, high, xhigh, and max)

Use this path only when no subagent mechanism is available. The usual multi-agent fan-out and subagent verify pass cannot run, so work through every selected angle yourself, in the same context, in one pass — do not skip angles for lack of fan-out. Re-check each candidate against the diff before keeping it; drop anything you cannot back up with a concrete failure scenario.

- At `medium`, use correctness angles A-C and all five cleanup angles, cap the report at 8 findings, and use the medium precision standard.
- At `high`, use correctness angles A-C and all five cleanup angles, cap the report at 10 findings, and use the high recall standard.
- At `xhigh` or `max`, use correctness angles A-E and all five cleanup angles, cap the report at 15 findings, and use the matching recall standard.

## Phase 1 — Find candidates (single pass)

Work through the selected angles yourself, in sequence, in the same context. Each angle surfaces candidate findings with `file`, `line`, a one-line `summary`, and a concrete `failure_scenario`. Apply the cleanup, altitude, and conventions candidate rules above.

## Phase 2 — Dedup and self-check (no subagent verify)

Dedup near-duplicates (same defect, same location, same reason → keep one). Re-check each remaining candidate yourself against the diff before keeping it.

At `xhigh` and `max`, take one more pass yourself in the same context as a fresh reviewer who has the deduplicated list. Re-read the diff and enclosing functions looking only for defects not already listed: moved/extracted code that dropped a guard or anchor; second-tier footguns (dataclass default evaluated once, `hash()` non-determinism, lock-scope shrink, predicate methods with side effects); setup/teardown asymmetry in tests; config defaults flipped.

State clearly in the review summary that this was a single-pass review done without the subagent mechanism, not the full multi-agent fan-out, so the reader is not misled about what actually ran.

## Inline output

For `medium`, `high`, `xhigh`, and `max`, return findings as a JSON array of at most the selected cap of objects:

```json
[
  {
    "file": "path/to/file.ext",
    "line": 123,
    "summary": "one-sentence statement of the bug",
    "failure_scenario": "concrete inputs/state → wrong output/crash"
  }
]
```

Rank findings most-severe first. The selected caps are 8 for `medium`, 10 for `high`, and 15 for `xhigh` or `max`. If more survive, keep the most severe. If nothing survives verification, return `[]`. Do not use a separate host-specific findings-reporting tool even if one is available — this review's output contract is the JSON block above.

## Posting to GitHub (--comment)

The `--comment` flag was passed. After producing the findings list, if the review target is a GitHub PR, post each finding as an inline PR comment via an available source-control integration, CLI, or API (one call per finding; include a suggestion block only when it fully fixes the issue). If posting is not available in this session, print the findings instead. If the target is not a PR, print the findings and note that `--comment` was ignored.

## Applying fixes (--fix)

The `--fix` flag was passed. After producing the findings list, apply the findings to the working tree instead of stopping at the report: fix each one directly — correctness bugs and reuse/simplification/efficiency cleanups alike. Skip any finding whose fix would change intended behavior, require changes well outside the reviewed diff, or that you judge to be a false positive — note the skip rather than arguing with it. Finish with a brief summary of what was fixed and what was skipped.
