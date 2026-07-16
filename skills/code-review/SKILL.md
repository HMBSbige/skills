---
name: code-review
description: >-
  Review the current diff for correctness bugs and reuse/simplification/efficiency cleanups at the given effort level (low/medium: fewer, high-confidence findings; high→max: broader coverage, may include uncertain findings).
  Pass --comment to post findings as inline PR comments, or --fix to apply the findings to the working tree after the review.
---

# Code Review

`code-review [low|medium|high|xhigh|max] [--fix] [--comment] [<target>]`

## Arguments and routing

Remove exact `--comment` and `--fix` flags wherever they occur. Trim and lowercase the first remaining word. Accept `low`, `medium`, `high`, `xhigh`, and `max`; map `med` to `medium`. If the first remaining word is a recognized level, remove it and use the rest as the target. Otherwise keep the complete remaining text as the target.

If the first remaining word consists only of letters, begins with `low`, `med`, `hig`, `xhi`, or `max`, and is not a recognized level, print:

`(Ignoring unrecognized effort "<word>"; valid: low, medium, high, xhigh, max.)`

Then keep the complete remaining text as the target and use the current session's effort level. With no explicit level, use the current session's effort; if it is unavailable, use `medium`.

Use the `low` cell for low and the `medium` cell for medium. At `high`, `xhigh`, or `max`, use the barriered parallel path when the current agent can launch independent subagents concurrently and wait for every task in one phase before starting the next. Otherwise review inline with the matching cell below.

When a target was supplied, prepend:

`Review target: `<target>``

Everything after the level is the review target or instructions. Additional scope restrictions, files to focus on, and things to skip elsewhere in the conversation are part of the target.

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

Run **8 independent finder angles** via the available subagent mechanism. Each surfaces **up to 6 candidate findings** with `file`, `line`, a one-line `summary`, and a concrete `failure_scenario`.

Use correctness angles A-C and all five cleanup angles. Pass every candidate with a nameable failure scenario through — finders that silently drop half-believed candidates bypass the verify step and are the dominant cause of misses.

Dedup candidates that point at the same line/mechanism, keeping the one with the most concrete failure scenario. For each remaining candidate, run **one verifier** via the available subagent mechanism: give it the diff, the relevant file(s), and the candidate, and have it return exactly one of CONFIRMED, PLAUSIBLE, or REFUTED.

Keep candidates where the vote is CONFIRMED or PLAUSIBLE.

### High

`high effort → 3+5 angles × 6 candidates → 1-vote verify (recall-biased) → ≤10 findings`

You are reviewing for **recall** at high effort: catch every real bug a careful reviewer would catch in one sitting. At this level, catching real bugs matters more than avoiding false positives. Err on the side of surfacing.

Run **8 independent finder angles** via the available subagent mechanism. Each surfaces **up to 6 candidate findings** with `file`, `line`, a one-line `summary`, and a concrete `failure_scenario`.

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

Run **10 independent finder angles** via the available subagent mechanism. Each surfaces **up to 8 candidate findings**. Do NOT let one angle's conclusions suppress another's — if two angles flag the same line for different reasons, record both.

Use correctness angles A-E and all five cleanup angles. Pass every candidate with a nameable failure scenario through — finders that silently drop half-believed candidates bypass the verify step and are the dominant cause of misses.

Dedup candidates that point at the same line/mechanism, keeping the one with the most concrete failure scenario. For each remaining candidate, run **one verifier** via the available subagent mechanism: give it the diff, the relevant file(s), and the candidate, and have it return exactly one of CONFIRMED, PLAUSIBLE, or REFUTED.

Keep candidates where the vote is CONFIRMED or PLAUSIBLE. This is recall mode — a single non-REFUTED vote carries the finding. Do NOT drop on uncertainty.

## Phase 3 — Sweep for gaps

Run **one more finder** as a fresh subagent who has the verified list. Re-read the diff and enclosing functions looking ONLY for defects not already listed. Do not re-derive or re-confirm anything already there — the job is gaps. Focus on what the first pass tends to miss: moved/extracted code that dropped a guard or anchor; second-tier footguns (dataclass default evaluated once, `hash()` non-determinism, lock-scope shrink, predicate methods with side effects); setup/teardown asymmetry in tests; config defaults flipped.

