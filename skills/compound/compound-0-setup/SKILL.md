---
name: compound-0-setup
description: |
  Run once per repo to scaffold `docs/compound/` (the compounding-value ledger) and split-migrate any legacy `docs/retros/*.md` files into per-run universal `.retro.md` files. Idempotent and reversible — safe to re-run; original files renamed to `*.legacy.md` and a `.split-to-compound` breadcrumb is written. Hands off to `engineering-harness-v2` for harness audit work.
---

# compound-0-setup

The first compound skill. Bootstraps the ledger surface so the rest of the compound family (`compound-1-track`, `compound-2-bubble`, `compound-3-harvest`) has somewhere to write and read.

## When to fire

- First time `compound` is installed in a repo and nothing under `docs/compound/` exists
- Any time the user wants a re-check (the skill is idempotent)
- Automatically by tools that detect a missing/partial scaffold (e.g. `compound-1-track` running with no `_buffers/` dir)

## Sentinel check (first thing)

If `docs/compound/.disabled` exists → silently no-op and exit. The opt-out is absolute.

## Step 1 — Scaffold the canonical tree

The target tree (from workshop 006 § Canonical Tree):

```
docs/compound/
├── README.md
├── .disabled                            (optional; not created by setup)
├── _buffers/
│   ├── README.md
│   └── .gitignore                       *.session-buffer.md
└── agents/
    └── .gitkeep                         preserves empty dir in git
```

For each file: if it exists, leave it (idempotent). If it doesn't, create it with the seed content below.

### `docs/compound/README.md` (seed)

```markdown
# docs/compound/ — the Compounding Value ledger

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

## Opt-out

`touch docs/compound/.disabled` silences every compound skill (compound-1-track,
compound-2-bubble, compound-3-harvest). Remove the file to re-enable.
```

### `docs/compound/_buffers/README.md` (seed)

```markdown
# _buffers/

Transient per-agent session buffers. `compound-1-track` appends entries here
during a session; `compound-2-bubble` drains them at session end.

One file per active CLI agent: `<agent>.session-buffer.md`.

These files are **gitignored** (see `.gitignore` in this directory) — they're
transient and would create noisy commits if committed. Drained buffers are
reset to empty (not deleted, so the file path is stable across sessions).
```

### `docs/compound/_buffers/.gitignore`

```
*.session-buffer.md
```

### `docs/compound/agents/.gitkeep`

Empty file. Preserves the directory in git when no agents have produced retros yet.

## Step 2 — Split-migrate legacy `docs/retros/*.md` (one-time, reversible)

If `docs/retros/` exists and has `*.md` files and `docs/retros/.split-to-compound` is absent, run the split-migration.

The migration (per workshop 006 § Migration Recipe):

1. For each `docs/retros/<slug>.md`:
   1. Parse the file as a sequence of minih blocks (split on `/^## \d{4}-\d{2}-\d{2}T/m`)
   2. For each block:
      - Extract the minih `retrospective` shape from the block body
      - Run the `minihToUniversal()` mapping (workshop 005 § D9) to produce a universal retro
      - Compute the destination path via `resolvePath(retro)`:
        - `agents/<slugified-agent>/<YYYY-MM-DD>/T<HH-MM-SS>Z-<hash>.retro.md`
      - Write the universal `.retro.md` file (frontmatter + entries)
   3. Rename the original file: `docs/retros/<slug>.md` → `docs/retros/<slug>.legacy.md` (reversible)
3. Write breadcrumb: `docs/retros/.split-to-compound` with timestamp + summary

On re-invocation: the breadcrumb signals "already migrated". If new minih files have appeared in `docs/retros/*.md` since (no breadcrumb means not-yet-split for that file), split only the new ones.

If `docs/retros/` doesn't exist or is empty, skip Step 2 silently.

## Step 3 — Hand-off to `engineering-harness-v2`

After scaffolding (and any migration), print a one-line pointer:

> ℹ️ Compound ledger ready. Consider running `engineering-harness-v2` to audit the engineering harness (justfile/Makefile/dev script) — the substrate the agent harness sits on. Its `## Known Difficulties` template will auto-seed from compound entries once any have landed.

No auto-fire. Just a pointer.

## Step 4 — Auto-log the self-scaffold as a `gift` entry

Per spec Q6.2 — the system reflects on its own actions. Append one entry to the calling agent's session buffer (`docs/compound/_buffers/<agent>.session-buffer.md`):

```yaml
- id: GFT-001
  kind: gift
  target: compound
  description: "compound-0-setup ran cleanly — N files scaffolded, M legacy retros split-migrated."
  system:
    compound:
      status: open
      source: agent-self
```

The entry will be picked up by the next `compound-2-bubble` invocation like any other entry.

## Re-entrant behavior (idempotent re-check)

When invoked on a repo that already has `docs/compound/`:

- Every file in Step 1: leave existing files alone; create only missing ones
- Step 2: skip if breadcrumb present; split-migrate any new `docs/retros/*.md` files not yet seen
- Step 3: print the hand-off pointer (no harm in repeating)
- Step 4: log a one-line "re-check: no changes" gift entry (or silent if nothing changed)

The skill should never destroy user-modified content. Any file already on disk wins.

## Reversibility

If the user wants to undo:

```bash
# Restore legacy retros files
cd docs/retros/ && for f in *.legacy.md; do mv "$f" "${f%.legacy.md}.md"; done
rm docs/retros/.split-to-compound

# (optional) Remove the compound tree
rm -rf docs/compound/
```

The migration writes new files in `docs/compound/agents/`; reversal also needs `rm -rf docs/compound/agents/` if you want a clean slate. Compound never mutates content inside `docs/retros/*.md` — only renames the wrapper.

## Edge cases

- **Sentinel toggling mid-session**: if `.disabled` appears after a partial scaffold, subsequent steps no-op. Already-written files stay.
- **Permissions**: if any `mkdir`/`write` fails, print the error and exit non-zero. Partial scaffold is acceptable on retry.
- **Concurrent invocation**: two agents running compound-0-setup simultaneously is rare but safe — file writes are last-write-wins on identical content.

## References

- Workshop 005 — Universal retro contract (§ D9 round-trip mapping)
- Workshop 006 — Compound folder layout (§ Canonical Tree, § Migration Recipe, § D7 minih back-compat)
- Spec § Acceptance Criteria #1, #1a, #2, #3, #23
- Spec § Q6.2 (auto-log self-scaffold as gift entry)
