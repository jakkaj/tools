---
name: harness-3-retro
description: |
  Retro and Magic Wand stage of the harness loop (Boot → Backpressure Check → Do Work and Observe → Retro and Magic Wand → Improve). One skill, two modes. `--drain` (session-end soft prompt) reads `docs/harness/_buffers/<agent>.session-buffer.md`; if non-empty, presents a single soft prompt with `[s/t/p/e/d/a]` action menu and a one-line encoding hint per entry; routes saved entries into per-run `.retro.md` files under `docs/harness/agents/<agent>/<date>/`. `--harvest` (long-horizon curation) scans `docs/harness/agents/**/*.retro.md` (canonical) plus legacy `docs/retros/*.md` (back-compat), validates against the universal schema, dedups, clusters by kind + target, ages stale entries, and prints a prioritized terminal view (`--json` for tooling). Encode, don't document. Empty buffer / empty tree = silent. NO on-disk index files — views computed at read time.
---

# harness-3-retro

The **Retro** stage of the harness loop. The place the loop turns observation into encoded improvement. Two modes:

> **Encode, don't document.** A wiki paragraph that says "remember to do X" is worth nothing; an automated step that does X for you is worth everything. The whole point of retro is that friction observed during work becomes *executable knowledge* — a justfile recipe, a skill edit, a staged diff — not a prose note that rots. The `[e]ncode` action stages the change as a diff; that diff IS the encoding. Prefer an automated command over a wiki paragraph, a seed script over a manual setup step, a pre-flight check over a "remember to…". Executable knowledge > prose.

## Input

```
$ARGUMENTS
# Modes:
# --drain      Session-end: read the per-agent buffer, present the soft prompt, route entries to .retro.md
# --harvest    Long-horizon: scan + cluster + prioritize .retro.md files; print the curated view
# --harvest --json   Machine-readable render of the harvest view (for `just compound-value`, CI hooks)
# Plus --harvest runtime filters: --plan <slug> / --agent <slug> / --since <date> / --kind <kind>
# Plus --harvest --prune --older-than <Nd> [--apply]   Reversible stale-retro pruning (dry-run by default)
```

| Mode | Replaces | When | What it does |
|------|----------|------|--------------|
| `--drain` | session-end bubble | end of session / logical pause / cross-session leftover | Drains the per-agent buffer via the `[s/t/p/e/d/a]` menu into `.retro.md` |
| `--harvest` | long-horizon curate | FINAL phase / merge end / review end / ad-hoc | Scans + clusters + prioritizes `.retro.md` files; prints the curated view (or `--json`) |

The producer that fills the buffer `--drain` reads is `harness-2-observe`. The Boot stage is `harness-1-boot`.

---

## Mode: `--drain` (session-end)

The consumer-side surface of the loop. The ONE place retro talks to the user.

### When to fire

- **Auto-fired** by pipeline skills at natural logical pauses (plan-1a end, plan-3 end, plan-6 end-of-phase, plan-6-companion end-of-phase, plan-7 end, plan-8 end)
- **Manually fired** by the user (`/harness-3-retro --drain`) at any time
- **Start-of-skill** check on any auto-firing skill — if the buffer has leftover entries from a prior session (cross-session carryover), drain immediately

Each firing handles entries accumulated since the last drain. Once drained, the buffer is empty; the next firing on an unchanged buffer is silent.

### Sentinel check

If `docs/harness/.disabled` exists → silently no-op. No prompt, no output.

### Step 1 — Read the buffer

Path: `docs/harness/_buffers/<agent>.session-buffer.md`

Where `<agent>` is the calling CLI's slug (claude-code, codex, github-copilot, opencode, pi, or a companion slug like plan-6-companion).

If the file is missing or empty → silent (no prompt). Exit.

If non-empty → parse it as a sequence of YAML entry blocks (each prefixed with `- id: …`).

### Step 2 — Present the soft prompt

Single prompt at end of session. **Never asks twice.** Format:

