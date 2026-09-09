# AWS & Serverless Failure Semantics Checklist

Apply when repository evidence shows AWS SDK usage, serverless configurations (SAM, Serverless Framework, CDK), Terraform AWS resources, or Step Functions definitions.

---

## 1. AWS Lambda & Execution Boundaries

Inspect actual runtime handlers and resource definitions:
- **Execution Timeout & Trigger Boundaries:** Timeout behavior must be evaluated against the invocation path indicated by repository evidence:
  - *Synchronous API Gateway / AppSync:* 29s hard integration ceiling regardless of function timeout.
  - *SQS Event Source:* Function timeout must be strictly less than SQS queue visibility timeout to prevent duplicate in-flight message redelivery. (Recommended operational guideline: visibility timeout ≥ 6 × function timeout to absorb cold starts and retries; the actual configured timeout relationship in repository IaC/configs serves as the test oracle).
  - *Step Functions / EventBridge / Kinesis:* Task `TimeoutSeconds` and batch window limits.
  - *Async worker / Scheduled cron:* Configured Lambda timeout up to 15-minute maximum.
  Verify whether socket/client timeouts on downstream calls (Stripe, DB, external APIs) fail cleanly with structured error responses before the trigger envelope cuts off execution.
- **Automatic Retries:** Asynchronous invocations (S3 events, EventBridge, SNS) retry twice by default. Is the handler idempotent, or will it create duplicate records on retry?
- **Duplicate Execution:** SQS and DynamoDB Streams offer at-least-once delivery. Does the Lambda check a deduplication key?
- **IAM Permission Boundaries:** Does the execution role have minimal required permissions (`s3:PutObject`, `dynamodb:UpdateItem`)?
- **Cold Starts & Memory Allocation:** Does payload buffering or heavy dependencies risk out-of-memory errors on burst traffic?
- **Downstream Failure Catching:** Are downstream database or S3 errors caught, or do they trigger unhandled container crashes?

---

## 2. Amazon DynamoDB

Inspect queries, conditional writes, and indexing:
- **Conditional Expression Failure:** Does the code handle `ConditionalCheckFailedException` (e.g., race condition on balance update) and map it to a controlled business response?
- **Query vs. Scan:** Does query logic properly use Partition Key (PK) and Sort Key (SK)?
- **Missing vs. Existing Record:** What happens when `GetItem` returns an empty item? Does the code throw a NullPointerException?
- **Concurrency & Race Conditions:** When two concurrent requests update the same record, is optimistic locking (`attribute_exists(version) AND version = :v`) in place?
- **Transaction Rollback:** In `TransactWriteItems`, if 1 condition in a 5-item transaction fails, does the application handle full transaction cancellation gracefully?
- **Pagination Boundaries:** If query results exceed 1MB, does the handler process `LastEvaluatedKey` or truncate data?

---

## 3. Amazon S3

Inspect bucket operations, pre-signed URLs, and multipart uploads:
- **Pre-signed URL Expiration:** What happens if the client takes longer than the expiration window to upload a large file?
- **Content-Type Header Enforcement:** Does the pre-signed URL sign the `ContentType` header to prevent executable spoofing?
- **Orphan Object Accumulation:** If an S3 upload succeeds but database confirmation fails, is there a cleanup job or lifecycle rule?
- **Multipart Upload Abort:** Is an S3 Lifecycle Rule configured to abort incomplete multipart uploads after 7 days?

---

## 4. SQS, SNS & EventBridge

Inspect event schemas and queue subscriptions:
- **Visibility Timeout vs. Function Duration:** Function timeout must be strictly less than the SQS queue visibility timeout to prevent in-flight messages from prematurely returning to the queue while processing. (AWS operational guideline recommends visibility timeout ≥ 6 × function timeout; the actual configured timeout relationship in repository IaC/configuration serves as the test oracle).
- **Poison-Pill Messages:** If a malformed payload arrives, will it fail repeatedly and block the queue, or does it route to a Dead Letter Queue (DLQ)?
- **Dead Letter Queue (DLQ) Configuration:** Does the queue have a maxReceiveCount and redrive policy?
- **Out-of-Order Delivery:** If non-FIFO SQS or EventBridge is used, does the consumer assume strict message ordering?
- **Event Schema Evolution:** Does the consumer safely ignore new fields added to event payloads?

---

## 5. AWS Step Functions

Inspect state transitions, catch blocks, and retry policies:
- **Timeout per Task:** Are individual task timeouts configured to prevent state machine executions from hanging for 1 year?
- **Partial State Failure:** If State 1 (Payment) succeeds, but State 2 (Fulfillment) fails, does the Catch block trigger a compensation Lambda (Refund)?
- **Execution Restartability:** Can a failed execution be safely restarted without double-charging or duplicate side effects?
