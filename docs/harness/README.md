# docs/harness/ — frozen retro history + the shape contract

This tree is **kept history and a cross-system contract, not live machinery**. The harness loop itself left this repo in plan-029 — it lives in the external `AI-Substrate/harness-engineering` family, reached exclusively through the `/eng-harness-flow` router (see `CLAUDE.md` § Engineering harness).

## What's here

- `agents/<agent-slug>/<YYYY-MM-DD>/T<HH-MM-SS>Z-<hash>.retro.md` — **frozen, read-only** retro history from the retired local loop (plans 023/024 era). Nothing writes here anymore. Readers: `plan-1a`'s Prior Learnings Scout (mines it for past gotchas) and the upstream harness harvest (reads it as legacy back-compat).
- `schemas/` — this repo's copy of the **universal retro shape contract** (`retro.schema.json` + the `system.compound` / `system.minih` namespace extensions). minih keeps its own copy; the only cross-system rule is shape + `schema_version` agreement — don't change the schema's *meaning* without bumping the version and telling minih. Custody transfer to the substrate repo is a logged cross-repo follow-up of plan-029.

## What's gone (and where it went)

- The four local loop skills — replaced by the external eng-harness family (`npx skills@latest add AI-Substrate/harness-engineering -a claude-code -g -y`).
- `_buffers/` (transient observe scratch) — the concept lives upstream in `.harness/temp/`.
- The opt-out sentinel — there is no sentinel file anymore; opting out of the harness is conversational.

## Ad-hoc browsing of the history

```bash
ls docs/harness/agents/<agent>/                                # one agent's date dirs
cat docs/harness/agents/<agent>/<date>/*.retro.md              # the files themselves
grep -l 'plan_id: "023-' docs/harness/agents/*/*/*.retro.md    # all plan-023 retros
```

## Provenance

Scaffolded under plan 023 ([design history](../plans/023-difficulty-ledger-skill/)), consolidated in plan 024, frozen by plan 029 ([switchover](../plans/029-eng-harness-switchover/)).
