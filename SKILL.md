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

## 🛑 PRE-TOOL GATE 0: MANDATORY INPUT CHECK (ZERO-TOOL BARRIER)

**DO NOT CALL ANY TOOL, DO NOT RUN COMMANDS, AND DO NOT INSPECT FILES BEFORE PASSING THIS GATE.**

Evaluate the user prompt immediately before taking ANY tool action:
1. **Check for an explicit User Story AND Acceptance Criteria:**
   - Did the user explicitly provide a User Story (business requirement/goal) AND Acceptance Criteria?
2. **If MISSING or VAGUE:**
   - If the user prompt only says: *"test changes in this branch"*, *"write test details for this task"*, *"run impact analysis on my PR"*, or provides only a commit message, branch name, PR title, or ticket number without acceptance criteria:
   - **STOP IMMEDIATELY.**
   - **CALL ZERO TOOLS.** (Do NOT call `run_command`, `scripts/git-context.sh`, `view_file`, or search tools).
   - **DO NOT REVERSE-ENGINEER REQUIREMENTS** (`REQ-01`, `REQ-02`, etc.) from Git diffs, commits, or code comments. Synthesizing pseudo-requirements from the implementation is a direct safety violation.
   - **Respond immediately with:**
     ```markdown
     ## 🛑 Analysis Status: BLOCKED (Prerequisite Failure)

     **Reason:** Missing mandatory User Story and Acceptance Criteria.

     The QA Impact Analysis skill strictly operates from business requirements to implementation changes. It will NOT infer or reverse-engineer intended business behavior from:
     - Git diffs or modified code
     - Commit messages or branch names
     - PR titles
     - Inline code comments or TODOs

     To generate accurate, requirement-grounded QA test details, please provide:

     ### Required Input:
     1. **User Story / Business Requirement:** (e.g., *"As a user, I want..."*)
     2. **Acceptance Criteria:**
        - Primary happy-path workflow
        - Negative conditions and validation rules
        - Role/tenant permissions and limits
     3. **Out of Scope (Optional):** (e.g., *"Llama models are out of scope"*)
     4. **Optional Implementation Context:** (Branch name or PR link — if different from active Git state)
     ```
   - **HALT EXECUTION IMMEDIATELY.**
3. **If PRESENT:**
   - Proceed to Critical Rules and Step 1 (Scope & Context Determination).

---

## Critical rules

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
11. **DUAL-LAYER OUTPUT ARCHITECTURE.** Output must contain:
    - **Layer 1: QA Release Handoff** (compact, copy-pasteable directly into Jira/Linear/PR descriptions, referencing Test IDs without repeating test bodies).
    - **Layer 2: Detailed Technical Impact Analysis** (full architecture, RBAC matrix, compatibility, complete manual test cards, traceability, and mechanical quality gate).
12. **NO DUPLICATE TEST BODIES.** Define full step-by-step test instructions only once in *QA Test Details*. All other sections reference test cases by `TC-ID`.
13. **SEPARATE QUALITY GATE FROM QA READINESS.**
    - **Quality Gate (`PASS` / `GAP` / `BLOCKED`):** Evaluates analytical completeness and evidence integrity.
    - **Recommended QA Readiness (`READY` / `READY WITH GAPS` / `BLOCKED`):** Evaluates whether the code change is reasonably safe to hand off to QA testing. (A feature with an implementation bug can be `READY` for QA testing to expose the bug).
14. **MANDATORY INPUT GATE & ANTI-PSEUDO-STORY SYNTHESIS.**
    A User Story and its Acceptance Criteria **MUST be provided when invoking `/qa-impact-analysis`**. Without the business requirement baseline, the agent cannot distinguish intentional modifications from unintended regressions, nor derive requirement-backed oracles.
    If the User Story or Acceptance Criteria is missing:
    - **Do NOT** call any tools or commands.
    - **Do NOT** proceed with impact analysis or blast-radius calculation.
    - **Do NOT** generate final QA test details.
    - **Do NOT** guess, infer, or hallucinate user intent from code changes alone, and **DO NOT synthesize `REQ-XX` items from Git diffs, commits, PR titles, or code comments**.
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
- **Working Tree:** Must report exact status from `git status --porcelain`. If pre-existing unstaged/untracked files exist (e.g. in test suites), report honestly: `DIRTY ([N] pre-existing uncommitted files detected in working tree; preserved untouched)`. Never claim "clean and untouched" if working tree contains changes.
- **Inspected Evidence:** Count and paths of changed source files, infrastructure files, test files, and API schemas.
- **Not Inspected / Unavailable:** Companion repositories (e.g., Android, iOS, external microservices) or unverified production configurations.
- **Out-of-Scope Items:** Explicitly record any items declared out of scope by the User Story (e.g., *"Llama models are out of scope"*). The agent MUST NOT generate test cases for out-of-scope items.
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
Where dynamic reflection, string-based routing, or runtime DI containers prevent static resolution of callers, flag the caller as: `Potential Indirect Dependency` and require developer confirmation under *Unknowns* rather than assuming no callers exist.

