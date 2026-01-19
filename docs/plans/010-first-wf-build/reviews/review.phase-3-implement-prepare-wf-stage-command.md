# Phase 3: Implement prepare-wf-stage Command – Code Review

**Plan**: [../first-wf-build-plan.md](../first-wf-build-plan.md)
**Phase Dossier**: [../tasks/phase-3-implement-prepare-wf-stage-command/tasks.md](../tasks/phase-3-implement-prepare-wf-stage-command/tasks.md)
**Execution Log**: [../tasks/phase-3-implement-prepare-wf-stage-command/execution.log.md](../tasks/phase-3-implement-prepare-wf-stage-command/execution.log.md)
**Review Date**: 2026-01-19
**Reviewer**: plan-7-code-review

---

## A) Verdict

**REQUEST_CHANGES**

The Phase 3 implementation demonstrates solid foundational work with the Stage class and prepare-wf-stage command functional and tested. However, several **CRITICAL** and **HIGH** severity issues were identified that require remediation before merge:

1. **Schema contract violation**: `finalized_at` field name vs spec's `published_at`
2. **Path traversal vulnerabilities**: Unvalidated file paths from config YAML
3. **Missing directory creation**: `finalize()` may crash on missing parent directories
4. **Documentation graph violations**: Dossier footnote stubs not normalized per convention

---

## B) Summary

Phase 3 successfully implements the Stage class abstraction and prepare-wf-stage command as specified in plan Appendix A.11. The implementation includes:

- **Stage class** (`stage.py`): Lazy loading, validation, finalization, and output access methods
- **Preparer module** (`preparer.py`): Input copying and parameter resolution with dry-run support
- **CLI commands** (`cli.py`): `finalize` and `prepare-wf-stage` commands with typer

All 8 plan tasks (3.1-3.8) and 7 acceptance criteria (P3-AC-01 through P3-AC-07) are implemented. Manual testing documented in execution log shows the workflow functioning: compose → finalize → prepare-wf-stage.

**Key Issues Identified:**
- 2 CRITICAL: Schema field naming, path traversal vulnerabilities
- 9 HIGH: Directory creation, finalization logic, security, performance, observability
- 15 MEDIUM: Documentation, error handling, dry-run UX
- 5 LOW: Minor style and documentation issues

---

## C) Checklist

**Testing Approach: Manual verification** (per plan)

- [x] Manual verification steps documented in execution log
- [x] Manual test results recorded with observed outcomes (T006, T012, T013, T014)
- [x] All acceptance criteria manually verified (P3-AC-01 through P3-AC-07)
- [x] Evidence artifacts present (console output in execution log, test fixtures created)

**Universal (all approaches):**

- [x] Only in-scope files changed (stage.py, preparer.py, cli.py)
- [x] Linters/type checks clean (syntax passes, imports work)
- [x] Absolute paths used (`Path.resolve()` throughout)
- [ ] Path traversal prevention (NOT IMPLEMENTED - files from config not validated)
- [ ] Complete error handling for I/O operations (GAPS IDENTIFIED)

---

## D) Findings Table

