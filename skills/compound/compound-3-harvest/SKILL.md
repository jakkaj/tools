---
name: compound-3-harvest
description: |
  Curator-side skill for the compounding-value loop. Scans `docs/compound/agents/**/*.retro.md` (canonical) plus legacy `docs/retros/*.md` (back-compat block parser); validates each retro against the universal schema; dedups by `retro_id`; clusters entries by kind + target; ages stale entries; prints a prioritized terminal view. NO on-disk index files — views are computed at read time and shown to the terminal. Supports runtime filters (`--plan` / `--agent` / `--since` / `--kind`) and reversible pruning (`--prune --older-than 90d --apply`).
---

# compound-3-harvest

The reader/curator side of the compound loop. Auto-fires at long-horizon reflection moments (plan-6-companion FINAL-phase debrief, plan-8 merge end, plan-7 end). Can also be run manually for ad-hoc curation.

## When to fire

- **AUTO-fired** at:
  - `plan-6-companion` FINAL-phase debrief (the dominant flow — replaces /plan-7 as harvest anchor)
  - `plan-8-merge` end (plan-completion reflection)
  - `plan-7-code-review` end (preserved for rare solo /plan-6 flow)
- **SUGGESTED at the start of**:
  - `plan-1a-explore` (if ≥5 unharvested entries — print invocation as one-liner; do NOT auto-fire)
  - `plan-3-architect` (if ≥10 unharvested entries — same)
- **Manually** by the user at any time: `/compound-3-harvest [--plan <slug>] [--agent <slug>] [--since <date>] [--kind <kind>]`

## Sentinel check

If `docs/compound/.disabled` exists → print one line: `"📴 compound is disabled (docs/compound/.disabled present). Remove the sentinel to re-enable."` and exit. Do not scan, do not print views.

## Buffer-non-empty advisory

At start, check `docs/compound/_buffers/<agent>.session-buffer.md` for the calling agent. If non-empty → print one line before scanning:

> ℹ️ Buffer has N unbubbled entries. Consider running `/compound-2-bubble` first so they land in the harvest view.

Then proceed with the scan anyway (the harvest reads `.retro.md` files; buffer entries are unrelated).

## Step 1 — Scan + validate

**Canonical path**: `docs/compound/agents/**/*.retro.md`

For each file:
- Parse the YAML frontmatter (between the first two `---` lines)
- Validate against `skills/compound/schemas/retro.schema.json`
- If invalid → print a warning naming the file path + the validation error; SKIP the entire retro (strict — no half-parse)
- If valid → add to the in-memory view

