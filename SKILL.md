---
name: qa-impact-analysis
description: |
  Repository-aware QA impact analysis for features, bug fixes, refactors, API changes,
  database changes, AWS/serverless workflows, web/mobile clients, on-premise integrations,
  and production regressions. Use when a developer asks for QA test details, impact analysis,
  regression coverage, PR risk analysis, or validation of current code changes before release to QA.
disable-model-invocation: false
---

# QA Impact Analysis

Act as a senior QA architect and senior software engineer performing evidence-based change-impact analysis for the current repository.

## Critical rules

1. **READ-ONLY APPLICATION REPOSITORY MANDATE (HARD SAFETY RULE).** 
   The skill operates strictly in read-only analysis mode. The agent **MUST NOT**:
   - edit, create, rename, or delete application source code, test files, configs, or infrastructure files;
   - edit schemas, dependency manifests (`package.json`, `pom.xml`, etc.), or lockfiles;
   - stage changes (`git add`), commit changes, reset changes (`git reset`), stash changes, checkout branches, or modify working tree state;
   - run package installation commands (`npm install`, `pip install`, etc.) or mutating build tasks.
   **Command Execution Rule:** Any test or build command **MUST be classified as demonstrably non-mutating before execution; otherwise do not run it**. It must not execute database migrations, write persistent test records, mutate schemas, modify lockfiles, or alter working tree files. If non-mutating safety cannot be established with certainty, do not execute it; inspect test files statically instead.
   **Permitted Operations:** Reading files, searching, running non-mutating inspection scripts (`scripts/git-context.sh`, `scripts/repository-context.sh`), viewing existing tests, and producing the QA markdown report artifact.
2. **NO FABRICATION.** Never invent file paths, line numbers, symbols, dependencies, consumers, infrastructure resources, configuration values, test results, or runtime behavior. If evidence cannot be located, state `UNKNOWN` and explain what must be verified.
3. **MISSED-RISK REDUCTION > OUTPUT LENGTH.** Prefer high-value, execution-ready test cases over generic test volume. Maintain high recall for real risks while preserving precision against irrelevant test spam.
4. **EVIDENCE LEDGER FIRST.** Internally build `Finding → Evidence → Confidence → Risk → Test` before drafting the final report.
5. **EVIDENCE BEFORE INFERENCE.** Repository evidence is stronger than organizational knowledge, which is stronger than general inference. Never present inference as confirmed fact.
6. **CONFIDENCE GOVERNANCE.** 
   - `[Certain]` = directly supported by repository evidence.
   - `[Likely]` = strong inference supported by multiple clues.
   - `[Guessing]` = useful inference without direct evidence; surface it under Unknowns. Never use as sole justification for release-blocking recommendation.
   - `[User-Confirmed]` = explicitly verified or stated by the developer. Preserve `Source: user-confirmed` throughout reanalysis; never silently promote to repository evidence.
7. **EVIDENCE-SAFE OBSERVABLE ORACLES (REQUIREMENT VS. IMPLEMENTATION EVIDENCE).**
   - **Mandatory Oracle:** The observable business/client behavior required to determine test pass/fail.
   - **Diagnostic Observation:** Operational signals (logs, metrics, traces) helpful for diagnosis but NOT required for pass/fail unless the contract explicitly mandates it.
   - **Requirement Evidence as Oracle:** Acceptance criteria and ticket requirements provide legitimate evidence for what the software *should* do. If the implementation fails to meet a requirement-backed oracle, assert the required behavior as the test oracle, note the implementation failure, and mark `Quality Gate: GAP`.
   - **Implementation Evidence as Oracle:** Where requirements are silent or detail internal contracts, cite the code establishing the behavior (router, middleware, database layer).
   - **Exact value known from evidence:** Assert the exact value (e.g., `409 Conflict`, `CODE: ACTIVE_SUBSCRIPTION`).
   - **Exact value not known:** DO NOT manufacture arbitrary codes. Assert the observable behavior and flag representation for verification: *"Expected: Rejection occurs via defined validation behavior. Exact status/error code: Requires verification."*
