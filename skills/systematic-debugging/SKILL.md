---
name: systematic-debugging
description: Use when diagnosing a bug, test or build failure, performance regression, intermittent fault, or other unexpected technical behavior. Take a fast path when the cause is directly evidenced and the proposed action is local and reversible; use the full evidence loop when uncertainty, irreversibility, cross-component behavior, intermittent reproduction, or failed prior attempts make a wrong action materially risky. Preserve diagnosis-only scope when the user has not asked for changes.
---

# Systematic Debugging

Scale the investigation to uncertainty and impact.

## Route the problem

Use the fast path when the symptom is reproducible, the error or diff directly supports one cause, and the fix is local and low risk:

1. Confirm the relevant evidence and expected behavior.
2. Apply the smallest coherent fix when authorized.
3. Re-run the focused reproduction and relevant regression check.
4. Stop when the evidence supports the result; do not expand into a general audit.

Use the full loop when uncertainty or irreversibility makes a wrong action materially costly, especially when the issue is intermittent, crosses components, has multiple plausible causes, or has survived previous fix attempts. High impact alone does not exclude a directly evidenced fast path; strengthen validation, rollback readiness, and monitoring instead.

## Run the full evidence loop

1. Establish the actual failure. Read the exact error, logs, assertion, or observed symptom; record the smallest reproduction and relevant environment or recent changes.
2. Separate observed facts, inferences, and unknowns. Trace incorrect data or state backward to its first supported divergence.
3. Rank a small number of hypotheses. Compare the failing path with the narrowest relevant working path or contract.
4. Run the smallest safe experiment whose outcomes distinguish the leading hypotheses. Change one conceptual variable at a time and update the ranking from the result.
5. Stop when the evidence is sufficient for the requested decision or action and the remaining uncertainty would not change it. If the next useful experiment is unavailable, report the limitation instead of looping.
6. When evidence conflicts with the working model or experiments stop distinguishing hypotheses, preserve confirmed facts and revisit the hypotheses, reproduction fidelity, and system boundaries before adding another patch. Consider architecture only when the evidence points there, not after an arbitrary attempt count.

Prefer read-only probes and existing diagnostics. Add instrumentation only when it provides necessary signal and can be scoped, sanitized, and removed safely.

## Act on the result

- For diagnosis only, report the supported cause or leading hypothesis, confidence, evidence, remaining uncertainty, and next useful experiment. Do not implement a fix.
- For a fix request, address the supported cause with the smallest coherent change and avoid unrelated cleanup.
- Add a regression test when it provides durable signal. Use configuration validation, rendering, integration checks, logs, or controlled reproduction when those fit the failure better.
- Verify the original symptom and the relevant regression surface after the change.

Within the user's authorization, urgent rollback or containment may precede complete root-cause analysis. Label it as mitigation and keep permanent remediation separate.

Do not claim a stronger cause or outcome than the evidence establishes. If reproduction or required state is unavailable, report what remains unverified.
