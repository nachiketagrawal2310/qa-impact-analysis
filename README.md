# qa-impact-analysis

**Repository-aware AI skill that turns your User Story and Git diff into execution-ready manual QA test details before you open a PR.**

[![Status: Candidate Frozen](https://img.shields.io/badge/Status-Candidate_Frozen-blue.svg)](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/walkthrough.md)
[![Safety: Read--Only](https://img.shields.io/badge/Safety-Read--Only-green.svg)](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/SKILL.md)
[![Evaluation: 14 Benchmarks](https://img.shields.io/badge/Evaluation-14_Benchmarks-purple.svg)](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/evaluation/README.md)

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

`qa-impact-analysis` combines **two sources of truth** with an internal analysis pipeline:

```text
User Story / Acceptance Criteria  →  Defines what the system SHOULD do
             +
Actual Git Diff / Repository     →  Defines what the code ACTUALLY does
             ↓
     QA Impact Analysis
             ↓
┌─────────────────────────────────────────────────────────┐
│              INTERNAL DEEP ANALYSIS (SILENT)            │
│  • Code Diff & Dependency Tracing                       │
│  • AWS / Cloud / Database / State Machine Analysis      │
│  • Web / Android / iOS / On-Premise Impact Discovery    │
│  • Security & Multi-Tenant Boundary Verification        │
│  • Regression Tracing & Devil's Advocate Hypotheses     │
│  • Static Test Coverage & Quality Gate Scoring          │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
 ┌────────────────────────────────────────────────────────┐
 │           DEFAULT OUTPUT: QA TEST DETAILS              │
 │  • Consolidated Preconditions & Test Data              │
 │  • Step-by-Step Executable Manual Test Cases           │
 │  • Concrete Expected Results & Feasibility Tags        │
 │  • Zero Reasoning Narrative / Zero Metadata Clutter    │
 └────────────────────────────────────────────────────────┘

Optional:
  • --full   / "Give me full impact analysis" → Exposes complete technical analysis
  • --phased / "Do phased analysis"          → Checkpoint on Scope + Impact before tests
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

### Default Output: QA Test Details
*(Directly executable manual test cases generated for the story above)*

```markdown
# QA Test Details

## Preconditions / Test Data

- User with Workplace Admin role in Workspace A
- User with Member role in Workspace A (for RBAC test)
- Existing invoices in billing cycle (minimum 10 records)
- Boundary dataset: Invoice batch exceeding 500 records
- Chrome/Firefox browser with Network DevTools access

## Test Cases

### TC-01 — Successful CSV Export under 500 records
**Priority:** P0
**Type:** Functional
**Feasibility:** Manual

**Steps**
1. Log in as Workplace Admin and navigate to Billing > Invoices.
2. Click "Export Monthly Invoices".
3. Select "CSV" format from dropdown and click "Download".
4. Open the downloaded CSV file.

**Expected Result**
- Download initiates immediately with HTTP 200.
- Downloaded CSV contains invoice records matching billing screen.
- S3 archive is created under workspace billing prefix.

### TC-02 — Reject export exceeding 500 record ceiling
**Priority:** P0
**Type:** Negative
**Feasibility:** Requires test data

**Steps**
1. Navigate to Billing > Invoices on a workspace with >500 records.
2. Select all invoices and click "Export Monthly Invoices".
3. Select format and submit.

**Expected Result**
- Request is rejected with HTTP 400 Bad Request.
- UI displays clear validation error: "Batch export cannot exceed 500 records."
- No background export job or S3 object is created.

### TC-03 — Rapid double-click duplicate submission handling
**Priority:** P0
**Type:** Concurrency / Negative
**Feasibility:** Manual

**Steps**
1. Navigate to Billing > Invoices.
2. Set Network throttling to "Fast 3G" in Browser DevTools.
3. Click "Export Monthly Invoices" and rapidly double-click "Download" within 200ms.

**Expected Result**
- First request returns HTTP 200/202 and initiates export.
- Second request returns HTTP 409 Conflict with banner: "Export already in progress".
- Exactly ONE export job runs; no duplicate files created.

### TC-04 — Member role attempt to trigger export
**Priority:** P1
**Type:** Security / RBAC
**Feasibility:** Manual

**Steps**
1. Log in as standard Member.
2. Attempt to navigate directly to Billing export endpoint `/api/workspaces/{id}/invoices/export`.

**Expected Result**
- Request is denied with HTTP 403 Forbidden.
- UI does not render export button for non-admin personas.

## Notes

- **Scope Note:** No mobile-specific cases included; no affected mobile consumer was identified.
```

---

## Output Modes & Flags

You can control the output format using CLI-style flags or natural-language requests:

| Mode | Triggers | Deliverable |
|---|---|---|
| **Default** | `/qa-impact-analysis` | **Only Executable QA Test Details** (Preconditions, Test Cases with Priority, Type, Feasibility, Steps, Expected Result). Strictly zero narrative reasoning or internal IDs. |
| **Full Analysis** | `--full` or *"Give me the full impact analysis"*, *"Show me why these tests were selected"* | **Dual-Layer Technical Impact Report** (Scope, QA Release Handoff Card, Coverage Matrix, Checklist Decisions, Blast Radius, Side Effects, RBAC Matrix, Compatibility, Devil's Advocate, Scorecard). |
| **Phased** | `--phased` or *"Do phased analysis"*, *"Step by step impact review"* | **Interactive Checkpoint**: Phase 1 outputs understood Requirement + Scope + Confirmed Impact, then **STOPS** for developer feedback before generating final tests in Phase 2. |

---

## Safety & Anti-Hallucination Guarantees

- **Strictly Read-Only (Command Execution Ban):** The skill **never** modifies application source code, test files, configs, schemas, or Git state (`git add`, `git commit`, `git reset`, branch checkout). No test runner (`vitest`, `jest`, `pytest`), compiler (`tsc`), build system, package manager, or migration command may be executed. For V1, automated tests are evaluated 100% via static inspection to guarantee zero filesystem mutation.
- **Pre-Tool Zero-Action Barrier:** If invoked without a User Story or Acceptance Criteria, the skill immediately halts on Turn 1 before calling ANY tool or inspecting files. It will never synthesize requirements from diffs, commit messages, or code comments.
- **Zero Fabrication:** The skill never manufactures arbitrary HTTP status codes, error strings, or file paths. If evidence is missing, it asserts observable behavior and marks representations as requiring verification.

---

## Evaluation & Benchmark Suite

The skill is governed by **14 codified evaluation benchmarks** in [`evaluation/cases/`](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/evaluation/cases/):

| ID | Focus Area | Tested Invariant |
|---|---|---|
| **EVAL-01** | Evidence-Safe Oracles | Rejects inventing status codes when omitted from code. |
| **EVAL-02** | Cross-Repository | Degrades to contract fallback when companion repos are missing. |
| **EVAL-03** | Stale Tests | Flags legacy tests asserting obsolete behavior as Stale. |
| **EVAL-04** | Execution Honesty | Reports `Automated Tests: NOT RUN (inspected statically)` when not run. |
| **EVAL-05** | Gate Separation | Separates analytical quality gate (`GAP`) from release blockers (`BLOCKED`). |
| **EVAL-06** | Test Executability | Mandates feasibility tags, concrete steps, and observable oracles. |
| **EVAL-07** | Default Output Contract | Default output is strictly executable QA test details with zero narrative; dual-layer report reserved for --full. |
| **EVAL-08** | RBAC Isolation | Tests Admin, Member, Cross-Tenant, and Anonymous personas. |
| **EVAL-09** | Precision Filter | Excludes irrelevant technology checklists (e.g. AWS checklist on CSS changes). |
| **EVAL-10** | Feasibility Tags | Flags tests requiring infrastructure or database seed setups. |
| **EVAL-11** | Read-Only Safety | Mechanical Git and filesystem audit: verifies zero file mutations. |
| **EVAL-12** | Story Completeness | Flags user story omissions (file sizes, role restrictions) as `GAP`. |
| **EVAL-13** | Mandatory Input Gate | Blocks execution when invoked without a User Story or Acceptance Criteria. |
| **EVAL-14** | Pre-Tool Barrier & Command Ban | Vague prompt ("test this branch"): zero tools called, zero commands, immediate `BLOCKED`. |

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
