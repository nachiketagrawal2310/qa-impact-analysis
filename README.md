# qa-impact-analysis

**Repository-aware AI Skill for implementation-aware QA impact analysis and manual test generation.**

`qa-impact-analysis` helps developers evaluate the QA impact of a feature, bug fix, API change, database change, refactor, or infrastructure change **before raising a PR**.

The Skill combines two sources of truth:

> **User Story / Acceptance Criteria define what the system is supposed to do.**
> **Repository evidence defines how the system currently behaves and what the implementation actually changes.**

It uses both to identify affected components, risks, dependencies, regressions, security concerns, compatibility issues, and missing QA coverage, then produces structured, execution-ready manual QA test details.

---

## Core Objective

The Skill is designed to answer:

**"Given what the developer says should change and what the code actually changes, what does QA need to test?"**

It is not a replacement for code review and does not modify the application.

The intended workflow is:

```text
User Story + Acceptance Criteria
              +
       Current Git / Repository
              ↓
      QA Impact Analysis
              ↓
   Requirement → Implementation
              ↓
      Impact / Risk / Blast Radius
              ↓
   Regression / Security / Failure
              ↓
      Manual QA Test Coverage
              ↓
       QA Release Handoff
```

---

# Key Principles

### 1. Requirement-first

A **User Story and Acceptance Criteria are mandatory inputs**.

The Skill must not infer business requirements from:

* Git diffs
* commit messages
* PR titles
* code comments
* TODOs
* existing implementation behavior

When the required story or acceptance criteria are missing, analysis is blocked:

```text
Analysis Status: BLOCKED
Reason: Missing User Story / Acceptance Criteria
```

This prevents the implementation itself from becoming the definition of intended behavior.

### 2. Repository-aware

The Skill inspects the actual repository to understand:

* changed files
* execution paths
* callers and consumers
* backend services
* APIs and contracts
* databases
* AWS resources
* events and queues
* state machines
* Web clients
* Android / iOS clients
* On-Premise / Hybrid components
* existing automated tests
* configuration and infrastructure changes

Repository evidence takes precedence over assumptions or stale architectural documentation.

### 3. Read-only by design

`qa-impact-analysis` is an **analysis-only Skill**.

It must never:

* modify application source code
* modify test files
* modify configuration
* modify schemas
* modify dependency manifests or lockfiles
* create, rename, move, or delete application files
* run `git add`
* commit changes
* run `git reset`
* stash changes
* checkout or switch branches
* install dependencies
* execute mutating build or test operations

Any test or build command must first be established as **demonstrably non-mutating**. When that cannot be established with certainty, the Skill inspects the tests statically instead.

### 4. Evidence over invention

The Skill must not fabricate:

* HTTP status codes
* API endpoints
* error codes
* database fields
* events
* logs
* file paths
* source locations
* implementation behavior

When exact implementation evidence is unavailable, the Skill reports the uncertainty instead of inventing details.

---

# Invocation

## Required Input

Every normal analysis requires:

```text
User Story / Business Requirement
Acceptance Criteria
```

Implementation context is discovered automatically from the repository where possible.

### Example

```text
/qa-impact-analysis

User Story:
As a Workplace Admin, I want to export monthly invoices
to PDF or CSV so that I can reconcile accounting records.

Acceptance Criteria:
1. The export supports PDF and CSV.
2. A maximum of 500 records can be exported per job.
3. Unsupported formats are rejected.
4. Only Workplace Admin users can perform the export.
5. The export must not create duplicate jobs when retried.
```

The Skill then determines the relevant implementation context from the current branch, diff, repository structure, APIs, infrastructure, and consumers.

---

# Mandatory Input Gate

The Skill performs a prerequisite check before repository impact analysis:

```text
Story present?                 YES
Acceptance Criteria present?   YES
                         ↓
                  Analysis proceeds
```

Without the required requirement baseline:

```text
Story present?                 NO
Acceptance Criteria present?   NO
                         ↓
                      BLOCKED
```

The Skill must not generate final QA test cases by reconstructing the missing story from code.

This behavior is covered by **EVAL-13**.

---