### 4. Conditionally Load Technology Checklists

Load only the checklists directly relevant to the inspected diff:
- `references/checklists/api.md` (REST/GraphQL/gRPC endpoints, payload contracts)
- `references/checklists/database.md` (schemas, migrations, locking, transactions)
- `references/checklists/events.md` (queues, publishers, consumers, idempotency)
- `references/checklists/security.md` (authn/authz, input validation, encryption)
- `references/checklists/aws.md` (serverless, cloud infrastructure failure paths)
- `references/checklists/compatibility-and-caching.md` (rolling deploy, caching)
- `references/checklists/web.md` (browser-specific behaviors, network drops, forms)
- `references/checklists/mobile.md` (offline sync, device permissions, deep links)
- `references/checklists/on-premise.md` (on-prem connectors, sync agents, tokens, drop reconnection)
- `references/checklists/state-machines.md` (multi-step workflows, transitions)
- `references/checklists/backend.md` (threading, concurrency, race conditions)
- `references/checklists/regression.md` (blast radius, existing workflows)

### 5. Multi-Dimensional Blast Radius & Side-Effect Inventory

Analyze four blast-radius dimensions:
1. **Direct Impact:** Modified lines, functions, classes, and database schemas.
2. **Upstream Callers:** Call sites, controllers, and entry points invoking changed symbols.
3. **Downstream Consumers:** Databases, caches, queues, third-party APIs, and external microservices.
4. **Client Consumers:** Web apps, Mobile apps (Android/iOS), On-Premise sync connectors.

**Side-Effect Inventory (Mandatory for State Mutations):**
For any code modifying database records, sending emails/webhooks, or dispatching events, build an internal inventory:
- Primary side effect (e.g., record inserted).
- Secondary side effect (e.g., audit log created, notification queued).
- Idempotency & Retry behavior (what happens if retried with identical idempotency key or request body?).
- Partial failure behavior (what happens if step 2 fails after step 1 succeeds?).
- Compensation / Recovery path (is there a rollback or saga mechanism?).

### 6. RBAC & Tenant Isolation Matrix

For changes affecting authorization or data access, generate an explicit verification matrix:
| Persona / Role | Target Resource | Action | Expected Result | Evidence (file:line) |
|---|---|---|---|---|
| Workplace Admin | Modified Endpoint | Read / Write | Allow (200 OK) | `src/auth/roles.ts:32` |
| Member | Modified Endpoint | Read / Write | Deny / Allow per policy | `src/auth/roles.ts:45` |
| Cross-Tenant User | Tenant B Resource | Any Action | Deny (404 / 403) | `src/middleware/tenant.ts:18` |
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

**Execution Honesty Rule:**
Automated test suites are strictly inspection-only. Never execute test runners (`npm test`, `vitest`, `jest`, `playwright`, `pytest`), compilers (`tsc`), or build scripts. Statically reading test files does NOT constitute running them. Always report: `Automated Tests: NOT RUN (inspected statically)`. Never claim tests "passed" based on static inspection alone.

### 10. Generate Executable Manual QA Test Cases (Two-Pass Generation Flow)

Execute test generation in distinct, cleanly separated passes:
- **Pass 1 (Story Tests — Direct AC Validation):**
  - Explicitly labeled: `Category: Direct Requirement (Story AC)`.
  - Directly tests the primary user workflows and acceptance criteria stated in the user story.
  - Keeps tests focused on the core requirement without bloating with unrequested scenarios.
  - Strictly honors Out-of-Scope boundaries (no tests generated for out-of-scope items).
- **Pass 2 (Implementation Impact Tests — Secondary Blast Radius):**
  - Explicitly labeled: `Category: Implementation Impact / Regression`.
  - Covers secondary edge cases discovered by tracing code blast radius, side effects, legacy workflows (e.g., editing vs viewing existing entities with deprecated fields), database constraints, and stale automated tests.
  - Clearly separated from direct acceptance criteria so QA knows what is core requirement vs. what is defensive regression testing.
- **Pass 3 (Merge & Deduplicate):** Combine into prioritized suite with clear category labels.

Every generated test case MUST adhere to the **Canonical Executable Manual QA Test Schema**:
- **TC-ID / Title**
- **Category:** `Direct Requirement (Story AC)` | `Implementation Impact / Regression`
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