```
💡 harness retro — 3 entries from this session:

  1. [difficulty/tooling] grep on src/ took 47s
     → encode as: justfile recipe wrapping ripgrep

  2. [magic-wand/project] A `just rg <pattern>` recipe would shave 40+s per search
     → encode as: justfile recipe

  3. [gift/compound] harness ledger scaffolded cleanly
     → no encoding needed (it's a gift)

  4. [difficulty/project-sensor] Had to infer whether the website rendered correctly because no smoke path or screenshot evidence was available
     → encode as: add smoke command or visual evidence capture

[s]ave all to scope file
[t]ask: emit /plan-5 --fix invocations for the encodable ones
[p]lan: emit /plan-1b invocations for the bigger ones
[e]ncode: stage diffs in scratch/encode-<id>-<target>.diff
[d]ismiss all (entries dropped, not saved)
[a]ll-save (default — press Enter)

[s/t/p/e/d/a]: ▮
```

Notes on the prompt:
- One line per entry, prefixed `[kind/target]`
- One-line encoding hint per entry (from `suggested_encoding` or a sensible default)
- Action menu fits in two screen-lines
- Pressing Enter without typing = `[a]ll-save` (the default)
- Drain should make both improvement shapes visible: ease/friction improvements (faster, clearer, less annoying) and proof/back-pressure improvements (new deterministic signals, sensors, evidence paths, architecture checks). Both use the same schema; distinguish them by `target`, description, and encoding hint, not by new `kind` values.

### Step 3 — Route by action

#### `[a]ll-save` (default)

Wrap all buffer entries in a single universal retro envelope and write one `.retro.md` file:

```yaml
---
schema_version: "1.0"
retro_id: "<ISO>-<agent>-<short-hash>"
agent: <agent>
plan_id: <plan-id-from-cwd-or-branch-detection-or-null>
started_at: "<ISO of first entry's first_seen_at, or session start>"
ended_at: "<now in ISO UTC>"
summary: "harness-3-retro --drain session-end save (N entries)"
entries:
  # ... all buffer entries verbatim
system:
  compound:
    bubble_action: "all-save"
---
```

File path via `resolvePath()` (workshop 006 § Path Resolver):

`docs/harness/agents/<slugified-agent>/<YYYY-MM-DD>/T<HH-MM-SS>Z-<hash>.retro.md`

Then **clear the buffer** (truncate to empty; keep the file).

#### `[s]ave` (selective save)

Prompt: "Which entries to save? [1,2,3 or a]". Save the selected ones into a `.retro.md` (same envelope as `[a]ll-save`); discard the rest. Clear buffer.

#### `[t]ask` — emit copy-pasteable `/plan-5 --fix` invocations

For each encodable entry, print:

```
/plan-5 --fix --description "<entry.description>" --target <entry.target>
```

