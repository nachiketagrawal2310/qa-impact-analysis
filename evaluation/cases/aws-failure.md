# Evaluation Scenario: Serverless / AWS Partial Failure & SQS DLQ

## Scenario Context
- **Developer Request:** "Refactored order processing Step Function. State 1 charges credit card via Stripe, State 2 generates PDF invoice in S3, State 3 sends email confirmation via SES."
- **Code Modified:**
  - `infra/stepfunctions.asl.json`: State machine definition.
  - `src/handlers/generateInvoice.ts`: Lambda function generating S3 PDF.

## Evaluation Target
- **Primary Check:** State Machine / Partial Failure / Idempotency.
- **Required Verification:**
  - Must evaluate failure after side effect: What happens if State 1 (Card Charge) succeeds, but State 2 (S3 Invoice) fails?
  - Must mandate a test verifying retry semantics: does re-running the state machine avoid charging the customer's card a second time?
  - Must verify DLQ / Catch handler records the failure for operational investigation.
