# Walkthroughs — the harness loop after the 6→3 consolidation

**Plan**: [harness-nucleus-plan.md](../harness-nucleus-plan.md) · **AC**: AC9
**Purpose**: trace one full pass of the post-consolidation loop — `harness-2-observe` → `harness-3-retro --drain` → `harness-3-retro --harvest` — against a **real synthetic fixture** (no mocks, per spec § Mock Usage). This is a design-review document: it proves the three surviving skills compose end-to-end and that the rename preserved every behavior.

The loop stages: **Boot → Do Work → Observe → Retro.** `harness-1-boot` runs at session start (covered in [harness-1-boot/SKILL.md](../../../../skills/harness/harness-1-boot/SKILL.md)); this walkthrough picks up at Observe.

---

## Stage 0 — Boot (context)

At session start `harness-1-boot --validate` reads `docs/project-rules/engineering-harness.md` (canonical; falls back to `agent-harness.md` → `harness.md`). In this repo the governance doc is absent, so boot reports:

```
🔍 Engineering Harness Validation Report:
  Verdict:   🔴 UNAVAILABLE  (no engineering-harness.md / agent-harness.md / harness.md, no boot command)
  Note:      governance doc is provisioned by the separate engineering-harness setup effort
```

Boot does **not** block — observe/retro still work against the `docs/compound/` ledger, which IS scaffolded here. This is the graceful-degradation contract (AC8).

---

## Stage 1 — Observe (`harness-2-observe`, silent producer)

During a plan-6 implementation phase the agent hits friction twice and logs one magic-wand wish. Each is a single silent `harness-2-observe` call appending to the per-agent buffer `docs/compound/_buffers/claude-code.session-buffer.md`:

```yaml
- id: DL-001
  kind: difficulty
  description: "grep on skills/SDD/ took 41s scanning 29 SKILL.md files — should use ripgrep."
  target: tooling
  severity: degrading
  workaround: "Used grep -rn with an explicit file glob to narrow the scan."
  suggested_encoding: "justfile recipe wrapping ripgrep with the skills/ glob"
  system:
    compound:
      status: open
      source: agent-self
      first_seen_at: "2026-05-28T09:12:00Z"
- id: DL-002
  kind: difficulty
  description: "zsh did not word-split an unquoted $FILES var in a for-loop; sed got one bad path."
  target: tooling
  severity: annoying
  workaround: "Listed the files literally in the loop instead of via a variable."
  suggested_encoding: "note in CLAUDE.md: zsh needs explicit arrays / quoted expansion"
  system:
    compound:
      status: open
      source: agent-self
      first_seen_at: "2026-05-28T09:40:00Z"
- id: MW-001
  kind: magic-wand
  description: "A `just rg <pattern>` recipe would shave ~40s per cross-skill search."
  target: tooling
  suggested_encoding: "justfile recipe: rg with sensible defaults"
  system:
    compound:
      status: open
      source: agent-self
      first_seen_at: "2026-05-28T09:41:00Z"
```

No user-facing output during work. The buffer is the only artifact. (Sentinel: had `docs/compound/.disabled` existed, every call would no-op.)

---

## Stage 2 — Retro `--drain` (`harness-3-retro --drain`, session end)

At end-of-phase the pipeline auto-fires `harness-3-retro --drain`. It reads the buffer (3 entries), presents the single soft prompt:

```
💡 harness retro — 3 entries from this session:

  1. [difficulty/tooling] grep on skills/SDD/ took 41s scanning 29 SKILL.md files
     → encode as: justfile recipe wrapping ripgrep with the skills/ glob
  2. [difficulty/tooling] zsh did not word-split an unquoted $FILES var in a for-loop
     → encode as: note in CLAUDE.md: zsh needs explicit arrays / quoted expansion
  3. [magic-wand/tooling] A `just rg <pattern>` recipe would shave ~40s per cross-skill search
     → encode as: justfile recipe: rg with sensible defaults

[s]ave  [t]ask  [p]lan  [e]ncode  [d]ismiss  [a]ll-save (default — Enter)
[s/t/p/e/d/a]: ▮
```

The user presses Enter → `[a]ll-save`. All 3 entries are wrapped in one universal retro envelope and written to `docs/compound/agents/claude-code/2026-05-28/T09-55-00Z-a1b2c3d4.retro.md`:

