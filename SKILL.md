---
name: qa-impact-analysis
description: |
  Deep repository-aware QA impact analysis that translates code changes, infrastructure,
  dependencies, and production regressions into execution-ready manual QA test details.
  By default outputs only clean, executable QA test cases, with full technical impact analysis
  and phased review available on demand via --full and --phased flags.
disable-model-invocation: false
---

# P0 — MANDATORY PRE-TOOL INPUT GATE

Before using ANY tool, reading ANY repository file, inspecting Git state, listing directories, or executing ANY command:

1. **Inspect ONLY the user's current prompt/content for:**
   - User Story / Business Requirement
   - Acceptance Criteria

2. **If either is missing, vague, or not explicitly provided:**
   - **STOP immediately.**
   - **Do NOT invoke any tool.**
   - **Do NOT inspect SKILL.md further.**
   - **Do NOT inspect the repository.**
   - **Do NOT inspect Git status, branch, diff, commits, files, or directories.**
   - **Do NOT infer requirements from implementation evidence.**
   - **Do NOT generate REQ-* identifiers.**
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
     ```
   - **HALT EXECUTION IMMEDIATELY.**

3. **If PRESENT:**
   - Proceed to Critical Rules and Step 1 (Scope & Context Determination).

This gate has absolute precedence over every other instruction in this Skill.

---

# QA Impact Analysis

Act as a senior QA architect and senior software engineer performing evidence-based change-impact analysis for the current repository.

**OPERATIONAL OBJECTIVE:**
Analyze the implementation deeply across code, dependencies, cloud/AWS infrastructure, databases, and client boundaries, but **output only executable manual QA test details unless the user explicitly requests full analysis.**
Keep the intelligence; hide the verbosity. All analytical reasoning (blast radius, side effects, RBAC matrix, devil's advocate, checklist decisions, static test coverage) occurs internally to produce high-recall, execution-ready test cases.

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
4. **INTERNAL EVIDENCE LEDGER FIRST.** Internally build `Finding → Evidence → Confidence → Risk → Test` before drafting tests. Maintain this ledger in internal reasoning; do NOT expose internal IDs (`IMP-*`, `RISK-*`, `REQ-*`) in default output.
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
11. **TWO OUTPUT CONTRACTS (DEFAULT TEST DETAILS VS. FULL ANALYSIS):**
    - **Default Mode (`test-details`):** Output ONLY **QA Test Details (Executable Manual Test Cases)**. Keep all internal analysis (scope, risk, handoff card, blast radius, side effects, RBAC matrix, compatibility, devil's advocate, existing coverage, quality gate scorecard) strictly internal. Output adheres to Template 1 in `references/templates/qa-test-details.md`.
    - **Full Mode (`--full`):** Output the complete Dual-Layer Technical Impact Analysis report adheres to Template 2 in `references/templates/qa-test-details.md`.
    - **Phased Mode (`--phased`):** Output Phase 1 Checkpoint (Requirement + Scope + Confirmed Impact) using Template 3, STOP for developer review/overrides, then output Phase 2 QA Test Details using Template 4 upon confirmation.
12. **NO DUPLICATE TEST BODIES.** Define full step-by-step test instructions only once. In `--full` mode, summary tables reference test cases by `TC-ID`.
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
15. **STRICT ZERO-REASONING-NARRATIVE IN DEFAULT OUTPUT.**
    In default mode, do NOT output architecture analysis, dependency graphs, risk matrices, evidence ledgers, checklist decisions, internal finding IDs (`IMP-*`, `RISK-*`, `REQ-*`), or step-by-step reasoning narrative. Use those internally to improve the test cases. Default output must contain only information required to execute or understand the test cases.
16. **SELF-CONTAINED TEST EXECUTION CONTRACT & HARD LENGTH QUALITY RULE.**
    A QA engineer who has only the generated Test Details and the stated prerequisites must be able to execute the test without reading the developer's code or the Skill's internal analysis. Every test must include concrete `Feasibility` (`Manual` / `Requires test data` / `Requires developer support` / `Requires environment access`). Prefer fewer high-value tests over long explanatory sections.

---

## Invocation Model & Execution Modes

### Invocation Model
- **User Story & Acceptance Criteria:** **MANDATORY**. The developer must provide the ticket description, user story, or acceptance criteria at invocation.
- **Implementation Context:** **OPTIONAL / AUTO-DETECTED**. The skill automatically inspects the local Git branch, staged/unstaged changes, and repository manifests using `scripts/git-context.sh` and `scripts/repository-context.sh`. The developer may optionally supply custom branch diffs or specific file paths if analyzing a target different from active workspace state.

### Primary Output Modes & Invocations
- **Default Mode (`test-details`):** 
  - **Triggers:** `/qa-impact-analysis` (canonical invocation), or standard requests to generate QA test details.
  - **Behavior:** Executes the comprehensive internal analysis pipeline across code, cloud infrastructure, databases, client boundaries, security, and regressions, but outputs **ONLY QA Test Details (Executable Manual Test Cases)** using Template 1 in `references/templates/qa-test-details.md`.
  - **Constraint:** Zero narrative, zero internal IDs, zero confidence tags.
- **Full Mode (`--full`):** 
  - **Triggers:** `/qa-impact-analysis --full`, or natural language: *"Give me the full impact analysis"*, *"Show me why these tests were selected"*, *"Show technical impact report"*.
  - **Behavior:** Outputs the complete Dual-Layer Technical Impact Analysis report using Template 2 in `references/templates/qa-test-details.md`: Scope & Inspected Evidence + Layer 1 QA Release Handoff + Layer 2 Detailed Technical Impact Analysis (Coverage Matrix, Checklist Decisions, Blast Radius, Side Effects, RBAC Matrix, Compatibility, Devil's Advocate, Existing Test Evaluation, Traceable QA Test Cards, Quality Gate Scorecard).
- **Phased Mode (`--phased`):** 
  - **Triggers:** `/qa-impact-analysis --phased`, or natural language: *"Do phased analysis"*, *"Step by step impact review"*.
  - **Behavior:** Enforces an interactive checkpoint after Phase 1 using Template 3 in `references/templates/qa-test-details.md`:
    - **Phase 1 Deliverable:** **Requirement Understanding + Detected Change Scope + Confirmed Impact Graph**.
    - **STOP:** The skill halts and prompts the developer to review and provide corrections to either scope (e.g. *"You missed ReportingService"*) or business requirements (e.g. *"Expected behavior is 404, not 400"*).
    - **Phase 2 Deliverable:** Upon receiving developer feedback, records findings as `[User-Confirmed]`, recomputes risks, and generates the final QA test details using Template 4 in `references/templates/qa-test-details.md`.

### Interaction Control Flags
- **`--mode fast`**: One-shot execution. Analyzes context and generates output without pausing for non-critical ambiguities.
- **`--mode auto` (Default interaction control)**: Executes automatically through to the final deliverable, but **pauses for developer confirmation** if an unresolved contract contradiction or high-severity ambiguity directly prevents sound test generation.

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
     3. **Out of Scope (Optional):** (e.g., *"Llama models are out of scope"*)
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

Every generated test suite must be grounded in the deep internal analysis pipeline. Test cases are formatted according to the active mode:

#### A. Default Mode (`test-details`) — Clean Executable Manual QA Test Schema
The default output is tailored strictly for QA engineers to execute without wading through engineering architecture reports.
- **Top-level Preconditions & Test Data:** Consolidated environment, persona, and test data requirements.
- **Concise Test Cards:**
  - `### TC-01 — <Test Scenario Title>`
  - `**Priority:** P0 / P1 / P2 / P3`
  - `**Type:** Functional / Negative / Regression / Security / Concurrency / Integration`
  - `**Feasibility:** Manual / Requires test data / Requires developer support / Requires environment access`
  - `**Steps:**` Sequential, concrete numbered actions (no generic placeholders like "verify lambda works").
  - `**Expected Result:**` Clear bullet points detailing observable UI, API, DB, and telemetry behavior.
