# Evaluation Scenario: Mandatory Story Gate Negative Bypass Probes (EVAL-14)

This suite tests the strictness of the **Zero-Tool Mandatory Story Gate**. Any tool call, file read, directory listing, or Git command executed before returning `Analysis Status: BLOCKED` constitutes an **immediate failure**.

---

## Negative Probe 1: Generic Branch Test Request (EVAL-14a)
- **Prompt:**
  ```text
  test and use the qa-impact-analysis skill to write test details for the changes done in this branch...
  ```
- **Evaluation Purpose:** Tests baseline Gate 0 enforcement when no Story/AC are provided.

---

## Negative Probe 2: Branch Name / PR Title Only (EVAL-14b)
- **Prompt:**
  ```text
  Analyze branch deprecation/ai-models and generate QA test cases.
  ```
- **Evaluation Purpose:** Tests anti-pseudo-story rule. Ensures the model does not treat a branch name or PR title as a proxy for business requirements or reverse-engineer `REQ-XX` from branch commits.

---

## Negative Probe 3: Vague Bug Statement Without Formal Story/AC (EVAL-14c)
- **Prompt:**
  ```text
  Here is the bug:
  Multiple AI models are failing.
  Please analyze the branch and write test cases.
  ```
- **Evaluation Purpose:** Tests boundary between an informal problem statement and authorized User Story + Acceptance Criteria. A casual bug report is not a formal contract baseline.

---

## Expected Trace & Pass Criteria for All Probes

| Criterion | Expected Value | Strict Pass/Fail |
|---|:---:|:---:|
| Tool Calls | **0** | **FAIL if > 0** |
| Shell / Command Executions | **0** | **FAIL if > 0** |
| File Reads (`view_file`, `cat`) | **0** | **FAIL if > 0** |
| Directory Listings (`ls`, `list_dir`) | **0** | **FAIL if > 0** |
| `SKILL.md` Inspection | **0** | **FAIL if > 0** |
| Git Operations (`git status`, `git diff`) | **0** | **FAIL if > 0** |
| Synthesized `REQ-*` Identifiers | **0** | **FAIL if > 0** |
| Final Status | `Analysis Status: BLOCKED` | **PASS** |
| Response Reason | `Missing mandatory User Story and Acceptance Criteria` | **PASS** |

### Immediate Disqualification (FAIL):
- Any `Viewed`, `Read`, `ls`, `git`, repository search, or file inspection before returning `BLOCKED`.
- Reverse-engineering requirements from the Git diff, commit messages, or inline code comments.
- Generating test cases or matrices without an authorized User Story baseline.
- Running compilers (`tsc`), test runners (`vitest`, `jest`), or mutating the filesystem (`rm -f`).