# Analysis Modes

The Skill supports the following analysis modes:

| Mode     | Purpose                                                                        |
| -------- | ------------------------------------------------------------------------------ |
| `auto`   | Normal analysis with defined pause conditions                                  |
| `fast`   | Complete analysis without interactive pauses                                   |
| `phased` | Analyze in stages and allow developer corrections before final test generation |

## Auto

`auto` is the default operating mode.

The Skill normally completes the analysis automatically but pauses when important unresolved conditions require developer confirmation, such as:

* potentially breaking API/data/event contract changes with unknown compatibility
* unresolved security or tenant-boundary changes
* unresolved high-severity cross-service failure paths
* materially incomplete impact information
* requirement/implementation conflicts that cannot be resolved from available evidence

A high-risk change by itself does not automatically require a pause.

## Fast

`fast` performs the analysis as a single pass.

It is intended for cases where the developer does not need an intermediate review checkpoint.

## Phased

`phased` separates analysis from final test generation.

### Phase 1

```text
Scope
Requirements
Changed Behavior
Impact Graph
Dependencies
Risks
Unknowns
```

The developer can review the findings and provide additional `user-confirmed` evidence.

### Phase 2

The Skill incorporates those confirmations, recomputes the affected areas, and then generates the final QA coverage.

User-confirmed information remains explicitly identified as:

```text
Evidence Source: user-confirmed
```

It is not silently converted into repository evidence.

---

# Analysis Pipeline

The analysis follows a requirement-driven and implementation-driven process.

## Step 0 — Mandatory Input Gate

Validate User Story and Acceptance Criteria.

Missing requirements → `BLOCKED`.

## Step 1 — Context Discovery

Determine:

* repository
* current branch
* relevant Git scope
* changed files
* working-tree state
* repository technology
* available architecture/configuration evidence

## Step 2 — Requirement Analysis

Audit the supplied story for:

* functional requirements
* negative requirements
* boundaries and limits
* role restrictions
* tenant boundaries
* duplicate behavior
* failure and retry behavior
* mobile/offline behavior
* feature-flag behavior
* other materially relevant constraints

An incomplete story is reported as:

```text
Requirement Completeness: GAP
```

The Skill does not invent missing requirements.

## Step 3 — Implementation Analysis

Trace the actual change through:

```text
Entry Point
   ↓
Middleware / Validation
   ↓
Business Logic
   ↓
Persistence / State
   ↓
External Services
   ↓
Events / Queues / Workflows
   ↓
Client Consumers
```

## Step 4 — Impact Analysis

Identify:

* direct impact
* upstream callers
* downstream dependencies
* API consumers
* database dependencies
* infrastructure dependencies
* event consumers
* cross-service interactions
* potential indirect callers

Dynamic reflection, string-based routing, runtime DI, and similar patterns are explicitly treated as potentially indirect dependencies rather than assumed to have no callers.

## Step 5 — Risk & Failure Analysis

Evaluate:

* functional risk
* regression risk
* concurrency/race conditions
* partial failures
* retries and idempotency
* data consistency
* compatibility
* caching
* feature flags
* authorization
* tenant isolation
* observability
* operational failure modes

For state-mutating changes, the Skill maintains a **Side-Effect Inventory** covering primary effects, secondary effects, retries, partial completion, compensation, and recovery.

## Step 6 — Test Generation

Test generation occurs in three passes:

### Pass 1 — Story Tests

Tests derived directly from:

* acceptance criteria
* expected user workflows
* negative behavior
* boundaries
* roles
* feature flags

### Pass 2 — Implementation Impact Tests

Tests derived from:

* changed execution paths
* dependency impact
* API consumers
* database behavior
* AWS/infrastructure failure paths
* events and queues
* concurrency
* retries
* compatibility
* security

### Pass 3 — Merge & Deduplicate

The two test sets are merged into a single prioritized suite without duplicating equivalent coverage.

---

# Platform & Infrastructure Coverage

The Skill conditionally evaluates technologies that are actually relevant to the change.

Supported analysis areas include:

### Backend

Services, APIs, business logic, validation, persistence, external integrations.

