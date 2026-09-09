# qa-impact-analysis

A senior QA architect and software engineering AI skill that performs evidence-based change-impact analysis and generates structured, evidence-backed, execution-ready manual QA test details before releasing code changes to QA.

---

## What It Does

When developers finish a feature, bug fix, refactor, API modification, or database migration, they can run `/qa-impact-analysis` to:

1. **Enforce Read-Only Safety:** Operates strictly as a read-only analyst. It will never edit application files, test files, configs, schemas, or dependencies, and will never stage (`git add`), commit, reset, or checkout Git branches.
2. **Enforce Mandatory Input Gate:** Requires a User Story and Acceptance Criteria before analysis begins. Rejects vague, ungrounded code inspections to ensure tests are anchored to intended business requirements rather than hallucinated from code diffs.
3. **Audit Story Completeness & Bidirectional Traceability:** Audits user stories for missing constraints (allowed file types, size ceilings, duplicate handling) and maps requirements bidirectionally against actual code changes.
4. **Calculate Multi-Dimensional Blast Radius:** Evaluates relevant changed execution paths, upstream callers, downstream services, database tables, and client consumers (Web, Android, iOS, and On-Premise/Hybrid).
5. **Mitigate Production Regressions:** Uncovers edge cases, race conditions, backward compatibility risks, and failure after partial completion using **Devil's Advocate Analysis** and **Side-Effect Inventories**.
6. **Generate Execution-Ready Manual QA Test Cases:** Produces complete, deterministic test cards adhering to the **Canonical Executable Manual QA Test Schema** with concrete feasibility tags, preconditions, test data, step-by-step user actions, and observable expected results (Mandatory Oracles vs. Diagnostic Observations).
7. **Produce a 2-Layer Handoff:**
   - **Layer 1: QA Release Handoff Card:** A compact, copy-paste-ready summary for Jira, Linear, or GitHub PR descriptions containing risk ratings, blocking items, action owners, and a table referencing test IDs without repetition.
   - **Layer 2: Detailed Technical Impact Analysis:** Complete architectural blast radius, RBAC authorization matrix, rolling-deployment compatibility, side-effect inventory, full manual test cards, and a granular quality gate scorecard.
8. **Enforce Evidence-Safe Anti-Hallucination:** Strictly forbids inventing status codes, line numbers, or endpoints. Flags missing repository context honestly without halting analysis.

---

## Installation

Install into your AI agent environment (Cursor, Antigravity, or custom agent):

- **Project Root:** `.cursor/skills/qa-impact-analysis/` or `.agents/skills/qa-impact-analysis/`
- **Global / User Root:** `~/.cursor/skills/qa-impact-analysis/` or `~/.gemini/config/skills/qa-impact-analysis/`

---

## Invocation Model & Execution Modes

### Invocation Model
- **User Story & Acceptance Criteria:** **MANDATORY**. The developer must supply the business requirement, ticket description, or acceptance criteria. If missing, the skill halts immediately with `Analysis Status: BLOCKED`.
- **Implementation Context:** **AUTO-DETECTED / OPTIONAL**. The skill automatically discovers changed files, branch diffs, and repository stack manifests using non-mutating inspection scripts. Custom branch comparisons or file paths can be supplied optionally.

Example Cursor Invocation:
```text
/qa-impact-analysis
Story: As a workplace admin, I want to export monthly invoices to PDF/CSV so that I can reconcile accounting records.
Acceptance Criteria:
1. Support PDF and CSV export formats.
2. Limit batch export to 500 records per job.
3. Reject unsupported formats with validation error.
4. Enforce Workplace Admin role authorization.
```

### Execution Modes
- **`--mode auto` (Default):** Runs automatically, but pauses for developer confirmation if a potentially breaking contract, unverified security boundary change, cross-service high-severity failure path, or requirement-implementation mismatch is detected. *(Does not pause merely because Risk = HIGH).*
- **`--mode fast`:** One-shot execution. Generates the full report and test cases without pausing.
- **`--mode phased`:** Pauses after Phase 1 (Analysis Scope + Requirements + Impact Graph), allowing the developer to review and add `user-confirmed` findings before Phase 2 completes test generation.

