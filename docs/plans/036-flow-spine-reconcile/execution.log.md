# Execution Log — flow-spine-reconcile (Phase 1, Simple)

**Plan**: `flow-spine-reconcile-plan.md` · **Mode**: Simple · **Started/Completed**: 2026-06-27

## Pre-flight
- Baseline `just check-flow` → clean (0 warnings). git: only `CLAUDE.md` (earlier edit) + new plan folder; no concurrent uncommitted edits to spine files. Last commit `98436c6`.
- Harness: router installed, repo **unprovisioned** (`.harness:` absent) → standard testing; **no** per-phase harness nodes emitted (correct per `harness-seams.md` § Node emission). Seam calls skipped silently (best-effort).

## Tasks

### T001 — SKILL.md: `sync` verb + grammar + invariant ✓
- Registry: added `sync` row (id=verb=`sync`, module `references/00-routing.md`, "no flags — auto-fired every guided entry; also invokable on demand"). Added a `>` note framing it as a **maintenance verb** (no ordinal id, no stage artifact, never moves the cursor), distinct from `8c reconcile`.
- Command grammar: added a line — `sync` resolves alone, `/the-flow sync` runs the pass on demand (literal kept inside the grammar section → L3-exempt).
- Hard invariants: added **#11 — "Keep the spine complete — reconcile every guided entry"**: engine runs the spine-reconcile pass on every resume/adopt before narrating; idempotent, advisory, CLI-only, never gates/advances `nav`; "the user must never have to ask 'make sure all phases/chores are represented'."

### T002 — 00-routing.md: reconcile routine + every-entry triggers ✓
- Added `## Reconcile the spine — the every-entry completeness pass`: the routine (when it runs; diff plan `#### Phase Index`/`### Implementation` + `workshops/*.md` + harness seam-node set vs `the-flow.json`; backfill via `insert-node --after`/`--branch-of`; status rules incl. "never downgrade an already-advanced node"; harness half installed+provisioned only, **nodes only**; render iff changed; never advances `nav`/gates/re-parents; no new state).
- Resume section: inserted "**reconcile the spine** (runs on every resume *and* adopt, idempotent)" before narrate.
- CLI cadence step 2: noted the reconcile pass is the **idempotent superset** of the one-shot plan-pass reveal (catches adopt / post-pass-edit / direct-jump / harness-installed-mid-flow).

### T003 — harness-seams.md: reconcile/seam-node ownership cross-ref ✓
- Added `## Reconcile pre-anchors seam nodes (the every-entry pass)`: reconcile ensures per-phase seam nodes exist across **all known phases**; emits **nodes only**; `eng-harness-flow` keeps sole ownership of the chore **flag** (dedup on `--hook`); names the canonical target shape that hand-runs drift from; unprovisioned/not-installed → no harness nodes.

### T004 — getting-started.md: rendered view ✓
- Added a `sync` row to the stage table and a `sync` row to Quick Reference (no `/the-flow <verb>` literal → L3-safe in the banner view). Banner intact (L5 ok).

### T005 — validate ✓
- `just check-flow` → **clean, 0 warnings**; Registry parses **11 rows** (sync added); L1 = 0 leak lines across 10 sub-skills (sub-skills untouched/harness-blind); L3/L4/L5/L6 all OK.
- Dry-read: `/the-flow sync` resolves via Registry (id=verb=`sync` → 00-routing § Reconcile the spine); auto-fire wired via invariant #11 + Resume trigger; idempotent no-op on a complete spine stated in the routine.

## Acceptance Criteria
- AC-01 verb in Registry & resolvable ✓ · AC-02 auto-fired every entry + idempotent ✓ · AC-03 backfills all phases + workshops ✓ · AC-04 pre-anchors harness seam nodes, ownership/dedup respected ✓ · AC-05 best-effort/no-gate/no-state/CLI-only ✓ · AC-06 check-flow passes ✓

## Notes / Discoveries
- **L3 verb-led rule**: a literal `/the-flow sync` is flagged outside the Command grammar section even in banner views — so `sync` is shown via the grammar section + named in prose elsewhere. No workaround needed; design fits the pattern.
- **Not deployed**: edits are to repo source only; `just install-skills-from-source` not run (not requested). Live CLIs pick up the change on next deploy.
