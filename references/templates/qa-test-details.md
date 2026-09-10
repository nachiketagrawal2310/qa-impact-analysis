# QA Impact Analysis Templates

This document provides canonical output templates for the `qa-impact-analysis` skill across its output modes:
1. **Default Test-Details Template** (Used for standard `/qa-impact-analysis` invocations)
2. **Full Analysis Template** (Used for `--full` or requests like *"Give me the full impact analysis"*)
3. **Phased Phase-1 Checkpoint Template** (Used for Phase 1 of `--phased` or *"Do phased analysis"*)
4. **Phased Final Test-Details Template** (Used for Phase 2 of phased workflows after developer feedback)

---

## 1. DEFAULT TEST-DETAILS TEMPLATE

Use this template by default. It produces **strictly executable manual test cases** for QA engineers, containing zero architecture narrative, zero internal finding IDs, and zero confidence tags.

```markdown
# QA Test Details

## Preconditions / Test Data

- User with [Role / Permission, e.g. Workplace Admin] access
- Existing test records: [Specific entities / IDs / setup state]
- Test data: [Exact JSON payloads, form values, boundary inputs, or file specs]
- Operational tooling access: [CloudWatch Logs / Alarms / DB client] *(only if required to verify telemetry)*

## Test Cases

### TC-01 — [Primary Happy-Path Scenario Title]
**Priority:** P0
**Type:** Functional
**Feasibility:** Manual / Requires test data / Requires developer support / Requires environment access

**Steps**
1. Log in as [User Role] and navigate to [View / Feature].
2. Perform [Action / Input] with valid data [Data Specs].
3. Click [Submit / Action Button].
4. [Follow-up verification action, e.g. reload or check list].

**Expected Result**
- [Primary client observable outcome: success toast, updated view, status change].
- [Backend/API outcome: HTTP 200/201, payload structure].
- [Data persistence: record created in DB, expected field values].

### TC-02 — [Negative / Boundary Condition Scenario Title]
**Priority:** P0
**Type:** Negative
**Feasibility:** Manual / Requires test data / Requires developer support / Requires environment access

**Steps**
1. Navigate to [Feature].
2. Provide invalid/boundary data [Data Specs, e.g. exceeding 500 records].
3. Trigger the action.

**Expected Result**
- Request is rejected with expected validation error message [e.g. HTTP 400 Bad Request].
- No partial state or orphan records written.
- UI displays clear actionable field error.

### TC-03 — [Implementation Impact / Regression Scenario Title]
**Priority:** P0
**Type:** Negative / Regression
**Feasibility:** Manual / Requires test data / Requires developer support / Requires environment access

**Steps**
1. Request a non-existent or conflicting entity.
2. Verify API response.
3. Check application logs and CloudWatch metric/alarm.

**Expected Result**
- Expected NotFound response (e.g. HTTP 404) is returned.
- Event is logged as WARN, not ERROR.
- Expected NotFound does NOT increment the ERROR alarm or trigger pager.

### TC-04 — [Failure Recovery / Unexpected Error Scenario Title]
**Priority:** P1
**Type:** Negative / Integration
**Feasibility:** Requires developer support to inject controlled failure

**Steps**
1. Trigger controlled unexpected failure (with developer/infra support).
2. Check Lambda/service logs.
3. Check corresponding CloudWatch metric and alarm.

**Expected Result**
- Unexpected failure produces ERROR log.
- CloudWatch metric count increases and triggers alarm according to threshold.
- Notification (SNS/Slack) is dispatched.

## Notes *(Optional)*

- [Environment prerequisites, e.g. "Requires Prod-like staging environment with active CloudWatch Alarms."]
- [Multi-tenant prerequisites, e.g. "Requires two separate workplace tenants to verify cross-tenant data isolation."]
- [Scope note when omission might otherwise confuse QA, e.g. "**Scope Note:** No mobile-specific cases included; no affected mobile consumer was identified."]
```

---

## 2. FULL ANALYSIS TEMPLATE

Use this template when the user explicitly requests full technical impact analysis (`--full` or natural language like *"Give me the full impact analysis"* or *"Show me why these tests were selected"*).

