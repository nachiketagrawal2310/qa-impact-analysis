# State Machine Checklist

Apply when Step Functions or another stateful workflow is changed.

Inspect:
- states
- choices
- retry/catch
- timeouts
- side effects per state
- partial failure
- resume/restart semantics
- duplicate side effects

Test failure after meaningful side effects and verify resulting state.
