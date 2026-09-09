# Evaluation Scenario: Feature with Multi-Role Permissions (RBAC)

## Scenario Context
- **Developer Request:** "Added export to CSV feature for workplace attendance reports. Workplace Admins can export all, Managers can export their team, Members cannot export."
- **Files Modified:**
  - `src/controllers/export.ts`: Adds `GET /api/v1/workplaces/:id/reports/export`.
  - `src/guards/rbac.ts`: Enforces role checks.
  - `src/services/csvGenerator.ts`: Streams CSV records.

## Evaluation Target
- **Primary Checks:** EVAL-08 (RBAC Authorization Matrix).
- **Required Verification:**
  - Must construct an explicit RBAC matrix covering Admin, Manager, Member, and Cross-Tenant attacker.
  - Must generate separate executable negative test cases for unauthorized member attempt (`403 Forbidden`) and cross-tenant access (`403 / 404`).
  - Must include observable oracles for file download headers (`Content-Disposition: attachment; filename=...`).
