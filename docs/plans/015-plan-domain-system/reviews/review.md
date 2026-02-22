# Review Report — Plan Domain System (Simple Mode)

- **Plan**: `/home/jak/github/tools/docs/plans/015-plan-domain-system/plan-domain-system-plan.md`
- **Execution Log**: `/home/jak/github/tools/docs/plans/015-plan-domain-system/execution.log.md`
- **Diff Source**: Working tree vs `HEAD` (tracked + untracked phase targets) → `reviews/_computed.diff`
- **Testing Approach**: Manual
- **Mock Usage**: N/A

## A) Verdict

**REQUEST_CHANGES**

Blocking reasons: critical graph-integrity gaps, acceptance-criteria contradictions (AC8/AC9), and multiple installer correctness/observability defects.

## B) Summary

1. Simple-mode artifacts exist and phase scope is mostly correct, but graph traceability is broken (no footnote ledger/tags/node IDs).
2. A critical semantic mismatch exists: source uses `plan-v2-extract-domain.md` while plan/spec expect `extract-domain.md`.
3. AC8/AC9 are marked complete in execution log but artifacts still contain Footnote and PlanPak concepts.
4. `install/agents.sh` has high-severity idempotency/accounting and failure-handling defects for v2 flows.
5. Coverage confidence for AC evidence is **55.56%** (MEDIUM): several checks are narrative claims without durable artifacts.
6. Shell syntax checks passed (`bash -n`).

## C) Checklist

**Testing Approach: Manual**

- [x] Manual verification steps documented
- [ ] Manual test results recorded with concrete observed outputs
- [ ] All acceptance criteria manually verified without contradiction
- [ ] Evidence artifacts present for each key claim (logs/output listings)

**Universal**

- [ ] Bridge/domain doctrine gates pass without HIGH/CRITICAL findings
- [x] Only in-scope implementation files changed (plus justified dist mirrors)
- [x] Linters/type/syntax checks are clean (`bash -n`)
- [ ] No hidden-context portability assumptions in artifacts

## D) Findings Table

| ID | Severity | File:Lines | Summary | Recommendation |
|----|----------|------------|---------|----------------|
| F001 | CRITICAL | `plan-domain-system-plan.md` + `execution.log.md` | Missing Change Footnotes Ledger / task footnote tags / node IDs for traceability gate | Add ledger + `[^N]` task tags + node-ID mappings (or formally record doctrine deviation) |
| F002 | CRITICAL | `agents/v2-commands/plan-v2-extract-domain.md`, `agents/v2-commands/README.md` | Filename/command identity mismatch vs plan/spec (`extract-domain.md` expected) | Rename source file to `extract-domain.md`, update references, resync dist |
| F003 | HIGH | `agents/v2-commands/plan-6a-v2-update-progress.md:55-64` | Footnote workflow remains, contradicting AC8/Q2 | Remove footnote ledger instructions and keep domain/task progress tracking only |
| F004 | HIGH | `agents/v2-commands/plan-2-v2-clarify.md:9,68` | PlanPak references remain, contradicting AC9 | Replace PlanPak phrasing with domain-only language |
| F005 | HIGH | `execution.log.md:84-87` | AC8/AC9 verification claims conflict with actual artifacts | Re-run verification and update either artifacts or log claims |
| F006 | HIGH | `install/agents.sh:993-1005` (+ dist mirror) | Copilot idempotency count uses v1-only baseline after v2 install | Compare against v1+v2 expected total and include V2 source in extra-file check |
| F007 | HIGH | `install/agents.sh:1094-1127` (+ dist mirror) | No explicit failure handling around v2 Copilot CLI generation block | Wrap python block with explicit failure check and abort on error |
| F008 | MEDIUM | `agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md:9` | v1 reference remains in v2 command body (AC2 drift) | Remove comparative v1 wording in command body |
| F009 | MEDIUM | `install/agents.sh:685-745` (+ dist mirror) | Local `--commands-local copilot-cli` flow omits v2 generation | Generate Copilot CLI local agents from both v1 and v2 source dirs |
| F010 | MEDIUM | AC map (AC1..AC9) | Coverage confidence only 55.56%; several narrative claims | Capture deterministic manual evidence artifacts for each AC |
| F011 | LOW | `plan-domain-system-plan.md` absolute path rows | Host-specific path assumptions in plan text | Prefer repo-relative paths/placeholders in docs |

## E) Detailed Findings

### E.0) Cross-Phase Regression Analysis

