# Fix FX001: Group A — Quick Wins from Post-Launch Review

**Created**: 2026-05-18
**Status**: Proposed
**Plan**: [023-difficulty-ledger-skill](../difficulty-ledger-skill-plan.md)
**Source**: Workshop 007 § Group A (review fixes RV-001, RV-002, RV-003 from external compound + harness skill-pack review)
**Domain(s)**: `engineering-harness` (modify) + `compound` (modify) + `scripts` (extend)

---

## Problem

External review of the just-shipped compound + engineering-harness skill family surfaced 7 concrete fixes (workshop 007). Three of them are cheap, aligned with our principles, and immediately shippable as a single batch:

1. **Confirmed bug**: `engineering-harness-v2`'s boot-time relevance filter admits only `engineering-harness | tooling | infra` targets, but fixture entries emit `build | config | tooling | minih | project`. Three of five fixture targets get silently dropped from Known Difficulties seeding — boot-time agents miss the most actionable friction. Verified at `skills/SDD/engineering-harness-v2/SKILL.md:218` vs `grep "target:" skills/compound/schemas/fixtures/*.retro.md`.

2. **Missing stable read interface**: `compound-3-harvest` computes a useful view transiently and prints it; there is no machine-readable surface, so future skills, hooks, or `just` recipes can't consume the loop status. The KISS rule from workshop 006 (no on-disk index) is right, but it shouldn't preclude a read-time `--json` render.

3. **"Encoded" is ambiguous**: When `compound-2-bubble [e]ncode` stages a diff into `scratch/encode-*.diff`, reviewers see the patch but have to infer how to verify it. The action means "we wrote a patch" rather than "we changed the loop AND can prove it."

## Proposed Fix

Three coordinated changes shipping as one batch:

1. **RV-001**: Widen the target filter to `engineering-harness | tooling | infra | build | config | dependencies | env | auth | tests | observe`.
2. **RV-002**: Document a `--json` output schema for `compound-3-harvest`; add `scripts/compound-value.sh` (stdin JSON pretty-printer); add `just compound-value` recipe.
3. **RV-003**: Add a `## Validation` footer template to the `compound-2-bubble [e]ncode` flow so staged diffs always include Run / Expected / Lifecycle blocks.

All three preserve the workshop 006 KISS rule (no on-disk index — view computed at read time and printed). All three are additive — no schema bump, no breaking change. Group B (RV-004, RV-005) and Group C (RV-006, RV-007) are tracked separately and ship as FX002/FX003 later.

---

## Domain Impact

| Domain | Relationship | What Changes |
|--------|-------------|-------------|
| engineering-harness | modify | Boot-time relevance filter widens — more compound entries surface in `## Known Difficulties` |
| compound | modify | `compound-3-harvest` adds `--json` flag spec; `compound-2-bubble` adds validation footer to encode-flow template |
| scripts | extend | New `scripts/compound-value.sh` — stdin JSON pretty-printer, no state |
| justfile | extend | New `compound-value` recipe wiring the script |

**No contract changes.** No schema-version bump. No new dependencies.

---

## Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | FX001-1 | Expand boot-time relevance filter from `engineering-harness \| tooling \| infra` to `engineering-harness \| tooling \| infra \| build \| config \| dependencies \| env \| auth \| tests \| observe`. Update both the HTML comment at L155-156 and the Step 4a algorithm clause at L218. | engineering-harness | `/Users/jordanknight/github/tools/skills/SDD/engineering-harness-v2/SKILL.md` | After running `engineering-harness-v2` against `skills/compound/schemas/fixtures/`, `grep -E "target: (build\|config)" docs/project-rules/engineering-harness.md` returns ≥1 line. | Workshop 007 RV-001 — **confirmed bug**. Closes retro `RV-001` (status: `suggested` → `encoded`). |
| [ ] | FX001-2 | Spec the `--json` output schema in `compound-3-harvest/SKILL.md` (exact shape per workshop 007 RV-002). Create `scripts/compound-value.sh` that reads JSON on stdin and prints the 6-line terminal view (Harness / Compound counts / Top friction / Next encoding). Add `compound-value` recipe to `justfile` that pipes stdin to the script. | compound + scripts | `/Users/jordanknight/github/tools/skills/compound/compound-3-harvest/SKILL.md` (modify) ; `/Users/jordanknight/github/tools/scripts/compound-value.sh` (new) ; `/Users/jordanknight/github/tools/justfile` (modify) | `echo '<sample-json-payload>' \| just compound-value` renders the 6-line terminal view per workshop 007. `compound-3-harvest/SKILL.md` documents the `--json` shape verbatim. | Workshop 007 RV-002 + Q2 RESOLVED (cross-CLI portable via stdin pretty-printer). Closes retro `RV-002`. Preserves workshop 006 KISS rule (no persisted index). |
| [ ] | FX001-3 | Add `## Validation` footer template to the `[e]ncode` action in `compound-2-bubble/SKILL.md`. Every staged diff at `scratch/encode-<id>-<target>.diff` must end with a `## Validation` block containing `Run:`, `Expected:`, and `Compound lifecycle:` sub-sections. | compound | `/Users/jordanknight/github/tools/skills/compound/compound-2-bubble/SKILL.md` | After a seeded `[e]ncode` flow, `grep -A 8 "^## Validation" scratch/encode-*.diff` shows a populated Run/Expected/Lifecycle block. | Workshop 007 RV-003. Closes retro `RV-003`. Purely additive to encode-flow template. |

