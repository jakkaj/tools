# Fix Tasks — 014-lite-agent-flows (REQUEST_CHANGES)

Testing approach: **Lightweight**. Fix order is critical-path first; rerun grep validation gates after each batch.

## 1) CRITICAL — Spec Contract Alignment

### FT-001 (CRITICAL)
- **Files:** `agents/commands-lite/*` (all 12), plan/spec references
- **Issue:** Output path does not match spec contract (`agents/commands/lite/` vs `agents/commands-lite/`).
- **Fix:** Either move files to `agents/commands/lite/` and update references, or formally amend spec+plan ACs to the delivered directory and rebaseline.
- **Patch hint:**
```diff
- agents/commands-lite/
+ agents/commands/lite/
```
- **Validation:** `test -d agents/commands/lite && ls agents/commands/lite/*.md | wc -l`

### FT-002 (CRITICAL)
- **Files:** `docs/plans/014-lite-agent-flows/lite-agent-flows-plan.md`, `execution.log.md`
- **Issue:** Full-mode traceability graph artifacts missing for plan-7 strict linkage checks.
- **Fix:** Choose one path and apply consistently:
  1) Convert plan metadata to Simple and align review contract to simple artifacts, or
  2) Generate full-mode dossiers/backlinks (`tasks/<phase>/tasks.md`, task↔log metadata/anchors).
- **Validation:** rerun plan-7 link validators with zero CRITICAL/HIGH.

## 2) HIGH — Acceptance Criteria Regressions

### FT-003 (HIGH)
- **File:** `agents/commands-lite/plan-6-implement-phase.md`
- **Issue:** AC6 grep matches `/TAD` token.
- **Fix:** Replace slash-token wording with non-command token text.
- **Patch hint:**
```diff
-* Full TDD/TAD/Lightweight: ...
+* Full TDD, TAD, Lightweight: ...
```
- **Validation:** rerun AC6 grep; expect zero matches.

### FT-004 (HIGH)
- **Files:** `agents/commands-lite/plan-3-architect.md`, `plan-5-phase-tasks-and-brief.md`
- **Issue:** AC15 grep matches literal `[^` regex examples.
- **Fix:** Reword examples to avoid literal `[^` or narrow AC15 regex to real footnotes only.
- **Validation:** rerun AC15 grep; expect zero matches.

### FT-005 (HIGH)
- **Files:** `agents/commands-lite/plan-3-architect.md`, `plan-5-phase-tasks-and-brief.md`, `plan-6-implement-phase.md`, `plan-7-code-review.md`
- **Issue:** Lite still contains Full-mode/non-lite branches (`Mode: Full`, `PLAN_DIR/tasks/...`, non-lite review paths).
- **Fix:** Enforce simple-layout contracts in all lite commands; remove full/tad/hybrid branches where out-of-scope.
- **Validation:** `rg -n 'Mode: Full|PLAN_DIR/tasks' agents/commands-lite/*.md` should be empty or intentionally justified.

### FT-006 (HIGH)
- **Files:** `AGENTS.md`, `CLAUDE.md`, plan manifest/task tables
- **Issue:** Out-of-scope edits not declared.
- **Fix:** Either revert these edits from this feature diff, or add explicit cross-cutting classification in plan tasks/manifest/execution log.
- **Validation:** scope guard rerun has no unclassified files.

## 3) HIGH — Security/Correctness/Performance Hardening

### FT-007 (HIGH)
- **File:** `agents/commands-lite/plan-1a-explore.md`
- **Issue:** Plan path resolution not constrained to `docs/plans`.
- **Fix:** Canonicalize and enforce subpath containment before accepting user-provided plan path.
- **Validation:** add negative examples to docs/tests and verify rejected traversal inputs.

### FT-008 (HIGH)
- **File:** `agents/commands-lite/plan-6-implement-phase.md`
- **Issue:** Blocked tasks `[!]` can omit failure evidence.
- **Fix:** Require `log#anchor` + blocked task execution-log entry with failing command/error/unblock plan.
- **Validation:** simulate blocked task and verify traceability appears in log + notes.

### FT-009 (HIGH)
- **Files:** `agents/commands-lite/plan-5-phase-tasks-and-brief.md`, `plan-7-code-review.md`
- **Issue:** Reviewer fan-out and prior-phase checks can over-parallelize and time out.
- **Fix:** Add concurrency cap and staged triage (run core checks first, specialize only when needed).
- **Validation:** run on large diff; verify bounded reviewer count and stable completion.

## 4) MEDIUM — Governance and Documentation Consistency

### FT-010 (MEDIUM)
- **File:** `lite-agent-flows-plan.md`
- **Issue:** Plan status/AC checklist/next-step metadata inconsistent with completion.
- **Fix:** Update status lifecycle and AC checkboxes to align with actual verified state.

### FT-011 (MEDIUM)
- **File:** `lite-agent-flows-plan.md`
- **Issue:** Mock policy is not selected.
- **Fix:** Pick explicit policy (`No mocks` or `Targeted mocks`) and enforce in review command text.

### FT-012 (MEDIUM)
- **File:** `agents/commands-lite/GETTING-STARTED.md`
- **Issue:** Mixed shorthand command names may not resolve.
- **Fix:** Standardize to canonical names (`/plan-5-phase-tasks-and-brief`, `/plan-6-implement-phase`, `/plan-7-code-review`).

---

## Final Validation Bundle (run after fixes)
```bash
grep -riE 'flowspace|FlowSpace|fs2|flow_squared|flowspace-tree|flowspace-search|flowspace-get_node|flowspace-research' agents/commands-lite/*.md
grep -riE 'planpak|plan-pack|PlanPak|features/<' agents/commands-lite/*.md
grep -riE 'plan-ordinal|jk-po' agents/commands-lite/*.md
grep -riE '/plan-0-constitution|/plan-2-clarify|/plan-2b-prep-issue|/plan-3a-adr|/plan-4-complete-the-plan|/plan-5c-requirements-flow|/plan-6a-update-progress|/plan-6b-worked-example|/plan-8-merge|/planpak|/tad|/util-0-handover|/code-concept-search|/flowspace-research' agents/commands-lite/*.md
grep -riE 'footnote|Footnote|\[\^|Change Footnotes Ledger' agents/commands-lite/*.md
ls agents/commands-lite/*.md | wc -l
git --no-pager diff -- agents/commands/*.md | wc -l
```
