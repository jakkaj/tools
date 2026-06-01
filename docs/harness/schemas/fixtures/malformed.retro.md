---
schema_version: "1.0"
retro_id: "not-a-valid-retro-id"
agent: "Has Spaces And Caps"
started_at: "not-an-iso-timestamp"

entries:
  - id: bad-id-no-prefix
    kind: not-a-real-kind
    description: "too short"

  - id: DL-001
    # missing required: kind
    description: "This entry is missing the required kind field."

  - id: DL-002
    kind: difficulty
    # missing required: description

  - kind: difficulty
    description: "This entry is missing the required id field."
---

## Negative test fixture

This file deliberately violates the schema in multiple ways:

1. `retro_id` doesn't match the required pattern (`<ISO>-<agent>-<hash>`)
2. `agent` is not lowercase kebab-case
3. `started_at` is not a valid ISO datetime
4. Entry 1: `id` doesn't match `^[A-Z]+-\d{3,}$`; `kind` not in the enum; `description` is below `minLength: 10`
5. Entries 2-3: missing required fields
6. Entry 4: missing required `id`

A conforming validator should reject this entire retro (per workshop 005 EC2 — strict skip).

When `compound-3-harvest` encounters this file, it should:
- Log a warning naming this file path + listing the validation errors
- Skip the entire retro (do NOT half-parse)
- Continue to the next file

This fixture is used to verify the harvest's error-tolerance path.
