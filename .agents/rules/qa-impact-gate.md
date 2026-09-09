# QA Impact Analysis: Zero-Tool Mandatory Story Gate

When the user asks to perform QA impact analysis, generate test details for code changes/branches/PRs, or invokes the `qa-impact-analysis` skill:

## 🛑 P0 MANDATORY PRE-TOOL GATE (ZERO-TOOL BARRIER)

Before using ANY tool, reading ANY file (including `SKILL.md`), inspecting Git state (`git status`, `git diff`, `git-context.sh`), listing directories (`ls`), or executing ANY command:

1. **Inspect ONLY the user's current prompt/content for:**
   - User Story / Business Requirement
   - Acceptance Criteria

2. **If either is missing, vague, or not explicitly provided (e.g., only "test changes in this branch", a branch name, commit message, or PR title):**
   - **STOP IMMEDIATELY.**
   - **DO NOT INVOKE ANY TOOL.** (Do NOT call `view_file`, `run_command`, `read_browser_page`, etc.)
   - **Do NOT inspect `SKILL.md`.**
   - **Do NOT inspect the repository or Git state.**
   - **Do NOT infer requirements from implementation evidence or generate `REQ-*` identifiers.**
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

3. **Only if BOTH User Story and Acceptance Criteria are explicitly present in the user prompt:**
   - Proceed to read `SKILL.md` and conduct read-only repository analysis.
