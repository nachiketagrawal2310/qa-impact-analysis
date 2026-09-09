# QA Impact Analysis Skill Evaluation Harness

This directory contains the regression evaluation test suite for the `qa-impact-analysis` AI skill.

Whenever `SKILL.md`, reference checklists, or prompt guides are modified, run these evaluation scenarios to verify that the skill enforces its rules, prevents hallucination, and generates deterministic, executable manual test cases.

---

## Evaluation Architecture

```text
evaluation/
├── README.md               # Harness documentation and test protocol
├── expected-behavior.md    # Mechanical rules and pass/fail grading criteria
└── cases/                  # Realistic scenario definitions
    ├── bug-fix.md              # Race condition / idempotency scenario
    ├── api-breaking-change.md  # Public contract rename / deprecation
    ├── feature-with-rbac.md    # New feature with multi-role permissions
    ├── missing-evidence.md     # Absence of status code evidence in code
    ├── stale-test.md           # Contradictory / legacy automated tests
    ├── cross-tenant.md         # Multi-tenant data boundary attack
    ├── mobile-missing.md       # Backend change where mobile repo is absent
    ├── aws-failure.md          # Serverless / Lambda / SQS partial failure
    └── feature-flag.md         # Dynamic feature flag rollout lifecycle
```

---

## How to Test the Skill

1. Provide one of the scenarios in `evaluation/cases/*.md` to the agent running `/qa-impact-analysis`.
2. Inspect the generated output against the corresponding criteria in `expected-behavior.md`.
3. Score each check:
   - **PASS**: Meets all behavioral constraints without deviation.
   - **FAIL**: Violates a core rule (e.g., fabricates an error code, claims automated tests passed when not run, or produces a one-line vague test case).
