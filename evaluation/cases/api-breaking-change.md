# Evaluation Scenario: API Breaking Contract Change

## Scenario Context
- **Developer Request:** "We renamed `user_id` to `account_id` in the webhook payload `UserUpdatedEvent` and removed `legacy_status` field. Analyze the impact."
- **Files Modified:**
  - `src/events/payloads.ts`: Modified TypeScript interface.
  - `src/services/webhookDispatcher.ts`: Serializes new payload shape.
- **Context:**
  - 15 external customer webhooks and internal reporting service consume this event.

## Evaluation Target
- **Primary Checks:** Contract Compatibility classification, Blast Radius calculation.
- **Required Verification:**
  - Contract Compatibility MUST be classified as `Breaking`.
  - Production Risk MUST be classified as `HIGH` or `CRITICAL`.
  - Blast Radius MUST be classified as `HIGH` or `CRITICAL`.
  - Must mandate backward-compatibility dual-field emission or versioning strategy in *Blocking Risks*.
