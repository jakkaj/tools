# _buffers/

Transient per-agent session buffers. `compound-1-track` appends entries here
during a session; `compound-2-bubble` drains them at session end.

One file per active CLI agent: `<agent>.session-buffer.md`.

These files are **gitignored** (see `.gitignore` in this directory) — they're
transient and would create noisy commits if committed. Drained buffers are
reset to empty (not deleted, so the file path is stable across sessions).

## Agent slugs

The slug matches the calling CLI:

- Claude Code → `claude-code.session-buffer.md`
- Codex → `codex.session-buffer.md`
- GitHub Copilot → `github-copilot.session-buffer.md`
- OpenCode → `opencode.session-buffer.md`
- Pi → `pi.session-buffer.md`
- Minih companion → `<companion-slug>.session-buffer.md` (e.g. `plan-6-companion.session-buffer.md`)

## Format

Append-only YAML entries. Each call to `compound-1-track` appends one block:

```yaml
- id: DL-001
  kind: difficulty
  description: "<entry description>"
  ...
```

See [`skills/compound/schemas/retro.schema.json`](../../../skills/compound/schemas/retro.schema.json)
§ `$defs.Entry` for the full schema.
