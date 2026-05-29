# Getting Started — moved

This guide has been superseded. The current visual getting-started — covering the **v3 `/plan-*` pipeline** *and* the **harness loop** (Boot → Observe → Retro), with mermaid diagrams that distinguish manual calls from auto-fired harness stages — now lives **inside the `sdd-tutorial` skill** so it ships with the skills via `npx skills`:

➡️ **[`skills/SDD/sdd-tutorial/references/getting-started.md`](../../skills/SDD/sdd-tutorial/references/getting-started.md)**

It's bundled there (rather than here) because `npx skills` deploys whole skill folders — a doc at this `docs/` path would never reach anyone who installs the skills. Keeping a single source of truth inside the skill avoids the two-copy drift this repo fights.

For the full command reference, see [README.md](./README.md).

> The previous content of this file predated the v3 merges (`/plan-2` and `/plan-4` are no longer separate steps) and had no harness coverage. It was retired in favour of the bundled guide above.