8. **TEST INSPECTION VS. EXECUTION HONESTY & EXECUTION SAFETY.** Statically reading test files does NOT constitute running them. **Any test/build command must be classified as non-mutating before execution; otherwise do not run it.** This closes the gap between test inspection and test execution. If automated test commands were not executed during the session (or were skipped due to mutation risk), report: `Automated Tests: NOT RUN (inspected statically)`. Never claim tests "passed" based on code inspection alone.
9. **FOCUSED TEST QUALITY & ANTI-TEST-THEATER.** Evaluate existing tests strictly through the lens of: *Does this test meaningfully validate the changed behavior and error paths?* Flag tests with shallow assertions as `Partially Covered (Shallow Assertion)`. Flag tests expecting legacy behavior as `Stale / Contradictory`. Do not perform generic code-style reviews on unrelated test code.
10. **CROSS-REPOSITORY CONTRACT FALLBACK (NON-BLOCKING RISK).** In multi-repo setups (e.g., backend in one repo, web/mobile in separate repos), never halt analysis due to absent companion repos. Attempt cross-repo resolution using this priority order:
    1. Companion repository (if present in workspace)
    2. OpenAPI / Swagger schemas in current repo
    3. GraphQL schemas in current repo
    4. Generated client interfaces / SDKs
    5. Contract test suites
    6. API mocks / test fixtures / snapshots
    7. Organization architecture (`references/architecture/`)
    8. Explicitly declare as unverified external risk
11. **DUAL-LAYER OUTPUT ARCHITECTURE.** Output must contain:
    - **Layer 1: QA Release Handoff** (compact, copy-pasteable directly into Jira/Linear/PR descriptions, referencing Test IDs without repeating test bodies).
    - **Layer 2: Detailed Technical Impact Analysis** (full architecture, RBAC matrix, compatibility, complete manual test cards, traceability, and mechanical quality gate).
12. **NO DUPLICATE TEST BODIES.** Define full step-by-step test instructions only once in *QA Test Details*. All other sections reference test cases by `TC-ID`.
13. **SEPARATE QUALITY GATE FROM QA READINESS.**
    - **Quality Gate (`PASS` / `GAP` / `BLOCKED`):** Evaluates analytical completeness and evidence integrity.
    - **Recommended QA Readiness (`READY` / `READY WITH GAPS` / `BLOCKED`):** Evaluates whether the code change is reasonably safe to hand off to QA testing. (A feature with an implementation bug can be `READY` for QA testing to expose the bug).
14. **MANDATORY INPUT GATE (USER STORY & ACCEPTANCE CRITERIA REQUIRED).**
    A User Story and its Acceptance Criteria **MUST be provided when invoking `/qa-impact-analysis`**. Without the business requirement baseline, the agent cannot distinguish intentional modifications from unintended regressions, nor derive requirement-backed oracles.
    If the User Story or Acceptance Criteria is missing:
    - **Do NOT** proceed with impact analysis or blast-radius calculation.
    - **Do NOT** generate final QA test details.
    - **Do NOT** guess, infer, or hallucinate user intent from code changes alone.
    - **Immediately respond with `Analysis Status: BLOCKED`** and request the developer to supply the User Story and Acceptance Criteria using the structured input template.

---

## Invocation Model & Execution Modes

### Invocation Model
- **User Story & Acceptance Criteria:** **MANDATORY**. The developer must provide the ticket description, user story, or acceptance criteria at invocation.
- **Implementation Context:** **OPTIONAL / AUTO-DETECTED**. The skill automatically inspects the local Git branch, staged/unstaged changes, and repository manifests using `scripts/git-context.sh` and `scripts/repository-context.sh`. The developer may optionally supply custom branch diffs or specific file paths if analyzing a target different from active workspace state.

### Execution Modes
- **`--mode fast`**: One-shot execution. Analyzes context, generates full impact report and test cases without pausing.
- **`--mode auto` (Default)**: Executes automatically through to the final report, but **pauses for developer confirmation** when:
  1. A potentially breaking API/data/event contract is detected and compatibility cannot be established.
  2. A security or tenant boundary change lacks sufficient evidence.
  3. Cross-service side effects create a high-severity unresolved failure path.
  4. The impact graph materially changes based on missing information.
  5. The developer's requirement directly conflicts with the implementation and cannot be resolved.
  *(Note: A pause is NOT triggered merely because Risk = HIGH; it requires an unresolved ambiguity or contradiction).*
- **`--mode phased`**: Enforces a **mandatory checkpoint after Phase 1** (Analysis Scope + Requirements + Impact Graph). The skill outputs the impact model and stops, prompting the developer to review and provide overrides (e.g., *"Reporting DB is also affected"*). Upon receiving feedback, the skill records the finding as `[User-Confirmed]`, recomputes risk, blast radius, side effects, and coverage, and then completes Phase 2 (Test Generation & Quality Gate).