```markdown
# QA Impact Analysis: [Feature / Bug Fix / Task Title]

## Analysis Scope & Inspected Evidence

- **User Story / Ticket Context:** `[Ticket-ID / Summary]` (Mandatory Input Gate: PASSED)
- **Repository:** `[repository-name]`
- **Git Scope:** `[base-branch]...[feature-branch]` (`[N]` commits)
- **Working Tree:** Clean / Uncommitted changes included
- **Inspected Evidence:** `[N]` source files, `[N]` infrastructure files, `[N]` test files, `[N]` schemas
- **Not Inspected / Unavailable:** `[None / mobile-app / external-service / runtime configs]`
- **Analysis Status:** `COMPLETE` / `PARTIAL` / `BLOCKED`
- **Confidence Level:** `HIGH` / `MEDIUM` / `LOW` — *[Brief explanation]*

---

# LAYER 1: QA Release Handoff
*(Copy-paste ready for Jira / Linear / GitHub PR Description)*

### Summary & Risk Assessment
- **Change Description:** [1-2 sentences summarizing what changed and why]
- **Production Risk:** `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`
- **Blast Radius:** `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`
- **Contract Compatibility:** `Compatible` / `Breaking` / `Unverified (Cross-Repo)`
- **Change Type:** `Bug Fix` / `New Feature` / `Refactor` / `API Change` / `DB Migration`
- **Recommended QA Readiness:** `READY` / `READY WITH GAPS` / `BLOCKED`

### Must-Test Scenarios (Mandatory QA)
| TC-ID | Title | Priority | Risk | Feasibility | Reason |
|---|---|---|---|---|---|
| TC-001 | [Test Title] | P0 | HIGH | READY | Direct requirement validation |
| TC-002 | [Test Title] | P0 | HIGH | REQUIRES TEST DATA | High-risk failure path / regression |

### Blocking Production Risks & Devil's Advocate
- **[Primary Risk]:** [Concrete failure mode that could cause production incident]
- **[Secondary Risk]:** [State inconsistency, data corruption, or backward compatibility issue]

### Action Items & Ownership
| Action Item | Owner | Blocking Release? |
|---|---|:---:|
| [Action 1: e.g., Confirm mobile app schema compatibility] | Mobile Team | Yes |
| [Action 2: e.g., Verify feature flag is configured in staging] | Developer / DevOps | Yes |
| [Action 3: e.g., Execute mandatory manual QA test cases] | QA | Yes |

---

# LAYER 2: Detailed Technical Impact Analysis

## 1. Bidirectional Requirements ↔ Test Coverage Matrix

| Requirement / AC | Implementation Status | Implementation Evidence | Test Case | Coverage Status | Risk |
|---|---|---|---|---|---|
| REQ-01 | Met | `src/...:line` | TC-001 | Covered | High |
| REQ-02 (Negative) | Met | `src/...:line` | TC-002 | Covered | High |
| Unrequested Code | Unrequested Scope | `src/...:line` | — | Not Covered | Medium |

## 2. Checklist Decisions

| Checklist | Decision | Justification |
|---|:---:|---|
| `api.md` | LOADED / EXCLUDED | [Reason based on diff] |
| `security.md` | LOADED / EXCLUDED | [Reason based on diff] |
| `aws.md` | LOADED / EXCLUDED | [Reason based on diff] |
| `database.md` | LOADED / EXCLUDED | [Reason based on diff] |
| `mobile.md` | LOADED / EXCLUDED | [Reason based on diff] |

## 3. Impact Summary & Blast Radius

### Verified Impact [Certain]
- Direct code changes, modified routes, updated database operations with exact `file:line` evidence.

### Potential Impact [Likely]
- Downstream callers, dependent UI components, event consumers inferred from architecture.

### Cross-Repository & Unverified Risks [Unknown / Cannot Verify]
- Companion client apps, external microservice consumers, unverified endpoints.

## 4. Side-Effect Inventory & Partial-Failure Analysis
*(Include when change creates, updates, or deletes state)*
- **Primary State Effect:** [Main record/file/state created or updated]
- **Secondary Side Effects:** [DB rows, S3 files, event bus messages, push notifications, cache keys]
- **Partial-Failure Recovery Analysis:** [What if step 2 fails after step 1 succeeds? Are orphan records left? Is compensation logic in place?]

## 5. Security & RBAC Authorization Matrix
*(Include if auth, roles, workplace/tenant, or IDs are touched)*

| Persona / Role | Resource & Scope | Action | Expected Result | Enforcement Evidence |
|---|---|---|---|---|
| Workplace Admin | Workplace A Resource | Create / Update | Allow (`200 OK`) | `src/...:line` |
| Member / Submitter | Workplace A Resource | Update | Deny (`403 Forbidden`) | `src/...:line` |
| Member (Workplace B) | Workplace A Resource | Read | Deny (`404 / 403 Cross-Tenant`) | `src/...:line` |
| Unauthenticated | Any Resource | Any API Call | Deny (`401 Unauthorized`) | `src/...:line` |

## 6. Compatibility, Caching & Rollout Analysis
*(Include if API, DB, cache, or feature flags are touched)*
- **Client Caching:** [LocalStorage, IndexedDB, SQLite, CoreData impact]
- **Rolling Deployment ($N$ / $N+1$):** [Behavior when old client hits new backend or vice versa]
- **Feature Flag Strategy:** [Behavior when Flag is OFF vs ON, and dynamic toggle safety]

## 7. Devil's Advocate Failure Analysis

| Hypothesis | Vulnerability / Failure Mode | Evidence / Mechanism | Mitigating Test Case |
|---|---|---|---|
| [Assumption failure] | [What happens if input format or order varies] | `src/...:line` | TC-003 |
| [Race condition] | [Rapid double-submit or simultaneous calls] | `src/...:line` | TC-004 |

## 8. QA Test Details (Executable Manual Test Cards)

### TC-001 — [Area]: [Title]
- **Objective:** [Specific business rule or failure mode verified]
- **Type:** Functional / Negative / Boundary / Regression / Security / Concurrency
- **Risk:** HIGH | **Priority:** P0 | **Execution Tier:** Mandatory QA
- **Execution Feasibility:** READY / REQUIRES TEST DATA / REQUIRES DEV/INFRA SUPPORT
- **Target Platform:** Web Desktop / Mobile (Android/iOS) / API / On-Premise
- **Environment:** Specified in context / Requires Confirmation
- **Persona / Role:** [e.g., Workplace Admin]
- **Preconditions:**
  1. [Initial state requirement 1]
- **Test Data:**
  - `field_name`: `"test_value"`
- **Steps:**
  1. [Step 1]
  2. [Step 2]
- **Expected Observable Results:**
  - **Mandatory Oracle (Required for Pass/Fail):**
    - **UI:** [Banner text, modal, field error, button state]
    - **API:** [HTTP status code, response body payload]
    - **Database:** [Record mutation, audit log created]
  - **Diagnostic Observation (Operational Signal — Not Pass/Fail Blocker):**
    - **Observability:** [Log string, metric increment; flag for verification if unconfirmed]
- **Cleanup / Postconditions:** [Reset state / restore flag]
- **Traceability:** REQ-01 → IMP-01 → RISK-01
- **Evidence:** `src/handlers/example.ts:45` (Source: repository / requirement / user-confirmed)

*(Repeat for each TC-ID. Omit irrelevant sub-bullets.)*

## 9. Existing Coverage & Test Quality Evaluation

- **Automated Tests Execution:** `NOT RUN (inspected statically)` *(or list execution results)*

| Test File / Suite | Tested Symbol / Route | Status | Assertion Depth & Notes |
|---|---|---|---|
| `test/example.test.ts` | `updateRecord()` | Partially Covered | Shallow: only checks 200, does not assert payload. |

## 10. Quality Gate Scorecard & Release Gate

### 9-Dimension Quality Gate Scorecard
| Dimension | Status | Notes |
|---|:---:|---|
| Requirement Completeness | PASS / GAP | Story ambiguity / completeness audit |
| Requirement Coverage | PASS / GAP | All acceptance criteria mapped |
| Code/Behavior Coverage | PASS / GAP | All modified code branches tested |
| Dependency Coverage | PASS / GAP | Downstream callers evaluated |
| Contract Coverage | PASS / GAP | API/event contracts verified |
| Security & Tenant Isolation | PASS / GAP | RBAC matrix verified |
| Cross-Repository Coverage | PASS / GAP / UNKNOWN | Companion repos or contract fallback |
| Evidence Integrity | PASS / GAP | All assertions grounded in evidence |
| Automated Test Status | NOT RUN | Inspected statically |

- **Quality Gate Overall:** `PASS` / `GAP` / `BLOCKED`
- **Recommended QA Readiness:** `READY` / `READY WITH GAPS` / `BLOCKED`
- **Gate Justification:** [Summary of decision]
```

