# Architecture Analysis Guide

Treat the repository as a graph of:

`entry point → business logic → data/dependency → side effect → consumer`

For each changed behavior, ask:

- Who calls this?
- What does this call?
- What data does it read/write?
- Which contracts cross the boundary?
- Which side effects occur?
- What happens if a dependency is missing, slow, duplicated, retried, or partially successful?
- Which clients consume the result?
- Does tenant/security context change?

Repository evidence outranks this guide.
