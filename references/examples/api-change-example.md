# API Change Example: Modifying User Profile Contract with Multi-Client Impact

This reference example illustrates a QA impact analysis for a public API contract modification across Web and Mobile clients, including handling unverified cross-repository dependencies and backward compatibility.

---

```markdown
# QA Impact Analysis: Split `full_name` into `firstName` and `lastName` in Profile API

## Analysis Scope & Inspected Evidence

- **Repository:** `user-management-api`
- **Git Scope:** `origin/main...feature/split-name-contract` (4 commits)
- **Working Tree:** Clean
- **Inspected Evidence:** 4 source files, 1 schema file (`docs/openapi.json`), 3 test files
- **Not Inspected / Unavailable:** `android-app`, `ios-app` (External repositories; mobile client impact logged as unverified external risk)
- **Analysis Status:** `PARTIAL` (Backend code available; mobile client consumers unavailable)
- **Confidence Level:** `MEDIUM` — *Backend contract and validation changes verified; client deserialization on legacy mobile versions requires external QA verification.*

---

# LAYER 1: QA Release Handoff
*(Copy-paste ready for Jira / Linear / GitHub PR Description)*

### Summary & Risk Assessment
- **Change Description:** Updates `PUT /api/v2/users/profile` to accept `firstName` and `lastName`. Deprecates `full_name` but maintains backward compatibility by auto-splitting `full_name` if new fields are omitted.
- **Production Risk:** `HIGH` (Touches core user profile data used across all client platforms)
- **Blast Radius:** `HIGH` (Cross-platform: Web, Android, iOS, and external integrations)
- **Contract Compatibility:** `Compatible` (Backward-compatible fallback implemented in `src/transforms/name.ts:18`)
- **Change Type:** `API Change`
- **Recommended QA Readiness:** `READY WITH GAPS` (Backend ready; manual verification required on legacy mobile builds)

### Must-Test Scenarios (Mandatory QA)
| TC-ID | Title | Priority | Risk | Feasibility | Reason |
|---|---|---|---|---|---|
| TC-001 | Update Profile with New `firstName` and `lastName` Fields | P0 | HIGH | READY | Primary acceptance criteria validation |
| TC-002 | Backward Compatibility: Legacy Client Sends Only `full_name` | P0 | HIGH | READY | Prevents breaking older deployed mobile versions |
| TC-003 | Validation Error on Blank/Whitespace-Only Names | P1 | MEDIUM | READY | Input boundary and error-handling verification |
| TC-004 | GET Profile Returns Both Separate Names and Computed `fullName` | P1 | HIGH | READY | Regression check for client deserialization |

### Blocking Production Risks & Devil's Advocate
- **Cross-Repository Mobile App Risk:** If older mobile app versions strictly validate response schemas without `@JsonIgnoreProperties(ignoreUnknown = true)`, returning new fields `firstName` and `lastName` could trigger JSON deserialization crashes.
- **Client Cache Deserialization:** Ensure web client LocalStorage profile cache is migrated or invalidated when new response shape is received.

### Action Items & Ownership
| Action Item | Owner | Blocking Release? |
|---|---|:---:|
| Confirm mobile app response parsing ignores unknown fields | Mobile Team | Yes |
| Manually test `PUT /api/v2/users/profile` using legacy mobile app build (v3.2.0) on staging | QA (Mobile) | Yes |
| Verify web client profile edit form persists correctly after reload | QA (Web) | No |

---

# LAYER 2: Detailed Technical Impact Analysis

## 1. Bidirectional Requirements ↔ Test Coverage Matrix

| Requirement / Ticket ID | Implementation Status | Implementation Evidence | Test Case | Coverage Status | Risk |
|---|---|---|---|---|---|
| API-201 (Accept firstName & lastName) | Met | `src/controllers/user.ts:42` | TC-001 | Covered | High |
| API-201-AC1 (Auto-split full_name fallback) | Met | `src/transforms/name.ts:18-35` | TC-002 | Covered | High |
| API-201-AC2 (Reject whitespace-only names) | Met | `src/validators/user.ts:24` | TC-003 | Covered | Medium |
| API-201-AC3 (Computed fullName in GET response) | Met | `src/serializers/user.ts:15` | TC-004 | Covered | High |

## 2. Checklist Decisions

| Checklist | Decision | Justification |
|---|:---:|---|
| `api.md` | LOADED | Request and response schema modified |
| `database.md` | LOADED | Postgres migration adds `first_name` and `last_name` columns |
| `compatibility-and-caching.md` | LOADED | Client cache deserialization and rolling N/N+1 deploy checked |
| `mobile.md` | LOADED | Evaluated legacy mobile client backward-compatibility risk |
| `aws.md` | EXCLUDED | No AWS infrastructure or serverless Lambda changes |

## 3. Impact Summary & Blast Radius

### Verified Impact [Certain]
- `src/schemas/userProfile.json`: Updated JSON schema requiring `firstName` (max 50 chars) and `lastName` (max 50 chars) or `full_name`.
- `src/transforms/name.ts:18`: Fallback parser: `const [first, ...rest] = body.full_name.trim().split(/\s+/);`.
- `src/controllers/user.ts:55`: Writes `first_name` and `last_name` to Postgres `users` table.

### Potential Impact [Likely]
- Downstream search index sync job (`src/jobs/syncSearchIndex.ts:33`) now indexes `first_name` and `last_name`.

### Cross-Repository & Unverified Risks [Unknown / Cannot Verify]
- **`android-app` & `ios-app` Repositories:** Unavailable in current workspace. Deployed mobile clients may experience issues if response JSON schema is strictly typed.
- **Fallback Evidence Checked:** OpenAPI schema (`docs/openapi.json`) verified; mobile client repository code unavailable.

## 4. Side-Effect Inventory & Partial-Failure Analysis

- **Primary State Effect:** User record updated with `first_name` and `last_name` in Postgres `users` table.
- **Secondary Side Effects:**
  - Search index synchronization event published.
  - Web client LocalStorage session cache updated.
- **Partial-Failure Recovery Analysis:**
  - Database write operates in a single transaction; failure on validation prevents any partial row mutation.

## 5. Compatibility, Caching & Rollout Analysis

- **Rolling Deployment ($N$ / $N+1$):**
  - Database columns `first_name` and `last_name` are nullable in migration `20260909_add_names.sql:4`. Old backend instances can safely insert without error.
- **Response Compatibility:**
  - `GET /api/v2/users/profile` response includes `firstName`, `lastName`, and `full_name` (computed) to avoid breaking older consumers.

## 6. Devil's Advocate Failure Analysis

| Hypothesis | Vulnerability / Failure Mode | Evidence / Mechanism | Mitigating Test Case |
|---|---|---|---|
| Single-word name handling in fallback | User passes `full_name: "Cher"`. `lastName` becomes empty string or null. | `src/transforms/name.ts:22` defaults `last = ""` | TC-005 |
| Conflicting parameters sent | Client sends both `full_name: "Alice Smith"` and `firstName: "Bob"`. Which wins? | `src/transforms/name.ts:12` prioritizes explicit `firstName` | TC-006 |

## 7. QA Test Details (Executable Manual Test Cases)

### TC-001 — User Profile: Update Profile with New `firstName` and `lastName`
- **Objective:** Verify standard profile update using new separate name fields.
- **Type:** Functional / Contract
- **Risk:** HIGH | **Priority:** P0 | **Execution Tier:** Mandatory QA
- **Execution Feasibility:** `READY`
- **Target Platform:** REST API / Web Desktop
- **Environment:** Specified in context / Requires Confirmation
- **Persona / Role:** Standard Authenticated User
- **Preconditions:**
  1. User `user_test_01` exists and is logged in.
- **Test Data:**
  ```json
  {
    "firstName": "Alexander",
    "lastName": "Hamilton"
  }
  ```
- **Execution Steps:**
  1. Send `PUT /api/v2/users/profile` with the test payload.
  2. Send `GET /api/v2/users/profile` to retrieve updated profile.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API (PUT):** Returns `200 OK` with payload: *(Evidence: `src/controllers/user.ts:42`)*
      ```json
      {
        "id": "user_test_01",
        "firstName": "Alexander",
        "lastName": "Hamilton",
        "fullName": "Alexander Hamilton"
      }
      ```
    - **API (GET):** Returns `firstName: "Alexander"`, `lastName: "Hamilton"`, `fullName: "Alexander Hamilton"`. *(Evidence: `src/serializers/user.ts:15`)*
    - **Database:** Query `SELECT first_name, last_name FROM users WHERE id = 'user_test_01'` matches `"Alexander"` and `"Hamilton"`.
- **Traceability:** API-201 → IMP-01 → RISK-01
- **Evidence:** `src/controllers/user.ts:42` (Source: repository)

### TC-002 — User Profile: Backward Compatibility (Legacy Client Sends Only `full_name`)
- **Objective:** Verify that older mobile versions sending only `full_name` are properly parsed without error.
- **Type:** Regression / Backward Compatibility
- **Risk:** HIGH | **Priority:** P0 | **Execution Tier:** Mandatory QA
- **Execution Feasibility:** `READY`
- **Target Platform:** REST API
- **Environment:** Specified in context / Requires Confirmation
- **Persona / Role:** Standard Authenticated User
- **Test Data:** `{"full_name": "Marie Curie Skłodowska"}`
- **Execution Steps:**
  1. Send `PUT /api/v2/users/profile` containing ONLY `full_name`.
  2. Inspect HTTP status and database record.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API:** Returns `200 OK`. *(Evidence: `src/transforms/name.ts:18`)*
    - **Database:** `first_name` is set to `"Marie"`, `last_name` is set to `"Curie Skłodowska"`. *(Evidence: `src/controllers/user.ts:55`)*
- **Traceability:** API-201-AC1 → IMP-02 → RISK-02
- **Evidence:** `src/transforms/name.ts:18-35` (Source: repository)

### TC-003 — User Profile: Validation Error on Blank/Whitespace-Only Names
- **Objective:** Verify input rejection when names consist only of whitespace characters.
- **Type:** Negative / Boundary
- **Risk:** MEDIUM | **Priority:** P1 | **Execution Tier:** Recommended Regression
- **Execution Feasibility:** `READY`
- **Target Platform:** REST API
- **Environment:** Specified in context / Requires Confirmation
- **Test Data:** `{"firstName": "   ", "lastName": ""}`
- **Execution Steps:**
  1. Send `PUT /api/v2/users/profile` with whitespace-only values.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API:** Returns `400 Bad Request` with error validation array: *(Evidence: `src/validators/user.ts:24`)*
      ```json
      {
        "errors": [
          { "field": "firstName", "message": "firstName cannot be empty" }
        ]
      }
      ```
    - **Database:** User record remains completely unchanged.
- **Traceability:** API-201-AC2 → IMP-03 → RISK-03
- **Evidence:** `src/validators/user.ts:24` (Source: repository)

### TC-005 — User Profile: Single-Word Name Boundary in Fallback
- **Objective:** Verify that entering a mononym (single name) in `full_name` does not cause null pointer or string split crash.
- **Type:** Boundary / Negative
- **Risk:** MEDIUM | **Priority:** P2 | **Execution Tier:** Recommended Regression
- **Execution Feasibility:** `READY`
- **Target Platform:** REST API
- **Test Data:** `{"full_name": "Plato"}`
- **Execution Steps:**
  1. Send `PUT /api/v2/users/profile` with `full_name: "Plato"`.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API:** Returns `200 OK`. `firstName` is `"Plato"`, `lastName` is `""`. *(Evidence: `src/transforms/name.ts:22`)*
- **Traceability:** DEVIL-01 → IMP-05 → RISK-05
- **Evidence:** `src/transforms/name.ts:22` (Source: repository)

## 8. Existing Coverage & Test Quality Evaluation

- **Automated Tests Execution:** `NOT RUN (inspected statically)`

| Test File / Suite | Tested Symbol / Route | Status | Assertion Depth & Notes |
|---|---|---|---|
| `test/user.test.ts` | `updateProfile` | Stale / Contradictory | Test still sends legacy `full_name` and expects legacy response without `firstName`/`lastName`. |
| `test/transforms.test.ts` | `parseName()` | Covered | Unit tests verify string splitting logic across various whitespace inputs. |

## 9. Quality Gate Scorecard & Release Gate

### 9-Dimension Quality Gate Scorecard
| Dimension | Status | Notes |
|---|:---:|---|
| Requirement Completeness | PASS | Ticket clearly specified fields, fallback parsing, and boundary rules |
| Requirement Coverage | PASS | All acceptance criteria mapped to test cases |
| Code/Behavior Coverage | PASS | Controller, transform parser, and validator covered |
| Dependency Coverage | PASS | Downstream search sync job evaluated |
| Contract Coverage | PASS | OpenAPI schema updated and verified |
| Security & Tenant Isolation | PASS | User can only mutate own authenticated profile |
| Cross-Repository Coverage | GAP | Mobile companion repository code unavailable |
| Evidence Integrity | PASS | All assertions grounded in repository code |
| Automated Test Status | NOT RUN | Inspected statically |

- **Quality Gate Overall:** `GAP` (Cross-repository mobile client code unavailable)
- **Recommended QA Readiness:** `READY WITH GAPS`
- **Gate Justification:** Backward compatibility fallback handles legacy inputs; staging verification required for unverified mobile apps.
```