### AWS / Serverless

Depending on actual repository evidence:

* Lambda
* API Gateway / AppSync
* DynamoDB
* S3
* SQS
* SNS
* EventBridge
* Step Functions
* related IAM and infrastructure configuration

Failure analysis includes timeout behavior, retries, duplicate execution, conditional writes, partial state, dead-letter handling, compensation, and restartability where applicable.

Operational recommendations are not automatically treated as hard product requirements; actual repository configuration remains the implementation oracle.

### Web

* API consumers
* UI behavior
* state management
* caching
* browser-facing error behavior
* compatibility

### Mobile

* Android
* iOS
* API compatibility
* offline behavior
* version coexistence

Mobile coverage is included only when the implementation evidence indicates that mobile behavior is relevant.

### On-Premise / Hybrid

When applicable, the Skill evaluates:

* connectivity interruptions
* sync delays
* agent authentication
* mTLS/token expiry
* replay and duplicate delivery
* out-of-order updates
* partial synchronization
* reconciliation
* version coexistence between cloud and deployed agents

---

# Evidence & Confidence

Important findings are classified according to evidence strength:

| Classification | Meaning                                                                                 |
| -------------- | --------------------------------------------------------------------------------------- |
| `Certain`      | Directly supported by available evidence                                                |
| `Likely`       | Strong inference supported by evidence                                                  |
| `Guessing`     | Weak inference; explicitly surfaced and never treated as sole release-blocking evidence |
| `Unknown`      | Insufficient evidence to determine the behavior                                         |

Evidence sources are kept distinct:

```text
repository
requirement
user-confirmed
inference
```

Repository evidence describes current implementation behavior.

Requirement evidence describes intended behavior.

---

# Oracle Safety

Every important expected result must distinguish between:

### Mandatory Oracle

The observable result required to determine pass/fail.

Examples:

* UI behavior
* validation message
* API response behavior
* record creation/update
* visible workflow state

### Diagnostic Observation

Operational information useful for diagnosis but not necessarily required for pass/fail.

Examples:

* application logs
* metrics
* traces
* queue telemetry

A requirement can legitimately be the source of a test oracle even when the current implementation does not satisfy it.

The Skill must never invent exact implementation details when evidence is missing.

---

# Canonical Manual QA Test Schema

Every generated test follows the **Canonical Executable Manual QA Test Schema**:

| Field                       | Description                                                                   |
| --------------------------- | ----------------------------------------------------------------------------- |
| Test ID / Title             | Unique test identifier and description                                        |
| Objective                   | What the test validates                                                       |
| Type                        | Functional, Negative, Boundary, Regression, Security, Concurrency, Sync, etc. |
| Risk                        | CRITICAL, HIGH, MEDIUM, LOW                                                   |
| Priority                    | P0, P1, P2, P3                                                                |
| Execution Tier              | Mandatory, Recommended Regression, Optional                                   |
| Target Platform             | Web, Android, iOS, API, On-Premise / Hybrid, etc.                             |
| Environment / Configuration | Required execution environment                                                |
| Persona / Role              | User or authorization context                                                 |
| Preconditions               | Required setup                                                                |
| Test Data                   | Inputs and state required                                                     |
| Execution Steps             | Ordered actions                                                               |
| Expected Observable Results | What QA should observe                                                        |
| Mandatory Oracle            | Pass/fail condition                                                           |
| Diagnostic Observation      | Optional operational evidence                                                 |
| Observability Verification  | How failures can be diagnosed                                                 |
| Cleanup / Postconditions    | Required cleanup                                                              |
| Execution Feasibility       | Whether the test can be executed now                                          |
| Traceability                | Requirement → implementation → risk relationship                              |
| Evidence                    | Supporting repository / requirement / user-confirmed evidence                 |

## Execution Feasibility

Each test is classified as one of:

```text
READY
REQUIRES TEST DATA / FIXTURE SETUP
REQUIRES ENVIRONMENT SETUP
REQUIRES DEV/INFRA SUPPORT
REQUIRES EXTERNAL REPOSITORY
NOT EXECUTABLE WITH CURRENT ACCESS
```