The user copy-pastes one or more of these. The entries are ALSO saved to a `.retro.md` (so the suggestion is captured even if the user doesn't run all of them). Clear buffer.

#### `[p]lan` — emit copy-pasteable `/plan-1b` invocations

For each entry suggesting a larger piece of work, print:

```
/plan-1b "<one-line spec derived from entry.description + entry.suggested_encoding>"
```

User copy-pastes the ones they want. Entries also saved to `.retro.md`. Clear buffer.

#### `[e]ncode` — stage diffs

For each entry where the encoding is a small mechanical edit (frequently true for `kind: difficulty` with a clear `suggested_encoding`):

1. Generate the diff (the agent makes a best-effort guess at the change)
2. Append the **Validation footer** (mandatory — see template below) so the staged diff documents how a reviewer verifies the encoded fix actually works
3. Write to `scratch/encode-<entry-id>-<target-slug>.diff`
4. Print the file path: "Staged scratch/encode-DL-001-tooling.diff — review and `git apply` to land"

**Nothing is auto-applied.** The diff is staged for user review. This is the "encode, don't document" mechanism — the encoding is in the diff, not in a doc.

Entries are also saved to `.retro.md` with `system.compound.status: suggested` and `system.compound.resolved_by: scratch/encode-<id>-<target>.diff`. Clear buffer.

##### Validation footer template (mandatory on every encoded diff)

Every staged `scratch/encode-<id>-<target>.diff` MUST end with a literal `## Validation` block of this shape:

```markdown
## Validation

Run:
  <command 1>
  <command 2 — optional>

Expected:
  - <observable outcome 1>
  - <observable outcome 2 — optional>

Compound lifecycle:
  <entry-id> transitions system.compound.status: suggested → encoded when this diff lands.
  resolved_by: <commit-sha-after-land>
```

How the three sub-sections are filled:

- **`Run:`** — best-effort shell command(s) that exercise the encoded change. If the entry's `suggested_encoding` mentions a recipe/command, use it; otherwise the agent picks a sensible reproduction or verification command (compile / test / grep / curl). If genuinely unknown, write `Run: (manual review only)`.
- **`Expected:`** — observable outcomes (file content matches, command exits 0, output contains substring). Plain bullets — no full test framework needed.
- **`Compound lifecycle:`** — names the entry id and the transition the `--harvest [r]esolved` lifecycle action will execute on this entry. The `resolved_by` line is a placeholder the user fills with the actual SHA after the diff lands.

The footer makes "encoded" mean *the loop changed AND we can prove it*, not just *we wrote a patch*. Reviewers see the verification path inline with the change.

#### `[d]ismiss all`

Truncate the buffer. Entries are dropped — not saved anywhere. Print one line: "✓ buffer dismissed (3 entries dropped)".

This is the "I don't want this captured" escape hatch. Use sparingly — entries dismissed here can't be recovered.

### Step 4 — Plan ID detection

When saving, populate `frontmatter.plan_id` from:

1. Current working directory: if cwd matches `docs/plans/<NNN-slug>/`, set `plan_id: <NNN-slug>`
2. Else: current git branch: if branch matches `<NNN>-<slug>`, set `plan_id: <branch-name>`
3. Else: `plan_id: null` (no plan context)

### Cross-session leftover check

At the start of any auto-firing skill, before doing its primary work, check the buffer:

- If `_buffers/<agent>.session-buffer.md` is non-empty → fire `harness-3-retro --drain` immediately
- Then proceed with the skill's primary work

This catches entries left over from a prior session (e.g. the user pressed Ctrl-C before the auto-drain fired).

### What `--drain` does NOT do

- **No mid-session prompting**. Only at end-of-session / logical pauses / next-session leftover.
- **No auto-applying** any encoded diff. Staged-only.
- **No editing of `.retro.md` files** after writing them. (That's `--harvest`'s job for lifecycle status mutations.)
- **No reading or aggregating** retros from other sessions. Each drain handles its OWN buffer; cross-session aggregation is `--harvest`.

### `--drain` edge cases

- **Empty buffer**: silent. No prompt. Exit cleanly.
- **Sentinel during drain**: if `.disabled` appears mid-drain, abort (don't write). Buffer stays as-is.
- **Concurrent drains** (two agents simultaneously): each has its own buffer, no collision.
- **Save to a path that already exists** (extremely rare hash collision): append `-2`, `-3`, etc. to the filename per workshop 006 § EC3.
- **User interrupts mid-prompt**: buffer stays unchanged. Next drain will see the same entries.
- **Malformed entry in buffer**: skip with a warning ("⚠ skipped 1 malformed entry"); save the valid ones; clear buffer (the malformed one is lost — better than corrupting a `.retro.md`).

### One-line encoding hint generation

For each entry, the prompt shows a one-line encoding hint. Source:

1. If `entry.suggested_encoding` is set → use it verbatim
2. Else, derive from `entry.kind` + `entry.target`:
   - `difficulty/tooling` → "wrap in a justfile recipe"
   - `difficulty/skill` → "edit the SKILL.md"
   - `magic-wand/<any>` → "encode as the suggestion above"
   - `gift/<any>` → "no encoding needed"
   - `insight/<any>` → "document in AGENTS.md or a docs/how article"
3. Else → "(no encoding hint — review manually)"

---

## Mode: `--harvest` (long-horizon)

The reader/curator side of the loop. Auto-fires at long-horizon reflection moments (plan-6-companion FINAL-phase debrief, plan-8 merge end, plan-7 end). Can also be run manually for ad-hoc curation.

### When to fire

- **AUTO-fired** at:
  - `plan-6-companion` FINAL-phase debrief (the dominant flow — replaces /plan-7 as harvest anchor)
  - `plan-8-merge` end (plan-completion reflection)
  - `plan-7-code-review` end (preserved for rare solo /plan-6 flow)
- **SUGGESTED at the start of**:
  - `plan-1a-explore` (if ≥5 unharvested entries — print invocation as one-liner; do NOT auto-fire)
  - `plan-3-architect` (if ≥10 unharvested entries — same)
- **Manually** by the user at any time: `/harness-3-retro --harvest [--plan <slug>] [--agent <slug>] [--since <date>] [--kind <kind>]`

### Sentinel check

If `docs/harness/.disabled` exists → print one line: `"📴 the harness retro ledger is disabled (docs/harness/.disabled present). Remove the sentinel to re-enable."` and exit. Do not scan, do not print views.

### Buffer-non-empty advisory

At start, check `docs/harness/_buffers/<agent>.session-buffer.md` for the calling agent. If non-empty → print one line before scanning:

> ℹ️ Buffer has N unbubbled entries. Consider running `/harness-3-retro --drain` first so they land in the harvest view.

Then proceed with the scan anyway (the harvest reads `.retro.md` files; buffer entries are unrelated).

### Step 1 — Scan + validate

**Canonical path**: `docs/harness/agents/**/*.retro.md`

For each file:
- Parse the YAML frontmatter (between the first two `---` lines)
- Validate against the bundled `references/retro.schema.json` (a deployment mirror of the canonical, frozen `docs/harness/schemas/retro.schema.json` — copied into this skill folder so it travels with the skill via `npx skills add`; in a source checkout either path is identical). If neither is present, skip validation and print `⚠ retro schema not found — skipping validation` (best-effort: a missing schema never blocks the harvest).
- If invalid → print a warning naming the file path + the validation error; SKIP the entire retro (strict — no half-parse)
- If valid → add to the in-memory view

**Back-compat path**: `docs/retros/*.md` (minih's legacy single-big-file-per-agent format)

For each file (skip `*.legacy.md` — those are post-migration archives):
- Parse the file as a sequence of `## <ISO timestamp> — <slug> / <runId>` blocks (regex on `/^## \d{4}-\d{2}-\d{2}T/m`)
- For each block:
  - Run the minih block → universal retro mapping inline (workshop 005 § D9 `minihToUniversal`)
  - Add to the in-memory view

### Step 2 — Dedup by `retro_id`

If the same `retro_id` appears in both the canonical and back-compat paths (rare; happens during minih dual-write phase), the **canonical (universal) version wins**. Skip the back-compat copy.

### Step 3 — Schema-version skew handling

If a retro has `schema_version` starting with a major number this reader doesn't know (e.g. `2.x` when the reader supports `1.x`):

- Print: `"⚠ Skipped 1 retro with unsupported schema_version: <path>"`
- Skip the retro

Minor-version skew (`1.1` when reader is `1.0`) is silent — forward-compat per workshop 005 § D8.

### Step 4 — Curate

Build the in-memory view:

#### Cluster open entries

Group entries by `(kind, target)`. Within each cluster:

- Count entries
- Age-order (oldest first by `system.compound.first_seen_at` or fallback to retro's `started_at`)
- Track which agents/retros they came from

#### Stale flag

- `open` entries older than **4 weeks** → tag as stale
- `suggested` entries older than **2 weeks** without `resolved_by` → tag as stale

These thresholds are observational hints (printed in the view), not enforced. No auto-mutations.

#### Prioritize top-10

Sort clusters by:

1. Recurrence (count of entries) — highest first
2. Severity (entries with `severity: blocking` rank higher; then `degrading`; then `annoying`; entries with no severity rank lowest)
3. Back-pressure leverage (clusters whose target or representative entry indicates missing proof/sensors/evidence/architecture/security/schema checks should stay legible as proof-improvement candidates)
4. Age (older clusters rank higher)

Cap at top-10 for the default view. Filtered views may show more.

Back-pressure leverage is advisory display guidance only. It does not create a gate, score, persisted index, or threshold, and it must not mutate entries.

#### Recognize proof/back-pressure clusters

Treat these as proof/back-pressure improvement candidates when printing labels or choosing representative wording:

- Targets such as `project-sensor`, `runtime-inspectability`, `architecture-fitness`, `security`, `schema`, `infra`, or `tooling`
- Descriptions or `suggested_encoding` values that mention smoke paths, screenshots, logs, traces, health checks, dependency-direction rules, CodeQL/Roslyn/ArchUnit, schema validation, data checks, or missing evidence
- `difficulty` entries where the workaround was "manual review", "read code manually", "inferred", or "eyeballed"

Keep the original schema fields intact. Do not rewrite kinds to `signal-gap`, `sensor-gap`, or `weak-back-pressure`.

### Step 5 — Print terminal view (NO on-disk writes)

Default format:

```
🌾 Harness retro harvest — 2026-05-18T15:30:00Z

📚 Scanned 27 retros across 3 agents (claude-code, plan-6-companion, minih-my-agent)
   Date range: 2026-04-10 → 2026-05-18
   Total entries: 47 (28 open, 17 encoded, 2 wontfix)

📊 Open clusters (top 10 by recurrence > severity > back-pressure leverage > age):
   1. [tooling] grep/search slowness — 4 entries (claude-code: 3, plan-6-companion: 1)  [r/w/s]
   2. [proof/project-sensor] missing smoke or visual evidence — 3 entries  [r/w/s]
   3. [pipeline] missing example patterns — 3 entries  [r/w/s]
   4. [config] env var contract guessing — 2 entries  [r/w/s]
   ...

⏰ Stale (>4 weeks open): 3 entries
   - DL-061 (2026-04-10): "spec template § Domain Manifest unclear"  [r/w/s]
   ...

✅ Recently encoded (last 7 days): 6 entries — see scratch/encode-*.diff for the diffs

[s/t/p/e/d/a/r/w/s]: ▮
```

**Nothing is written to disk by the harvest itself** (per workshop 006 § D4 KISS revision — no `_LEDGER.md`, no `_AGENT.md`, no rollup files). The view is transient terminal output.

#### `--json` output (machine-readable read interface)

`/harness-3-retro --harvest --json` emits the same computed view as the default render but as a single JSON document on stdout. This is a **read-time render of transient computation** — still no on-disk index, still no persisted state. Use it for `just compound-value`, CI hooks, or any downstream skill that wants programmatic access to loop status.

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
- `top_clusters` — top-10 clusters by the same priority order as the default view (recurrence > severity > back-pressure leverage > age). Cap at 10; consumers wanting fewer should slice.
- `harness` — if `docs/project-rules/engineering-harness.md` (or legacy `agent-harness.md` / `harness.md`) exists, parse its `## Maturity Assessment` + `## History` for the most recent validation. If absent, emit `{"maturity": null, "last_validation": null, "boot_ms": null, "verdict": null}`.

**Missing/empty cases**:

- Empty tree → `{..., "retros": 0, "entries": {"total": 0, ...}, "top_clusters": [], "harness": {...or null}}`. Still valid JSON; consumers handle.
- Sentinel `docs/harness/.disabled` present → emit the disabled-line on stderr; exit non-zero; **no JSON on stdout** (consumers can detect by exit code).
- Schema-version skew on a retro → still emit JSON; skipped retros contribute to neither counts nor clusters.

Consumed by `scripts/compound-value.sh` (the cross-CLI portable pretty-printer) and `just compound-value`. Other consumers should pipe `<their-CLI invokes the skill> --harvest --json | jq ...`.

### Step 6 — Action menu

The same `[s/t/p/e/d/a]` actions as `--drain`, plus three lifecycle ops:

- `[s]ave` (selective save) — typically a no-op here (entries already saved); operates on top-10 cluster selection
- `[t]ask` — emit `/plan-5 --fix` invocations for selected entries
- `[p]lan` — emit `/plan-1b` invocations
- `[e]ncode` — stage `scratch/encode-<id>-<target>.diff` files (same as `--drain`)
- `[d]ismiss` — mutate `system.compound.status: dismissed` IN-PLACE in the source `.retro.md`
- `[a]ll-save` — typically a no-op (entries already saved)
- **`[r]esolved`** — mutate `system.compound.status: encoded`; prompt for `resolved_by:` (free-text; user pastes a commit hash / PR URL / scratch diff path)
- **`[w]ontfix`** — mutate `system.compound.status: wontfix`
- **`[s]tale`** — mutate `system.compound.status: stale`

For lifecycle ops, the harvest reads the source file, updates the entry's `system.compound.status`, writes back. The file's overall `schema_version`, `retro_id`, etc. are untouched.

### Runtime filters

All combinable. Each filters the scan + view to matching retros:

- `--plan <slug>` → only retros where `frontmatter.plan_id == <slug>`
- `--agent <slug>` → only retros where `frontmatter.agent == <slug>` (slugified match)
- `--since <YYYY-MM-DD>` → only retros where the directory date >= `<date>` (or `started_at` if directory not date-sliced)
- `--kind <kind>` → only entries (not retros) where `entry.kind == <kind>`; retros with no matching entries are omitted

Example: `/harness-3-retro --harvest --plan 023-difficulty-ledger-skill --since 2026-05-15 --kind difficulty` — show only difficulty entries from plan 023 retros newer than May 15.

### Pruning (`--prune`)

`/harness-3-retro --harvest --prune --older-than 90d` → **dry-run by default**:

1. List all retros older than 90 days
2. Show what would be deleted
3. Print: `"This is a dry run. Add --apply to actually delete (and recommend running on a clean git working tree)."`

`/harness-3-retro --harvest --prune --older-than 90d --apply` → actually delete the files. Single-confirmation prompt before deletion.

User responsibility — best-effort framing; no auto-pruning ever.

### What `--harvest` does NOT do

- **No on-disk index files written**. Every cross-cutting view is terminal print, computed at read time.
- **No auto-applying** any encoded diff. Staged-only via `[e]ncode`.
- **No buffer reading**. Buffer is `--drain`'s territory; this mode reads `.retro.md` files only.
- **No mid-session firing**. The auto-firing sites are at logical pauses (end of plan-N, debrief, merge).
- **No schema expansion**. Missing-signal and back-pressure entries stay schema-compatible by using existing `kind` values plus targets and encoding hints.
- **No proof gates**. Harvest can surface missing sensors as high-leverage improvement candidates, but it never blocks a plan, applies a threshold, or declares compliance.

### `--harvest` edge cases

- **Empty tree** (no `.retro.md` files anywhere): print `"🌾 No retros found. Start logging via harness-2-observe during sessions."` and exit.
- **Sentinel mid-harvest**: if `.disabled` appears mid-scan, abort. Don't write any pending lifecycle mutations.
- **Concurrent harvests**: lifecycle mutations are last-write-wins per file. Unlikely to collide because both readers compute identical views.
- **Hash collision in retro_id** (two retros, same ID): dedup keeps the canonical one. Print warning if both are canonical (`agents/**`); skip the second.
- **Schema-version skew**: see Step 3 above.
- **`docs/retros/` absent**: just skip the back-compat path. No error.

### Why no on-disk index files

Per workshop 006 § D4 KISS revision (the user demanded this in review):

> Persisting derived state creates four problems the system doesn't need: drift between index and source, git diff noise on every harvest, agent maintenance burden, and bureaucratic ceremony.

The harvest computes the view in <1s for typical repos (≤100 retros). Re-computation per invocation is cheap; persistence is expensive (in attention and git noise).

For ad-hoc shell-level browsing without the skill:

```bash
ls docs/harness/agents/*/$(date -u +%Y-%m-%d)/                # today's retros
ls docs/harness/agents/<agent>/                                # one agent's date dirs
cat docs/harness/agents/<agent>/<date>/*.retro.md              # the files themselves
grep -l 'plan_id: "023-' docs/harness/agents/*/*/*.retro.md    # all plan-023 retros
```

The tree IS the browse surface. Harvest is for clustered/prioritized views; shell tools are for raw browsing.

---

## References

- Workshop 001 — Self-improvement vibe (§ Anti-vibe 1 nag-ware; § D5 terse one-line hints)
- Workshop 004 — SDD pipeline integration (§ Walkthrough D)
- Workshop 005 — Universal retro contract (§ envelope; § validation; § D8 versioning; § D9 round-trip)
- Workshop 006 — Compound folder layout (§ Path Resolver; § Runtime Views; § D4 KISS no-indexes; § D6 pruning; § D7 minih back-compat; § EC2 cross-session carryover; § EC9 dual-source dedup)
- Spec § Acceptance Criteria #7-17, #23
- Spec § Q5.3 (stale heuristics — calibrate during dogfood)
- Spec § Q6.1 (task-boundary check only when buffer empty)