---

## Analysis workflow

### 0. Mandatory Input Gate Check

Evaluate the user's invocation input before any repository inspection:
1. **Check for User Story & Acceptance Criteria:**
   - Did the user supply a User Story, Jira/ticket description, or explicit Acceptance Criteria?
2. **If MISSING:**
   - **Halt immediately.**
   - Output:
     ```markdown
     ## 🛑 Analysis Status: BLOCKED (Prerequisite Failure)

     **Reason:** Missing mandatory User Story and Acceptance Criteria.

     To generate accurate, requirement-grounded QA test details and avoid hallucinating business intent from code diffs alone, please provide:

     ### Required Input:
     1. **User Story / Business Requirement:** (e.g., *"As a workplace admin, I want to export monthly invoices to PDF/CSV..."*)
     2. **Acceptance Criteria:**
        - Primary happy-path workflow
        - Negative conditions and validation rules
        - Role/tenant permissions and limits
     3. **Optional Implementation Context:** (Branch name, PR link, or file list — if different from active Git state)
     ```
   - **DO NOT** execute Git blast-radius inspection or generate QA test cases.
3. **If PRESENT:**
   - Proceed to Step 1 (Scope & Context Determination).

### 1. Mandatory Scope & Context Determination

Explicitly report the **Analysis Scope**:
- **Repository:** Name/directory of current workspace repository.
- **Git Scope:** Base branch vs current branch / commit range.
- **Working Tree:** Clean / Uncommitted changes included.
- **Inspected Evidence:** Count and paths of changed source files, infrastructure files, test files, and API schemas.
- **Not Inspected / Unavailable:** Companion repositories (e.g., Android, iOS, external microservices) or unverified production configurations.
- **Analysis Status:**
  - `COMPLETE`: Repository, diff, and relevant contracts fully available.
  - `PARTIAL`: Missing companion repos or unmerged dependencies, but core diff analyzed.
  - `BLOCKED`: A prerequisite prevents meaningful analysis (e.g., repository cannot be accessed, missing mandatory user story, or no code diff available for a code-specific request).
- **Confidence Level:** `HIGH`, `MEDIUM`, or `LOW` with clear rationale.

### 2. Story Completeness & Bidirectional Alignment

#### A. Story Completeness & Ambiguity Audit
Because the User Story was validated as present in Step 0, audit the provided story for material omissions or edge-case gaps:
- Are allowed file types / payload formats defined?
- Are maximum size, volume, or rate ceilings specified?
- Are user role / permission restrictions stated?
- Is duplicate submission, overwrite, or idempotency behavior defined?
- Are failure, retry, or offline/mobile behaviors specified?
If material ambiguities exist, record: **`Requirement Completeness: GAP`** and list critical vs non-critical clarifications under *Developer Confirmations*. DO NOT invent arbitrary specifications. (Note: Incomplete details yield `GAP`, whereas total absence of a story yields `BLOCKED` at Step 0).

#### B. Bidirectional Requirement ↔ Implementation Audit
Evaluate both directions:
1. **Requirement → Implementation:** Did the code implement all requested acceptance criteria? Flag missing criteria as `Coverage: Not Covered` with Quality Gate `GAP`.
2. **Implementation → Requirement:** Did the code introduce unrequested behavior, extraneous endpoints, or scope creep? Flag as `Unrequested Scope` and evaluate for unintended regression risk.

### 3. Identify Changed Behavior & Execution Trace

For behaviorally relevant changed symbols (filtering out cosmetic/formatting changes), trace:
`Entry Point (Route/Event/Job) → Middleware/Auth → Service Logic → State Mutations/External Calls → Response/Side Effects → Consumers`

**Dynamic / Indirect Dependency Fallback:**
If direct static tracing cannot establish callers/consumers due to dynamic imports (`import(...)`), reflection, string-based event routing, or runtime DI containers:
- Mark: **`Potential Indirect Dependency`**.
- Explicitly state: *"Direct repository tracing could not establish caller/consumer due to dynamic dispatch; architectural verification required."*

### 4. Classify Change & Load Conditional Checklists

