# Evaluation Scenario: Bug Fix (Double-Submit Race Condition)

## Scenario Context
- **Developer Request:** "Analyze my fix for BUG-1042 where users double-clicking the checkout button were charged twice."
- **Files Modified:**
  - `src/controllers/checkout.ts`: Added extraction of `X-Idempotency-Key` header.
  - `src/services/checkout.ts`: Implemented distributed lock and deduplication check.
  - `test/checkout.test.ts`: Existing test only tests single order submission.

## Evaluation Target
- **Primary Checks:** EVAL-06 (Executable test schema), EVAL-07 (Dual-layer handoff), EVAL-04 (Automated tests not run).
- **Required Verification:**
  - Must generate a concurrency test simulating rapid parallel requests.
  - Must generate a test for duplicate key replay.
  - Must generate a test for backward compatibility without the idempotency header.
  - Must highlight distributed lock release failure in Devil's Advocate analysis.
