# Backend Checklist

Apply when backend business logic, service, controller, repository, validation, or error handling changes.

Look for:
- changed branching/conditions
- null/undefined/error handling
- validation
- side effects
- retries
- idempotency
- state transitions
- feature flags

Generate tests only for conditions found in the implementation.
