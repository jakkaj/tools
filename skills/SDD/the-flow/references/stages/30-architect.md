# Stage 30 — Architect
*(absorbed from `plan-3-v3-architect`; loaded lazily via `/the-flow 3` or `/the-flow architect` — dispatch: `../../SKILL.md`)*

**Purpose**: Generate a lean, domain-aware implementation plan with self-validating fail-fast gates (G1–G7) run inline during generation; the plan always emits, stamped `**Status**: READY` (all gates pass) or `**Status**: DRAFT — UNRESOLVED GAPS` (any gate fails, with inline `⚠️ GAP:` markers + a final `## Unresolved Gaps` table).
**Entry conditions**: Spec exists at `docs/plans/<ordinal>-<slug>/<slug>-spec.md` with critical clarifications resolved (or `--skip-clarify`). Optional pre-architect inputs in the plan dir: `research-dossier.md`, `workshops/*.md`, `backpressure-coverage.md` (the post-spec harness seam's output). Optional repo doctrine: `docs/project-rules/{rules.md, idioms.md, architecture.md, constitution.md}`, `docs/adr/*.md`, `docs/domains/*`.
**Inputs**: `FEATURE_SPEC` = spec path; `PLAN_PATH` = `docs/plans/<ordinal>-<slug>/<slug>-plan.md`; optional `--skip-clarify` (G1 override); today {{TODAY}}.
**Output contract**: Writes `PLAN_PATH` containing the Gate Matrix (G1–G7) + Status header — plus inline `⚠️ GAP:` markers and a final `## Unresolved Gaps` table on any gate FAIL. Terminal report: plan path · Status · phase/task/domain counts · gate tally · next step. Then **always** auto-runs `/validate-v2 --artifact "${PLAN_PATH}"` (real skill invocation), READY or DRAFT.
**Next routing**: READY + **Full Mode** → `/the-flow 5 --phase "<Phase 1: Title>" --plan "<PLAN_PATH>"` (module `references/stages/50-phase-tasks.md`); READY + **Simple Mode** → `/the-flow 6 --plan "<PLAN_PATH>"` (module `references/stages/60-implement.md` — inline tasks, no stage-50 expansion). DRAFT → fix gaps, then re-run `/the-flow 3` (module `references/stages/30-architect.md`; idempotent); G1 gaps via `/the-flow 1b` re-entry (module `references/stages/20-specify.md` § Re-entry: mid-plan clarifications); G4 gaps via `/the-flow 3a` (module `references/stages/35-adr.md`).

---

## Procedure

Generate a **lean, domain-aware implementation plan** with phases, task tables, acceptance criteria, AND **self-validating fail-fast gates** baked in. Replaces both the legacy `plan-3-v2-architect` and the bolt-on `plan-4-v2-complete-the-plan` validator — gates run inline and the plan emits in one of two states:

- **`**Status**: READY`** — all gates passed; Full Mode plans continue to `/the-flow 5` (module `references/stages/50-phase-tasks.md`), Simple Mode plans continue directly to `/the-flow 6` (module `references/stages/60-implement.md` — inline tasks).
- **`**Status**: DRAFT — UNRESOLVED GAPS`** — one or more gates failed. The plan is **still written** (the user has context to fix) but is annotated with inline `⚠️ GAP: <reason>` markers at each violation site, plus a final `## Unresolved Gaps` summary table.

The plan is always written. The user is never blocked from seeing it. But the status header + inline gap markers + summary table make it impossible to silently consume a broken plan downstream.

---

> Complexity: CS 1–5 only — no time estimates (rubric: `references/00-routing.md` § Shared conventions).

---

```md
Inputs:
  FEATURE_SPEC = `docs/plans/<ordinal>-<slug>/<slug>-spec.md`,
  PLAN_PATH    = `docs/plans/<ordinal>-<slug>/<slug>-plan.md`,
  rules at `docs/project-rules/{rules.md, idioms.md, architecture.md, constitution.md}` (if present),
  ADRs at `docs/adr/*.md` (if present),
  today {{TODAY}}.

## PHASE 0: Detect Mode & Load Context

**Mode Detection**:
- Check spec for `**Mode**: Simple` or `**Mode**: Full`
- Simple → single-phase plan with inline tasks
- Full → multi-phase plan

**Domain Loading**:
- Read `## Target Domains` from spec → capture as `SPEC_DOMAINS` (the set every gate downstream compares against)
- Load domain context per `references/00-routing.md` § Domain context loading.
- For each NEW domain → note the sketch from spec (Purpose, Boundary Owns/Excludes)

**Harness Loading** (router-only):
- Probe `test -f ~/.agents/skills/eng-harness-flow/SKILL.md` (fallback `~/.claude/skills/eng-harness-flow/SKILL.md`) — the harness is reached exclusively through the `/eng-harness-flow` router; never read governance docs or maturity levels yourself
- Check spec `## Clarifications` for harness decisions
- Harness provisioning is NEVER an SDD phase — when no harness exists, the router's setup track owns standing one up (suggest `/eng-harness-flow` to the user); the plan just uses standard testing

**ADR Loading** (NEW in v3):
- If `docs/adr/` exists → read all `docs/adr/*.md`
- Filter to `Status: Accepted` → capture as `ACCEPTED_ADRS`
- For each, note the constraint it imposes (what it requires / what it forbids)

## PHASE 1: Pre-Generation Gates

Each gate produces a PASS / FAIL / N/A verdict. FAILs do **not** block emission — they become inline `⚠️ GAP:` markers + entries in the final `## Unresolved Gaps` table + flip the plan's `**Status**` to `DRAFT — UNRESOLVED GAPS`.

### Gate G1 — Clarify
- If critical `[NEEDS CLARIFICATION]` markers remain in spec → **FAIL** with list of markers
- User can override with `--skip-clarify` → PASS with override note

### Gate G2 — Constitution (if `docs/project-rules/constitution.md` exists; else N/A)
- For each principle in the constitution, evaluate whether the planned approach violates it
- If any HIGH-impact violation has no entry in the Deviation Ledger → **FAIL**
- Deviation Ledger format (mandatory if violating):

| Principle Violated | Why Needed | Simpler Alternative Rejected | Risk Mitigation |
|-------------------|------------|------------------------------|-----------------|

### Gate G3 — Architecture (if `docs/project-rules/architecture.md` exists; else N/A)
- Check planned files/domains against layer boundaries and dependency rules
- Any violation without a documented exception → **FAIL**

### Gate G4 — ADR Compliance (if `ACCEPTED_ADRS` non-empty; else N/A)
- For each Accepted ADR: does the plan contradict its decision?
- Contradiction with no mitigation → **FAIL** with ADR reference (e.g. `ADR-007: requires X, plan does Y`)

## PHASE 2: Research

### Check for Existing Research

If `${PLAN_DIR}/research-dossier.md` exists:
- Read fully; extract critical findings
- Reduce to 1 research subagent (implementation-focused only)
- Reference findings throughout plan

If `${PLAN_DIR}/workshops/*.md` exist:
- Read all workshops — these are **authoritative design decisions**
- Do NOT contradict workshop decisions
- Skip research for workshopped topics

If `${PLAN_DIR}/backpressure-coverage.md` exists (produced via the post-spec harness seam — `/eng-harness-flow --event post-spec --spec <path>`):
- This is the **expected** pre-architect input — the recommended flow is spec → post-spec seam → architect, so the plan can be shaped by what's *provable by deterministic sensors* rather than by inference. Read it. Note its qualitative Certainty and its **Recommended Phase 0: Establish Backpressure** table (if present).
- Treat a Recommended Phase 0 as an **optional, user-decided** input to phase design (see § Phase Design Principles) — NOT a gate. Absence of this artifact changes nothing (no error, no Status change) — it's recommended, not required.

### Research Subagents (2 parallel)

**Subagent 1 — Domain & Pattern Scout**:
"What exists that this plan needs to know about?

Check:
1. `docs/domains/` — existing domain contracts and composition
2. Codebase patterns relevant to this feature
3. Integration points where new code connects to existing code
4. **Anti-reinvention**: Does any planned capability already exist? Scan `§ Concepts` tables across domains — concept matches are higher confidence than code-level matches.

For each proposed new component, check domain contracts and concepts:
- EXISTING → reuse (report contract and location)
- EXTEND → add to existing domain (report what to extend)
- NEW → create fresh (confirm no duplication)

Output: 4–6 findings, Critical and High impact only.
Format per finding: Title | Impact | What exists | What to do about it"

**Subagent 2 — Risk & Constraint Finder**:
"What could go wrong or surprise the implementor?

Check:
1. API limitations, framework gotchas
2. Spec ambiguities that affect implementation
3. Cross-domain dependencies needing coordination
4. Contract-breaking changes to existing domains

Output: 4–6 findings, Critical and High impact only.
Format per finding: Title | Impact | The risk | Mitigation"

**Wait for both. Merge into Key Findings table.**

## PHASE 3: Generate Plan

### Output Contract (MUST satisfy — these are the things G5/Structure validates)

The plan **MUST** contain these sections, in this order:

1. `# [Feature Name] Implementation Plan` (title)
2. Metadata block with: `Plan Version`, `Created`, `Spec` link, `**Status**` (READY or DRAFT — UNRESOLVED GAPS)
3. `## Gate Matrix` (inserted by Phase 4 — see below)
4. `## Summary` (3–5 sentences: problem, approach, expected outcome)
5. `## Target Domains` table — every domain in `SPEC_DOMAINS` MUST appear with status, relationship, role
6. `## Domain Manifest` table — every file mentioned in any phase task table MUST appear with domain + classification
7. `## Key Findings` table (from Phase 2 research)
8. `## Phases` containing `### Phase Index` table followed by per-phase blocks
9. `## Acceptance Criteria` (testable, derived from spec)
10. `## Risks` table
11. `## Harness Seams` (if the `/eng-harness-flow` router is installed — else omit cleanly)
12. `## Unresolved Gaps` (only if Status is `DRAFT — UNRESOLVED GAPS`; else omit)

Any required section that cannot be populated correctly → still emit the heading with inline `⚠️ GAP: <reason — see Unresolved Gaps table>` marker. **Never silently omit a required section.**

### Plan Output Format

```markdown
# [Feature Name] Implementation Plan

**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link to spec]
**Status**: READY | DRAFT — UNRESOLVED GAPS

## Gate Matrix

| Gate | Check | Status | Notes |
|------|-------|--------|-------|
| G1 | Clarify | PASS / FAIL | <details if FAIL> |
| G2 | Constitution | PASS / FAIL / N/A | <details if FAIL> |
| G3 | Architecture | PASS / FAIL / N/A | <details if FAIL> |
| G4 | ADR Compliance | PASS / FAIL / N/A | <ADR refs if FAIL> |
| G5 | Structure | PASS / FAIL | <missing sections if FAIL> |
| G6 | Testing Alignment | PASS / FAIL | <offending phases if FAIL> |
| G7 | Domain Completeness | PASS / FAIL | <missing items if FAIL> |

## Summary

[3–5 sentences]

## Target Domains

| Domain | Status | Relationship | Role |
|--------|--------|-------------|------|
| ... | existing/NEW | modify/create/consume | ... |

## Domain Manifest

| File | Domain | Classification | Rationale |
|------|--------|---------------|-----------|

Classification: `contract` (public interface), `internal` (domain-internal), `cross-domain` (editing another domain's files)

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|
| 01 | Critical | ... | ... |
| 02 | High | ... | ... |

## Phases

### Phase Index

| Phase | Title | Primary Domain | Objective (1 line) | Depends On |
|-------|-------|---------------|-------------------|------------|
| 0 | Establish Backpressure | — | [if applicable — see § Phase Design Principles] | None |
| 1 | ... | ... | ... | ... |
| N | ... | ... | ... | Phase N-1 |

[Then each phase in detail using Per-Phase Format below]

## Acceptance Criteria

- [ ] [Testable criterion from spec]
- [ ] [Testable criterion from spec]

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

## Harness Seams
[if the `/eng-harness-flow` router is installed — see below; else omit]

## Unresolved Gaps
[only if Status is DRAFT — UNRESOLVED GAPS — see Phase 4]
```

### Phase Design Principles

- Each phase should primarily target **ONE domain**. Multi-domain phases are permitted but each domain-touch is a separate task group.
- Domain creation phases come BEFORE domain extension phases.
- Composition/wiring phases come LAST.
- **Harness provisioning is never an SDD phase**: when no harness exists, the external router's setup track owns standing one up (`/eng-harness-flow` routes it) — never plan a "Build Agent Harness" phase. If explore-stage research (`/the-flow 1a`, module `references/stages/10-explore.md`) surfaced that no working dev substrate exists (no boot command, no test runner), surface it as a Critical Key Finding; the plan still uses standard testing.
- **If `${PLAN_DIR}/backpressure-coverage.md` recommends a Phase 0** (produced via the post-spec seam): include an **optional** "Phase 0: Establish Backpressure" whose tasks build the sensors named in that artifact's Recommended Phase 0 table (data-check scripts, dependency/architecture rules, smoke routes, CodeQL/Roslyn queries, schema checks). This is **advisory** — include it when the survey recommends it and the user wants the deterministic provability; **never gate on it and never flip Status to DRAFT for its absence**.
- **Surface the harness seams in every phase (router-only, best-effort)**: when the `/eng-harness-flow` router is installed (probe from § Harness Loading), each phase's task table should make the two seams `/the-flow 6` (module `references/stages/60-implement.md`) fires visible: a **pre-flight** task at phase start (`/eng-harness-flow --event pre-implement --phase <id> --plan-dir <p>`) and a **phase-end** task at phase end (`/eng-harness-flow --event phase-end --plan-dir <p>`). The router decides what (if anything) the harness does at each seam — never name its child skills. These are **advisory scaffolding, never gates**: no Status flip, no blocking, no thresholds. **If the router isn't installed, omit them entirely** and fall back to the plan's standard testing approach — a repo without a harness is fully supported.
- For each NEW domain, first phase includes domain setup task:
  - Create `docs/domains/<slug>/domain.md` (use format from `/extract-domain`)
  - Create source directory
  - Update `docs/domains/registry.md`
  - Update `docs/domains/domain-map.md` — add new domain node with exposed contracts + dependency edges

### Per-Phase Format

#### Phase N: [Title]

**Objective**: [One sentence]
**Domain**: [Primary domain]
**Delivers**: [Bullet list of concrete deliverables]
**Depends on**: [Prior phases or "None"]
**Key risks**: [1–2 sentences, or "None"]

| # | Task | Domain | Success Criteria | Notes |
|---|------|--------|-----------------|-------|
| N.0 | **Harness pre-flight** — `/eng-harness-flow --event pre-implement --phase "<Phase N>" --plan-dir <plan dir>` | — | Router envelope handled; verdict narrated verbatim before any code | _Harness seam — omit if router not installed_ |
| N.1 | [What to build] | [domain] | [How you know it works] | |
| N.2 | [What to build] | [domain] | [How you know it works] | Per finding 01 |
| N.z | **Harness phase-end** — `/eng-harness-flow --event phase-end --plan-dir <plan dir>` | — | Router envelope handled at phase end | _Harness seam — omit if router not installed_ |

> The `N.0` and `N.z` rows make the harness seams **visible in the plan** — they are advisory scaffolding `/the-flow 6` already auto-fires, surfaced here for legibility. The router owns what happens behind each seam; never name its child skills. **Include them only when the `/eng-harness-flow` router is installed; otherwise drop both rows entirely.** Never a gate.

### Harness Seams (if the `/eng-harness-flow` router is installed — else omit)

Make the harness touchpoints legible. Emit this section so the implementor sees where each seam fires across the phases:

```markdown
## Harness Seams
- **Entry point**: `/eng-harness-flow --event <seam> [--phase <id>] [--plan-dir <p>] --json` — the single door to the engineering harness; child skills are private and never named in this plan.
- **Backpressure** (post-spec seam): ran before this plan — see `backpressure-coverage.md` (Certainty: [Strong/Partial/Weak]). [Recommended Phase 0 folded in? yes/no]
- **Pre-implement** (`--event pre-implement`): fired by `/the-flow 6` at the start of each phase (the N.0 rows); verdicts narrated verbatim from the router's envelope (`healthy / SLOW / UNHEALTHY / UNAVAILABLE`). `UNAVAILABLE` is not an error — falls back to standard testing.
- **Phase end** (`--event phase-end`): fired by `/the-flow 6` at each phase seam (the N.z rows); `--event plan-complete` fires at merge (`/the-flow 8`).
- **Best-effort**: every item above is advisory and never blocks; the router decides what the harness does at each seam.
```

**Omit this section entirely** when the router isn't installed — a repo with no harness is fully supported and should see no harness scaffolding.

### Simple Mode

When `Mode: Simple`, generate a streamlined single-phase plan:

```markdown
# [Feature Name] Implementation Plan

**Mode**: Simple
**Plan Version**: 1.0.0
**Created**: {{TODAY}}
**Spec**: [link]
**Status**: READY | DRAFT — UNRESOLVED GAPS

## Gate Matrix
[as above]

## Summary
[2–3 sentences]

## Target Domains
[From spec]

## Domain Manifest
[File → Domain mapping]

## Key Findings

| # | Impact | Finding | Action |
|---|--------|---------|--------|

## Implementation

**Objective**: [One sentence]
**Testing Approach**: [From spec]

### Tasks

| Status | ID | Task | Domain | Path(s) | Done When | Notes |
|--------|-----|------|--------|---------|-----------|-------|
| [ ] | T001 | ... | ... | /abs/path | ... | |

### Acceptance Criteria
- [ ] ...

### Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|

## Unresolved Gaps
[only if Status is DRAFT — UNRESOLVED GAPS]
```

Simple Mode tasks use the 7-column format directly (no `/the-flow 5` expansion needed).

## PHASE 4: Self-Validation Gate Matrix & Emit

Before writing the plan file, run the post-generation gates (G5–G7), build the full Gate Matrix, and determine the Status.

### Gate G5 — Structure
- All required sections from the Output Contract present and populated? **FAIL** lists missing sections.
- Phase task tables present with success criteria? **FAIL** lists offending phases.
- Heading hierarchy correct (no skipped levels, no orphaned subsections)? **FAIL** describes the break.
- Cross-references resolve (e.g., "Per finding 01" — finding 01 actually exists)? **FAIL** lists broken refs.

### Gate G6 — Testing Alignment
- Read spec's `## Testing Strategy`. What approach? (Full TDD / Lightweight / Manual / Hybrid)
- If TDD: in every phase task table, do test tasks appear before implementation tasks? **FAIL** lists offending phases.
- If Lightweight: at least one basic validation task per phase? **FAIL** lists phases without one.
- If Manual: verification steps described per phase? **FAIL** lists phases without them.
- Acceptance criteria measurable (not vague — "works correctly" fails; "returns 200 on /health with `status: ok`" passes)? **FAIL** lists vague criteria.
- Mock usage intent matches spec preference (if specified)? **FAIL** describes mismatch.

### Gate G7 — Domain Completeness
- Is every domain in `SPEC_DOMAINS` present in the plan's Target Domains table with status + relationship + role? **FAIL** lists missing.
- For each NEW domain: does some phase have a domain setup task (create `domain.md`, source dir, registry entry, domain-map update)? **FAIL** lists NEW domains without setup tasks.
- Domain Manifest covers every file referenced in phase task tables? **FAIL** lists uncovered files.
- For each existing domain referenced in the plan: does the domain actually exist in registry? **FAIL** lists unknown domains.
- Domain Manifest classifications are consistent (`contract` / `internal` / `cross-domain`)? **FAIL** lists inconsistencies.
- If domain map exists: are new domains and edges consistent with topology (no circular business-domain deps; consumed-relationship domains have contracts identified)? **FAIL** describes the topology issue.
- NEW domains with contracts have `§ Concepts` planned (concepts identified during implementation per plan tasks)? **FAIL** lists missing.

### Determine Status

- All gates (G1–G7) PASS or N/A → `**Status**: READY`
- Any gate FAIL → `**Status**: DRAFT — UNRESOLVED GAPS`

### Emit Plan

1. Build the Gate Matrix table with each gate's verdict + one-line note.
2. For each FAIL: embed an inline `⚠️ GAP: <one-line reason — see Unresolved Gaps>` marker at the violation site in the plan body.
3. If any FAIL: append `## Unresolved Gaps` at the end of the plan:

   ```markdown
   ## Unresolved Gaps

   | Gate | Severity | Where in plan | What to fix |
   |------|----------|---------------|-------------|
   | G6 | HIGH | Phase 2 task table | Re-order: tests must precede impl per spec's TDD strategy |
   | G7 | HIGH | Target Domains table | Add `notifications` domain (in spec, missing from plan) |
   ```

4. Create parent directory if needed: `docs/plans/<ordinal>-<slug>/`
5. Write plan to: `docs/plans/<ordinal>-<slug>/<slug>-plan.md`
6. Report to terminal:

```
✅ Plan written: [path]
Status: READY | DRAFT — UNRESOLVED GAPS
Phases: [count]
Tasks: [count]
Domains: [count existing + count new]
Gate Matrix: [N PASS / M FAIL / K N/A]

(Deep validation via /validate-v2 auto-runs next — always, READY or DRAFT.)

[If READY + Simple Mode]
Next: /the-flow 6 --plan "<PLAN_PATH>" (module references/stages/60-implement.md — inline tasks)

[If READY + Full Mode]
Next: /the-flow 5 --phase "<Phase 1: Title>" --plan "<PLAN_PATH>" (module references/stages/50-phase-tasks.md)

[If DRAFT — UNRESOLVED GAPS]
Unresolved gaps listed at end of plan. Common fixes:
  - G1 Clarify FAIL → run /the-flow 1b re-entry (module references/stages/20-specify.md § Re-entry: mid-plan clarifications)
  - G2/G3 Constitution/Architecture FAIL → add deviation ledger entry OR rework approach
  - G4 ADR FAIL → run /the-flow 3a (module references/stages/35-adr.md) to add mitigation, or update plan to comply
  - G5 Structure / G6 Testing / G7 Domain FAIL → edit plan inline, then re-run /the-flow 3 (module references/stages/30-architect.md; idempotent)
Re-run /the-flow 3 after fixing to re-check gates.
```

### Auto-Run Deep Validation

After the plan is written, **always** auto-call the thesis-aware validator on the freshly written plan, regardless of Status:

```
/validate-v2 --artifact "${PLAN_PATH}"
```

This runs whether the plan emitted `Status: READY` or `Status: DRAFT — UNRESOLVED GAPS`. The inline G1–G7 gates are lightweight structural checks done during generation; `validate-v2` is the heavier multi-agent thesis/forward-compatibility review — they are complementary, not redundant. The validator's findings are applied or surfaced per its own flow; a DRAFT plan's already-known gaps will simply be reconfirmed alongside any deeper issues the validator finds.
```

Next step (when `Status: READY`, **Simple Mode**): Run **`/the-flow 6 --plan "<PLAN_PATH>"`** (module `references/stages/60-implement.md`) — inline tasks; deep validation has already run automatically
Next step (when `Status: READY`, **Full Mode**): Run **`/the-flow 5 --phase "<Phase 1: Title>" --plan "<PLAN_PATH>"`** (module `references/stages/50-phase-tasks.md`) — deep validation has already run automatically
Next step (when `Status: DRAFT — UNRESOLVED GAPS`): Address the gaps (see report above + validator findings), then re-run **`/the-flow 3`** (module `references/stages/30-architect.md`) to re-validate.
