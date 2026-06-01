---
schema_version: "1.0"
retro_id: "2026-05-17T14:22:15Z-claude-code-c1d5"
agent: claude-code
plan_id: "023-difficulty-ledger-skill"
started_at: "2026-05-17T14:00:00Z"
ended_at: "2026-05-17T14:22:15Z"
summary: "Implementing compound family; covering all seven entry kinds in one session for fixture purposes."

entries:
  - id: DL-001
    kind: difficulty
    target: tooling
    severity: degrading
    description: "grep on src/ took 47s — should use ripgrep."
    workaround: "Used `grep -r -I` to skip binaries; still slow."
    suggested_encoding: "justfile recipe wrapping ripgrep"

  - id: MW-001
    kind: magic-wand
    target: project
    description: "A `just rg <pattern>` recipe pinned to ripgrep would shave off 40+ seconds per search."

  - id: GFT-001
    kind: gift
    description: "Workshop 005's JSON Schema dropped in verbatim and validated on the first try."

  - id: INS-001
    kind: insight
    description: "The KISS revision (no on-disk index files) saved roughly 6 maintenance tasks from the plan."

  - id: COORD-001
    kind: coordination
    description: "Minih currently writes to docs/retros/; the back-compat reader handles it but the RFC needs to land before v2 unification."

  - id: SUGG-001
    kind: improvement-suggestion
    description: "Add an `--apply` flag to compound-3-harvest --prune so dry-run-by-default is enforced at the flag level."

  - id: CONF-001
    kind: confusion
    description: "Wasn't sure whether `system.compound.status` updates on harvest were supposed to mutate the original file or write a new one; the spec says in-place."
---

## Reflection

This fixture deliberately covers all seven kinds to exercise the validator + the harvest clustering logic.
