# QA Impact Analysis: [Feature / Bug Fix / Task Title]

## Analysis Scope & Inspected Evidence

- **User Story / Ticket Context:** `[Ticket-ID / Summary]` (Mandatory Input Gate: PASSED)
- **Repository:** `[repository-name]`
- **Git Scope:** `[base-branch]...[feature-branch]` (`[N]` commits)
- **Working Tree:** Clean / Uncommitted changes included
- **Inspected Evidence:** `[N]` source files, `[N]` infrastructure files, `[N]` test files, `[N]` schemas
- **Not Inspected / Unavailable:** `[None / mobile-app / external-service / runtime configs]`
- **Analysis Status:** `COMPLETE` / `PARTIAL` / `BLOCKED`
- **Confidence Level:** `HIGH` / `MEDIUM` / `LOW` — *[Brief explanation of confidence]*

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
| `database.md` | LOADED / EXCLUDED | [Reason based on diff] |
| `on-premise.md` | LOADED / EXCLUDED | [Reason based on diff] |
| `mobile.md` | LOADED / EXCLUDED | [Reason based on diff] |

## 3. Impact Summary & Blast Radius

### Verified Impact [Certain]
- Direct code changes, modified routes, updated database operations with exact `file:line` evidence.

### Potential Impact [Likely]
- Downstream callers, dependent UI components, event consumers inferred from architecture.

### Cross-Repository & Unverified Risks [Unknown / Cannot Verify]
- Companion client apps, external microservice consumers, unverified endpoints.
- *Fallback Evidence Checked:* OpenAPI / GraphQL / Client SDK / Mocks / Unknown.

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

## 8. QA Test Details (Executable Manual Test Cases)

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
  2. [Initial state requirement 2]
- **Test Data:**
  - `field_name`: `"test_value"`
- **Steps:**
  1. [Step 1]
  2. [Step 2]
  3. [Step 3]
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
| Requirement Coverage | PASS / GAP | All acceptance criteria mapped to tests |
| Code/Behavior Coverage | PASS / GAP | Changed code paths covered |
| Dependency Coverage | PASS / GAP | Downstream callers evaluated |
| Contract Coverage | PASS / GAP | API/event contracts verified |
| Security & Tenant Isolation | PASS / GAP | RBAC matrix verified |
| Cross-Repository Coverage | PASS / GAP / UNKNOWN | Companion repos or contract fallback |
| Evidence Integrity | PASS / GAP | All assertions grounded in evidence |
| Automated Test Status | NOT RUN | Inspected statically |

- **Quality Gate Overall:** `PASS` / `GAP` / `BLOCKED`
- **Recommended QA Readiness:** `READY` / `READY WITH GAPS` / `BLOCKED`
- **Gate Justification:** [Clear rationale based on verified risk and test coverage]
