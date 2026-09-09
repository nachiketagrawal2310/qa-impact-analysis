# Test Generation Guide: Canonical Executable Manual QA Test Schema

This guide governs the generation of structured, evidence-backed, execution-ready manual test cases. Every generated test must be deterministic in its steps, actionable by a QA engineer without guesswork, and grounded in code or requirement evidence.

---

## 1. Canonical Executable Manual QA Test Schema

Every test case generated under `## QA Test Details` must adhere to this schema:

```markdown
### TC-[ID] — [Area/Feature]: [Concise, Descriptive Title]

- **Objective:** What specific business rule, failure mode, or risk is this test verifying?
- **Type:** Functional | Negative/Edge Case | Boundary | Regression | Security/RBAC | Concurrency | Offline/Sync
- **Risk:** CRITICAL | HIGH | MEDIUM | LOW
- **Priority:** P0 (Release blocker) | P1 (Must test before release) | P2 (High-value secondary) | P3 (Edge case)
- **Execution Tier:** Mandatory QA | Recommended Regression | Optional Edge Case
- **Execution Feasibility:** 
  - `READY` (Can be executed immediately with standard user access)
  - `REQUIRES TEST DATA / FIXTURE SETUP` (Needs specific records, multi-tenant accounts, or mock state)
  - `REQUIRES ENVIRONMENT SETUP` (Needs environment variables, feature flags, or sandbox config)
  - `REQUIRES DEV/INFRA SUPPORT` (Needs fault injection, network throttling, or direct DB/AWS access)
  - `REQUIRES EXTERNAL REPOSITORY` (Needs companion mobile build or external microservice)
  - `NOT EXECUTABLE WITH CURRENT ACCESS` (Logically valid but operationally blocked)
- **Target Platform:** Web Desktop | Mobile (Android/iOS) | REST API / Backend | On-Premise / Hybrid
- **Environment:** Specified in context / Requires Confirmation
- **Persona / Role:** Exact user role (e.g., Workplace Admin, Workflow Submitter, Read-Only Guest, Cross-Tenant Attacker, Unauthenticated)
- **Preconditions:**
  1. Specific existing state (e.g., "User account exists with active subscription").
  2. Configuration state (e.g., "Feature flag `ENABLE_BULK_UPLOAD` is set to `true`").
  3. Clean database state or mocked external dependencies.
- **Test Data / Payload:**
  - Exact JSON payload, form values, boundary inputs, or file specifications.
- **Execution Steps:**
  1. Detailed, sequential user or client action.
  2. Click / Submit / Dispatch trigger.
  3. Secondary step (e.g., reload page, background the mobile app, wait 5 seconds).
- **Expected Observable Results:**
  - **Mandatory Oracle (Required for Pass/Fail):**
    - **UI:** Visible banner text, modal popup, button state (disabled/loading), field inline error message.
    - **API:** HTTP status code, exact response body fields, header values.
    - **Database:** Record creation, updated column values, timestamp mutation, lack of orphan rows.
    - **Event / Workflow:** SQS message emitted, Step Function execution status.
  - **Diagnostic Observation (Operational Signal — Not Pass/Fail Blocker unless mandated by contract):**
    - **Observability:** Application logs, CloudWatch/Datadog metrics, error count, DLQ checks. *(If exact log message is not defined in code, state: "Verify operational logging signals rejection; exact string requires verification").*
- **Cleanup / Postconditions:**
  - Instructions to reset state (e.g., "Delete created test workplace", "Restore feature flag to default").
- **Traceability:** `REQ-[ID] → IMP-[ID] → RISK-[ID]`
- **Evidence:** `relative/path/to/file.ts:line` (Evidence Source: `repository` / `requirement` / `user-confirmed`)
```

### Formatting Rule: Omit Irrelevant Sub-bullets
Do NOT pollute test cases with generic filler text (e.g., "Database: N/A", "Observability: None"). If a test is a pure frontend UI validation with no database mutation or event emission, omit the `Database` and `Event/Workflow` bullets entirely. Keep every included line meaningful.

---

## 2. Evidence-Safe Observable Oracles (Anti-Fabrication Protocol)

### Mandatory Oracle vs. Diagnostic Observation
1. **Mandatory Oracle:** The core user/client observable outcome essential to determine whether the software behaved correctly.
   - Example: The user receives an error modal saying *"Cannot cancel active subscription"*, or the API responds with a rejection.
2. **Diagnostic Observation:** Operational telemetry (log strings, metric increments, trace spans) useful for debugging.
   - Do NOT turn an unverified log message into a hard test blocker for QA unless the ticket requirement specifically mandates that log contract.

### Grounding Rules: Requirement Evidence vs. Implementation Evidence
- **Requirement Evidence as Oracle:**
  - Acceptance criteria and ticket requirements provide legitimate evidence for what the software *should* do.
  - *Example:* The story says: *"When a user deletes their account, return 404 on subsequent lookups."*
  - If the implementation currently returns `200` with an empty object, the test oracle **MUST** assert `404 Not Found` (grounded in `Evidence Source: requirement`), flag an implementation defect, and set `Quality Gate: GAP`.
- **Implementation Evidence as Oracle:**
  - Where requirements are silent or detail internal contracts, cite the code establishing the behavior (router, middleware, database layer).
  - *Example:* Code returns `res.status(409).json({ code: "ACTIVE_SUB" })`. The test asserts `409` with code `ACTIVE_SUB` (`Evidence Source: repository`).
- **Exact value known from evidence:** Assert the exact value.
- **Exact value not known:** DO NOT manufacture arbitrary codes. Assert the observable behavior and flag representation for verification:
  > *"API: Request is rejected via defined validation behavior. Exact status code (400 vs 422) requires verification in test environment."*

---

## 3. Bidirectional Traceability: Requirements ↔ Implementation ↔ Tests

Maintain bidirectional scrutiny:
1. **Requirement → Implementation → Test:**
   - Did the developer implement and test all requested acceptance criteria?
   - Any missing acceptance criterion is flagged as `Coverage: Not Covered` with Quality Gate `GAP`.
2. **Implementation Change → Requirement:**
   - Did the developer introduce unrequested behavior, modified unmentioned endpoints, or add scope creep?
   - Any unrequested code path is flagged as `Unrequested Scope` and evaluated for unintended regression risks.