---

## 8-Step Developer Engineering Workflow

```text
1. Implement Changes & verify locally.
2. Run /qa-impact-analysis in Cursor chat with your User Story & Acceptance Criteria (code diff is auto-detected).
3. Review Impact Model & Side-Effect Inventory.
4. Resolve Unknowns & supply user-confirmed overrides if needed.
5. Review Mandatory QA Test Cases for execution feasibility.
6. Address any Coverage Gaps or Stale Tests identified by the skill.
7. Run Automated Tests separately in terminal (Skill inspects code statically in read-only mode).
8. Copy Layer 1 (QA Release Handoff Card) directly into your PR description or Jira ticket.
```

---

## Canonical Executable Manual QA Test Schema

Every test generated by the skill provides:

1. **TC-ID & Title**
2. **Objective**
3. **Type** (Functional, Negative, Boundary, Regression, Security, Concurrency, Sync, etc.)
4. **Risk** (CRITICAL, HIGH, MEDIUM, LOW)
5. **Priority** (P0, P1, P2, P3)
6. **Execution Tier** (Mandatory QA, Recommended Regression, Optional)
7. **Execution Feasibility** (`READY`, `REQUIRES TEST DATA / FIXTURE SETUP`, `REQUIRES ENVIRONMENT SETUP`, `REQUIRES DEV/INFRA SUPPORT`, `REQUIRES EXTERNAL REPOSITORY`, `NOT EXECUTABLE WITH CURRENT ACCESS`)
8. **Target Platform** (Web Desktop, Mobile Android/iOS, REST API, On-Premise / Hybrid)
9. **Environment** (Specified in context / Requires Confirmation)
10. **Persona / Role** (e.g., Workplace Admin, Member, Cross-Tenant Attacker)
11. **Preconditions**
12. **Test Data**
13. **Execution Steps** (Numbered, sequential user actions)
14. **Expected Observable Results**:
    - **Mandatory Oracle (Pass/Fail):** Observable business outcomes grounded in Requirement or Implementation evidence (UI toast/text, API status code/payload, DB record mutation).
    - **Diagnostic Observation:** Operational telemetry (log strings, metric increments).
15. **Cleanup / Postconditions**
16. **Traceability & Evidence** (`REQ → IMP → RISK` | `file:line` | Evidence Source: `repository` / `requirement` / `user-confirmed`)

---

## Quality Gate vs. QA Readiness

The skill evaluates two distinct decisions:

- **Quality Gate Scorecard (`PASS` / `GAP` / `BLOCKED`):** Evaluates analytical completeness and evidence-grounding across 9 distinct dimensions:
  1. Requirement Completeness
  2. Requirement Coverage
  3. Code/Behavior Coverage
  4. Dependency Coverage
  5. Contract Coverage
  6. Security & Tenant Isolation
  7. Cross-Repository Coverage
  8. Evidence Integrity
  9. Automated Test Status (`NOT RUN (inspected statically)`)
- **Recommended QA Readiness (`READY` / `READY WITH GAPS` / `BLOCKED`):** Evaluates whether the change is reasonably safe and testable for QA handoff.

---

## Testing & Regression Evaluation for the Skill

Before deploying this skill to your engineering team:
1. Review [evaluation/expected-behavior.md](file:///Users/clappia/Downloads/clappia/qa-impact-analysis/evaluation/expected-behavior.md).
2. Test the skill against the 13 benchmark cases in `evaluation/cases/`.
3. Verify both **Risk Recall** (finding real production risks) and **Test Precision** (avoiding irrelevant test volume).

---

## Status

**Candidate architecture frozen pending real-repository pilot/evaluation.**
All core contracts, canonical schemas, checklists, safety invariants, and evaluation rubrics are codified. The next step is empirical evaluation against real-world engineering repositories.
