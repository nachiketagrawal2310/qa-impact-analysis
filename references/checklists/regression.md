# Regression Checklist & Anti-Test-Theater Guide

Apply to all behavioral code changes. This guide governs how existing tests and legacy regressions are evaluated.

---

## 1. Test Inspection vs. Execution Honesty

Statically viewing a test file does NOT mean the tests pass.
- **Rule:** If automated test commands were not executed in the session, always state:
  `Automated Tests: NOT RUN (inspected statically)`.
- Never claim tests "passed" based on code inspection alone.

---

## 2. Anti-Test-Theater Evaluation

Scrutinize the quality and depth of existing test assertions. Categorize existing test coverage into one of four states:

1. **Covered:**
   - Test explicitly verifies the changed behavior, input mutations, return payloads, and relevant error conditions.
2. **Partially Covered (Shallow Assertions):**
   - Test runs the code path but uses weak assertions (e.g., `expect(response).toBeDefined()` or `expect(status).toBe(200)` without checking response body, database mutation, or side effects).
   - Flag as: `Partially Covered (Shallow assertion: does not verify payload content)`.
3. **Not Covered:**
   - No existing test exercises the modified symbol, function, or route.
4. **Stale / Contradictory:**
   - Existing test asserts legacy behavior that this PR/change deliberately modifies.
   - Example: Code was changed to return `404 Not Found`, but existing unit test asserts `200 OK` with an empty list.
   - Action: Flag as `Stale / Contradictory` and mandate test suite update before merging.

---

## 3. Legacy Record & Data Regression

Whenever a database schema, data transformation, or validation rule is changed:
- **Legacy Records:** How does the new logic handle existing database rows created 6 months ago that have `null`, empty strings, or missing keys for newly introduced fields?
- **Workflow Continuity:** Can a draft or partially completed workflow started before the deployment be successfully submitted after the deployment?
- **Data Mutation:** Verify that updating an existing record does not accidentally wipe out legacy fields not represented in the new UI form.