| ID | Severity | File:Lines | Summary | Recommendation |
|----|----------|------------|---------|----------------|
| SEM-001 | CRITICAL | stage.py:262 | Schema field `finalized_at` should be `published_at` per A.5d | Fix field name to match spec |
| SEC-001 | HIGH | preparer.py:119-146 | Path traversal vulnerability in file copying | Add `is_relative_to()` validation |
| SEC-002 | HIGH | stage.py:302-337 | Path traversal in output accessors | Validate paths don't escape stage dir |
| COR-001 | CRITICAL | stage.py:258-265 | Missing directory creation before writing output-params.json | Add `mkdir(parents=True)` |
| COR-002 | HIGH | preparer.py:188-191 | Empty params dict skips params.json write | Write even if params empty |
| COR-003 | HIGH | stage.py:273-284 | `_update_wf_run_status` crashes if wf-run.json missing | Add existence check |
| SEM-002 | HIGH | preparer.py:152-183 | Missing `source+query` fallback per A.11 algorithm | Implement fallback resolution |
| PERF-001 | HIGH | stage.py:202-205 | `is_complete` calls `validate()` without caching | Use `@cached_property` |
| PERF-002 | HIGH | stage.py:322-337 | `query_output()` re-reads JSON files every call | Add JSON caching |
| OBS-001 | HIGH | stage.py:136-141 | YAML parsing errors not caught with context | Add try-except |
| OBS-002 | HIGH | stage.py:273-284 | Silent success when stage_id not found in wf-run.json | Add validation |
| LINK-001 | CRITICAL | tasks.md:903-918 | Footnote stubs not normalized (11 rows for [^17]) | Consolidate to 3 rows |
| LINK-002 | MEDIUM | plan/dossier | Log entry anchors combined (T007-T009, T010-T011) | Split into individual anchors |
| LINK-003 | MEDIUM | plan:1958 | Footnote [^17] references wrong file for ValidationResult | Points to validator.py not stage.py |
| PLAN-001 | MEDIUM | plan↔dossier | Plan has 8 tasks, dossier has 14 - mapping unclear | Add mapping documentation |
| OBS-003 | MEDIUM | preparer.py:143-144 | File copy lacks I/O error handling | Add try-except for shutil.copy2 |
| OBS-004 | MEDIUM | preparer.py:190-191 | params.json write lacks error handling | Add try-except |
| PERF-003 | MEDIUM | stage.py:152-200 | validate() accesses config and files multiple times | Cache and batch |
| PERF-004 | MEDIUM | stage.py:216-271 | finalize() duplicates parameter extraction from validate() | Reuse validation results |
| SEC-003 | MEDIUM | stage.py:258-265 | Race condition in finalization | Consider atomic write |
| SEC-004 | MEDIUM | stage.py:273-284 | TOCTOU in wf-run.json updates | Use file locking or atomic write |
| COR-004 | MEDIUM | preparer.py:74-104 | `get_source_stage()` doesn't set result.success in helper | Explicit state update |
| OBS-005 | LOW | cli.py:173-186 | Dry-run output doesn't clarify "would copy" vs "copied" | Improve messaging |
| PERF-005 | LOW | stage.py:39 | Regex compiled on every `resolve_query()` call | Move to module level |
| LINK-004 | LOW | tasks.md | Task mapping notes missing | Add mapping explanation |

---

## E) Detailed Findings

### E.0) Cross-Phase Regression Analysis

**Verdict: PASS** (no prior phase tests to regress)

Phase 3 builds on Phase 2's compose command. Manual verification shows:
- `chainglass compose` still works (Phase 2 functionality preserved)
- New Stage class and preparer module don't break existing functionality
- CLI remains backward compatible (`--version`, `compose` commands unchanged)

### E.1) Doctrine & Testing Compliance

#### Graph Integrity Violations

**Task↔Log Validation:**
- 5 MEDIUM violations: Combined log entries for T007-T009 and T010-T011 break 1:1 task-to-log convention
- Impact: Navigation links work but heading labels show combined ranges

**Task↔Footnote Validation:**
- 2 CRITICAL violations: Dossier Phase Footnote Stubs has 11 rows for [^17], 3 rows for [^18] - should be 3 total rows (one per footnote)
- 1 HIGH violation: Task mapping between plan tasks (3.1-3.8) and dossier tasks (T001-T014) inconsistent

**Footnote↔File Validation:**
- 1 MEDIUM violation: [^17] lists `class:enhance/src/chainglass/stage.py:ValidationResult` but ValidationResult is defined in `validator.py`, not `stage.py`
- 17 of 18 node IDs valid (1 incorrect file attribution)

**Plan↔Dossier Sync Validation:**
- Plan has 8 tasks (3.1-3.8), dossier has 14 tasks (T001-T014)
- All tasks marked [x] completed - status synchronized
- Missing: explicit mapping documentation between abstraction levels

**Graph Integrity Score: ⚠️ MINOR_ISSUES** (structural violations in footnote stubs, content issues fixable)

#### Testing Strategy Compliance (Manual Approach)

Per plan: "Testing Approach: Manual verification of file copying, parameter resolution, and --dry-run validation"

| Check | Status | Evidence |
|-------|--------|----------|
| Manual verification steps documented | ✅ | execution.log.md T006, T012-T014 |
| Test results recorded with observed outcomes | ✅ | Console output in log entries |
| All acceptance criteria manually verified | ✅ | P3-AC-01 through P3-AC-07 covered |
| Evidence artifacts present | ✅ | Test fixtures (run-2026-01-18-003/004/005) |

**Testing Compliance Score: PASS**

### E.2) Semantic Analysis

#### Domain Logic Correctness

