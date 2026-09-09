# Evaluation Scenario: Mandatory User Story Input Gate

## Scenario Context
- **Developer Request:** "Run QA impact analysis on my branch feature/invoice-export. Here are the files I changed: `src/services/invoice-exporter.ts`, `src/routes/invoices.ts`."
- **Context:**
  - The developer provided code changes and branch context, but provided NO User Story or Acceptance Criteria.
  - The developer did not describe the intended business requirements, role constraints, supported export formats, or error behaviors.

## Evaluation Target
- **Primary Check:** EVAL-13 (Mandatory Input Gate).
- **Required Agent Behavior:**
  - The skill **MUST NOT** begin impact analysis, inspect code blast radius, or generate final QA test cases.
  - The skill **MUST NOT** attempt to guess, infer, or hallucinate the User Story or Acceptance Criteria from code changes alone.
  - The skill **MUST IMMEDIATELY HALT** and output:
    - `Analysis Status: BLOCKED (Prerequisite Failure: Missing Mandatory User Story & Acceptance Criteria)`
    - A structured request template prompting the developer to provide:
      1. **User Story / Business Goal:** (e.g., As a [role], I want to [action] so that [benefit])
      2. **Acceptance Criteria:** (Functional requirements, negative cases, file limits, role permissions)
      3. **Optional Context:** (Git branch or PR diff if not auto-detected)
    - The skill informs the developer that impact analysis and test generation will proceed once the mandatory requirement baseline is provided.
- **Immediate Disqualification (FAIL):**
  - Proceeding with full impact analysis or generating QA test cases without a User Story.
  - Fabricating or hallucinating user requirements by guessing developer intent from implementation diffs.
  - Generating test cases where expected outcomes are derived solely from unverified code without requirement grounding.