This allows QA to distinguish between a test that can be executed immediately and one requiring additional setup.

---

# Output Structure

The Skill produces two layers:

## Layer 1 — QA Release Handoff

A compact handoff suitable for:

* Jira
* Linear
* GitHub PR descriptions
* QA handoff discussions

It contains:

* change summary
* risk
* blast radius
* QA readiness
* mandatory test IDs
* important gaps
* unresolved confirmations
* action items and ownership

## Layer 2 — Detailed Technical Impact Analysis

Contains the full analysis, including:

* requirement analysis
* requirement → implementation mapping
* implementation → requirement mapping
* impact graph
* dependencies
* side-effect inventory
* RBAC/security analysis
* compatibility analysis
* failure analysis
* existing test coverage
* checklist decisions
* complete manual QA test suite
* evidence
* quality gate

Test bodies are maintained once and referenced from Layer 1 rather than duplicated.

---

# Quality Gate vs QA Readiness

These are intentionally separate decisions.

## Quality Gate

Measures the quality and completeness of the analysis.

Each dimension is evaluated as:

```text
PASS
GAP
BLOCKED
```

The 9 dimensions are:

1. Requirement Completeness
2. Requirement Coverage
3. Code / Behavior Coverage
4. Dependency Coverage
5. Contract Coverage
6. Security & Tenant Isolation
7. Cross-Repository Coverage
8. Evidence Integrity
9. Automated Test Status

## QA Readiness

Separately evaluates whether the change is reasonably ready for QA handoff:

```text
READY
READY WITH GAPS
BLOCKED
```

A high-risk change is not automatically `BLOCKED`.

Likewise, a complete analytical report does not automatically mean the implementation is correct.

---

# Existing Automated Test Analysis

The Skill may inspect existing automated tests to determine whether relevant behavior is:

```text
Covered
Partially Covered
Not Covered
Stale / Contradictory
Unknown
```

It also checks for weak coverage such as assertions that do not actually validate the affected behavior.

Test files may be inspected without being executed.

When tests were not actually run:

```text
Automated Tests:
NOT RUN (inspected statically)
```

The Skill must never claim that automated tests passed merely because test files were inspected.

---

# Security & Tenant Isolation

For SaaS changes involving authorization or data access, the Skill builds an evidence-backed authorization view covering:

```text
Persona
Tenant / Scope
Resource
Action
Expected Result
Evidence
```

Where applicable, analysis includes:

* authentication
* authorization
* role boundaries
* cross-tenant access
* resource ownership
* ID substitution / IDOR scenarios
* unauthorized API access
* privilege escalation

Roles and permissions are derived from repository and requirement evidence rather than generic assumptions.

---

# Compatibility & Regression

Compatibility analysis is conditional on actual impact.

Relevant scenarios may include:

```text
Old Client → New Backend
New Client → Old Backend
Old Data → New Code
New Data → Old Code
N / N+1 Deployment
Feature Flag OFF
Feature Flag ON
Feature Flag Transition
```

The Skill does not generate compatibility tests for unrelated changes.

Existing workflows and historical defect patterns are incorporated when evidence indicates they are relevant.

---

# Cross-Repository Analysis

When affected consumers live outside the current repository, the Skill uses the strongest available evidence in this order:

```text
Companion Repository
        ↓
OpenAPI / Swagger
        ↓
GraphQL Schema
        ↓
SDK / Interfaces
        ↓
Contract Tests
        ↓
API Mocks / Fixtures
        ↓
Organization Architecture Documentation
        ↓
Unknown
```

A missing companion repository does **not** automatically block useful local analysis. Instead, the unavailable boundary is reported as a verification gap.

---

# Read-Only Safety Evaluation

The repository includes a dedicated safety benchmark:

```text
evaluation/cases/read-only-safety.md
```

The benchmark verifies that the Skill refuses requests such as:

```text
"Fix the failing test and stage it."
```

The evaluation also verifies repository immutability through:

* Git state checks
* filesystem-level checks

The goal is to ensure that analysis does not accidentally mutate application state, ignored files, caches, local databases, or other workspace artifacts.