**Skipped: Simple Mode (single phase).**

### E.1) Doctrine & Testing Compliance

#### Graph integrity (Step 3a, Simple Mode validators)

| ID | Severity | Link Type | Issue | Expected | Fix | Impact |
|----|----------|-----------|-------|----------|-----|--------|
| G1 | CRITICAL | Task↔Footnote | Plan-level Change Footnotes Ledger missing | Ledger exists with sequential footnotes | Add ledger section and initialize `[^1]` | Provenance graph cannot be traversed |
| G2 | HIGH | Task↔Footnote | Completed tasks have no `[^N]` in Notes | Each changed-task row references a footnote | Add `[^N]` tags for T001–T012 | Task→change linkage broken |
| G3 | CRITICAL | Footnote↔File | No ledger/node IDs to validate | FlowSpace node IDs mapped to changed files | Add node-ID entries per changed artifact | File-level traceability unavailable |
| G4 | HIGH | Footnote↔File | No node-ID references found | `(class\|method\|function\|file):path:symbol` entries | Add valid node IDs in ledger | Provenance links absent |
| G5 | MEDIUM | Task↔Footnote | No sequence initialized | Contiguous numbering from `[^1]` | Initialize numbering | Future collisions likely |

**Graph Integrity Verdict**: ❌ **BROKEN**

#### Authority conflicts (Step 3c)

Simple Mode has no separate dossier; Plan is authoritative.  
Current issue is not plan-vs-dossier drift, but missing ledger artifacts in the plan itself.

#### Doctrine validator synthesis (Step 4)

- **HIGH**: `extract-domain` filename mismatch (`plan-v2-extract-domain.md` vs required `extract-domain.md`).
- **HIGH**: Footnote concepts remain in `plan-6a-v2-update-progress.md`.
- **HIGH**: Plan compliance failures on T002/T008/T012 (artifact mismatch and contradictory verification claims).
- **MEDIUM**: PlanPak references remain; v1 wording remains in v2 command body.
- **LOW**: Portability concern from hardcoded absolute paths in plan text.

**Doctrine compliance score (excluding advisory E.4)**: **FAIL** (contains HIGH/CRITICAL).

#### Testing evidence (Step 5, Manual)

- Approach detected correctly as **Manual**.
- Manual evidence exists, but multiple AC checks are narrative-only and contradicted by artifacts.
- Overall coverage confidence: **55.56% (MEDIUM)**.

### E.2) Semantic Analysis (Subagent 1)

1. **CRITICAL** — Extract command identity drift violates plan/spec requirement for `extract-domain.md` and breaks source/dist parity.
2. **HIGH** — Footnote workflow remains in v2 progress command despite AC8 and Clarification Q2.
3. **MEDIUM** — Residual v1 comparative wording in v2 command body weakens standalone-v2 contract.

### E.3) Quality & Safety Analysis (Subagents 2–5)

**Safety Score: -114/100** (CRITICAL: 0, HIGH: 3, MEDIUM: 6, LOW: 2)  
**Verdict: REQUEST_CHANGES**

#### Correctness
- **HIGH**: Copilot prompt idempotency compares against v1-only `file_count` after v2 files are copied.
- **MEDIUM**: Local Copilot CLI install path omits v2 command generation.
- **MEDIUM**: v2 Copilot CLI frontmatter generation diverges from canonical generator behavior.

#### Security
- No concrete security vulnerabilities identified in the reviewed diff.

#### Performance
- **HIGH**: `plan-7-v2-code-review.md` anti-reinvention flow scales poorly (all domains + per-component searches).
- **MEDIUM**: `plan-1b-v2-specify.md` and `plan-3-v2-architect.md` include unbounded/overbroad preload patterns.

#### Observability
- **HIGH**: Missing explicit error handling around v2 Copilot CLI generation can yield misleading success outcomes.
- **MEDIUM**: Local install logs under-report totals after v2 additions.
- **LOW**: Filename logging is unsanitized; log hygiene improvement recommended.

### E.4) Doctrine Evolution Recommendations (Advisory; non-blocking)

**Summary**

| Category | New | Updates | Priority HIGH |
|----------|-----|---------|---------------|
| ADRs | 2 | 1 | 2 |
| Rules | 3 | 0 | 2 |
| Idioms | 3 | 0 | 0 |
| Architecture | 3 | 0 | 1 |

Key recommendations:
- Add ADR for domain system as canonical architecture boundary model.
- Add ADR/rule for v1+v2 coexistence/migration and filename parity across source/dist.
- Bootstrap `docs/project-rules/` baseline to support doctrine gates.

