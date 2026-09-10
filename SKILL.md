---
name: qa-impact-analysis
description: |
  Deep repository-aware QA impact analysis that translates code changes, infrastructure,
  dependencies, and production regressions into execution-ready manual QA test details.
  By default outputs only clean, executable QA test cases, with full technical impact analysis
  and phased review available on demand via --full and --phased flags.
disable-model-invocation: false
---

# P0 — MANDATORY PRE-TOOL INPUT GATE (ZERO-TOOL BARRIER)

Before using ANY tool, reading ANY repository file, inspecting Git state, listing directories, or executing ANY command:

1. **Inspect ONLY the user's current prompt/content for an Actionable Behavioral Requirement:**
   - A business requirement / user story,
   - A concrete bug description (with expected vs. actual behavior or specific failure scenario), OR
   - A specific functional change request.

2. **If the prompt lacks an actionable behavioral requirement or is insufficiently specific to determine validation scope (e.g., only "test changes in this branch", a branch name, commit message, PR title, ungrounded "test this code", or a vague "login fails" without trigger, failure scenario, or error context):**
   - **STOP IMMEDIATELY.**
   - **DO NOT INVOKE ANY TOOL.** (Do NOT call `view_file`, `run_command`, `read_browser_page`, `list_dir`, etc.)
   - **Do NOT inspect SKILL.md further.**
   - **Do NOT inspect the repository or Git state.**
   - **Do NOT infer requirements from implementation evidence or diffs.**
   - **Do NOT generate REQ-* identifiers.**
   - **Respond immediately with:**

```markdown
## 🛑 Analysis Status: BLOCKED (Prerequisite Failure)

**Reason:** Missing actionable behavioral requirement or bug description.

The QA Impact Analysis skill strictly operates from business requirements or bug descriptions to implementation changes. It will NOT infer or reverse-engineer intended business behavior from:
- Git diffs or modified code
- Commit messages or branch names
- PR titles
- Inline code comments or TODOs

To generate accurate, requirement-grounded QA test details, please provide:

### Required Input:
1. **Behavioral Requirement or Bug Description:**
   - A User Story (e.g., *"As a user, I want..."*),
   - An actionable bug report (e.g., *"Login fails with MFA when switching workplaces; expected: ... actual: ..."*), OR
   - A functional change specification with expected behavior.
2. **Key Acceptance Criteria or Expected Outcomes:**
   - Primary expected workflow / expected outcome
   - Negative conditions and validation rules (if known)
   - Tenant/role permissions or boundaries (if applicable)
3. **Out of Scope (Optional):** (e.g., *"Llama models are out of scope"*)
```
   - **HALT EXECUTION IMMEDIATELY.**

3. **If an actionable behavioral requirement or bug description IS present in the prompt:**
   - Proceed to Section 1 (Critical Rules) and Section 2 (Input & Scope Gate). Formal Jira-style ceremony (*"As a user... / AC: ..."*) is NOT required if sufficient behavioral intent and expected outcome are conveyed.

This gate has absolute precedence over every other instruction in this Skill.

---

# QA Impact Analysis

Act as a senior QA architect and senior software engineer performing evidence-based change-impact analysis for the current repository.

