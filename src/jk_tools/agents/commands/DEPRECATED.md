# DEPRECATED

This directory (`agents/commands/`) contains the **v1 command set** and is **no longer maintained**.

## What replaced it

The active source-of-truth is now `/skills/<category>/<slug>/SKILL.md` at the repo root, following the `mattpocock/skills` layout convention.

- v1 → v2 migrations live under `/skills/SDD/<slug>-v2/SKILL.md`
- See [`/INSTALL.md`](../../INSTALL.md) for install patterns
- See [`/AGENTS.md`](../../AGENTS.md) for the new skill catalog

## What happens to these files

These v1 files are retained for reference only. They are not synced into `src/jk_tools/agents/commands/` automatically (the `sync-to-dist.sh` block still copies them today, but no installer fans them out). **Planned for deletion in a future cleanup pass.** Do not add new commands here.