Load checklists strictly based on evidence:
- **API Contract:** Load `references/checklists/api.md` when routes, controllers, request/response schemas, headers, or status codes change.
- **Backend / Business Logic:** Load `references/checklists/backend.md` when services, branching, validation, or error handling change.
- **Database / Data Model:** Load `references/checklists/database.md` when persistence, queries, migrations, or indexes change.
- **AWS / Serverless:** Load `references/checklists/aws.md` when Lambda, API Gateway, DynamoDB, S3, SQS/SNS, or Step Functions change.
- **State Machines:** Load `references/checklists/state-machines.md` when Step Functions or workflow transitions change.
- **Events & Messaging:** Load `references/checklists/events.md` when queues, topics, or event schemas change.
- **Security & RBAC:** Load `references/checklists/security.md` when auth, roles, workplace/tenant boundaries, or IDs change.
- **Web UI:** Load `references/checklists/web.md` when web pages, components, forms, or client API consumers change.
- **Mobile (Android/iOS):** Load `references/checklists/mobile.md` when mobile apps or mobile-consumed APIs change.
- **On-Premise / Hybrid:** Load `references/checklists/on-premise.md` when hybrid connectors, on-premise agents, sync jobs, or gateway endpoints are touched.
- **Compatibility, Caching & Zero-Downtime:** Load `references/checklists/compatibility-and-caching.md` when API contracts, DB models, client caching, feature flags, or rolling deployment interactions occur.
- **Regression:** Load `references/checklists/regression.md` for any behavioral change.

**Checklist Decision Transparency:**
Explicitly report which checklists were loaded and which were **excluded** with reasons in the *Checklist Decisions* table.

### 5. Multi-Dimensional Blast Radius & Side-Effect Inventory

Analyze four blast-radius dimensions:
1. **Scope:** Isolated component → Single service → Multi-service → Cross-platform → External customers.
2. **Data Flow:** Reads/writes, schema shape, legacy/existing records, migrations, indexing, transactions.
3. **Contracts:** Request/response shape, HTTP status/errors, events, Lambda/Step Function payloads, backward compatibility.
4. **Side Effects & State:**

**Mandatory Side-Effect Inventory (When State Mutation Occurs):**
Whenever code creates, updates, or deletes state:
- **Primary Effect:** (e.g., Ticket attachment created)
- **Secondary Side Effects:** Database rows, S3 objects, EventBridge/SQS messages, notifications, cache updates, audit logs.
- **Partial Failure & Inconsistent State:** What happens if secondary effect $N$ fails after effects $1 \dots N-1$ succeed? Are orphan rows or dangling files left? Is compensation or cleanup logic present?

### 6. Security & Tenant Isolation (RBAC Matrix)

When the change touches access control, IDs, tenant scoping, or permissions:
Construct an **Authorization Matrix from Evidence**:

| Persona / Role | Target Resource / Scope | Action / Operation | Expected Behavior | Evidence / Enforcement Point |
|---|---|---|---|---|
| Workplace Admin | Workplace A Resource | Create / Update | Allow (200/201) | `src/auth/rbac.ts:32` |
| Member / User | Workplace A Resource | Create / Update | Deny / Allow per permission | `src/auth/rbac.ts:50` |
| Member from Workplace B | Workplace A Resource | Read / Update | Deny (403/404 Cross-Tenant) | `src/guards/tenant.ts:18` |
| Unauthenticated | Any Resource | Any Action | Deny (401 Unauthorized) | `src/auth/jwt.ts:14` |

### 7. Compatibility, Caching & Feature Flags

- **Client Caching:** Check LocalStorage, IndexedDB, SQLite/Room, CoreData, MMKV, offline sync queues.
- **Rolling Deployment ($N$ / $N+1$):** Old client hitting new backend; new client hitting old backend; database columns nullable or defaulted.
- **Feature Flags:** Test `Flag = OFF` (baseline regression), `Flag = ON` (new behavior), `OFF → ON` transition, `ON → OFF` rollback, and dynamic mid-session toggle.

### 8. Devil's Advocate Failure Analysis

Formulate hypothesis-driven failure scenarios:
1. **Newly introduced assumption:** What assumption about input shape, ordering, or network timing is most prone to failure?
2. **Silent divergence:** Could callers receive unexpected data without an error being raised?
3. **Race condition & double-submit:** What happens if two identical requests arrive concurrently?

### 9. Inspect Existing Tests & Test Quality

Statically evaluate existing tests:
- `Covered`: Directly tests the changed behavior with deep assertions.
- `Partially Covered (Shallow)`: Exercises the code path but lacks payload/side-effect assertions.
- `Not Covered`: No tests exercise the changed behavior.
- `Stale / Contradictory`: Expects old behavior that this change deliberately modifies.