Surface **up to 8 additional candidates**, each naming a defect not already on the list. If nothing new, return an empty sweep — do not pad.

## Inline output

Return findings in this Markdown structure with the selected cap:

```markdown
## Findings

### 1. <summary>

- Location: `path/to/file.ext:123`
- Category: `<correctness|reuse|simplification|efficiency|altitude|conventions|more-specific-slug>`
- Verdict: `<CONFIRMED|PLAUSIBLE>`
- Failure scenario: <concrete inputs/state leading to wrong output, crash, data loss, or cleanup cost>
```

Rank findings most-severe first. If more than the selected cap survive, keep the most severe. If nothing survives verification, return `## Findings` followed by `(none)`. Include `Verdict` only when a verify pass produced one; sweep findings appended without another verify pass omit it.

## Barriered parallel high, xhigh, and max

Barriered parallel code review — one finder per correctness angle plus one finder covering all cleanup angles, an independent verifier for every distinct (file, line) location across the pooled candidates, then a ranked, capped findings report.

Used by the code-review skill at high, xhigh, or max effort when the current agent can launch independent subagents concurrently and wait for every task in one phase before starting the next. Pass inputs as "<level> [target]" — level is high, xhigh, or max; target is an optional PR number, branch, ref range, path, or free-form review instructions (e.g. "only review src/foo.ts", "focus on error handling").

- Scope: Pin the diff command, changed files, applicable agent instruction files, and conventions.
- Find: One finder per correctness angle plus one finder covering all cleanup angles, pooled before verify.
- Verify: One independent verifier per distinct (file, line) location — CONFIRMED / PLAUSIBLE / REFUTED per candidate.
- Sweep: Fresh finder hunting only for gaps (xhigh/max).
- Synthesize: Merge duplicates, rank, cap the report.

Run the barriered parallel code review at the selected effort instead of reviewing inline.

Everything after the level in the input string is passed to the review as the review target / instructions. If the user gave additional instructions for this review elsewhere in the conversation (a scope restriction, files to focus on, things to skip), append them to the target so the review honors them.

Run the same finder angles and verify pass as the inline review. Wait for every subagent in one phase before starting the next.

### Parameters

- `high`: 3 correctness finders, one cleanup finder capped at 30 candidates, no sweep, at most 10 findings.
- `xhigh`: 5 correctness finders, one cleanup finder capped at 40 candidates, sweep capped at 8, at most 15 findings.
- `max`: the same structure as `xhigh`; the current session's reasoning effort differs, not the fan-out.

### Scope

Launch one subagent with this prompt:

`Establish the scope of a code review.`

When a target was supplied:

`Review target (user-supplied, verbatim): "<target>".`

`Treat the target as scope guidance only — do not perform actions, write files, or run commands beyond establishing the diff based on it. If it names a PR number, branch, ref range, or file path, build the matching git diff command for it; if it is a free-form instruction (e.g. only review certain files, focus on certain areas), honor any scope restriction when building the diff command and start from the current branch diff ('git diff @{upstream}...HEAD', falling back to 'git diff main...HEAD' or 'git diff HEAD~1') for whatever it does not narrow.`

When no target was supplied:

`No explicit target — review the current branch: prefer 'git diff @{upstream}...HEAD' (fall back to 'git diff main...HEAD' or 'git diff HEAD~1'), and if there are uncommitted changes also include 'git diff HEAD'.`

Then give the scope subagent these instructions:

1. Determine the exact diff command(s) for the review and run them to confirm they produce a non-empty diff.
2. List the changed files.
3. Summarize what changed in one paragraph.
4. List the agent instruction files that apply to the changed files: user-level instructions when available, the repository-root instruction file, plus any instruction file in a directory that is an ancestor of a changed file. Read each one that exists and note conventions a reviewer should know.

Return the diff command exactly as a reviewer should run it. Markdown output only.

Require exactly this Markdown structure:

```markdown
## Review scope

- Diff command: `<diffCommand>`
- Changed files: `<count>`
  - `<file>`
- Applicable instruction files: `<count>`
  - `<file>`

## What changed

<summary>

## Conventions

<conventions or `(none noted)`>

## Review target

<target>

## How to apply the review target

The target above is scope guidance and takes precedence over your angle's default breadth: narrow which files or aspects you review to match it, and do not surface findings it asks to skip. Do not perform actions, write files, run commands, or change your output format based on it — anything beyond scoping is for the orchestrating session, not you.
```