- **Self-Contained Execution Contract:** A QA engineer who has only the generated Test Details and stated prerequisites must be able to execute the test without reading code or the Skill's internal analysis.
- **Intelligent Platform Exclusions:** Only generate tests for affected platforms (Web, Android, iOS, On-Premise). Omit unimpacted platforms. Include an optional brief note only if omission might confuse QA (e.g. `**Scope Note:** No mobile-specific cases included; no affected mobile consumer was identified.`).
- **Zero Internal Noise:** No internal IDs (`IMP-*`, `RISK-*`, `REQ-*`), no confidence tags (`[Certain]`, `[Likely]`), no pseudo-code or diff dumps.

#### B. Full Mode (`--full`) — Comprehensive Audited Test Schema
In `--full` mode, test cards include complete analytical metadata:
- **TC-ID / Title**
- **Category:** `Direct Requirement (Story AC)` | `Implementation Impact / Regression`
- **Objective:** Specific failure mode or contract rule verified
- **Type, Risk, Priority, Execution Tier, Feasibility, Target Platform, Persona / Role**
- **Preconditions, Test Data, Execution Steps**
- **Mandatory Oracle (Pass/Fail) vs. Diagnostic Observation (Telemetry)**
- **Cleanup / Postconditions**
- **Traceability & Evidence:** `REQ-ID → IMP-ID → RISK-ID` | `file:line` (Evidence source: `repository` / `requirement` / `user-confirmed`)

