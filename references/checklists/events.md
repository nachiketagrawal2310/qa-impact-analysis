# Events Checklist

Apply when an event/queue/topic/consumer relationship changes.

Inspect:
- event schema
- producer
- consumers
- ordering assumptions
- duplicate delivery
- retries
- DLQ
- poison-message behavior
- version compatibility

Only generate duplicate/out-of-order tests when the event architecture makes them relevant.
