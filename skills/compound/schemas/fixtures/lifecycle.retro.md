---
schema_version: "1.0"
retro_id: "2026-05-14T11:22:00Z-claude-code-d2e6"
agent: claude-code
plan_id: "023-difficulty-ledger-skill"
started_at: "2026-05-14T11:00:00Z"
ended_at: "2026-05-14T11:45:00Z"
summary: "Earlier session; one difficulty observed, later encoded as a justfile recipe."

entries:
  - id: DL-103
    kind: difficulty
    target: tooling
    severity: annoying
    description: "grep on src/ took 47s — should use ripgrep."
    workaround: "Used `grep -r -I` to skip binaries; still slow."
    suggested_encoding: "justfile recipe"
    system:
      compound:
        status: encoded
        resolved_by: "scratch/encode-DL-103.diff (applied as commit 8a3f9c1)"
        first_seen_at: "2026-05-14T11:22:00Z"
        last_harvested_at: "2026-05-16T07:42:00Z"
        harvest_count: 2
        source: agent-self

  - id: MW-007
    kind: magic-wand
    target: project
    description: "A pre-commit hook that runs the slug-collision check would catch dupes before push."
    system:
      compound:
        status: suggested
        first_seen_at: "2026-05-14T11:30:00Z"
        last_harvested_at: "2026-05-16T07:42:00Z"
        harvest_count: 2
        source: agent-self
---

## Reflection

This fixture exercises full lifecycle metadata: one entry advanced from `open` → `encoded` with a `resolved_by` pointer; one entry stuck at `suggested`. Useful for testing the harvest curation + status mutation flows.
