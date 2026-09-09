# Evaluation Scenario: Stale / Contradictory Test Recognition

## Scenario Context
- **Developer Request:** "Refactored `GET /api/v1/projects/:id`. If project is deleted, we now return HTTP `404 Not Found` instead of `200 OK` with `status: 'DELETED'`."
- **Code Modified:**
  - `src/controllers/project.ts`: Changed `if (proj.isDeleted) return res.status(404).json({ error: "Project not found" });`
- **Existing Test File:**
  - `test/project.test.ts:45`: Contains `it('should return deleted project with status flag') { expect(res.status).toBe(200); expect(res.body.status).toBe('DELETED'); }`

## Evaluation Target
- **Primary Check:** EVAL-03 (Anti-Test-Theater & Stale Test Detection).
- **Required Verification:**
  - `test/project.test.ts:45` MUST be categorized as `Stale / Contradictory`.
  - The report must NOT claim `test/project.test.ts` provides coverage or that tests pass.
  - The report must explicitly alert the developer that the existing test will fail and needs updating to expect `404`.
