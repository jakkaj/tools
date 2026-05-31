# `skills/compound/` — frozen schema contract (not a skill category)

This directory is **not** a set of installable skills. It holds only [`schemas/`](./schemas/) — the universal `.retro.md` contract shared across systems.

## Why it lives here

The compound + harness skills that used to live under `skills/compound/` were consolidated into three loop-stage skills under [`skills/harness/`](../harness/) by [plan-024](../../docs/plans/024-harness-nucleus/):

| Old (under `skills/compound/`) | New |
|---|---|
| `compound-1-track` | [`harness-2-observe`](../harness/harness-2-observe/) |
| `compound-2-bubble` + `compound-3-harvest` | [`harness-3-retro`](../harness/harness-3-retro/) (`--drain` / `--harvest`) |
| `compound-0-setup` | dropped to the separate engineering-harness setup effort (`AI-Substrate/harness-engineering` owns provisioning) |

The **schemas stay here on purpose.** `skills/compound/schemas/` is a frozen cross-system path commitment with minih (the v1 home for the universal retro contract) until the schemas are extracted to a shared `@ai-substrate/retro-schema` npm package. Renaming or moving the path is an explicit Non-Goal — see [`docs/plans/024-harness-nucleus/harness-nucleus-spec.md`](../../docs/plans/024-harness-nucleus/harness-nucleus-spec.md) § Non-Goals (IC-01 / IC-08).

So `npx skills add jakkaj/tools/skills/compound` installs nothing (no `SKILL.md` folders here). To install the loop skills, use `jakkaj/tools/skills/harness` — see [`INSTALL.md`](../../INSTALL.md).

Runtime vs setup boundary:

- **tools** owns the runtime loop skills: `harness-1-boot`, `harness-2-observe`, and `harness-3-retro`.
- **harness-engineering** owns setup/provisioning: creating project governance docs, ledger folders, command maps, starter harness CLI surfaces, and setup templates.
- Runtime skills consume those artifacts when present and degrade gracefully when absent; they do not scaffold them.
- Old deployed runtime slugs can remain after renames because `npx skills add` does not prune. Use `just skills-orphans` and `just doctor-skills` from the repo root to report drift; review before deleting anything.

## What's in `schemas/`

See [`schemas/README.md`](./schemas/README.md) for the full contract: `retro.schema.json`, the `system.*` namespace extensions, fixtures, wire format, and versioning.