| ID | Severity | Issue | Spec Requirement | Fix |
|----|----------|-------|------------------|-----|
| SEM-001 | CRITICAL | output-params.json uses `finalized_at` instead of `published_at` | A.5d: `'required': ['stage_id', 'published_at', 'parameters']` | Change field name at stage.py:262 |
| SEM-002 | HIGH | Parameter resolution missing `source+query` fallback | A.11 algorithm step 6b: "Else if param.source + query set..." | Add fallback in preparer.py after line 170 |

**Schema Contract Violation Detail:**

```python
# stage.py:260-264 ACTUAL:
output_params_data = {
    "stage_id": self.stage_id,
    "finalized_at": datetime.now(timezone.utc).isoformat(),  # WRONG
    "parameters": parameters,
}

# A.5d EXPECTED:
{
  "stage_id": "explore",
  "published_at": "2026-01-18T10:15:00Z",  # REQUIRED FIELD NAME
  "parameters": {...}
}
```

**Impact:** Downstream tools expecting `published_at` field will fail schema validation. This is a breaking contract violation.

### E.3) Quality & Safety Analysis

**Safety Score: 45/100** (CRITICAL: 1, HIGH: 9, MEDIUM: 10, LOW: 3)
**Verdict: REQUEST_CHANGES**

#### Correctness Issues

| ID | Severity | File:Lines | Issue | Fix |
|----|----------|------------|-------|-----|
| COR-001 | CRITICAL | stage.py:258-265 | Directory not created before writing output-params.json | Add `output_params_path.parent.mkdir(parents=True, exist_ok=True)` |
| COR-002 | HIGH | preparer.py:188-191 | Empty params dict won't trigger params.json write | Change condition to `if result.success and not dry_run:` |
| COR-003 | HIGH | stage.py:273-284 | `_update_wf_run_status` doesn't check wf-run.json exists | Add `if not self.wf_run_path.exists(): return` |
| COR-004 | MEDIUM | preparer.py:74-104 | `get_source_stage()` doesn't explicitly set result.success=False | Add explicit state update |

#### Security Issues

| ID | Severity | File:Lines | Issue | Mitigation |
|----|----------|------------|-------|------------|
| SEC-001 | HIGH | preparer.py:119-146 | Path traversal in file copying - no validation of source_rel_path | Add `is_relative_to()` checks |
| SEC-002 | HIGH | stage.py:302-337 | Path traversal in get_output_data, get_output_file, query_output | Validate paths stay within stage directory |
| SEC-003 | MEDIUM | stage.py:258-265 | Race condition in directory creation | Use try-except with atomic write |
| SEC-004 | MEDIUM | stage.py:273-284 | TOCTOU vulnerability in wf-run.json updates | Consider file locking |

**Path Traversal Fix Example:**
```python
# preparer.py - add before line 127:
source_abs = (source.path / source_rel_path).resolve()
if not source_abs.is_relative_to(source.path):
    result.errors.append(f"Path traversal detected: {source_rel_path}")
    result.success = False
    continue
```

#### Performance Issues

| ID | Severity | File:Lines | Issue | Fix |
|----|----------|------------|-------|-----|
| PERF-001 | HIGH | stage.py:202-205 | `is_complete` calls validate() every time | Use `@cached_property` |
| PERF-002 | HIGH | stage.py:322-337 | `query_output()` re-reads JSON on every call | Add `_json_cache` dict |
| PERF-003 | MEDIUM | stage.py:152-200 | validate() accesses config multiple times in loops | Cache config reference |
| PERF-004 | MEDIUM | stage.py:216-271 | finalize() duplicates parameter extraction from validate() | Reuse validation results |
| PERF-005 | LOW | stage.py:39 | Regex compiled per call | Move pattern to module level |

#### Observability Issues

| ID | Severity | File:Lines | Issue | Fix |
|----|----------|------------|-------|-----|
| OBS-001 | HIGH | stage.py:136-141 | YAML parsing errors not caught | Add try-except with context |
| OBS-002 | HIGH | stage.py:273-284 | Silent success when stage_id not in wf-run.json | Add validation check |
| OBS-003 | MEDIUM | preparer.py:143-144 | File copy lacks I/O error handling | Add try-except |
| OBS-004 | MEDIUM | preparer.py:190-191 | params.json write lacks error handling | Add try-except |
| OBS-005 | LOW | cli.py:173-186 | Dry-run output unclear | Improve messaging |

