# Database Checklist

Apply when persistence or data-access behavior changes.

Inspect actual operations before generating tests:
- Get/Put/Update/Delete
- Query/Scan
- batch/transaction
- conditional writes
- keys/indexes
- pagination
- migrations

Conditional scenarios:
- missing item
- existing item
- invalid key
- condition failure
- legacy record
- concurrent write
- pagination boundary