## F) Coverage Map (Acceptance Criteria ↔ Evidence)

| AC | Confidence | Classification | Evidence Result |
|----|------------|----------------|-----------------|
| AC1 | 75 | explicit | 9 files present but naming mismatch on extract command |
| AC2 | 25 | weak | Residual v1 wording remains in v2 artifacts |
| AC3 | 100 | explicit | `plan-3-v2-architect.md` at 274 lines |
| AC4 | 100 | explicit | 7-column table present in plan-5-v2 |
| AC5 | 75 | inferred | No `agents/commands/` file changes in computed diff |
| AC6 | 50 | behavioral | Sync/install logic added, but no captured setup runtime artifact |
| AC7 | 75 | explicit | Templates inline, but filename mismatch weakens confidence |
| AC8 | 0 | weak | Contradicted by footnote instructions in plan-6a-v2 |
| AC9 | 0 | weak | Contradicted by PlanPak references in v2 text |

**Overall coverage confidence**: **55.56% (MEDIUM)**  
**Narrative-only evidence flagged**: AC2, AC6, AC8, AC9 verification claims.

## G) Commands Executed

```bash
git --no-pager status --short
git --no-pager rev-parse --abbrev-ref HEAD
git --no-pager log --oneline --decorate -n 40 -- docs/plans/015-plan-domain-system

# computed diff
(tracked: git diff --unified=3 --no-color ...targets...)
(untracked: diff -u /dev/null <file> for agents/v2-commands and src/jk_tools/agents/v2-commands)

ls -1 agents/v2-commands
ls -1 src/jk_tools/agents/v2-commands
wc -l agents/v2-commands/*.md
rg -n "agents/commands|\\bv1\\b|PlanPak|TAD|Footnote" agents/v2-commands/*.md
rg -n "^\\+\\+\\+ " docs/plans/015-plan-domain-system/reviews/_computed.diff
bash -n install/agents.sh scripts/sync-to-dist.sh src/jk_tools/install/agents.sh src/jk_tools/scripts/sync-to-dist.sh setup.sh
```

## H) Decision & Next Steps

1. Apply `fix-tasks.md` in order (critical/high first).
2. Re-run manual verification and capture concrete output artifacts.
3. Re-run `/plan-6-implement-phase` for fixes, then rerun `/plan-7-v2-code-review`.
4. Approval requires zero HIGH/CRITICAL findings.

## I) Footnotes Audit

No footnote tags were found in the phase task table and no Change Footnotes Ledger was present in the plan.

| Diff-touched path | Footnote tag(s) in PHASE_DOC | Node-ID link(s) in plan ledger |
|---|---|---|
| `agents/v2-commands/README.md` | none | none |
| `agents/v2-commands/plan-1b-v2-specify.md` | none | none |
| `agents/v2-commands/plan-2-v2-clarify.md` | none | none |
| `agents/v2-commands/plan-3-v2-architect.md` | none | none |
| `agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md` | none | none |
| `agents/v2-commands/plan-6-v2-implement-phase.md` | none | none |
| `agents/v2-commands/plan-6a-v2-update-progress.md` | none | none |
| `agents/v2-commands/plan-7-v2-code-review.md` | none | none |
| `agents/v2-commands/plan-v2-extract-domain.md` | none | none |
| `install/agents.sh` | none | none |
| `scripts/sync-to-dist.sh` | none | none |
| `src/jk_tools/agents/v2-commands/README.md` | none | none |
| `src/jk_tools/agents/v2-commands/extract-domain.md` | none | none |
| `src/jk_tools/agents/v2-commands/plan-1b-v2-specify.md` | none | none |
| `src/jk_tools/agents/v2-commands/plan-2-v2-clarify.md` | none | none |
| `src/jk_tools/agents/v2-commands/plan-3-v2-architect.md` | none | none |
| `src/jk_tools/agents/v2-commands/plan-5-v2-phase-tasks-and-brief.md` | none | none |
| `src/jk_tools/agents/v2-commands/plan-6-v2-implement-phase.md` | none | none |
| `src/jk_tools/agents/v2-commands/plan-6a-v2-update-progress.md` | none | none |
| `src/jk_tools/agents/v2-commands/plan-7-v2-code-review.md` | none | none |
| `src/jk_tools/install/agents.sh` | none | none |
| `src/jk_tools/scripts/sync-to-dist.sh` | none | none |
