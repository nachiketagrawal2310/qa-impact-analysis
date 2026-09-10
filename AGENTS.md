# Workspace Agent Instructions: QA Impact Analysis Gate

When the user asks to perform QA impact analysis, generate test details for code changes/branches/PRs, or invokes the `qa-impact-analysis` skill:

## 🛑 P0 MANDATORY PRE-TOOL GATE (ZERO-TOOL BARRIER)

Before using ANY tool, reading ANY file (including `SKILL.md`), inspecting Git state (`git status`, `git diff`, `git-context.sh`), listing directories (`ls`), or executing ANY command:

1. **Inspect ONLY the user's current prompt/content for an Actionable Behavioral Requirement:**
   - A business requirement / user story,
   - A concrete bug description (with expected vs. actual behavior or specific failure scenario), OR
   - A specific functional change request.

2. **If the prompt lacks an actionable behavioral requirement (e.g., only "test changes in this branch", a branch name, commit message, PR title, or ungrounded "test this code"):**
   - **STOP IMMEDIATELY.**
   - **DO NOT INVOKE ANY TOOL.** (Do NOT call `view_file`, `run_command`, `read_browser_page`, etc.)
   - **Do NOT inspect `SKILL.md`.**
   - **Do NOT inspect the repository or Git state.**
   - **Do NOT infer requirements from implementation evidence or generate `REQ-*` identifiers.**
   - **Respond immediately with:**

```markdown
## 🛑 Analysis Status: BLOCKED (Prerequisite Failure)

**Reason:** Missing actionable behavioral requirement or bug description.

The QA Impact Analysis skill strictly operates from business requirements or bug descriptions to implementation changes. It will NOT infer or reverse-engineer intended business behavior from:
- Git diffs or modified code
- Commit messages or branch names
- PR titles
- Inline code comments or TODOs

To generate accurate, requirement-grounded QA test details, please provide:

### Required Input:
1. **Behavioral Requirement or Bug Description:**
   - A User Story (e.g., *"As a user, I want..."*),
   - An actionable bug report (e.g., *"Login fails with MFA when switching workplaces; expected: ... actual: ..."*), OR
   - A functional change specification with expected behavior.
2. **Key Acceptance Criteria or Expected Outcomes:**
   - Primary expected workflow / expected outcome
   - Negative conditions and validation rules (if known)
   - Tenant/role permissions or boundaries (if applicable)
3. **Out of Scope (Optional):** (e.g., *"Llama models are out of scope"*)
```

3. **If an actionable behavioral requirement or bug description IS present in the user prompt:**
   - Proceed to read `SKILL.md` and conduct read-only repository analysis. Formal Jira-style ceremony (*"As a user... / AC: ..."*) is NOT required if sufficient behavioral intent and expected outcome are conveyed.
