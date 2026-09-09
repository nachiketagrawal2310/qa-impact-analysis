# Risk Guide

## Risk
Production consequence if the change fails:
- CRITICAL: data/security/customer-wide or core workflow failure
- HIGH: major feature/service disruption or broad regression
- MEDIUM: meaningful but contained regression
- LOW: limited impact or cosmetic behavior

## Priority
Suggested test execution order:
- P0: execute before release candidate sign-off
- P1: high-value regression
- P2: useful secondary coverage
- P3: lower-risk edge case

Priority is not organizational release policy.

## Blast Radius
Estimate scope:
- CRITICAL: cross-tenant/security/core platform or many customer workflows
- HIGH: multiple services/clients or important shared dependency
- MEDIUM: single service/workflow with several consumers
- LOW: localized behavior

## Contract Compatibility
- Compatible: Existing consumers continue functioning without error
- Breaking: Existing consumers fail or require coordinated migration
- Unverified (Cross-Repo): Companion client or downstream service repository unavailable to establish compatibility

Do not infer compatibility merely from adding/removing fields; inspect consumer behavior where possible.
