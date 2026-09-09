# Feature Example: Multi-File Attachment Upload with S3 & RBAC Permissions

This reference example illustrates a QA impact analysis for a major new feature spanning backend S3 pre-signed URL generation, database tracking, RBAC tenant permissions, and feature flag rollout.

---

```markdown
# QA Impact Analysis: Multi-File Attachment Upload Support

## Analysis Scope & Inspected Evidence

- **Repository:** `document-service`
- **Git Scope:** `origin/main...feature/multi-file-attachments` (8 commits)
- **Working Tree:** Clean
- **Inspected Evidence:** 7 source files, 1 Terraform file, 4 test files, 1 OpenAPI schema (`docs/openapi.yaml`)
- **Not Inspected / Unavailable:** Production runtime S3 bucket permissions
- **Analysis Status:** `COMPLETE`
- **Confidence Level:** `HIGH` — *Direct code, AWS IaC definitions, and permission guards fully available.*

---

# LAYER 1: QA Release Handoff
*(Copy-paste ready for Jira / Linear / GitHub PR Description)*

### Summary & Risk Assessment
- **Change Description:** Adds capability for users to upload multiple file attachments (PDF, PNG, JPEG up to 10MB each) to workflow tickets using S3 pre-signed upload URLs. Guarded by feature flag `FEATURE_MULTI_ATTACHMENTS`.
- **Production Risk:** `HIGH` (Touches external S3 storage, IAM permissions, and file-type validation)
- **Blast Radius:** `MEDIUM` (Workflow ticket attachments module and S3 bucket quota)
- **Contract Compatibility:** `Compatible` (Adds new endpoint `POST /api/v1/tickets/:id/attachments/presign`; existing single-file upload endpoint preserved)
- **Change Type:** `New Feature`
- **Recommended QA Readiness:** `READY WITH GAPS` (Ready for functional QA; staging S3 CORS policy confirmation pending)

### Must-Test Scenarios (Mandatory QA)
| TC-ID | Title | Priority | Risk | Feasibility | Reason |
|---|---|---|---|---|---|
| TC-001 | Successful Multi-File Upload & Ticket Association | P0 | HIGH | REQUIRES TEST DATA | Core acceptance criteria validation |
| TC-002 | RBAC Security: Cross-Tenant File Upload Attempt Rejected | P0 | CRITICAL | REQUIRES TEST DATA | Verifies tenant isolation prevents cross-workplace file injection |
| TC-003 | File Validation: Reject Disallowed MIME Type (.exe) | P0 | HIGH | READY | Security protection against unauthorized executable uploads |
| TC-004 | File Size Boundary: Reject File Exceeding 10MB Limit | P1 | MEDIUM | READY | Validates byte boundary enforcement |
| TC-005 | Feature Flag OFF: Pre-signed Endpoint Returns 503 | P1 | MEDIUM | REQUIRES ENVIRONMENT SETUP | Verifies rollback capability and zero regression when disabled |

### Blocking Production Risks & Devil's Advocate
- **Orphan S3 Objects on Client Abort:** If S3 upload succeeds but user abandons session before the confirm endpoint is called, unattached objects accumulate in S3. S3 Lifecycle rule must be verified.
- **Content-Type Spoofing:** S3 upload pre-signed URL must enforce matching `Content-Type` header on PUT.

### Action Items & Ownership
| Action Item | Owner | Blocking Release? |
|---|---|:---:|
| Confirm S3 Bucket CORS policy allows `PUT` from staging web domain (`infra/s3.tf:45`) | Developer / DevOps | Yes |
| Validate S3 lifecycle expiration rule (7-day abort on unconfirmed uploads) in AWS Console | DevOps | No |
| Ensure feature flag `FEATURE_MULTI_ATTACHMENTS` is created in LaunchDarkly / Unleash | Developer | Yes |
| Execute mandatory manual QA test cases | QA | Yes |

---

# LAYER 2: Detailed Technical Impact Analysis

## 1. Bidirectional Requirements ↔ Test Coverage Matrix

| Requirement / AC | Implementation Status | Implementation Evidence | Test Case | Coverage Status | Risk |
|---|---|---|---|---|---|
| FEAT-501 (Pre-sign URLs) | Met | `src/services/attachment.ts:32-60` | TC-001 | Covered | High |
| FEAT-501-AC1 (Allowed MIME types) | Met | `src/validators/attachment.ts:18` | TC-003 | Covered | High |
| FEAT-501-AC2 (10MB size limit) | Met | `src/validators/attachment.ts:25` | TC-004 | Covered | Medium |
| FEAT-501-AC3 (RBAC author/admin) | Met | `src/guards/ticketRbac.ts:40` | TC-002 | Covered | Critical |
| FEAT-501-AC4 (Feature flag guard) | Met | `src/controllers/attachment.ts:15` | TC-005 | Covered | Medium |

## 2. Checklist Decisions

| Checklist | Decision | Justification |
|---|:---:|---|
| `api.md` | LOADED | New route `POST /api/v1/tickets/:id/attachments/presign` |
| `aws.md` | LOADED | S3 SDK v3 client and Terraform S3 bucket definitions modified |
| `security.md` | LOADED | Role and workplace tenant permissions enforced on upload |
| `compatibility-and-caching.md` | LOADED | Feature flag `FEATURE_MULTI_ATTACHMENTS` introduced |
| `mobile.md` | EXCLUDED | No mobile repository changes; OpenAPI contract verified compatible |

## 3. Impact Summary & Blast Radius

### Verified Impact [Certain]
- `src/controllers/attachment.ts:25`: New route handler `POST /api/v1/tickets/:id/attachments/presign`.
- `src/services/s3.ts:14`: AWS S3 SDK v3 client calling `getSignedUrl(s3Client, new PutObjectCommand(...))`.
- `infra/s3.tf:12`: New bucket `clappia-attachments-${var.env}` configured with private ACL and server-side AES256 encryption.

### Potential Impact [Likely]
- Database `ticket_attachments` table row count increases.
- CloudWatch S3 upload metrics.

## 4. Side-Effect Inventory & Partial-Failure Analysis

- **Primary State Effect:** Record created in `ticket_attachments` table with `status = 'CONFIRMED'`.
- **Secondary Side Effects:**
  - S3 Object stored in bucket `clappia-attachments-${var.env}`.
  - Audit log entry generated via `src/services/audit.ts:18`.
- **Partial-Failure Recovery Analysis:**
  - *Failure Mode:* User uploads binary to S3 but browser disconnects before calling `/confirm`.
  - *Recovery:* S3 object remains unassociated. Background job `src/jobs/s3Cleanup.ts:18` sweeps unconfirmed attachments older than 24 hours.

## 5. Security & RBAC Authorization Matrix

| Persona / Role | Target Resource & Scope | Action | Expected Result | Enforcement Evidence |
|---|---|---|---|---|
| Workplace Admin | Any Ticket in Workplace A | Generate Upload URL | Allow (`200 OK`) | `src/guards/ticketRbac.ts:42` |
| Ticket Author (Member) | Own Ticket in Workplace A | Generate Upload URL | Allow (`200 OK`) | `src/guards/ticketRbac.ts:48` |
| Non-Author Member | Another's Ticket in Workplace A | Generate Upload URL | Deny (`403 Forbidden`) | `src/guards/ticketRbac.ts:55` |
| Member (Workplace B) | Ticket in Workplace A | Generate Upload URL | Deny (`404 Not Found`) | `src/guards/tenant.ts:22` |
| Unauthenticated | Any Ticket | Generate Upload URL | Deny (`401 Unauthorized`) | `src/middleware/auth.ts:10` |

## 6. Compatibility, Caching & Rollout Analysis

- **Feature Flag Strategy:**
  - Controlled by `process.env.FEATURE_MULTI_ATTACHMENTS === "true"`.
  - When disabled, returns `503 Service Unavailable` with message `"Multi-file attachments feature is disabled"`.
- **Database Rollout:**
  - Table `ticket_attachments` created in independent migration `20260907_create_attachments.sql`. Zero impact on existing queries.

## 7. Devil's Advocate Failure Analysis

| Hypothesis | Vulnerability / Failure Mode | Evidence / Mechanism | Mitigating Test Case |
|---|---|---|---|
| Orphaned S3 uploads | User uploads file to S3 but closes browser before `confirm` API call | `src/jobs/s3Cleanup.ts:18` sweeps unconfirmed attachments older than 24h | TC-006 |
| Content-Type bypass | Attacker gets URL for `image.png` but uploads `virus.exe` | S3 `PutObjectCommand` signs `ContentType` header (`src/services/s3.ts:22`) | TC-007 |

## 8. QA Test Details (Executable Manual Test Cases)

### TC-001 — Attachments: Successful Multi-File Upload & Ticket Association
- **Objective:** Verify standard upload flow of 2 valid files (1 PDF and 1 PNG) attached to a ticket.
- **Type:** Functional / Integration
- **Risk:** HIGH | **Priority:** P0 | **Execution Tier:** Mandatory QA
- **Execution Feasibility:** `REQUIRES TEST DATA / FIXTURE SETUP`
- **Target Platform:** REST API & Web Desktop
- **Environment:** Specified in context / Requires Confirmation
- **Persona / Role:** Ticket Author (Standard User)
- **Preconditions:**
  1. Ticket `TCK-100` created by `test_user_01` in Workplace `WP-A`.
  2. Feature flag `FEATURE_MULTI_ATTACHMENTS` is `true`.
- **Test Data:**
  - File 1: `sample.pdf` (500 KB, `application/pdf`)
  - File 2: `diagram.png` (1.2 MB, `image/png`)
- **Execution Steps:**
  1. Call `POST /api/v1/tickets/TCK-100/attachments/presign` with payload:
     ```json
     {
       "files": [
         { "fileName": "sample.pdf", "contentType": "application/pdf", "fileSizeBytes": 512000 },
         { "fileName": "diagram.png", "contentType": "image/png", "fileSizeBytes": 1258291 }
       ]
     }
     ```
  2. For each returned `uploadUrl`, execute HTTP `PUT` with file binary data and matching `Content-Type` header.
  3. Call `POST /api/v1/tickets/TCK-100/attachments/confirm` with returned `attachmentIds`.
  4. Query `GET /api/v1/tickets/TCK-100/attachments`.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API (Step 1):** Status `200 OK` with 2 pre-signed S3 URLs and unique `attachmentId`s. *(Evidence: `src/controllers/attachment.ts:38`)*
    - **S3 (Step 2):** Each `PUT` returns `200 OK`. *(Evidence: AWS S3 contract)*
    - **API (Step 3):** Status `200 OK` with `"status": "ATTACHED"`. *(Evidence: `src/controllers/attachment.ts:72`)*
    - **Database:** Rows exist in `ticket_attachments` table with `status = 'CONFIRMED'`. *(Evidence: `src/services/attachment.ts:95`)*
  - **Diagnostic Observation:**
    - **Observability:** Audit log entry created in CloudWatch/Datadog: `AttachmentConfirmed: TCK-100`. *(Evidence: `src/services/audit.ts:18`)*
- **Cleanup / Postconditions:**
  - Delete ticket `TCK-100` and associated S3 objects via admin test cleanup script.
- **Traceability:** FEAT-501 → IMP-01 → RISK-01
- **Evidence:** `src/services/attachment.ts:32-60` (Source: repository)

### TC-002 — Attachments: Cross-Tenant File Upload Attempt Rejected
- **Objective:** Ensure user from Workplace B cannot generate upload URLs or attach files to Workplace A tickets.
- **Type:** Security / Multi-Tenant Isolation
- **Risk:** CRITICAL | **Priority:** P0 | **Execution Tier:** Mandatory QA
- **Execution Feasibility:** `REQUIRES TEST DATA / FIXTURE SETUP`
- **Target Platform:** REST API
- **Environment:** Specified in context / Requires Confirmation
- **Persona / Role:** Member of Workplace B (Cross-Tenant Attacker)
- **Preconditions:**
  1. Ticket `TCK-100` belongs to Workplace A.
  2. User token belongs to authenticated user in Workplace B.
- **Execution Steps:**
  1. Send `POST /api/v1/tickets/TCK-100/attachments/presign` with Workplace B JWT token.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API:** Returns `404 Not Found` (never confirms ticket existence across tenant boundary). *(Evidence: `src/guards/tenant.ts:22`)*
    - **Database:** Zero records created in `ticket_attachments`. *(Evidence: `src/services/attachment.ts:40`)*
  - **Diagnostic Observation:**
    - **Observability:** Application log records authorization rejection signal; exact log message requires verification in test environment.
- **Traceability:** FEAT-501-AC3 → IMP-02 → RISK-SEC-01
- **Evidence:** `src/guards/tenant.ts:22` (Source: repository)

### TC-003 — Attachments: Reject Disallowed MIME Type (.exe / .sh)
- **Objective:** Verify upload rejection for non-whitelisted file extensions.
- **Type:** Negative / Security
- **Risk:** HIGH | **Priority:** P0 | **Execution Tier:** Mandatory QA
- **Execution Feasibility:** `READY`
- **Target Platform:** REST API
- **Test Data:** `{"fileName": "exploit.exe", "contentType": "application/x-msdownload", "fileSizeBytes": 1024}`
- **Execution Steps:**
  1. Send `POST /api/v1/tickets/TCK-100/attachments/presign` with `.exe` file metadata.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API:** Returns `422 Unprocessable Entity` with error:
      ```json
      {
        "code": "INVALID_FILE_TYPE",
        "message": "File type application/x-msdownload is not allowed. Supported: pdf, png, jpeg"
      }
      ```
  - **Diagnostic Observation:**
    - Error metric `validation_error_mime_type` incremented in observability platform.
- **Traceability:** FEAT-501-AC1 → IMP-03 → RISK-03
- **Evidence:** `src/validators/attachment.ts:18` (Source: repository)

### TC-004 — Attachments: Reject File Exceeding 10MB Limit
- **Objective:** Verify boundary check rejecting files larger than 10MB (10,485,760 bytes).
- **Type:** Boundary / Negative
- **Risk:** MEDIUM | **Priority:** P1 | **Execution Tier:** Recommended Regression
- **Execution Feasibility:** `READY`
- **Target Platform:** REST API
- **Test Data:** `{"fileName": "huge.pdf", "contentType": "application/pdf", "fileSizeBytes": 10485761}` (10MB + 1 byte)
- **Execution Steps:**
  1. Send `POST /api/v1/tickets/TCK-100/attachments/presign` with 10,485,761 bytes.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API:** Returns `422 Unprocessable Entity` with error `"File size exceeds maximum limit of 10MB"`.
- **Traceability:** FEAT-501-AC2 → IMP-04 → RISK-04
- **Evidence:** `src/validators/attachment.ts:25` (Source: repository)

### TC-005 — Attachments: Feature Flag OFF Safe Degradation
- **Objective:** Verify endpoint behavior when `FEATURE_MULTI_ATTACHMENTS` is set to `false`.
- **Type:** Functional / Feature Flag
- **Risk:** MEDIUM | **Priority:** P1 | **Execution Tier:** Recommended Regression
- **Execution Feasibility:** `REQUIRES ENVIRONMENT SETUP`
- **Preconditions:**
  1. Feature flag disabled in environment.
- **Execution Steps:**
  1. Send valid upload request to `POST /api/v1/tickets/TCK-100/attachments/presign`.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - **API:** Returns `503 Service Unavailable` with body `{"message": "Multi-file attachments feature is disabled"}`.
- **Traceability:** FEAT-501-AC4 → IMP-05 → RISK-05
- **Evidence:** `src/controllers/attachment.ts:15` (Source: repository)

## 9. Existing Coverage & Test Quality Evaluation

- **Automated Tests Execution:** `NOT RUN (inspected statically)`

| Test File / Suite | Tested Symbol / Route | Status | Assertion Depth & Notes |
|---|---|---|---|
| `test/attachment.test.ts` | `generatePresignedUrl` | Covered | Validates S3 command parameters and expiration timestamp. |
| `test/rbac.test.ts` | `ticketRbacGuard` | Partially Covered | Shallow: tests admin role, but lacks cross-tenant negative test assertion. |

## 10. Quality Gate Scorecard & Release Gate

### 9-Dimension Quality Gate Scorecard
| Dimension | Status | Notes |
|---|:---:|---|
| Requirement Completeness | PASS | Story clearly defined file types, 10MB ceiling, and role constraints |
| Requirement Coverage | PASS | All 5 acceptance criteria mapped to test cases |
| Code/Behavior Coverage | PASS | Pre-sign, validation, and confirm handlers tested |
| Dependency Coverage | PASS | S3 client and DB attachment repo evaluated |
| Contract Coverage | PASS | OpenAPI spec matches controller response |
| Security & Tenant Isolation | PASS | RBAC and cross-tenant boundaries covered (TC-002) |
| Cross-Repository Coverage | PASS | OpenAPI spec verifies client compatibility |
| Evidence Integrity | PASS | All assertions grounded in repository code |
| Automated Test Status | NOT RUN | Inspected statically |

- **Quality Gate Overall:** `PASS`
- **Recommended QA Readiness:** `READY WITH GAPS`
- **Gate Justification:** Code and security requirements are fully covered. Staging S3 CORS policy confirmation is required prior to full QA sign-off.
```
