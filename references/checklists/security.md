# Security & Tenant Isolation Checklist

Apply whenever authentication, authorization, role permissions, workplace/tenant boundaries, resource lookups, or user IDs are touched.

---

## 1. Key Areas of Inspection

Inspect actual enforcement mechanisms in code:
- Authentication guards and JWT token validation.
- Role-based permissions (Admin, Creator, Submitter, Guest).
- Resource ownership verification (does user $X$ own resource $Y$?).
- Multi-tenant / workplace scoping (e.g., `WHERE workplace_id = :id`).
- ID manipulation / Insecure Direct Object References (IDOR).
- Disabled, deactivated, or deleted user access.

---

## 2. Evidence-Backed RBAC Authorization Matrix

Rather than generic testing notes ("test as admin"), build a concrete authorization matrix from code evidence:

| Persona / Role | Target Resource & Scope | Action / Operation | Expected Behavior | Enforcement Point (Evidence) |
|---|---|---|---|---|
| Workplace Admin | Workplace A Resource | Create / Update / Delete | Allow (`200 OK` / `201 Created`) | `src/auth/rbac.ts:32` |
| Member / Submitter | Workplace A Resource | Update / Delete | Deny (`403 Forbidden`) | `src/auth/rbac.ts:50` |
| Member (Workplace B) | Workplace A Resource | Read / Update | Deny (`403 / 404 Cross-Tenant`) | `src/guards/tenant.ts:18` |
| Unauthenticated / Expired | Any Protected Resource | Any Action | Deny (`401 Unauthorized`) | `src/auth/jwt.ts:14` |

---

## 3. Mandatory Security Test Scenarios

1. **Cross-Tenant Access Attempt:**
   - Attempt to access or mutate Workplace A resource using an authenticated token from Workplace B. Expected: Rejected with `403 Forbidden` or `404 Not Found` (never leaks Workplace A existence or data).
2. **Privilege Escalation:**
   - Standard user crafts a request payload containing admin-only parameters (e.g., `role: "ADMIN"` or `permissions: ["all"]`). Expected: Rejected or parameters stripped.
3. **IDOR via Direct ID Manipulation:**
   - Substitute a UUID / resource ID in API URL or body with another user's resource ID.
4. **Token Expiry / Invalidation:**
   - Verify action immediately fails once session is revoked or token expires.