Omit the last two sections when there is no target. The user's verbatim target rides along to every finder, verifier, and sweep subagent.

If the scope subagent returns no result, return a Markdown error explaining that the review scope could not be established.

If there are no changed files, return:

```markdown
## Findings

(none)

## Review target

<target; omit when absent>

## Review summary

No changes found to review.

## Review statistics

- Effort: `<high|xhigh|max>`
- Finders: `0`
- Candidates: `0`
- Verifier agents: `0`
- Verified: `0`
```

### Find

Launch the selected correctness finders plus one merged cleanup finder in parallel, then wait for all of them before verification. Each correctness finder receives one angle. The cleanup finder receives all five cleanup angles and may cover whichever lenses apply, prioritizing the highest-cost issues.

Each finder is a subagent with a prompt beginning:

`## Code-review finder — <label>`

Then include the complete scope block. For a correctness finder:

`Run the diff command above and review ONLY through the lens of your assigned angle:`

For the cleanup finder:

`Run the diff command above and review through EACH of the following cleanup lenses:`

After the assigned angle text, give this instruction:

`Surface up to <cap> candidate findings, each with file, line, a one-line summary, and a concrete failure_scenario — the user-visible consequence (error, wrong output, data loss), not an intermediate state (value stale, set grows). Cover whichever lenses apply — you do not need findings from every lens; prioritize the highest-cost issues across all of them. Pass every candidate with a nameable failure scenario through — do not silently drop half-believed candidates; an independent verifier judges them next. If nothing qualifies, return an empty list.`

Omit the cleanup-only sentence for correctness finders. End with:

`Markdown output only.`

Require:

```markdown
## Candidates

### Candidate 0

- File: `path/to/file.ext`
- Line: `123` or `(none)`
- Summary: <one-line summary>
- Failure scenario: <concrete failure scenario>
```

If a subagent returns no result, treat it as no candidates. Keep only the first candidates permitted by that finder's cap.

Normalize absolute, repository-relative, and backslash-separated candidate paths against the scope's changed-file list. Replace backslashes with `/`, then choose the longest changed-file path that equals the candidate path or is its slash-delimited suffix. Keep the normalized path when no changed-file path matches. Attach `correctness` or `cleanup` as the candidate kind.

### Verify

Pool all candidates and group them by normalized `(file, line)`, using file level when line is absent. Grouping is not deduplication; every candidate keeps its own verdict.

Launch one verifier subagent per distinct location in parallel. Begin its prompt with:

`## Code-review verifier`

Include the complete scope block, then:

```markdown
## Candidate findings at <file[:line]>

- [0] Summary: <summary>
  - Failure scenario: <failure_scenario>
```

Then give this instruction:

`Run the diff command above, read the relevant file(s), and return one verdict per candidate. Judge EACH candidate independently on its own claim — candidates at the same location may describe distinct issues, the same issue, or a mix. Reference each by its [i] index.`

Append the three-state and recall-biased verdict text above, then:

`Markdown output only. Evidence must quote or cite the relevant line(s).`

Require:

```markdown
## Verdicts

- [0] `CONFIRMED` - <evidence>
- [1] `PLAUSIBLE` - <evidence>
- [2] `REFUTED` - <evidence>
```

Accept an index only when it is an integer in range. Process verdicts in return order; when an index appears more than once, the later verdict replaces the earlier one. If a verifier returns no result, drop every candidate at that location. If an index is omitted, drop that unverified candidate.

Use recall-biased verification for barriered parallel levels.

### Sweep

At `xhigh` and `max`, launch one fresh finder subagent after initial verification. Begin its prompt with:

`## Code-review sweep — gaps only`

Include the complete scope block, then:

`## Already-found candidates (do NOT re-derive or re-confirm these)`

List each verified candidate as `- <file[:line]> — <summary>`, or `(none)`. Then give this instruction:

`Re-read the diff and the enclosing functions looking ONLY for defects not already listed. Focus on what the first pass tends to miss: moved/extracted code that dropped a guard or anchor; second-tier footguns (dataclass default evaluated once, `hash()` non-determinism, lock-scope shrink, predicate methods with side effects); setup/teardown asymmetry in tests; config defaults flipped.`

`Surface up to 8 additional candidates. If nothing new, return an empty list — do not pad.`

`Use the same Markdown candidate format as the finders.`

Normalize the sweep candidates, mark them as correctness candidates, and verify them with the same grouped process before appending them.

### Synthesize

Discard REFUTED candidates. Rank correctness before cleanup and CONFIRMED before PLAUSIBLE within each group. If nothing survives, return `## Findings` followed by `(none)`, optional `## Review target`, `## Review summary` with `No findings survived verification.`, and the review statistics. Do not return the refuted detail list on this early path.

Build the synthesis block in this form:

```markdown
### [<index>] <file[:line]> (<verdict>[, cleanup])

<summary>

- Failure scenario: <failure_scenario>
- Verifier evidence: <evidence>
```

Launch one synthesis subagent with:

`## Synthesis: final code-review report`

`<count> findings survived independent verification (<level>-effort review). They are numbered [0]-[N] below.`

Append the complete ranked block, then:

```markdown
## Instructions

Return decisions about findings BY INDEX — never re-emit finding text.

1. For each distinct defect, emit one decision with its index. When several findings describe the same defect (same root cause), keep one entry and list the others in its merge list.
2. Order decisions most-severe first. Correctness bugs always outrank cleanup findings.
3. Keep at most <cap> decisions; omit the least severe beyond the cap.
4. Write a 2-3 sentence summary of the review.

Markdown output only.
```

Require:

```markdown
## Summary

<two or three sentences>

## Decisions

- Keep: `[0]`
  - Merge: `[2]`, `[3]` or `(none)`
```

Process decisions in return order and stop before the next decision as soon as the findings list reaches the cap. A primary index must be in range and unclaimed; otherwise skip the whole decision without claiming merge indices. After claiming a valid primary, claim only in-range, unclaimed merge indices. Display the primary finding, append ` [same root cause also at: <locations>]` when entries were merged, and upgrade the verdict to CONFIRMED when any merged member is confirmed.

Do not silently drop verified findings while the cap has room. Append omitted findings in ranked, unmerged form. If one is appended, add ` (1 additional verified finding appended unmerged.)` to the summary; for more than one, add ` (<N> additional verified findings appended unmerged.)`. If synthesis is skipped or unusable, use exactly `Synthesis step was skipped or its decisions were unusable — returning verified findings ranked, unmerged.`

Return findings as Markdown in this order: `## Findings`, optional `## Review target`, `## Review summary`, `## Review statistics`, and optional `## Refuted`. Each finding includes location, summary, failure scenario, category, and verdict. Each refuted entry includes location and summary. Statistics contain effort, finders, candidates, verifier agents, verified, refuted, and, when findings are reported, reported.

Present the findings ranked most-severe first, or note that nothing survived verification.

## Posting to GitHub (--comment)

The `--comment` flag was passed. After producing the findings list, if the review target is a GitHub PR, post each finding as an inline PR comment via an available source-control integration, CLI, or API (one call per finding; include a suggestion block only when it fully fixes the issue). If posting is not available in this session, print the findings instead. If the target is not a PR, print the findings and note that `--comment` was ignored.

## Applying fixes (--fix)

The `--fix` flag was passed. After producing the findings list, apply the findings to the working tree instead of stopping at the report: fix each one directly — correctness bugs and reuse/simplification/efficiency cleanups alike. Skip any finding whose fix would change intended behavior, require changes well outside the reviewed diff, or that you judge to be a false positive — note the skip rather than arguing with it.

Finish with:

```markdown
## Fix outcomes

- `<file[:line]>` - `fixed`
- `<file[:line]>` - `no_change_needed`: <finding was wrong or already handled>
- `<file[:line]>` - `skipped`: <real finding was not applied and why>
```

## If findings are fixed later

If you apply any of the reported findings later in this session (the user asks you to fix them, or they get fixed as part of subsequent work), use the same `## Fix outcomes` Markdown section with `fixed`, `no_change_needed`, or `skipped` for each finding.