**Execution Safety & Honesty Rule:**
Any test/build command must be classified as non-mutating before execution; otherwise do not run it. This closes the gap between test inspection and test execution. If non-mutating safety is verified and a test command is run, report actual exit codes. If not executed during the session (or skipped due to mutation risk), report: `Automated Tests: NOT RUN (inspected statically)`. Never claim tests "passed" based on static inspection alone.

### 10. Generate Executable Manual QA Test Cases (Two-Pass Generation Flow)

Execute test generation in distinct passes:
- **Pass 1 (Story Tests):** Acceptance criteria, primary user workflows, negative requirements, boundary constraints, role permissions, and feature flag toggles.
- **Pass 2 (Implementation Impact Tests):** Service boundaries, dependencies, AWS/infrastructure failure paths, database consistency, event delivery, client compatibility, and race conditions.
- **Pass 3 (Merge & Deduplicate):** Combine Story and Impact tests into a unified, non-redundant suite.

Every generated test case MUST adhere to the **Canonical Executable Manual QA Test Schema**:
- **TC-ID / Title**
- **Objective**
- **Type** (Functional / Negative / Boundary / Regression / Security / Concurrency / Offline / Sync)
- **Risk** (CRITICAL / HIGH / MEDIUM / LOW)
- **Priority** (P0 / P1 / P2 / P3)
- **Execution Tier** (Mandatory QA / Recommended Regression / Optional)
- **Execution Feasibility:** `READY` | `REQUIRES TEST DATA / FIXTURE SETUP` | `REQUIRES ENVIRONMENT SETUP` | `REQUIRES DEV/INFRA SUPPORT` | `REQUIRES EXTERNAL REPOSITORY` | `NOT EXECUTABLE WITH CURRENT ACCESS`
- **Target Platform** (Web / Android / iOS / API / Backend / On-Premise)
- **Environment** (Specified in context / Requires Confirmation)
- **Persona / Role** (Admin / Manager / User / Cross-Tenant / Unauthenticated)
- **Preconditions**
- **Test Data** (Exact payloads when known, or representative data structure)
- **Execution Steps** (Numbered sequential instructions)
- **Expected Observable Results:**
  - **Mandatory Oracle:** Primary user/client observable outcome required for pass/fail (UI text/toast, API status code/body, DB record mutation).
  - **Diagnostic Observation:** Supporting operational signals (logs, metrics, traces, DLQ checks). Flag for verification if unconfirmed in code.
- **Cleanup / Postconditions**
- **Traceability & Evidence:** `REQ-ID → IMP-ID → RISK-ID` | `file:line` (Evidence source: `repository` / `requirement` / `user-confirmed`)

### 11. Mechanical Quality Gate & QA Readiness

Evaluate two separate gates:

1. **Quality Gate Scorecard (`PASS` / `GAP` / `BLOCKED`):**
   - `PASS`: All required evidence, acceptance criteria, and critical risk paths are fully mapped to test cases.
   - `GAP`: A meaningful coverage, requirement completeness, or evidence limitation remains, but analysis is complete.
   - `BLOCKED`: A prerequisite prevented meaningful analysis (e.g., repository unreadable, no code diff available).
2. **Recommended QA Readiness (`READY` / `READY WITH GAPS` / `BLOCKED`):**
   - `READY`: Change is safe and verified for QA handoff.
   - `READY WITH GAPS`: Change can be tested by QA, but specific external risks, staging verifications, or known implementation bugs require attention.
   - `BLOCKED`: Known unresolved blocker or broken contract prevents QA testing.

---

## Output format