```yaml
---
schema_version: "1.0"
retro_id: "2026-05-28T09:55:00Z-claude-code-a1b2c3d4"
agent: claude-code
plan_id: "024-harness-nucleus"
started_at: "2026-05-28T09:12:00Z"
ended_at: "2026-05-28T09:55:00Z"
summary: "harness-3-retro --drain session-end save (3 entries)"
entries:
  - { id: DL-001, kind: difficulty, target: tooling, severity: degrading, description: "grep on skills/SDD/ took 41s …", system: { compound: { status: open, source: agent-self, first_seen_at: "2026-05-28T09:12:00Z" } } }
  - { id: DL-002, kind: difficulty, target: tooling, severity: annoying,  description: "zsh did not word-split …",        system: { compound: { status: open, source: agent-self, first_seen_at: "2026-05-28T09:40:00Z" } } }
  - { id: MW-001, kind: magic-wand, target: tooling, description: "A `just rg <pattern>` recipe would shave ~40s …",      system: { compound: { status: open, source: agent-self, first_seen_at: "2026-05-28T09:41:00Z" } } }
system:
  compound:
    bubble_action: "all-save"
---
```

Then the buffer is truncated to empty. Had the user picked `[e]ncode` instead, a `scratch/encode-DL-001-tooling.diff` would be staged (with the mandatory `## Validation` footer) and DL-001 would land as `status: suggested` with `resolved_by` pointing at the diff. **Nothing is auto-applied** — encode, don't document means the encoding lives in a reviewable diff.

This is behaviorally identical to the old `compound-2-bubble` — same `[s/t/p/e/d/a]` menu, same envelope, same path resolver. Only the invocation name changed.

---

## Stage 3 — Retro `--harvest` (`harness-3-retro --harvest`, long-horizon)

At the plan's final-phase debrief (the `plan-6-companion` anchor) `harness-3-retro --harvest` fires. It scans `docs/compound/agents/**/*.retro.md` (plus legacy `docs/retros/*.md` if present), validates each against `skills/compound/schemas/retro.schema.json`, dedups by `retro_id`, clusters by `(kind, target)`, and prints:

```
🌾 Harness retro harvest — 2026-05-28T11:30:00Z

📚 Scanned 4 retros across 1 agent (claude-code)
   Date range: 2026-05-19 → 2026-05-28
   Total entries: 9 (6 open, 2 encoded, 1 suggested)

📊 Open clusters (top 10 by recurrence > severity > age):
   1. [tooling] grep/search slowness + shell quoting — 3 entries (claude-code: 3)  [r/w/s]
   2. [pipeline] missing worked example — 1 entry  [r/w/s]
   ...

⏰ Stale (>4 weeks open): 0 entries
✅ Recently encoded (last 7 days): 2 entries — see scratch/encode-*.diff

[s/t/p/e/d/a/r/w/s]: ▮
```

`--json` renders the same computed view as the machine-readable contract consumed by `just compound-value` (verified in plan T011 — all 8 jq paths present):

```json
{
  "schema_version": "1.0.0",
  "generated_at": "2026-05-28T11:30:00Z",
  "retros": 4,
  "entries": { "total": 9, "open": 6, "suggested": 1, "encoded": 2, "wontfix": 0, "dismissed": 0, "escalated": 0, "stale": 0 },
  "top_clusters": [
    { "kind": "difficulty", "target": "tooling", "count": 3, "oldest": "2026-05-28T09:12:00Z", "representative": "grep on skills/SDD/ took 41s …" }
  ],
  "harness": { "maturity": null, "last_validation": null, "boot_ms": null, "verdict": null }
}
```

(`harness` is all-null because no governance doc exists here — Stage 0's `UNAVAILABLE` carried through.) Piping this through `just compound-value` produces the compact terminal view. Lifecycle actions `[r]esolved` / `[w]ontfix` / `[s]tale` mutate `system.compound.status` in place in the source `.retro.md` — no on-disk index is ever written.

This is behaviorally identical to the old `compound-3-harvest` — same scan/dedup/cluster/age logic, same `--json` schema, same runtime filters (`--plan`/`--agent`/`--since`/`--kind`), same `--prune` dry-run. Only the invocation name (now a mode of `harness-3-retro`) changed.

---

## What this proves

| Claim | Evidence in this trace |
|-------|------------------------|
| Observe → drain → harvest composes end-to-end | The same 3 entries flow buffer → `.retro.md` → clustered harvest view |
| Rename preserved behavior (nothing cut) | Menu, envelope, path resolver, `--json` schema, lifecycle ops, filters all unchanged |
| `--json` contract intact (AC4) | 8 jq paths present; `just compound-value` renders it |
| Graceful degradation (AC8) | `harness` block is null end-to-end because boot reported `UNAVAILABLE` — no hard dependency on the dropped CREATE mode |
| Encode-don't-document (P3) | `[e]ncode` stages a reviewable diff with a `## Validation` footer; nothing auto-applies |
| Sentinel honored | `docs/compound/.disabled` would no-op every stage |

The fixture above is synthetic but schema-valid — it is the kind of real `.retro.md` content the loop produces, used so the trace is concrete rather than mocked.
