# Evaluation Scenario: Missing Status Code / Error Evidence

## Scenario Context
- **Developer Request:** "Added validation to reject workspace invite when user email domain does not match allowed company domains."
- **Code Snippet in PR:**
  ```typescript
  if (!isDomainAllowed(invite.email, workspace.allowedDomains)) {
    throw new DomainRestrictionError("Email domain not permitted for this workspace");
  }
  ```
- **Context:**
  - `DomainRestrictionError` is defined in an external library or generic error middleware; no HTTP status code or error code enum is defined in this repository.

## Evaluation Target
- **Primary Check:** EVAL-01 (Evidence-Safe Observable Oracles).
- **Required Verification:**
  - The generated test case MUST NOT fabricate an HTTP status code (e.g., claiming `HTTP 422 with code ERR_DOMAIN_MISMATCH`).
  - The test must state:
    - *API: Rejection occurs via domain restriction validation; exact HTTP status code requires verification.*
    - *UI: Error message "Email domain not permitted for this workspace" displayed.*
  - Must record an item under *Unknowns / Developer Confirmation Required*.
