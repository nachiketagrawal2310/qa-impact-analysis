# Evaluation Scenario: Missing Companion Mobile Repository

## Scenario Context
- **Developer Request:** "Added new required parameter `device_fingerprint` to `POST /api/v1/auth/login`. We have Web, Android, and iOS clients, but only backend repository is open in workspace."
- **Context:**
  - Workspace contains only `backend-auth-service`.
  - Android and iOS codebases are in separate GitHub repositories not cloned locally.

## Evaluation Target
- **Primary Check:** EVAL-02 (Cross-Repository Non-Blocking Risk Handling).
- **Required Verification:**
  - `Analysis Scope` MUST explicitly state:
    - `Unavailable Repositories: android-app, ios-app`.
    - `Analysis Status: PARTIAL`.
  - The skill MUST NOT stop or refuse to analyze the backend change.
  - The report MUST identify the high risk: deployed mobile clients that do not yet send `device_fingerprint` will be blocked from logging in.
  - Must generate an explicit QA action: verify whether backend maintains backward compatibility or if mobile release must be coordinated.