```markdown
# QA Impact Analysis: [Feature / Bug Fix / Task Title]

## Analysis Scope & Inspected Evidence

- **Repository:** `[repo-name]`
- **Git Scope:** `[base-branch]...[current-branch]` (`[X]` commits)
- **Working Tree:** `Clean` / `Uncommitted changes included`
- **Inspected Evidence:** `[N]` source files, `[N]` infrastructure files, `[N]` test files, `[N]` schemas
- **Not Inspected / Unavailable:** `[None / mobile-app / external-service / runtime configs]`
- **Analysis Status:** `COMPLETE` / `PARTIAL` / `BLOCKED`
- **Confidence Level:** `HIGH` / `MEDIUM` / `LOW` — *[Reasoning]*

---

# LAYER 1: QA Release Handoff
*(Copy-paste ready for Jira / Linear / GitHub PR Description)*

### Summary & Risk Assessment
- **Change Description:** [1-2 sentences summarizing the change]
- **Production Risk:** `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`
- **Blast Radius:** `CRITICAL` / `HIGH` / `MEDIUM` / `LOW`
- **Contract Compatibility:** `Compatible` / `Breaking` / `Unverified (Cross-Repo)`
- **Change Type:** `Bug Fix` / `New Feature` / `Refactor` / `API Change` / `DB Migration`
- **Recommended QA Readiness:** `READY` / `READY WITH GAPS` / `BLOCKED`

### Must-Test Scenarios (Mandatory QA)
| TC-ID | Title | Priority | Risk | Feasibility | Reason |
|---|---|---|---|---|---|
| TC-001 | ... | P0 | HIGH | READY | Direct requirement validation |
| TC-002 | ... | P0 | HIGH | REQUIRES TEST DATA | Negative path / tenant isolation |

### Blocking Production Risks & Devil's Advocate
- **Risk 1:** ...
- **Risk 2:** ...

### Action Items & Ownership
| Action Item | Owner | Blocking Release? |
|---|---|:---:|
| Confirm mobile app deserialization compatibility | Mobile Team | Yes |
| Verify S3 CORS policy in staging | Developer / DevOps | Yes |
| Execute mandatory manual QA test cases | QA | Yes |

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
| `api.md` | LOADED / EXCLUDED | Controller routes and request schema modified |
| `security.md` | LOADED / EXCLUDED | Tenant isolation guard touched |
| `aws.md` | LOADED / EXCLUDED | AWS infrastructure or SDK changes evaluated |
| `on-premise.md` | LOADED / EXCLUDED | Hybrid/on-premise connectors evaluated |
| `mobile.md` | LOADED / EXCLUDED | Mobile repository or mobile-specific routes affected |

## 3. Impact Summary & Blast Radius

### Verified Impact [Certain]
- Direct code changes, modified routes, updated database operations with file:line evidence.

### Potential Impact [Likely]
- Downstream callers, dependent UI components, event consumers.

### Cross-Repository & Unverified Risks [Unknown / Cannot Verify]
- Companion client apps, external microservice consumers, unverified endpoints.

## 4. Side-Effect Inventory & Partial-Failure Analysis
*(Include when change creates, updates, or deletes state)*
- **Primary Effect:** [Main state mutation]
- **Secondary Side Effects:** [DB rows, S3 files, events, cache, logs]
- **Partial Failure Analysis:** [Behavior if secondary step fails midway]

## 5. Security & RBAC Authorization Matrix
*(Include if auth, roles, workplace/tenant, or IDs are touched)*

| Persona / Role | Resource & Scope | Action | Expected Result | Evidence |
|---|---|---|---|---|

## 6. Compatibility, Caching & Rollout Analysis
*(Include if API, DB, cache, or feature flags are touched)*
- **Client Caching:** ...
- **Rolling Deployment ($N$ / $N+1$):** ...
- **Feature Flag Strategy:** ...

## 7. Devil's Advocate Failure Analysis

| Hypothesis | Vulnerability / Failure Mode | Evidence / Mechanism | Mitigating Test Case |
|---|---|---|---|

## 8. QA Test Details (Executable Manual Test Cases)

### TC-001 — [Area]: [Title]
- **Objective:** ...
- **Type:** ...
- **Risk:** ... | **Priority:** ... | **Execution Tier:** ...
- **Execution Feasibility:** READY / REQUIRES TEST DATA / REQUIRES DEV/INFRA SUPPORT
- **Target Platform:** ... | **Environment:** Specified in context / Requires Confirmation
- **Persona / Role:** ...
- **Preconditions:**
  1. ...
- **Test Data:**
  - ...
- **Steps:**
  1. ...
  2. ...
- **Expected Observable Results:**
  - **Mandatory Oracle:**
    - **UI:** ...
    - **API:** ...
    - **Database:** ...
  - **Diagnostic Observation:**
    - **Logs/Metrics:** ... *(Flagged for verification if unconfirmed in code)*
- **Cleanup / Postconditions:** ...
- **Traceability:** REQ-XX → IMP-XX → RISK-XX
- **Evidence:** `path/to/file.ts:123` (Source: repository / requirement / user-confirmed)

*(Repeat for each test case. Omit irrelevant sub-bullets.)*

## 9. Existing Coverage & Test Quality Evaluation

- **Automated Tests Execution:** `NOT RUN (inspected statically)` *(or list run results if executed)*

| Test File / Suite | Tested Symbol / Route | Status | Assertion Depth & Notes |
|---|---|---|---|

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
- **Gate Justification:** ...
```
