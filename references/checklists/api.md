# API Checklist

Apply when routes, controllers, request/response schemas, status codes, headers, auth requirements, or public contracts change.

Look for:
- method/path
- request fields
- response fields
- status codes
- error payloads
- authentication/authorization
- consumers
- backward compatibility

Conditional tests:
- changed request schema → missing/invalid input
- changed response schema → consumer compatibility
- changed status/error → client behavior
- changed auth → 401/403/tenant isolation