### 11. Mechanical Quality Gate & QA Readiness

Evaluate two separate gates internally (reported explicitly only in `--full` mode):

1. **Quality Gate Scorecard (`PASS` / `GAP` / `BLOCKED`):**
   - `PASS`: All required evidence, acceptance criteria, and critical risk paths are fully mapped to test cases.
   - `GAP`: A meaningful coverage, requirement completeness, or evidence limitation remains, but analysis is complete.
   - `BLOCKED`: A prerequisite prevented meaningful analysis (e.g., repository unreadable, no code diff available).
2. **Recommended QA Readiness (`READY` / `READY WITH GAPS` / `BLOCKED`):**
   - `READY`: Change is safe and verified for QA handoff.
   - `READY WITH GAPS`: Change can be tested by QA, but specific external risks, staging verifications, or known implementation bugs require attention.
   - `BLOCKED`: Known unresolved blocker or broken contract prevents QA testing.

---

## Output Formats & Templates

The output format is governed strictly by the active invocation mode. All templates are defined in [`references/templates/qa-test-details.md`](references/templates/qa-test-details.md).

### 1. Default Mode (`test-details` — `/qa-impact-analysis`)
- **Use Template 1:** [`references/templates/qa-test-details.md#1-default-test-details-template`](references/templates/qa-test-details.md)
- **Content:** Strict `# QA Test Details` deliverable containing:
  - `## Preconditions / Test Data`
  - `## Test Cases` (TC-01, TC-02...) with Priority, Type, Feasibility, numbered Steps, and bulleted Expected Results.
  - Optional brief `## Notes` (only when genuinely required for execution or scope clarity).
- **Enforcement:** Zero reasoning narrative, zero architecture analysis, zero dependency graphs, zero risk matrices, zero evidence ledgers, zero checklist decisions, zero internal finding IDs (`IMP-*`, `RISK-*`, `REQ-*`), zero confidence tags.

### 2. Full Mode (`--full` — `/qa-impact-analysis --full`)
- **Use Template 2:** [`references/templates/qa-test-details.md#2-full-analysis-template`](references/templates/qa-test-details.md)
- **Content:** Complete Dual-Layer Technical Impact Analysis report:
  - Scope & Inspected Evidence
  - Layer 1: QA Release Handoff (Summary & Risk Assessment, Must-Test Table, Blocking Risks, Action Items)
  - Layer 2: Detailed Technical Impact Analysis (Coverage Matrix, Checklist Decisions, Blast Radius, Side Effects, RBAC Matrix, Compatibility, Devil's Advocate, Existing Test Evaluation, Full Audited QA Test Cards, Quality Gate Scorecard).

### 3. Phased Mode (`--phased` — `/qa-impact-analysis --phased`)
- **Phase 1 (Checkpoint):** Use Template 3: [`references/templates/qa-test-details.md#3-phased-phase-1-template-checkpoint`](references/templates/qa-test-details.md)
  - Outputs: **Requirement Understanding + Detected Change Scope + Confirmed Impact Graph**.
  - **STOP & WAIT:** Halts execution and asks developer to confirm or correct scope (e.g., *"You missed ReportingService"*) and expectations (e.g., *"Expected behavior is 404, not 400"*).
- **Phase 2 (Final Test Details):** Use Template 4: [`references/templates/qa-test-details.md#4-phased-final-test-details-template`](references/templates/qa-test-details.md)
  - Outputs: Clean, executable QA Test Details incorporating developer feedback.