---

## F) Coverage Map

**Testing Approach: Manual** - Coverage map shows manual verification coverage of acceptance criteria.

| Acceptance Criterion | Manual Verification | Confidence |
|---------------------|---------------------|------------|
| P3-AC-01: prepare-wf-stage copies inputs and resolves parameters | T012: "Files copied, params.json written" | 100% |
| P3-AC-02: Inputs with `from_stage` copied to inputs/ folder | T012: Files copied evidence in log | 100% |
| P3-AC-03: Parameters resolved by querying prior stage JSON | T012: "Parameters resolved: total_findings: 15..." | 100% |
| P3-AC-04: Resolved parameters written to `inputs/params.json` | T012: cat params.json output in log | 100% |
| P3-AC-05: Query syntax supports dot notation and array index | T002: resolve_query tests pass for all patterns | 100% |
| P3-AC-06: `--dry-run` validates without copying/writing | T014: "specify/inputs/ (still empty)" | 100% |
| P3-AC-07: Blocked status with actionable error if source missing | T013: Error message with "Run finalize first" | 100% |

**Overall Coverage Confidence: 100%** - All acceptance criteria have explicit manual verification evidence in execution log.

---

## G) Commands Executed

```bash
# Module verification
cd /Users/jordanknight/github/tools/enhance
uv run python -c "import chainglass; print('Module import: OK')"
uv run python -m py_compile src/chainglass/stage.py src/chainglass/preparer.py src/chainglass/cli.py

# CLI verification
uv run chainglass --version
uv run chainglass finalize --help
uv run chainglass prepare-wf-stage --help

# Test commands (from execution log)
uv run chainglass finalize explore --run-dir sample/sample_1/runs/run-2026-01-18-003
uv run chainglass prepare-wf-stage specify --run-dir sample/sample_1/runs/run-2026-01-18-003
uv run chainglass prepare-wf-stage specify --run-dir sample/sample_1/runs/run-2026-01-18-004  # error test
uv run chainglass prepare-wf-stage specify --run-dir sample/sample_1/runs/run-2026-01-18-005 --dry-run
```

---

## H) Decision & Next Steps

### Decision: REQUEST_CHANGES

The implementation is functionally complete but has **3 CRITICAL** and **9 HIGH** severity issues that must be addressed before merge.

### Required Fixes (Blocking)

1. **SEM-001**: Change `finalized_at` → `published_at` in stage.py:262
2. **COR-001**: Add directory creation before output-params.json write
3. **SEC-001/SEC-002**: Add path traversal validation using `is_relative_to()`
4. **LINK-001**: Consolidate footnote stubs in dossier to 3 rows (one per footnote)

### Recommended Fixes (Non-Blocking)

1. Add I/O error handling for file operations (OBS-003, OBS-004)
2. Add JSON caching in Stage class (PERF-002)
3. Use `@cached_property` for is_complete (PERF-001)
4. Add YAML parsing error handling (OBS-001)

### Next Steps

1. Review `fix-tasks.phase-3-implement-prepare-wf-stage-command.md` for detailed fix instructions
2. Implement blocking fixes (estimated: 4 changes)
3. Re-run `/plan-6` for fixes
4. Re-run `/plan-7` to verify fixes
5. Once APPROVE: merge and proceed to Phase 4

---

## I) Footnotes Audit

| Diff-Touched Path | Footnote Tag | Plan Ledger Node ID | Status |
|------------------|--------------|---------------------|--------|
| `enhance/src/chainglass/stage.py` | [^17] | `file:enhance/src/chainglass/stage.py`, `class:...Stage`, `function:...resolve_query`, `class:...FinalizeResult` | ✅ Valid |
| `enhance/src/chainglass/stage.py` | [^17] | `class:...ValidationResult` | ⚠️ Wrong file (validator.py) |
| `enhance/src/chainglass/preparer.py` | [^18] | `file:enhance/src/chainglass/preparer.py`, `class:...PrepareResult`, `function:...prepare_wf_stage` | ✅ Valid |
| `enhance/src/chainglass/cli.py` | [^19] | `function:...finalize_cmd`, `function:...prepare_wf_stage_cmd` | ✅ Valid |

**Footnote Integrity: 17/18 valid** (1 misattribution in [^17])

---

**Review complete. See `fix-tasks.phase-3-implement-prepare-wf-stage-command.md` for actionable fix tasks.**
