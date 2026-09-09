# Confidence Guide

## [Certain]
Directly established by repository evidence, such as an actual call site, route registration, configuration, test assertion, or infrastructure definition.

## [Likely]
Strong inference supported by multiple clues, but not explicitly established. State the inference basis.

## [Guessing]
A useful inference without direct evidence. Must be surfaced under Unknowns. Never use as the sole basis for a release-blocking recommendation.

## [User-Confirmed]
Explicitly verified, stated, or overridden by the developer during the conversation. Sourced as `user-confirmed`.

## Unknown
The repository/context does not provide enough information to support a conclusion.

---

## Evidence Precedence

1. Repository code/config/tests and current Git state.
2. Developer direct input / user-confirmed overrides.
3. Organization architecture knowledge under `references/architecture/`.
4. General engineering inference.

Never convert missing evidence into a confident claim.
