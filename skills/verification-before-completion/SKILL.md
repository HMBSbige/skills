---
name: verification-before-completion
description: Use immediately before claiming that implementation, a bug fix, refactor, review remediation, build, test state, or generated artifact is complete, correct, or passing, and before commit, merge, or release decisions. Bind each claim to evidence from the latest relevant code and configuration state. Do not trigger for ordinary progress updates that make no completion or correctness claim.
---

# Verification Before Completion

Match each material completion claim to the smallest sufficient evidence from the current relevant state.

## Verify the claims

1. List the claims the final report will make: original symptom fixed, focused tests passing, build valid, requirements met, artifact rendered correctly, or another concrete outcome.
   - For a requirements-met claim, re-read the authoritative request, plan, and acceptance criteria against the current diff or artifact. Passing tests alone do not prove coverage.
   - For a regression-protection claim, demonstrate that the test fails on the unfixed behavior or on a targeted mutation or revert when practical and safe. A green run alone proves only compatibility with the current implementation.
2. Identify the evidence that proves each claim and what changes would invalidate it. Evidence remains current only when relevant code, configuration, dependencies, environment, or generated inputs have not changed since it was collected.
3. Run the appropriate checks:
   - For routine local changes, run the focused reproduction or test plus the relevant module checks.
   - For shared infrastructure, broad coupling, high-risk changes, or repeated failures, expand to affected dependents and broader gates.
   - For merge or release, run the repository-defined required gate. Do not assume every project requires a literal full monorepo suite when policy or CI defines a different authoritative gate.
   - For visual, document, configuration, migration, or generated artifacts, use rendering, inspection, schema validation, dry runs, or other evidence that directly tests the claim.
4. Read the result, exit status, failure count, and scope. Separate failures introduced by the change from known baseline failures.
5. Report what is verified and what is not. Narrow the wording when the evidence is partial.

Verification is keyed to the claim and its relevant state. When both are unchanged, reuse evidence with clear provenance instead of repeating the checklist or rerunning an expensive check. Do not extrapolate a focused pass into a broader claim.

Treat delegated summaries as leads, not proof. Reuse delegated evidence when it includes the command or procedure, scope, exit or completion status, a sufficient result summary or an inspectable log or artifact, provenance, and an unchanged relevant state. Full stdout is not required. If the evidence is incomplete or inconsistent, inspect the available output or rerun the smallest relevant check.

If a check cannot run because of missing dependencies, unavailable services, permissions, cost, or time, state in the user's current language that it is unverified, with the reason and the exact remaining check. Do not present an estimate as a verified result.

Keep verification non-destructive and within the user's authorization. Verification does not expand or narrow that authorization: an in-scope local action the user already requested, including a local commit, does not require a second confirmation. Follow applicable policy for remote writes, deployment, destructive actions, history rewriting, and scope expansion.
