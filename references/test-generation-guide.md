# Test Generation Guide: Executable Manual QA Test Schemas

This guide governs the generation of structured, evidence-backed, execution-ready manual test cases. Every generated test must be deterministic in its steps, actionable by a QA engineer without guesswork, and grounded in code and requirement evidence.

---

## 1. Primary Test Schemas: Clean vs. Audited

The skill supports two presentation schemas depending on whether the invocation is in **Default Mode** or **Full Mode (`--full`)**:

### A. Clean Executable Manual QA Test Schema (Default Mode)

Used in standard `/qa-impact-analysis` invocations. It strictly formats tests for direct QA execution, stripped of engineering architecture and internal reasoning noise.

```markdown
### TC-[ID] — [Area/Feature]: [Concise, Descriptive Title]
**Priority:** P0 (Release blocker) | P1 (Must test before release) | P2 (High-value secondary) | P3 (Edge case)
**Type:** Functional | Negative/Edge Case | Boundary | Regression | Security/RBAC | Concurrency | Offline/Sync | Integration
**Feasibility:** Manual | Requires test data | Requires developer support | Requires environment access

**Steps**
1. Detailed, sequential user or client action.
2. Click / Submit / Trigger action.
3. Verification action (e.g. inspect list, reload page, check notifications).

**Expected Result**
- Primary client/UI observable outcome (toast message, updated view, button state).
- API response status and payload contract (HTTP 200, 400 Bad Request with field error).
- State persistence (record created in DB, expected column values).
- Operational telemetry (log level WARN, CloudWatch metric increment) if validating alert behavior.
```

#### Self-Contained Execution Contract
> **Rule:** A QA engineer who has only the generated Test Details and stated prerequisites must be able to execute the test without reading the developer's code, Git diffs, or the Skill's internal analysis.
- Concrete prerequisites or feasibility flags must be stated (e.g. `Feasibility: Requires developer support to inject controlled failure`).
- Avoid vague placeholders like *"Verify Lambda works"* or *"Simulate an unexpected error"*. Provide concrete steps or state the exact fault-injection mechanism needed.

#### Intelligent Platform Exclusions
- The skill internally analyzes client consumers (Web, Android, iOS, On-Premise).
- Tests are generated **only for affected platforms**. Unimpacted platforms are omitted.
- An optional brief note is added only where omission might confuse QA:
  > `**Scope Note:** No mobile-specific cases included; no affected mobile consumer was identified.`

#### Zero Internal Noise
- In default mode, do NOT include:
  - Internal IDs: `IMP-xxx`, `RISK-xxx`, `REQ-xxx`
  - Confidence labels: `[Certain]`, `[Likely]`, `[Guessing]`
  - Risk matrices, blast radius tables, or architecture narratives.

---

### B. Comprehensive Audited Test Schema (Full Mode — `--full`)

Used when the user explicitly requests full technical impact analysis (`--full` or natural language like *"Give me the full impact analysis"*).

```markdown
### TC-[ID] — [Area/Feature]: [Concise, Descriptive Title]

- **Objective:** What specific business rule, failure mode, or risk is this test verifying?
- **Category:** `Direct Requirement (Story AC)` | `Implementation Impact / Regression`
- **Type:** Functional | Negative | Boundary | Regression | Security | Concurrency | Offline | Sync
- **Risk:** CRITICAL | HIGH | MEDIUM | LOW
- **Priority:** P0 | P1 | P2 | P3
- **Execution Tier:** Mandatory QA | Recommended Regression | Optional Edge Case
- **Execution Feasibility:** `READY` | `REQUIRES TEST DATA / FIXTURE SETUP` | `REQUIRES ENVIRONMENT SETUP` | `REQUIRES DEV/INFRA SUPPORT` | `REQUIRES EXTERNAL REPOSITORY` | `NOT EXECUTABLE WITH CURRENT ACCESS`
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

The skill internally maintains strict bidirectional scrutiny before test generation:
1. **Requirement → Implementation → Test:**
   - Did the developer implement and test all requested acceptance criteria?
   - Any missing acceptance criterion is flagged as `Coverage: Not Covered` with Quality Gate `GAP`.
2. **Implementation Change → Requirement:**
   - Did the developer introduce unrequested behavior, modified unmentioned endpoints, or add scope creep?
   - Any unrequested code path is flagged as `Unrequested Scope` and evaluated for unintended regression risks.

> **Note on Traceability Exposure:** In default mode, this traceability ledger operates internally to select and prioritize tests without cluttering the QA test document. In `--full` mode, the full traceability chain (`REQ-ID → IMP-ID → RISK-ID`) is explicitly output.