---

## Workshops Consumed

- **Primary**: [`workshops/007-post-launch-review-fixes.md`](../workshops/007-post-launch-review-fixes.md) — Group A authoritative source (RV-001 / RV-002 / RV-003 blocks)
- **Referenced**: [`workshops/006-compound-folder-layout.md`](../workshops/006-compound-folder-layout.md) — KISS "no on-disk index" rule that RV-002 must preserve
- **Referenced**: [`workshops/005-universal-retro-contract.md`](../workshops/005-universal-retro-contract.md) — `kind=improvement-suggestion` + `status=encoded` lifecycle used by all three closure retros

---

## Acceptance

- [ ] **FX001-1**: After running `engineering-harness-v2` against the 5 fixtures in `skills/compound/schemas/fixtures/`, `docs/project-rules/engineering-harness.md` shows entries with `target: build` and `target: config` under `## Known Difficulties`.
- [ ] **FX001-2**: `echo '{"retros":27,"entries":{"total":47,"open":28,"suggested":2,"encoded":17},"top_clusters":[{"kind":"difficulty","target":"tooling","count":4,"representative":"grep on src/ took 47s"}],"harness":{"maturity":"L2","last_validation":"2026-05-18","boot_ms":18000,"verdict":"healthy"}}' | just compound-value` produces a 6-line terminal view starting with `Harness: L2, last validation HEALTHY, boot 18s`.
- [ ] **FX001-3**: `compound-2-bubble [e]ncode` flow against a seeded buffer entry produces a diff under `scratch/encode-*.diff` whose final section is `## Validation` containing populated `Run:` / `Expected:` / `Compound lifecycle:` lines.
- [ ] **Cross-cutting**: `just install-skills-from-source` succeeds — none of the SKILL.md edits break the `npx skills` install path.
- [ ] **Compound loop closure**: Three retro entries with `id=RV-001`, `id=RV-002`, `id=RV-003`; `kind=improvement-suggestion`; `status=encoded`; `resolved_by=<commit-sha>` exist under `docs/compound/agents/<orchestrator-slug>/2026-05-1*/T*.retro.md`. **This is the literal compounding test for plan 023 — workshop 007 promised the loop closes; this fix proves it.**

---

## Out of Scope (tracked elsewhere)

| RV-ID | Topic | Where it goes |
|-------|-------|--------------|
| RV-004 | Optional `evidence:` pointers + schema v1.1.0 bump | **FX002** (Group B — schema bump batch) |
| RV-005 | Reduce mandatory confirmation in engineering-harness-v2 CREATE mode | **FX002** (Group B — same batch as RV-004) |
| RV-006 | Cluster → regression-proof pattern (opt-in only, 4 guardrails) | **FX003** or plan 025 — defer until plan 023 T028 dogfood signal |
| RV-007 | Move deterministic harvest logic to scripts | **FX003** or plan 025 — gated on Q1 (does `npx skills` preserve `scripts/` subdirs under a skill?) |

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| RV-001 filter widening surfaces noisy/irrelevant entries | Low | Low | The 7 new targets are all genuinely boot-relevant per workshop 007. If real dogfood shows noise, narrow back in FX002. |
| `scripts/compound-value.sh` duplicates harvest logic | Low | Low | The script is a pretty-printer only — it consumes JSON, doesn't compute. Real harvest stays in the skill. RV-007 (FX003) will properly extract harvest logic if needed. |
| Validation footer template adds review friction | Low | Low | Footer is on the staged diff in scratch — the reviewer sees it once. If real usage shows it's noise, simplify in FX002. |
| `npx skills` install breaks on the SKILL.md edits | Very low | Medium | Run `just install-skills-from-source` as part of acceptance. Existing recipe surfaces install errors. |

---

## Compound Tracking

When this fix lands, three retro entries are produced — one per RV — under the orchestrator's per-run directory:

```yaml
# Shape — actual emitted by plan-6a-v2-update-progress on completion
id: RV-001
kind: improvement-suggestion
target: engineering-harness
description: |
  Widened boot-time relevance filter to capture build/config/dependencies/env/auth/tests/observe targets.
  Prior filter dropped 3 of 5 fixture target classes silently.
status: encoded
linked_workshop: docs/plans/023-difficulty-ledger-skill/workshops/007-post-launch-review-fixes.md
linked_fix: docs/plans/023-difficulty-ledger-skill/fixes/FX001-group-a-quick-wins.md
resolved_by: <commit-sha>
```

Repeat for `RV-002` (target: compound) and `RV-003` (target: compound).

These three encoded retros are the **proof-by-existence** that the compounding loop from plan 023 works:
- Action chosen (review feedback → workshop → fix dossier)
- Entry encoded with `resolved_by` SHA
- Subsequent session will surface these encoded entries via `just compound-value`
- The user (you) did not disable the system

That's all four of the 4 Compounding Test signals from plan 023 spec, demonstrated on plan 023 itself.

---

## Discoveries & Learnings

_Populated during implementation._

| Date | Task | Type | Discovery | Resolution |
|------|------|------|-----------|------------|
| | | | | |