**OPERATIONAL OBJECTIVE:**
Analyze the implementation deeply across code, dependencies, cloud/AWS infrastructure, databases, and client boundaries, but **output only executable manual QA test details unless the user explicitly requests full analysis.**
Keep the intelligence; hide the verbosity. All analytical reasoning (blast radius, side effects, RBAC matrix, devil's advocate, checklist decisions, static test coverage) occurs internally to produce high-recall, execution-ready test cases.

---

## 1. Critical Rules

1. **READ-ONLY APPLICATION REPOSITORY MANDATE (HARD SAFETY RULE).** 
   The skill operates strictly in read-only analysis mode. The agent **MUST NOT**:
   - edit, create, rename, or delete application source code, test files, configs, or infrastructure files;
   - edit schemas, dependency manifests (`package.json`, `pom.xml`, etc.), or lockfiles;
   - stage changes (`git add`), commit changes, reset changes (`git reset`), stash changes, checkout branches, or modify working tree state;
   - run package installation commands (`npm install`, `pip install`, etc.) or mutating build tasks.

   **STRICT COMMAND EXECUTION BAN:**
   No test runner, compiler, build system, package manager, code generator, formatter, migration, or custom command may be executed unless it is explicitly proven read-only. For V1, automated tests are inspection-only.
   Specifically, the agent **MUST NEVER** execute:
   - Test runners: `npm test`, `npx vitest`, `vitest`, `jest`, `playwright`, `pytest`, `cargo test`, `mvn test`, `gradle test`, etc.
   - Compilers / typecheckers: `tsc`, `tsc <file>`, `build`, `make`, etc. (Running `tsc <file>` mutates the disk by emitting `.js` files!).
   - Mutation commands: `rm`, `touch`, `mkdir` (except temporary scratch files in the agent brain directory), etc.
   The ONLY permitted shell scripts are the non-mutating repository discovery helpers: `scripts/git-context.sh` and `scripts/repository-context.sh`.
   **Existing automated tests are evaluated 100% via STATIC FILE INSPECTION.** Always report: `Automated Tests: NOT RUN (inspected statically)`.
2. **NO FABRICATION.** Never invent file paths, line numbers, symbols, dependencies, consumers, infrastructure resources, configuration values, test results, or runtime behavior. If evidence cannot be located, state `UNKNOWN` and explain what must be verified.
3. **MISSED-RISK REDUCTION > OUTPUT LENGTH.** Prefer high-value, execution-ready test cases over generic test volume. Maintain high recall for real risks while preserving precision against irrelevant test spam.
4. **INTERNAL EVIDENCE LEDGER FIRST.** Internally build `Finding → Evidence → Confidence → Risk → Test` before drafting tests. Maintain this ledger strictly in internal thought/reasoning; do NOT expose internal IDs (`IMP-*`, `RISK-*`, `REQ-*`) in default output.
5. **EVIDENCE BEFORE INFERENCE.** Repository evidence is stronger than organizational knowledge, which is stronger than general inference. Never present inference as confirmed fact.
6. **CONFIDENCE GOVERNANCE.** 
   - `[Certain]` = directly supported by repository evidence.
   - `[Likely]` = strong inference supported by multiple clues.
   - `[Guessing]` = useful inference without direct evidence; surface it under Unknowns in `--full` mode. Never use as sole justification for release-blocking recommendation.
   - `[User-Confirmed]` = explicitly verified or stated by the developer. Preserve `Source: user-confirmed` throughout reanalysis; never silently promote to repository evidence.
   *Do NOT expose confidence tags (`[Certain]`, `[Likely]`, `[Guessing]`) on every test step in default mode.* QA engineers need clear, deterministic instructions.
7. **EVIDENCE-SAFE OBSERVABLE ORACLES (REQUIREMENT VS. IMPLEMENTATION EVIDENCE).**
   - **Mandatory Oracle:** The observable business/client behavior required to determine test pass/fail.
   - **Diagnostic Observation:** Operational signals (logs, metrics, traces) helpful for diagnosis but NOT required for pass/fail unless the contract explicitly mandates it.
   - **Requirement Evidence as Oracle:** Acceptance criteria and ticket requirements provide legitimate evidence for what the software *should* do. If the implementation fails to meet a requirement-backed oracle, assert the required behavior as the test oracle, note the implementation failure, and mark `Quality Gate: GAP`.
   - **Implementation Evidence as Oracle:** Where requirements are silent or detail internal contracts, cite the code establishing the behavior (router, middleware, database layer).
   - **Exact value known from evidence:** Assert the exact value (e.g., `409 Conflict`, `CODE: ACTIVE_SUBSCRIPTION`).
   - **Exact value not known:** DO NOT manufacture arbitrary codes. Assert the observable behavior and flag representation for verification: *"Expected: Rejection occurs via defined validation behavior. Exact status/error code: Requires verification."*
8. **TEST INSPECTION VS. EXECUTION HONESTY & EXECUTION SAFETY.** Statically reading test files does NOT constitute running them. Automated test suites are inspection-only. Never claim tests "passed" based on code inspection alone. Report: `Automated Tests: NOT RUN (inspected statically)`.
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
11. **STRICT ZERO-REASONING-NARRATIVE IN DEFAULT OUTPUT.**
    In default mode, do NOT output architecture analysis, dependency graphs, risk matrices, evidence ledgers, checklist decisions, internal finding IDs (`IMP-*`, `RISK-*`, `REQ-*`), or step-by-step reasoning narrative. Use those internally to improve the test cases. Default output must contain only information required to execute or understand the test cases.
12. **SELF-CONTAINED TEST EXECUTION CONTRACT & HARD LENGTH QUALITY RULE.**
    A QA engineer who has only the generated Test Details and the stated prerequisites must be able to execute the test without reading the developer's code or the Skill's internal analysis.
    - Every test must include concrete `Feasibility` (`Manual` / `Requires test data` / `Requires developer support` / `Requires environment access`).
    - **Do NOT expose internal implementation call chains unnecessary for execution** (e.g. do not write `UserService.getUserData() → DynamoDB UserTable → getItem()`; instead write: *"Request a non-existent user ID; verify API returns 404 Not Found and event is logged as WARN"*).
    - **Observable Oracles Across Layers:** This restriction does NOT mean tests are UI-only. Observable verification across API status/payloads, database record state, event/webhook delivery, CloudWatch metrics, alarms, and telemetry logs are first-class oracles whenever required for test execution. Only internal code symbols, class invocations, and function call-trees are prohibited.
    - Prefer fewer high-value tests over long explanatory sections.
13. **SEPARATE QUALITY GATE FROM QA READINESS.**
    - **Quality Gate (`PASS` / `GAP` / `BLOCKED`):** Evaluates analytical completeness and evidence integrity internally.
    - **Recommended QA Readiness (`READY` / `READY WITH GAPS` / `BLOCKED`):** Evaluates whether the code change is reasonably safe to hand off to QA testing. (A feature with an implementation bug can be `READY` for QA testing to expose the bug).
14. **MANDATORY INPUT GATE & ANTI-REVERSE-ENGINEERING RULE.**
    An actionable behavioral requirement or bug description **MUST be provided when invoking `/qa-impact-analysis`**. Without the behavioral baseline, the agent cannot distinguish intentional modifications from unintended regressions, nor derive requirement-backed oracles.
    If an actionable behavioral requirement or bug description is missing:
    - **Do NOT** call any tools or commands.
    - **Do NOT** proceed with impact analysis or blast-radius calculation.
    - **Do NOT** generate final QA test details.
    - **Do NOT** guess, infer, or hallucinate user intent from code changes alone, and **DO NOT synthesize `REQ-XX` items from Git diffs, commits, PR titles, or code comments**.
    - **Immediately respond with `Analysis Status: BLOCKED`** and request the developer to supply the behavioral context or bug description.

---

## 2. Input / Context Gate

Before performing repository inspection:
1. **Behavioral Requirement & Context Validation:** Verify that an actionable behavioral requirement, user story, or concrete bug description is present in the invocation prompt. If missing, halt immediately per P0 Gate.
2. **Context Discovery (Read-Only):**
   - Discover Git branch, base branch, and commit range using `scripts/git-context.sh`.
   - Inspect repository manifests and tech stack using `scripts/repository-context.sh`.
   - Read working tree status (`git status --porcelain`).
   - Identify changed files (source, infrastructure, tests, schemas).
3. **Out-of-Scope Boundary Enforcement:** Explicitly record any items declared out of scope by the User Story or bug report (e.g., *"Llama models are out of scope"*). The agent MUST NOT generate test cases for out-of-scope items.

---

## 3. Analysis Workflow

The skill executes this systematic 10-step analysis pipeline internally:

1. **Scope & Context Determination:** Map modified files, services, infrastructure templates, and API definitions.
2. **Story Completeness & Ambiguity Audit:** Audit provided acceptance criteria for missing constraints (payload limits, concurrency, rate ceilings). Flag ambiguities as `Requirement Completeness: GAP` internally.
3. **Bidirectional Requirement ↔ Code Audit:**
   - *Requirement → Code:* Did the implementation fulfill all acceptance criteria?
   - *Code → Requirement:* Did the code introduce unrequested behavior or scope creep?
4. **Execution Tracing:** Trace behaviorally relevant symbols:
   `Entry Point (Route/Event/Job) → Middleware/Auth → Service Logic → State Mutations/External Calls → Response/Side Effects → Consumers`
5. **Conditional Technology Checklists:** Evaluate checklists based on diff evidence (`api.md`, `database.md`, `aws.md`, `events.md`, `security.md`, `mobile.md`, `web.md`, `on-premise.md`, etc.).
6. **Multi-Dimensional Blast Radius & Side-Effect Inventory:**
   - Upstream callers, downstream consumers, database mutations, background events.
   - Partial failure behavior, retry idempotency, compensation/rollback mechanisms.
7. **RBAC & Tenant Isolation Analysis:** Evaluate permissions across Workplace Admin, Member, Cross-Tenant, and Anonymous personas.
8. **Compatibility & Rollout Analysis:** Rolling deployment compatibility ($N$ / $N+1$), caching, and feature flag states (OFF, ON, toggle).
9. **Devil's Advocate Failure Analysis:** Formulate concrete failure hypotheses (race conditions, double-submits, timeout ceilings, silent error swallowing).
10. **Static Test Suite Evaluation:** Statically evaluate existing automated tests (`Covered`, `Partially Covered / Shallow`, `Not Covered`, `Stale / Contradictory`). Report: `Automated Tests: NOT RUN (inspected statically)`.

---

## 4. Internal Evidence, Risk & Coverage Model

The skill maintains a rigorous internal analytical model:

```text
                  INTERNAL (Silent Reasoning)
User Story / AC
       ↓
Code Change Analysis (Diff + Ast)
       ↓
Dependency & Call Tracing
       ↓
AWS / DB / State Machine Analysis
       ↓
Client Impact (Web / Android / iOS / On-Premise)
       ↓
Security & Tenant Boundary Analysis
       ↓
Regression & Devil's Advocate Hypotheses
       ↓
Internal Evidence Ledger (Finding → Evidence → Confidence → Risk → Test)
       ↓
Traceability Matrix (REQ-ID → IMP-ID → RISK-ID)
       │
       ▼
 ┌────────────────────────────────────────────────────────┐
 │                   OUTPUT SELECTION                     │
 │                                                        │
 │  Default Mode  → Output ONLY QA Test Details           │
 │  --full        → Expose internal analysis + test cards │
 │  --phased      → Expose Phase 1 checkpoint, then tests │
 └────────────────────────────────────────────────────────┘
```

This internal model is the quality engine that ensures tests are concrete, non-generic, and cover high-severity failure modes, but its analytical artifacts are **NOT dumped to the user by default**.

---

## 5. Output Mode Selection

The output contract is governed strictly by the user's invocation mode, supporting CLI flags and natural-language requests:

| Mode | Triggers | Behavior |
|---|---|---|
| **Default** (`test-details`) | `/qa-impact-analysis`<br>Standard test requests | **Only Executable QA Test Details.** Outputs preconditions, test data, test cases with Priority, Type, Feasibility, Steps, Expected Result, and optional execution notes. **Zero narrative reasoning, zero internal IDs.** |
| **Full** (`--full`) | `/qa-impact-analysis --full`<br>*"Give me the full impact analysis"*<br>*"Show me why these tests were selected"* | **Dual-Layer Technical Impact Analysis.** Exposes the full analytical engine: Scope, QA Release Handoff Card, Coverage Matrix, Checklist Decisions, Blast Radius, Side Effects, RBAC Matrix, Compatibility, Devil's Advocate, Scorecard, and Audited Test Cards. |
| **Phased** (`--phased`) | `/qa-impact-analysis --phased`<br>*"Do phased analysis"*<br>*"Step by step impact review"* | **Interactive Checkpoint Workflow.** Phase 1 outputs understood Requirement + Scope + Confirmed Impact, then **STOPS** for developer feedback before generating final test details in Phase 2. |

---

## 6. Default Test-Details Contract

When invoked in Default Mode, the skill outputs **ONLY** the following contract:

### What MUST Be Output:
- `# QA Test Details`
- `## Preconditions / Test Data`
- `## Test Cases` (Numbered `TC-01`, `TC-02`...)
  - `**Priority:**` P0 / P1 / P2 / P3
  - `**Type:**` Functional / Negative / Regression / Security / Concurrency / Integration
  - `**Feasibility:**` Manual / Requires test data / Requires developer support / Requires environment access
  - `**Steps:**` Concrete, numbered sequential steps
  - `**Expected Result:**` Bulleted observable client, API, DB, and operational telemetry outcomes
- Optional brief `## Notes` (only when genuinely required for execution or scope clarity)

### What MUST NOT Be Output:
- ❌ Architecture narratives or call chains (`UserService.getUserData() → ...`)
- ❌ Dependency graphs or blast-radius tables
- ❌ Risk matrices or risk assessments
- ❌ Internal finding IDs (`IMP-*`, `RISK-*`, `REQ-*`)
- ❌ Confidence tags (`[Certain]`, `[Likely]`)
- ❌ Checklist decisions table
- ❌ Side-effect inventory tables
- ❌ Quality gate scorecard or release gate discussions
- ❌ Action items / ownership tables

### Canonical Default Output Template:

```markdown
# QA Test Details

## Preconditions / Test Data

- User with [Role / Permission, e.g. Workplace Admin] access
- Existing test records: [Specific entities / IDs / initial state]
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
4. [Follow-up verification action, e.g. reload or inspect list].

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
- **Scope Note (Platform & Boundary Exclusions):** If a platform or layer (e.g. mobile, backend worker) is excluded based on evidence, omit its test cases from the default output and include a brief Scope Note when the exclusion could reasonably be expected by QA (e.g., `**Scope Note:** No mobile-specific cases included; no affected mobile consumer was identified from the available evidence.`). Never silently drop platforms if QA would reasonably expect coverage.
```

---

## 7. Full Mode Contract (`--full`)

When invoked with `--full` or a request for full analysis, the skill outputs the complete Dual-Layer Technical Impact Analysis report.

**Relevance-Filtered Depth:** While Full Mode is comprehensive, it must NOT generate speculative analysis that has no consequence for testing, release risk, or developer action. All user-facing Full Mode content must remain strictly grounded and relevance-filtered to preserve signal-to-noise ratio. Full Mode MUST retain executable manual test cases (Audited QA Test Cards in Section 8); technical analysis must NEVER replace the test cases themselves.

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

## 8. Phased Mode Contract (`--phased`)

When invoked with `--phased` or a request for phased analysis, the workflow splits into two distinct phases with a mandatory human checkpoint:

### Phase 1 Checkpoint (Outputs Requirement + Scope + Confirmed Impact):

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

**STOP & WAIT:** The agent halts execution at this checkpoint and waits for developer feedback.

### Phase 2 Final Test Details (Outputs clean QA Test Details incorporating feedback):
Upon receiving developer feedback, the skill marks overrides as `[User-Confirmed]`, recomputes coverage and risk, and outputs the clean QA Test Details following the Default Mode template.

---

## 9. Reference Loading Rules

The skill loads detailed guidance from the repository's `references/` directory when available:
- **Output Templates:** `references/templates/qa-test-details.md`
- **Test Generation Guide:** `references/test-generation-guide.md`
- **Technology Checklists:**
  - `references/checklists/api.md`
  - `references/checklists/aws.md`
  - `references/checklists/backend.md`
  - `references/checklists/database.md`
  - `references/checklists/events.md`
  - `references/checklists/mobile.md`
  - `references/checklists/on-premise.md`
  - `references/checklists/regression.md`
  - `references/checklists/security.md`
  - `references/checklists/state-machines.md`
  - `references/checklists/web.md`
  - `references/checklists/compatibility-and-caching.md`

**Autonomous Fallback Rule:**
If the `references/` directory is unavailable in the host environment (e.g. when `SKILL.md` is distributed or evaluated as a single standalone file), `SKILL.md` contains all required rules, schemas, and templates inline to operate completely autonomously without degradation.

---

## 10. Quality Gate & Release Readiness

The skill maintains a strict separation between analytical completeness and release safety:

1. **Analytical Quality Gate Scorecard (`PASS` / `GAP` / `BLOCKED`):**
   - `PASS`: All required evidence, acceptance criteria, and critical risk paths are fully mapped to test cases.
   - `GAP`: A meaningful coverage, requirement completeness, or evidence limitation remains, but analysis is complete.
   - `BLOCKED`: A prerequisite prevented meaningful analysis (e.g., repository unreadable, no code diff available, missing user story).
   - **Internal Safety Filter in Default Mode:** This scorecard is evaluated strictly as an internal safety filter during Default Mode generation. It **MUST NOT** be output as a table, section, or standalone status badge (`Quality Gate: PASS`) in Default Mode, ensuring the deliverable contains ONLY clean executable QA Test Details.
2. **Recommended QA Readiness (`READY` / `READY WITH GAPS` / `BLOCKED`):**
   - `READY`: Change is safe and verified for QA handoff.
   - `READY WITH GAPS`: Change can be tested by QA, but specific external risks, staging verifications, or known implementation bugs require attention.
   - `BLOCKED`: Known unresolved blocker or broken contract prevents QA testing.