---

## 3. PHASED PHASE-1 TEMPLATE (Checkpoint)

Use this template during Phase 1 of a phased analysis (`--phased` or *"Do phased analysis"*).
The skill presents the understood requirement, detected change scope, and confirmed impact graph, and then **STOPS** for developer feedback before generating test cases.

```markdown
# QA Impact Analysis: Phase 1 Checkpoint

## 1. Requirement Understanding
- **User Story:** [Summary of business requirement]
- **Primary Acceptance Criteria:**
  1. [Criterion 1]
  2. [Criterion 2]
- **Out of Scope Items:** [Explicitly excluded scope]

## 2. Detected Change Scope
- **Repository & Branch:** `[repo-name]` (`[base]...[current]`)
- **Modified Components:**
  - `[Service / Controller / Lambda]`: [Summary of change]
  - `[Database / Schema / Migrations]`: [Summary of mutation]
  - `[Infrastructure / CloudFormation / Alarms]`: [Summary of infra changes]

## 3. Confirmed Impact & Dependencies
- **Upstream Call Sites:** [Direct controllers or entry points]
- **Downstream Services / DBs:** [Impacted databases, queues, external APIs]
- **Client Impact:**
  - Web: [Impacted views / forms]
  - Mobile: [Android/iOS impact or confirmed unimpacted]
- **Primary Risk Hypotheses:**
  1. [Hypothesis 1, e.g. Race condition on double submit]
  2. [Hypothesis 2, e.g. CloudWatch alarm false positives on 404]

---

### 🛑 Checkpoint: Developer Confirmation Required

Please review the understood requirement, change scope, and impact graph:
- **Did we miss any affected service, database, or background worker?** (e.g. *"You missed ReportingService"*)
- **Are there corrections to expected behavior or business rules?** (e.g. *"Expected behavior is 404, not 400"*)

Reply with your feedback or say **"Proceed"** to generate the final executable QA test details.
```

---

## 4. PHASED FINAL TEST-DETAILS TEMPLATE

Use this template for Phase 2 of a phased analysis after developer feedback has been provided. Incorporate user-confirmed corrections into the test suite and output the clean QA test details.

```markdown
# QA Test Details (Phase 2 Deliverable)

*(Incorporating developer feedback: [Brief 1-sentence note of what was adjusted])*

## Preconditions / Test Data

- User with [Role / Permission] access
- Existing test records: [Specific entities / IDs]
- Test data: [Payloads, boundary data]
- Tooling access: [Logs, alarms, DB]

## Test Cases

### TC-01 — [Test Title]
**Priority:** P0
**Type:** Functional
**Feasibility:** Manual / Requires test data / Requires developer support / Requires environment access

**Steps**
1. ...
2. ...

**Expected Result**
- ...
- ...

### TC-02 — [Test Title]
**Priority:** P0
**Type:** Negative
**Feasibility:** Manual / Requires test data / Requires developer support / Requires environment access

**Steps**
1. ...
2. ...

**Expected Result**
- ...

## Notes *(Optional)*

- [Dependencies, staging environments, or fault-injection prerequisites]
- [Scope notes]
```