**Back-compat path**: `docs/retros/*.md` (minih's legacy single-big-file-per-agent format)

For each file (skip `*.legacy.md` — those are post-migration archives):
- Parse the file as a sequence of `## <ISO timestamp> — <slug> / <runId>` blocks (regex on `/^## \d{4}-\d{2}-\d{2}T/m`)
- For each block:
  - Run the minih block → universal retro mapping inline (workshop 005 § D9 `minihToUniversal`)
  - Add to the in-memory view

## Step 2 — Dedup by `retro_id`

If the same `retro_id` appears in both the canonical and back-compat paths (rare; happens during minih dual-write phase), the **canonical (universal) version wins**. Skip the back-compat copy.

## Step 3 — Schema-version skew handling

If a retro has `schema_version` starting with a major number this reader doesn't know (e.g. `2.x` when the reader supports `1.x`):

- Print: `"⚠ Skipped 1 retro with unsupported schema_version: <path>"`
- Skip the retro

Minor-version skew (`1.1` when reader is `1.0`) is silent — forward-compat per workshop 005 § D8.

## Step 4 — Curate

Build the in-memory view:

### Cluster open entries

Group entries by `(kind, target)`. Within each cluster:

- Count entries
- Age-order (oldest first by `system.compound.first_seen_at` or fallback to retro's `started_at`)
- Track which agents/retros they came from

### Stale flag

- `open` entries older than **4 weeks** → tag as stale
- `suggested` entries older than **2 weeks** without `resolved_by` → tag as stale

These thresholds are observational hints (printed in the view), not enforced. No auto-mutations.

### Prioritize top-10

Sort clusters by:

1. Recurrence (count of entries) — highest first
2. Severity (entries with `severity: blocking` rank higher; then `degrading`; then `annoying`; entries with no severity rank lowest)
3. Age (older clusters rank higher)

Cap at top-10 for the default view. Filtered views may show more.

## Step 5 — Print terminal view (NO on-disk writes)

Default format:

```
🌾 Compound harvest — 2026-05-18T15:30:00Z

📚 Scanned 27 retros across 3 agents (claude-code, plan-6-companion, minih-my-agent)
   Date range: 2026-04-10 → 2026-05-18
   Total entries: 47 (28 open, 17 encoded, 2 wontfix)

📊 Open clusters (top 10 by recurrence > severity > age):
   1. [tooling] grep/search slowness — 4 entries (claude-code: 3, plan-6-companion: 1)  [r/w/s]
   2. [pipeline] missing example patterns — 3 entries  [r/w/s]
   3. [config] env var contract guessing — 2 entries  [r/w/s]
   ...

⏰ Stale (>4 weeks open): 3 entries
   - DL-061 (2026-04-10): "spec template § Domain Manifest unclear"  [r/w/s]
   ...

✅ Recently encoded (last 7 days): 6 entries — see scratch/encode-*.diff for the diffs

[s/t/p/e/d/a/r/w/s]: ▮
```

**Nothing is written to disk by the harvest itself** (per workshop 006 § D4 KISS revision — no `_LEDGER.md`, no `_AGENT.md`, no rollup files). The view is transient terminal output.

### `--json` output (machine-readable read interface)

`/compound-3-harvest --json` emits the same computed view as the default render but as a single JSON document on stdout. This is a **read-time render of transient computation** — still no on-disk index, still no persisted state. Use it for `just compound-value`, CI hooks, or any downstream skill that wants programmatic access to loop status.

**Schema** (stable contract — bump compound v1.x if changed):

```json
{
  "schema_version": "1.0.0",
  "generated_at": "2026-05-19T01:30:00Z",
  "retros": 27,
  "entries": {
    "total": 47,
    "open": 28,
    "suggested": 2,
    "encoded": 17,
    "wontfix": 0,
    "dismissed": 0,
    "escalated": 0,
    "stale": 0
  },
  "top_clusters": [
    {
      "kind": "difficulty",
      "target": "tooling",
      "count": 4,
      "oldest": "2026-05-14T11:22:00Z",
      "representative": "grep on src/ took 47s — should use ripgrep"
    }
  ],
  "harness": {
    "maturity": "L2",
    "last_validation": "2026-05-18",
    "boot_ms": 18000,
    "verdict": "healthy"
  }
}
```

Field semantics:

- `schema_version` — semver for the JSON contract itself; bump on breaking shape change.
- `generated_at` — ISO-8601 UTC timestamp of THIS render.
- `retros` — count of `.retro.md` files scanned (post dedup + version-skew filter).
- `entries.*` — counts by `system.compound.status` (plus `total` = sum of all entries seen). Missing-status entries count as `open`.
- `top_clusters` — top-10 clusters by the same priority order as the default view (recurrence > severity > age). Cap at 10; consumers wanting fewer should slice.
- `harness` — if `docs/project-rules/engineering-harness.md` (or legacy `agent-harness.md` / `harness.md`) exists, parse its `## Maturity Assessment` + `## History` for the most recent validation. If absent, emit `{"maturity": null, "last_validation": null, "boot_ms": null, "verdict": null}`.

**Missing/empty cases**:

- Empty tree → `{..., "retros": 0, "entries": {"total": 0, ...}, "top_clusters": [], "harness": {...or null}}`. Still valid JSON; consumers handle.
- Sentinel `docs/compound/.disabled` present → emit the disabled-line on stderr; exit non-zero; **no JSON on stdout** (consumers can detect by exit code).
- Schema-version skew on a retro → still emit JSON; skipped retros contribute to neither counts nor clusters.

Consumed by `scripts/compound-value.sh` (the cross-CLI portable pretty-printer) and `just compound-value`. Other consumers should pipe `<their-CLI invokes the skill> --json | jq ...`.

## Step 6 — Action menu

The same `[s/t/p/e/d/a]` actions as `compound-2-bubble`, plus three lifecycle ops:

- `[s]ave` (selective save) — typically a no-op here (entries already saved); operates on top-10 cluster selection
- `[t]ask` — emit `/plan-5 --fix` invocations for selected entries
- `[p]lan` — emit `/plan-1b` invocations
- `[e]ncode` — stage `scratch/encode-<id>-<target>.diff` files (same as bubble)
- `[d]ismiss` — mutate `system.compound.status: dismissed` IN-PLACE in the source `.retro.md`
- `[a]ll-save` — typically a no-op (entries already saved)
- **`[r]esolved`** — mutate `system.compound.status: encoded`; prompt for `resolved_by:` (free-text; user pastes a commit hash / PR URL / scratch diff path)
- **`[w]ontfix`** — mutate `system.compound.status: wontfix`
- **`[s]tale`** — mutate `system.compound.status: stale`

For lifecycle ops, the harvest reads the source file, updates the entry's `system.compound.status`, writes back. The file's overall `schema_version`, `retro_id`, etc. are untouched.

## Runtime filters

All combinable. Each filters the scan + view to matching retros:

- `--plan <slug>` → only retros where `frontmatter.plan_id == <slug>`
- `--agent <slug>` → only retros where `frontmatter.agent == <slug>` (slugified match)
- `--since <YYYY-MM-DD>` → only retros where the directory date >= `<date>` (or `started_at` if directory not date-sliced)
- `--kind <kind>` → only entries (not retros) where `entry.kind == <kind>`; retros with no matching entries are omitted

Example: `/compound-3-harvest --plan 023-difficulty-ledger-skill --since 2026-05-15 --kind difficulty` — show only difficulty entries from plan 023 retros newer than May 15.

## Pruning (`--prune`)

`/compound-3-harvest --prune --older-than 90d` → **dry-run by default**:

1. List all retros older than 90 days
2. Show what would be deleted
3. Print: `"This is a dry run. Add --apply to actually delete (and recommend running on a clean git working tree)."`

`/compound-3-harvest --prune --older-than 90d --apply` → actually delete the files. Single-confirmation prompt before deletion.

User responsibility — best-effort framing; no auto-pruning ever.

## What this skill does NOT do

- **No on-disk index files written**. Every cross-cutting view is terminal print, computed at read time.
- **No auto-applying** any encoded diff. Staged-only via `[e]ncode`.
- **No buffer reading**. Buffer is `compound-2-bubble`'s territory; this skill reads `.retro.md` files only.
- **No mid-session firing**. The auto-firing sites are at logical pauses (end of plan-N, debrief, merge).

## Edge cases

- **Empty tree** (no `.retro.md` files anywhere): print `"🌾 No retros found. Start logging via compound-1-track during sessions."` and exit.
- **Sentinel mid-harvest**: if `.disabled` appears mid-scan, abort. Don't write any pending lifecycle mutations.
- **Concurrent harvests**: lifecycle mutations are last-write-wins per file. Unlikely to collide because both readers compute identical views.
- **Hash collision in retro_id** (two retros, same ID): dedup keeps the canonical one. Print warning if both are canonical (`agents/**`); skip the second.
- **Schema-version skew**: see Step 3 above.
- **`docs/retros/` absent**: just skip the back-compat path. No error.

## Why no on-disk index files

Per workshop 006 § D4 KISS revision (the user demanded this in review):

> Persisting derived state creates four problems the system doesn't need: drift between index and source, git diff noise on every harvest, agent maintenance burden, and bureaucratic ceremony.

The harvest computes the view in <1s for typical repos (≤100 retros). Re-computation per invocation is cheap; persistence is expensive (in attention and git noise).

For ad-hoc shell-level browsing without the skill:

```bash
ls docs/compound/agents/*/$(date -u +%Y-%m-%d)/                # today's retros
ls docs/compound/agents/<agent>/                                # one agent's date dirs
cat docs/compound/agents/<agent>/<date>/*.retro.md              # the files themselves
grep -l 'plan_id: "023-' docs/compound/agents/*/*/*.retro.md    # all plan-023 retros
```

The tree IS the browse surface. Harvest is for clustered/prioritized views; shell tools are for raw browsing.

## References

- Workshop 005 — Universal retro contract (§ validation; § D9 round-trip; § D8 versioning)
- Workshop 006 — Compound folder layout (§ Runtime Views; § D4 KISS no-indexes; § D6 pruning; § D7 minih back-compat; § EC9 dual-source dedup)
- Spec § Acceptance Criteria #13-17, #23
- Spec § Q5.3 (stale heuristics — calibrate during dogfood)