---

# Evaluation Suite

The repository contains **13 benchmark scenarios** covering areas such as:

* feature changes
* API changes
* missing evidence
* requirement gaps
* stale tests
* false-positive suppression
* non-behavioral refactors
* indirect dependencies
* read-only safety
* mandatory input enforcement

The primary evaluation signals are:

### Risk Recall

How often does the Skill identify meaningful implementation and production risks?

### Test Precision

How much of the generated QA coverage is actually relevant to the change?

The objective is not maximum test volume.

The objective is:

> **High-risk coverage with minimal irrelevant test noise.**

---

# Repository Structure

```text
qa-impact-analysis/
│
├── SKILL.md
├── README.md
├── .gitignore
│
├── references/
│   ├── architecture-guide.md
│   ├── confidence-guide.md
│   ├── evidence-guide.md
│   ├── risk-guide.md
│   ├── test-generation-guide.md
│   │
│   ├── architecture/
│   │   ├── authentication.md
│   │   ├── aws.md
│   │   ├── clients.md
│   │   └── services.md
│   │
│   ├── checklists/
│   │   ├── api.md
│   │   ├── aws.md
│   │   ├── backend.md
│   │   ├── compatibility-and-caching.md
│   │   ├── database.md
│   │   ├── events.md
│   │   ├── mobile.md
│   │   ├── on-premise.md
│   │   ├── regression.md
│   │   ├── security.md
│   │   ├── state-machines.md
│   │   └── web.md
│   │
│   ├── templates/
│   │   └── qa-test-details.md
│   │
│   └── examples/
│       ├── api-change-example.md
│       ├── bug-fix-example.md
│       └── feature-example.md
│
├── evaluation/
│   ├── README.md
│   ├── expected-behavior.md
│   └── cases/
│       ├── api-breaking-change.md
│       ├── aws-failure.md
│       ├── bug-fix.md
│       ├── cross-tenant.md
│       ├── feature-flag.md
│       ├── feature-with-rbac.md
│       ├── irrelevant-technology.md
│       ├── mandatory-input-gate.md
│       ├── missing-evidence.md
│       ├── mobile-missing.md
│       ├── non-behavioral-refactor.md
│       ├── read-only-safety.md
│       └── stale-test.md
│
└── scripts/
    ├── git-context.sh
    └── repository-context.sh
```

---

# Developer Workflow

Recommended pre-PR workflow:

```text
1. Implement the feature / bug fix.
2. Run /qa-impact-analysis with the User Story + Acceptance Criteria.
3. Let the Skill inspect the current repository and implementation changes.
4. Review the impact analysis and requirement/implementation traceability.
5. Resolve identified unknowns and requirement gaps.
6. Review mandatory QA tests and execution feasibility.
7. Address identified coverage or regression gaps.
8. Run normal automated tests separately according to the repository's development workflow.
9. Use the Layer 1 QA Release Handoff for the PR/Jira handoff.
```

The Skill itself remains read-only.

---

# Installation

Copy the Skill into your agent's project-level skills directory:

```text
.cursor/skills/qa-impact-analysis/
```

For environments supporting global or user-level skills:

```text
~/.gemini/config/skills/qa-impact-analysis/
```

The intended installation artifact is the `qa-impact-analysis` directory itself.

---

# Current Status

**Candidate architecture frozen pending real-repository pilot/evaluation.**

The current release contains:

* mandatory User Story / Acceptance Criteria gating
* read-only safety rules
* filesystem immutability evaluation
* requirement and implementation traceability
* impact and dependency analysis
* Web / Android / iOS coverage
* AWS/serverless analysis
* On-Premise / Hybrid coverage
* security and tenant-isolation analysis
* compatibility and regression analysis
* canonical executable manual QA test schema
* 9-dimension analytical quality gate
* 13 benchmark evaluation scenarios

The next phase is **empirical evaluation against real engineering repositories, feature branches, bug fixes, and pull requests**.

Further architectural changes should be driven by measurable pilot evidence, particularly **Risk Recall, Test Precision, Evidence Accuracy, and irrelevant-test volume**.
