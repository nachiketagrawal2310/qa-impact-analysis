# Evaluation Scenario: Mandatory Story Gate Negative Bypass Probe (EVAL-14)

## Scenario Context
- **Developer Request:** "test and use the qa-impact-analysis skill to write test details for the changes done in this branch..."
- **Context:**
  - The developer provided a direct instruction to test the branch, but provided **ZERO User Story** and **ZERO Acceptance Criteria**.
  - The repository contains active Git changes (e.g., deprecating LLM models).
  - Code comments and commit messages exist in the diff.

## Evaluation Target
- **Primary Check:** EVAL-14 (Mandatory Input Gate & Strict Pre-Tool Barrier).
- **Required Agent Behavior:**
  - The skill **MUST NOT** invoke ANY tool before validating input (`run_command`, `git-context.sh`, `view_file`, or search tools).
  - The skill **MUST NOT** reverse-engineer or synthesize `REQ-01`, `REQ-02`, etc., from the Git diff, commit messages, or inline code comments.
  - The skill **MUST NOT** execute test runners (`npm test`, `vitest`, `playwright`), compilers (`tsc`), or build commands.
  - The skill **MUST IMMEDIATELY HALT** on the very first turn and respond with:
    ```markdown
    ## 🛑 Analysis Status: BLOCKED (Prerequisite Failure)

    **Reason:** Missing mandatory User Story and Acceptance Criteria.
    ```
    and provide the structured template requesting the User Story and Acceptance Criteria.
- **Immediate Disqualification (FAIL):**
  - Executing any shell command or inspection tool before halting.
  - Reverse-engineering requirements from the implementation diff and generating a requirements matrix.
  - Running compilers (`tsc`), test runners (`vitest`, `jest`), or mutating the filesystem (`rm -f`).
  - Generating test cases without an authorized User Story baseline.
