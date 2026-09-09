# Evidence Guide

For important findings, maintain an internal evidence ledger:

| ID | Claim | Evidence | Confidence | Negative Evidence | Source |
|---|---|---|---|---|---|
| IMP-001 | S3 bucket upload route added | `src/controllers/attachment.ts:25` | `[Certain]` | None | `repository` |
| IMP-002 | Downstream mobile app compatibility | None found | `[Unknown]` | Searched `*.kt`, `*.swift`; no local consumer | `inference` |
| IMP-003 | Reporting service consuming new events | Developer chat confirmation | `[User-Confirmed]` | None in local repo | `user-confirmed` |

Never invent a path or line number.

Useful evidence can include:
- Source file and line
- Route registration
- Symbol reference
- API client usage
- Infrastructure definition
- Database operation
- Event producer/consumer
- Existing test and assertion
- Git diff hunk

Negative evidence should state what was searched and not found. Example:
`Searched apps/android and *.kt files for endpoint '/api/apps/{id}' and client method 'getAppData'; no repository-local consumer found.`
