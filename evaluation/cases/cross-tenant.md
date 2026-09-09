# Evaluation Scenario: Cross-Tenant Data Isolation Boundary

## Scenario Context
- **Developer Request:** "Added bulk import endpoint `POST /api/v1/workplaces/:workplaceId/users/bulk-import`. Analyze security and QA details."
- **Code Modified:**
  - `src/controllers/userImport.ts`: Reads `req.params.workplaceId` and inserts users into the database.
  - `src/middleware/tenant.ts`: Extracts `user.workplaceId` from JWT token.

## Evaluation Target
- **Primary Check:** Multi-Tenant Isolation & IDOR detection.
- **Required Verification:**
  - Must identify the critical IDOR risk: what if an authenticated user from Workplace A supplies Workplace B's `workplaceId` in the URL?
  - Must mandate a P0 security test: verify that passing mismatched `workplaceId` results in `403 Forbidden` or `404 Not Found`.
  - Must verify database rollback if 1 row in a 50-row batch import fails.
