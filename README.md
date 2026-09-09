# qa-impact-analysis

**Repository-aware AI skill that turns your User Story and Git diff into execution-ready manual QA test details before you open a PR.**

[![Status: Candidate Frozen](https://img.shields.io/badge/Status-Candidate_Frozen-blue.svg)](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/walkthrough.md)
[![Safety: Read--Only](https://img.shields.io/badge/Safety-Read--Only-green.svg)](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/SKILL.md)
[![Evaluation: 13 Benchmarks](https://img.shields.io/badge/Evaluation-13_Benchmarks-purple.svg)](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/evaluation/README.md)

---

## What is this?

`qa-impact-analysis` is an AI-powered QA architect skill for **Cursor** and **Antigravity IDE**. When you finish a feature, bug fix, API change, database migration, or refactor, it analyzes your active Git changes against your business requirements and outputs a structured, execution-ready manual QA test plan.

### Why does it exist?

Developers frequently hand changes over to QA with vague notes like *"fixed order submission"* or *"updated export API"*. QA engineers are left guessing:
- What edge cases were created?
- What downstream consumers or background jobs were affected?
- Which roles, permissions, or client versions might break?

### Why is it different?

Most AI test generators fail because they rely on only **one** source of truth:
1. **Ticket-only AI:** Reads the Jira issue, hallucinates tests based on generic concepts, and has no idea what the code actually does.
2. **Diff-only AI:** Reads the Git diff, assumes whatever buggy code the developer wrote was intended, and reverse-engineers tests from bugs.

`qa-impact-analysis` combines **two sources of truth**:

```text
User Story / Acceptance Criteria  →  Defines what the system SHOULD do
             +
Actual Git Diff / Repository     →  Defines what the code ACTUALLY does
             ↓
     QA Impact Analysis
             ↓
Requirement ↔ Implementation Trace
             ↓
Multi-Dimensional Blast Radius & Side Effects
             ↓
Deterministic Manual QA Test Suite
             ↓
     QA Release Handoff
```

---

## Quick Start

### 1. Install the Skill

**Option A: Project-Level (Recommended for teams)**
Copy the `qa-impact-analysis` directory into your project:
```bash
# For Cursor
cp -R qa-impact-analysis .cursor/skills/qa-impact-analysis

# For Antigravity IDE
cp -R qa-impact-analysis .agents/skills/qa-impact-analysis
```

**Option B: Global (Available across all repositories)**
```bash
# For Antigravity IDE
cp -R qa-impact-analysis ~/.gemini/config/skills/qa-impact-analysis
```

### 2. Invoke in Chat

Open your AI chat in Cursor or Antigravity and provide your **User Story** and **Acceptance Criteria**. The skill automatically detects your branch, staged/unstaged changes, and tech stack:

```text
/qa-impact-analysis

Story: As a workplace admin, I want to export monthly invoices to PDF or CSV so that I can reconcile accounting records.

Acceptance Criteria:
1. Support PDF and CSV export formats.
2. Limit batch export to 500 records per job.
3. Reject unsupported formats with HTTP 400 validation error.
4. Enforce Workplace Admin role authorization.
5. Prevent duplicate export jobs on rapid double-clicks.
```

> **Mandatory Input Gate:** A User Story + Acceptance Criteria are **mandatory**. If omitted, the skill halts immediately with `Analysis Status: BLOCKED` to prevent hallucinating business intent from diffs alone.

---

## Example Output

Here is what `/qa-impact-analysis` generates in your chat session:

### Layer 1: QA Release Handoff Card
*(Compact summary ready to paste directly into Jira, Linear, or GitHub PR descriptions)*

```markdown
### QA Release Handoff: Invoice Batch Export (INV-104)

- **Production Risk:** HIGH | **Blast Radius:** MEDIUM | **Contract:** Compatible
- **Change Type:** New Feature | **Recommended QA Readiness:** READY

#### Must-Test Scenarios (Mandatory QA)
| TC-ID | Title | Priority | Risk | Feasibility | Reason |
|---|---|---|---|---|---|
| TC-001 | Successful CSV Export under 500 records | P0 | HIGH | READY | Direct AC-1 & AC-2 validation |
| TC-002 | Reject export exceeding 500 record ceiling | P0 | HIGH | READY | Boundary condition limit |
| TC-003 | Rapid double-click duplicate submission | P0 | HIGH | READY | Devil's advocate race condition |
| TC-004 | Member role attempt to trigger export | P1 | HIGH | READY | RBAC isolation boundary |

#### Blocking Production Risks & Devil's Advocate
- **Race Condition on Double-Submit:** Rapidly clicking "Export" triggers two concurrent Lambda executions. Mitigated by Redis idempotency lock (`src/services/lock.ts:42`).
- **Memory Ceiling:** PDF generation buffers in memory; jobs with >300 heavy invoices risk Lambda out-of-memory.

#### Action Items & Ownership
| Action Item | Owner | Blocking Release? |
|---|---|:---:|
| Verify Redis idempotency lock TTL in staging config | DevOps / Backend | Yes |
| Execute mandatory manual test suite (TC-001 to TC-004) | QA | Yes |
```

### Layer 2: Executable Manual QA Test Card (Sample)
*(Adheres to the Canonical Executable Test Schema)*

```markdown
#### TC-003: Rapid double-click duplicate submission handling
- **Objective:** Verify concurrent export requests with identical parameters reject duplicate processing and return conflict response without generating duplicate S3 objects.
- **Type:** Concurrency / Negative | **Risk:** HIGH | **Priority:** P0 | **Tier:** Mandatory QA
- **Execution Feasibility:** READY (Executable immediately with standard credentials)
- **Target Platform:** Web Desktop / REST API | **Persona / Role:** Workplace Admin
- **Preconditions:** Workplace has at least 10 invoices in current billing cycle.
- **Execution Steps:**
  1. Navigate to Billing > Invoices.
  2. Open Browser DevTools Network tab with throttling set to "Fast 3G".
  3. Click "Export Monthly Invoices", select "CSV".
  4. Rapidly double-click the "Download" button within 200ms.
- **Expected Observable Results:**
  - **Mandatory Oracle (Pass/Fail):**
    - First request returns HTTP 200 / 202 with job initiation payload.
    - Second request returns HTTP 409 Conflict with UI message "Export already in progress".
    - S3 bucket `clappia-invoices-export/` contains exactly ONE generated CSV archive for the billing cycle.
  - **Diagnostic Observation:**
    - Redis key `lock:export:{workspaceId}:{month}` observed with 60-second TTL.
- **Cleanup:** Delete generated test export artifact from user downloads.
- **Traceability:** REQ: AC-5 | IMP: `src/services/lock.ts:42` | RISK: Double-charge / duplicate file generation
```

---

## What It Analyzes

The skill inspects your actual codebase and selectively applies specialized failure semantics:

- **Backend & APIs:** REST endpoints, GraphQL mutations, RPC handlers, middleware auth, payload validation, status codes.
- **Databases:** PostgreSQL, MySQL, MongoDB, DynamoDB conditional checks, optimistic concurrency, transactions, lock contention, migrations.
- **AWS & Serverless:** Lambda timeouts (trigger-dependent ceilings), SQS queue visibility vs. function execution, S3 pre-signed URLs, EventBridge event routing, Step Functions state rollbacks.
- **Web Clients:** React/Next.js routes, optimistic UI states, token expiration, network drop banners, form double-submission.
- **Mobile Apps (Android & iOS):** Offline sync queues, backward-compatible API contracts, version coexistence (Client v1 against Backend v2).
- **On-Premise & Hybrid:** Sync agents, connectivity drops midway through sync, mTLS/token expiry, out-of-order replay idempotency, reconciliation jobs.

---

## What You Get

Every analysis delivers a structured **Two-Layer Handoff**:

1. **Layer 1: QA Release Handoff Card**
   Compact, copy-paste-ready summary for PR descriptions, Jira, or Slack handoffs containing risk ratings, blocking risks, action owners, and must-test scenarios referenced by ID.
2. **Layer 2: Detailed Technical Impact Analysis**
   - Bidirectional Requirements Matrix (`REQ → Code` and `Code → REQ` scope creep audit)
   - Multi-Dimensional Blast Radius (Upstream callers, downstream consumers, DB tables)
   - Devil's Advocate Failure Analysis & Side-Effect Inventory
   - Role-Based Access Control (RBAC) Isolation Matrix
   - Complete Executable Manual QA Test Cards
   - Existing Test Evaluation (`Covered`, `Shallow`, or `Stale/Contradictory`)
   - **9-Dimension Quality Gate Scorecard** (`PASS` / `GAP` / `BLOCKED`)

---

## How It Works

```text
Step 0: Mandatory Input Gate  → Verify User Story + AC present (Missing → BLOCKED)
Step 1: Context Discovery     → Read Git diff, branch, stack manifests (Read-Only)
Step 2: Requirement Audit     → Story Completeness & Bidirectional Code Mapping
Step 3: Execution Tracing     → Trace entry points, services, mutations, callers
Step 4: Failure Analysis      → Devil's Advocate scenarios & Side-Effect Inventory
Step 5: 3-Pass Test Suite     → Pass 1 (Story) + Pass 2 (Impact) → Pass 3 (Merged)
Step 6: Quality Gate Scorecard→ Evaluate 9 analytical dimensions & QA readiness
```

---

## Analysis Modes

| Mode | Command | Behavior |
|---|---|---|
| **Auto** (Default) | `/qa-impact-analysis` | Runs to completion automatically. Pauses for developer confirmation only if it detects unresolved breaking contracts or security boundary ambiguities. |
| **Fast** | `/qa-impact-analysis --mode fast` | One-shot analysis without interactive pauses. Ideal for standard bug fixes or pre-commit checks. |
| **Phased** | `/qa-impact-analysis --mode phased` | Pauses after Phase 1 (Impact Graph & Requirements). Allows you to provide `user-confirmed` overrides before generating test cases. |

---

## Safety & Anti-Hallucination Guarantees

- **Strictly Read-Only:** The skill **never** modifies application source code, test files, configs, schemas, or Git state (`git add`, `git commit`, `git reset`, branch checkout). Test commands must be verified as non-mutating before execution; otherwise they are inspected statically.
- **Zero Fabrication:** The skill never manufactures arbitrary HTTP status codes, error strings, or file paths. If evidence is missing, it asserts observable behavior and marks representations as requiring verification.
- **Prerequisite Enforcement:** Missing user stories or unresolvable prerequisite failures return `Analysis Status: BLOCKED` rather than guessing intended behavior.

---

## Evaluation & Benchmark Suite

The skill is governed by **13 codified evaluation benchmarks** in [`evaluation/cases/`](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/evaluation/cases/):

| ID | Focus Area | Tested Invariant |
|---|---|---|
| **EVAL-01** | Evidence-Safe Oracles | Rejects inventing status codes when omitted from code. |
| **EVAL-02** | Cross-Repository | Degrades to contract fallback when companion repos are missing. |
| **EVAL-03** | Stale Tests | Flags legacy tests asserting obsolete behavior as Stale. |
| **EVAL-04** | Execution Honesty | Reports `Automated Tests: NOT RUN (inspected statically)` when not run. |
| **EVAL-05** | Gate Separation | Separates analytical quality gate (`GAP`) from release blockers (`BLOCKED`). |
| **EVAL-06** | Test Executability | Mandates feasibility tags, concrete steps, and observable oracles. |
| **EVAL-07** | Dual-Layer Output | Layer 1 references Layer 2 test IDs without duplicating test bodies. |
| **EVAL-08** | RBAC Isolation | Tests Admin, Member, Cross-Tenant, and Anonymous personas. |
| **EVAL-09** | Precision Filter | Excludes irrelevant technology checklists (e.g. AWS checklist on CSS changes). |
| **EVAL-10** | Feasibility Tags | Flags tests requiring infrastructure or database seed setups. |
| **EVAL-11** | Read-Only Safety | Mechanical Git and filesystem audit: verifies zero file mutations. |
| **EVAL-12** | Story Completeness | Flags user story omissions (file sizes, role restrictions) as `GAP`. |
| **EVAL-13** | Mandatory Input Gate | Blocks execution when invoked without a User Story or Acceptance Criteria. |

*Empirical metrics (Risk Recall vs. Test Precision) will be measured during real-repository pilot evaluation.*

---

## Limitations

- **Garbage In, Garbage Out:** If acceptance criteria omit critical business rules, the skill will flag ambiguities under `Requirement Completeness: GAP` but cannot guess your business intent.
- **Dynamic Reflection & DI:** Highly dynamic reflection or string-based DI routing cannot always be fully traced statically; the skill flags them as `Potential Indirect Dependencies`.
- **Cross-Repository Visibility:** If companion repositories (e.g. separate frontend and backend repos) are not open in the workspace, the skill falls back to OpenAPI/GraphQL contracts and surfaces unverified boundaries.
- **Analysis-Only:** The skill designs tests but does not write or execute end-to-end automated scripts.

---

## Repository Structure

```text
qa-impact-analysis/
├── SKILL.md                          # Core operating contract & prompt rules
├── README.md                         # Project documentation
├── .gitignore                        # Git ignore patterns
│
├── references/                       # Domain methodology & checklists
│   ├── architecture-guide.md         # Multi-service architecture tracing
│   ├── confidence-guide.md           # Certain vs Likely vs Guessing taxonomy
│   ├── evidence-guide.md             # Evidence ledger & source governance
│   ├── risk-guide.md                 # Risk scoring & blast-radius calculation
│   ├── test-generation-guide.md      # 3-pass test generation & oracle safety
│   ├── architecture/                 # Clappia architecture reference notes
│   ├── checklists/                   # 12 conditional technology checklists
│   │   ├── api.md, aws.md, backend.md, database.md, events.md, mobile.md...
│   ├── examples/                     # Canonical reference examples
│   │   ├── feature-example.md, bug-fix-example.md, api-change-example.md
│   └── templates/
│       └── qa-test-details.md        # Master output template
│
├── evaluation/                       # Evaluation framework & benchmarks
│   ├── README.md
│   ├── expected-behavior.md          # 13-case evaluation rubric
│   └── cases/                        # 13 benchmark test cases (EVAL-01 to EVAL-13)
│
└── scripts/                          # Non-mutating repository discovery helpers
    ├── git-context.sh                # Inspects diffs, commits, and branches
    └── repository-context.sh         # Detects monorepos, stacks, and manifests
```

---

## Current Status

**Candidate architecture frozen pending real-repository pilot/evaluation.**

All contracts, canonical schemas, checklists, safety invariants, and evaluation rubrics are codified. The next step is empirical evaluation across real engineering repositories, feature branches, and pull requests.
