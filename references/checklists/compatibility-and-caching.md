# Compatibility, Caching & Deployment Checklist

Apply this checklist conditionally whenever:
- An API contract (request, response, header, status code) changes.
- A database schema, model, or migration changes.
- Client applications (Web, Android, iOS) cache server responses.
- Changes are deployed into a rolling zero-downtime environment.
- Changes are guarded by or introduce a feature flag.

---

## 1. Client-Side Caching Invalidation

Inspect whether clients store responses locally:
- **Web:** LocalStorage, SessionStorage, IndexedDB, Service Worker cache.
- **Mobile (Android / iOS):** SQLite / Room, CoreData, Realm, SharedPreferences, MMKV, offline sync queues.

### Critical Failure Modes to Test:
1. **Old Cache + New Code:** User upgrades web page or app; existing cached data structure missing new required fields. Does the client crash or safely handle missing fields?
2. **New Cache + Old Code:** User downgrades or hits cached data created by new code.
3. **Cache Eviction / Invalidation:** Does the code explicitly invalidate or migrate old cache keys?

---

## 2. Zero-Downtime Rolling Deployment ($N$ and $N+1$)

During canary and rolling container/pod deployments, old and new instances run simultaneously.

### Critical Interactions to Verify:
1. **Old Client → New Backend:**
   - Client sends requests using the old schema/payload.
   - The new backend MUST continue accepting old payloads without throwing `400 / 422` or `500`.
   - New database columns MUST be nullable or have safe defaults so old backend instances do not fail insert operations.
2. **New Client → Old Backend:**
   - If client is deployed first (or cached in browser), client sends new fields to old backend.
   - Backend ignores unknown fields without error.
3. **In-Flight User Sessions:**
   - Active user filling out a multi-step form during deployment does not experience session drop or submission failure.

---

## 3. Feature Flag Rollout Lifecycle

If the change is guarded by a feature flag:

### Mandatory Test Matrix:
- **Flag = OFF (Baseline Regression):**
  - Verify that the application functions exactly as before. Zero regression on existing workflows.
- **Flag = ON (New Functionality):**
  - Verify new behavior, new UI elements, and new data persistence.
- **Transition: OFF → ON:**
  - Verify existing records/users seamlessly adapt when the flag is enabled.
- **Transition: ON → OFF (Kill Switch / Rollback):**
  - If a production issue forces the flag OFF, does the system safely degrade without leaving corrupted state or orphan records?
- **Mid-Session Dynamic Toggle:**
  - If flags update dynamically via WebSocket or polling, verify the UI updates gracefully without infinite loops or page crashes.
