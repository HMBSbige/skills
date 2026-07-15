---
name: testing-strategy
description: Use when a code change needs a testing approach chosen or revised, especially for bug fixes lacking regression coverage, stable APIs suited to test-first work, legacy code needing characterization, prototypes or UI/configuration/integration work needing acceptance-style validation, or repositories with explicit strict TDD rules. Choose from contract stability, available test seams, and risk; for strategy-only requests, recommend evidence without implementing changes; skip trivial edits whose required checks are already obvious.
---

# Testing Strategy

Choose the testing approach that produces useful evidence without turning one methodology into a ritual.

## Select the approach

- **Bug fix:** Prefer a focused regression test that reproduces the symptom before the fix when practical. For intermittent, environmental, or external failures, use the most reliable controlled reproduction instead.
- **Stable API or well-defined behavior:** When an executable test is the cheapest clear expression of the contract, prefer test-first development at the narrowest stable public boundary. Otherwise implement first and verify afterward.
- **Legacy or poorly understood code:** Characterize only behavior that should remain stable around the change. Treat current output as a drift baseline, not a correctness oracle; do not lock in a reported or known defect. For a bug fix, assert the intended behavior separately.
- **Exploratory prototype or unsettled interface:** Allow a time-boxed implementation spike. Before retaining, merging, or shipping it, identify the behavior that is now contractual and add the smallest durable checks; otherwise keep it explicitly non-production or discard it.
- **UI, visual output, configuration, generated artifacts, migrations, or external integrations:** Use the strongest fitting evidence, such as rendering, screenshots, schema validation, builds, integration environments, logs, or focused manual acceptance. Automate checks that will remain valuable.
- **Strict TDD repository:** Follow its documented red-green-refactor rules and commands. Do not infer strict TDD from this skill alone.

## Apply the strategy

1. Identify the observable behavior, risk, stable test seam, and existing repository commands.
2. Establish the pre-change signal appropriate to the selected strategy: a failing regression, a test-first example, a characterization baseline, or an acceptance criterion.
3. When implementation is requested and authorized, implement the smallest coherent change. Keep unrelated cleanup outside the behavior-changing step.
4. For implementation work, run the focused check, then expand to related module or integration checks in proportion to coupling and risk.

For strategy-only or review requests, do not implement changes. Return the recommended approach, evidence, scope, and any validation that would remain before completion.

When implementation already exists in a dirty worktree, preserve it and apply the selected strategy to the current change. Add a regression or characterization test only when it is the fitting durable signal; otherwise use the selected acceptance, rendering, integration, configuration, or controlled-reproduction evidence. If proving the historical failure is valuable, use an isolated base revision or another non-destructive method; otherwise state that the pre-fix failure was not independently demonstrated.

## Keep tests useful

- Test externally observable behavior at stable boundaries; do not impose one test per method.
- Use real collaborators when inexpensive and deterministic. Use narrow doubles at slow, nondeterministic, destructive, or external boundaries.
- Avoid assertions that only prove mock choreography or private implementation details.
- Reuse existing test frameworks and seams. Do not add a new framework, harness, public API, or dependency-injection layer solely to test one change unless recurring risk justifies its maintenance.
- Derive expected outcomes from requirements, a real reproduction, a specification, or an independent oracle rather than the implementation under test. Review snapshots instead of accepting updates mechanically.
- Do not absorb unrelated baseline failures, warnings, or test debt into the task. Report them separately unless they block trustworthy validation.
- Do not default to the full repository suite when focused and relevant module checks are sufficient. Run broader gates when repository policy, shared infrastructure, coupling, or release risk warrants them.

At completion, bind each material claim to evidence from the current relevant state, reuse current evidence when that state is unchanged, and state which checks were not run. Use `verification-before-completion` when it is available; otherwise apply these rules directly.
