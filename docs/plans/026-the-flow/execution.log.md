# Execution Log — 026-the-flow (Simple Mode, single phase)

**Plan**: [the-flow-plan.md](./the-flow-plan.md) · **Testing**: Lightweight (no mocks) · **Harness**: N/A (prose skill — Boot/Interact/Observe not applicable; recorded in spec § Clarifications)

Pre-phase agent-harness validation skipped: no `docs/project-rules/engineering-harness.md` and the spec records harness N/A for building a prose skill. Compound sentinel `docs/compound/.disabled` absent → compound active, but there is no running-software friction surface here.

---

## T001 — Skill mechanics (frontmatter + re-entrant main loop + state contract + idempotency + adoption entry)
**Status**: ✅ complete → `skills/SDD/the-flow/SKILL.md`

- Frontmatter `name: the-flow` (matches leaf folder), description explicitly drives `plan-*` and disclaims `sdd-tutorial` (RPIV).
- Main loop with **three entry paths**: glob active state → 1=resume / >1=list+ask / 0 → (artifacts present → **adopt**; else **fresh start**). `<slug>` arg overrides the scan.
- Fresh start: allocate ordinal (`plan-ordinal`/`jk-po`, local-scan fallback) → derive slug (kebab of first ~3–5 significant words) → `mkdir` → write verbatim `original-ask.md` (shape included) → write state → init `the-flow.json` → issue `/plan-1a`/`/plan-1b`.
- State contract `.the-flow-state.json` transcribed from workshop 001 § State Contract; **temp-file + atomic rename** documented.
- **Idempotency rule** (found→advance once / not-found→reprint pending, no advance) — direct lift from `sdd-tutorial-next`.

## T002 — Skill content (rail + stage machine + 11 narration blocks + handshake + harness cues + invariants + AC-20)
**Status**: ✅ complete → same `SKILL.md`

- **Host rail rule (D5)** with Stage→rail map; rail present on every narration block (audit: 22 `[the-flow]` occurrences, ≥3 required).
- Stage machine + **Routing Table** (all 11 stages) + **11 narration blocks** (audit: `grep -cE '^### \`(start|awaiting-|complete)'` = 11), Orient→Suggest→Invite.
- Optional-branch one-liners (D7): deep-research tool-of-choice at `awaiting-1a`, plus `/plan-3a`/prework/fix-loop/domains/`/util-0-handover`.
- Companion/worker affordance (D10) at the build seam; `/compact` handshake (lines 20/360); harness cues (boot-before/drain-after) + `.disabled` sentinel.
- **AC-20** agent self-mirroring (todos synced to rail + re-invoke `/the-flow` after `/compact`/fresh session) — § "Tell the agent to mirror the flow".
- Invariants block lists all four (no code/merge; no self-invoke `/plan-*`; no gate/score; optional branches) + the minih + mermaid-source invariants.

## T003 — Catalog docs
**Status**: ✅ complete → `README_AGENTS.md` (count 27→28 + row after `sdd-tutorial`), `docs/skills-pipeline/README.md` (front-door row).

## T004 — Pipeline map mention
**Status**: ✅ complete → `getting-started.md`: § Big Picture front-door callout + Quick-Reference `/the-flow` row.

## T006 — Flight-plan DAG + shipped schema/templates
**Status**: ✅ complete → `skills/SDD/the-flow/references/{flight-plan.schema.json, flight-plan.template.json, flight-plan.template.md}`.

- Schema encodes the **full** node + `agents[]` field set from workshop 002 (required `id` + `phase/iterations/tool/runtime/note`), `$comment` marks it reference-only.
- **Real conformance test (no mocks)**: `jsonschema` is installed → `flight-plan.template.json` **and** `references/sample-the-flow.json` both **VALIDATE** against `flight-plan.schema.json` (14 nodes / 2 agents each; no unknown-field rejection). This closes the validator's HIGH "schema rejects its own sample" finding.
- Hand-crank cadence + render rules transcribed into SKILL.md § Flight plan.

## T007 — Mid-plan adoption (late-join)
**Status**: ✅ complete → `SKILL.md` § Adoption Contract.

- Trigger, folder resolution (>1→list+ask), full artifact→stage inference table (incl. partial-phase `awaiting-6`/`/plan-7`, spec-only `mode:unknown`), back-fill field handling (mtime `ran_at`, `reconstructed` flag), no-clobber safety (`original-ask.reconstructed.md`, merge-not-overwrite `the-flow.json`), confirmable-suggestion framing.

## T005 — Validation (Lightweight, no mocks)
**Status**: ✅ complete

| Check | Result |
|-------|--------|
| `bash scripts/check-skill-slugs.sh` | **OK: 34 skills, no slug collisions** (exit 0) |
| frontmatter `name` ↔ folder | `the-flow` == `the-flow` ✅ |
| `the-flow` in 3 docs | README_AGENTS (1), skills-pipeline (1), getting-started (2) ✅ |
| shipped references present | schema + template.json + template.md ✅ |
| **schema conformance** | template.json + sample-the-flow.json both **VALID** vs schema (jsonschema, real test) ✅ |
| AC body audit (grep) | AC-2/3/4/5/6/7/8/9/10/12/13/14/15/16/17/18/19/20 all present ✅ |
| 11 narration blocks / 22 rail prefaces | ✅ |

**Dry-run walkthrough (≥3 stages, dogfood `026-the-flow`)** — traced against the SKILL.md routing table:
1. **Adoption entry (AC-18)**: invoking `/the-flow` here (no `.the-flow-state.json`, but `the-flow-spec.md` + `the-flow-plan.md` + this `execution.log.md` present) → Adoption Contract triggers → folder resolves to `026-the-flow` → inference: plan present + `**Mode**: Simple` + Phase building → stage `awaiting-6`, `pending_command` ≈ `/plan-7`; back-fills `the-flow.json/.md`; **`original-ask.md` absent here so it would write the verbatim/`reconstructed` file (no clobber)**. Presented as a confirmable suggestion.
2. **Idempotency two-branch (AC-5)**: re-running `/the-flow` with no new artifact since `last_checkpoint_at` → reprints `pending_command`, **does not advance**. After the user runs the next `/plan-*` and a new artifact appears → advances exactly once.
3. **`/compact` re-entry (AC-7)**: after `/compact`, `/the-flow` (no args) globs active state → finds the flow → same-stage idempotent re-print. Handshake phrasing verified: "type `/compact` yourself, then re-run `/the-flow`."
- **`.disabled` (AC-8)**: harness-narration sections are all guarded by the `docs/compound/.disabled` sentinel check (silently skipped when present).

---

## Acceptance Criteria → status
All 20 ACs (AC-1..AC-20) satisfied — see plan § Acceptance Criteria (all checked) and the audits above.

## Discoveries & Learnings
| # | Discovery | Why it matters |
|---|-----------|----------------|
| OH-001 | `jsonschema` **is** installed in this env, so the AC-19 "validates by inspection" became a real automated conformance test for free. | The schema↔sample contract is now machine-verified, not eyeballed — directly retires the validator's HIGH finding. |
| OH-002 | The plan dogfoods adoption: `026-the-flow` itself is a spec+plan-bearing folder with no `.the-flow-state.json`, so it's a live adoption fixture (no mock needed). | Confirms the late-join path against a real in-flight plan, exactly the "run part-way through" case the user asked for. |
| OH-003 | Moving `getting-started.md` into the the-flow skill folder (user follow-up) turns the SKILL.md's external doc reference into an in-skill `references/` pointer — tighter, and the doc travels with the skill that voices it. | Reduces a cross-skill dependency; handled post-build with reference fix-ups. |
