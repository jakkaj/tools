# docs/harness/ — the Compounding Value ledger

This tree is the source of truth for the compounding-value system. Every retro
ever produced by any agent in this repo lives under `agents/<agent>/<date>/`.

## Layout

- `agents/<agent-slug>/<YYYY-MM-DD>/T<HH-MM-SS>Z-<hash>.retro.md` — one file per run
- `_buffers/<agent>.session-buffer.md` — transient (gitignored); drained by `compound-2-bubble`
- `.disabled` — optional opt-out sentinel (presence silences all compound activity)

## Skills that read or write here

| Skill | Reads | Writes |
|-------|-------|--------|
| `compound-0-setup` | — | scaffolds this tree (idempotent) |
| `compound-1-track` | — | appends entries to `_buffers/<agent>.session-buffer.md` |
| `compound-2-bubble` | buffer | writes one `.retro.md` per save action |
| `compound-3-harvest` | all `.retro.md` files + legacy `docs/retros/*.md` | mutates `system.compound.status` in-place |

## No on-disk index files

`compound-3-harvest` computes cross-cutting views (clusters, plan filters, stale
flags) at read time and prints them to the terminal. There are no `_LEDGER.md`,
`_AGENT.md`, `_DAY.md`, or `_PLAN.md` index files on disk — the tree IS the
source of truth.

For ad-hoc browsing without the skill:

```bash
ls docs/harness/agents/*/$(date -u +%Y-%m-%d)/                # today's retros
ls docs/harness/agents/<agent>/                                # one agent's date dirs
cat docs/harness/agents/<agent>/<date>/*.retro.md              # the files themselves
grep -l 'plan_id: "023-' docs/harness/agents/*/*/*.retro.md    # all plan-023 retros
```

## Opt-out

`touch docs/harness/.disabled` silences every compound skill (compound-1-track,
compound-2-bubble, compound-3-harvest). Remove the file to re-enable.

## Schema

The frontmatter of every `.retro.md` file validates against
[`docs/harness/schemas/retro.schema.json`](../../docs/harness/schemas/retro.schema.json).

Plus optional namespace extensions:
- [`system.compound.schema.json`](../../docs/harness/schemas/system.compound.schema.json) — lifecycle metadata
- [`system.minih.schema.json`](../../docs/harness/schemas/system.minih.schema.json) — minih run metadata

## Provenance

This tree was scaffolded by `compound-0-setup`. See plan 023
([`docs/plans/023-difficulty-ledger-skill/`](../plans/023-difficulty-ledger-skill/)) for
the design history (spec + 6 workshops + implementation plan).
