# Code Review: Subtask 001 - Preflight Command

**Plan**: first-wf-build-plan.md
**Phase**: Phase 4: Implement validate Command
**Subtask**: 001-subtask-preflight-command
**Date**: 2026-01-19
**Reviewer**: AI Code Review Agent

---

## A) Verdict

**REQUEST_CHANGES**

Two HIGH severity security/correctness issues require attention before merge.

---

## B) Summary

The preflight command implementation is **functionally complete** and **fully compliant** with the approved subtask dossier. All 7 tasks (ST001-ST007) are implemented correctly with proper testing evidence documented. The two-phase validation pattern (DYK-01), actionable error messages (DYK-04), and wf.md update (DYK-02) are all correctly implemented.

However, the review identified **2 HIGH severity issues** related to:
1. **TOCTOU race condition** in file existence/stat checks
2. **Missing path security validation** for `source_path` in Phase 2

These are defensive fixes that don't break existing functionality but address real edge cases.

---

## C) Checklist

**Testing Approach: Manual** (per project guidelines - no TDD overhead)

- [x] Manual verification steps documented in execution log
- [x] Manual test results recorded with observed outcomes (ST006, ST007)
- [x] All acceptance criteria manually verified
- [x] Evidence artifacts present (command output in execution log)

**Universal (all approaches)**:
- [x] BridgeContext patterns followed (N/A - not VS Code extension)
- [x] Only in-scope files changed (preflight.py, cli.py, wf.md)
- [ ] Linters/type checks are clean (not verified - recommend running `mypy`)
- [x] Absolute paths used (typer resolve_path=True, Path.resolve())

---

## D) Findings Table

| ID | Severity | File:Lines | Summary | Recommendation |
|----|----------|------------|---------|----------------|
| SEC-001 | HIGH | preflight.py:337-339 | Missing is_relative_to() check on source_path | Add path security validation |
| CORR-001 | HIGH | preflight.py:172-183, 234-250 | TOCTOU race: exists() then stat() pattern | Use single stat() with try/except |
| PERF-001 | MEDIUM | preflight.py:303,380 | Redundant JSON reads for output-params.json | Cache parsed JSON per source stage |
| PERF-002 | MEDIUM | preflight.py:156-197, 234-250 | Double stat() calls (exists + stat) | Use single stat() pattern |
| CORR-002 | LOW | cli.py:257-258 | Potential None action field in output | Add defensive null check |

---

## E) Detailed Findings

### E.0) Cross-Phase Regression Analysis

**Skipped**: Subtask review (no prior subtask phases to regress against)

---

### E.1) Doctrine & Testing Compliance

#### Graph Integrity ✅ INTACT

| Link Type | Status | Notes |
|-----------|--------|-------|
| Task↔Log | ✅ PASS | All 7 tasks have execution log entries |
| Task↔Footnote | ✅ PASS | 5 footnote stubs covering ST001-ST007 |
| Footnote↔File | ✅ PASS | All files exist at specified paths |

#### Plan Compliance ✅ FULL COMPLIANCE

- All 6 Goals implemented correctly
- All 4 Non-Goals correctly excluded
- All 6 Acceptance Criteria satisfied
- All 5 DYK decisions (DYK-01 through DYK-05) incorporated
- Zero scope creep, zero gold-plating

---

### E.2) Quality & Safety Analysis

**Safety Score: 45/100** (CRITICAL: 0, HIGH: 2, MEDIUM: 3, LOW: 1)
**Verdict: REQUEST_CHANGES**

#### SEC-001 [HIGH] - Missing Path Security in Phase 2

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py`
**Lines**: 337-339

**Issue**: In Phase 2, `source_file_path` is constructed from potentially untrusted `source` field without `is_relative_to()` validation.

**Evidence**:
```python
source_file_path = source_stage_path / source_path  # Line 339
# No security check follows - file accessed directly at line 341
```

**Impact**: An attacker controlling stage-config.yaml could include malicious paths like `../../../etc/passwd` in the `source` field to read files outside intended directories.

**Fix**: Add path security validation after line 339:
```python
source_file_path = source_stage_path / source_path
# Security: validate path is within source stage
if not source_file_path.resolve().is_relative_to(source_stage_path.resolve()):
    result.status = "fail"
    result.errors.append(
        PreflightCheck(
            check="path_security",
            path=f"{source_stage_id}/{source_path}",
            status="FAIL",
            message="Invalid path: escapes source stage directory",
            action="Remove '..' from source path in stage-config.yaml.",
            name=input_name,
        )
    )
    continue
```

---

#### CORR-001 [HIGH] - TOCTOU Race Condition

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py`
**Lines**: 172-183 (prompts), 234-250 (inputs)

**Issue**: Race condition between `exists()` check and subsequent `stat()` call. File can be deleted between checks, causing unhandled FileNotFoundError.

**Evidence**:
```python
if not full_path.exists():           # Line 172: Check 1
    # ... error handling
elif full_path.stat().st_size == 0:  # Line 183: Check 2 - may throw!
    # ... empty file handling
```

**Impact**: If file is deleted between lines 172 and 183, preflight crashes with unhandled exception instead of reporting actionable error.

**Fix**: Replace exists()+stat() pattern with single stat() in try/except:
```python
try:
    stat_result = full_path.stat()
    if stat_result.st_size == 0:
        # empty file handling
    else:
        # success
except FileNotFoundError:
    # missing file handling
```

---

#### PERF-001 [MEDIUM] - Redundant JSON Reads

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py`
**Lines**: 303, 380

**Issue**: `output-params.json` is read twice per parameter with `from_stage`: once for existence check (line 303), again for content parsing (line 380).

**Impact**: For N parameters: 2N file I/O operations instead of N. Doubles parse overhead with large JSON files.

**Fix**: Cache output-params.json content after first read. Build dict mapping source_stage_id -> parsed params.

---

#### PERF-002 [MEDIUM] - Double stat() Calls

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py`
**Lines**: 156-197, 234-250

**Issue**: Each file is stat'd twice: once via `exists()`, once via `stat().st_size`. `Path.exists()` internally stats the file.

**Impact**: 2 extra syscalls per prompt file, plus N extra syscalls for N input files.

**Fix**: Use single `stat()` call wrapped in try/except (also fixes CORR-001).

---

#### CORR-002 [LOW] - Optional None Field

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/cli.py`
**Lines**: 257-258

**Issue**: `error.action` is typed as optional (`str | None = None`) but CLI assumes it's always set.

**Impact**: If `action` is None (allowed by type), prints "Action: None" to stderr.

**Fix**: Add defensive check:
```python
if error.action:
    typer.echo(f"    Action: {error.action}", err=True)
```

---

## F) Coverage Map

**Testing Approach**: Manual (per project guidelines)

| Acceptance Criterion | Test Evidence | Confidence |
|---------------------|---------------|------------|
| Validates inputs | ST006 test output in execution log | 100% |
| Detects missing input files | ST006 Test 1: FAIL with actionable error | 100% |
| Detects unfinalized source stages | ST007 test output: "Source stage 'explore' not finalized" | 100% |
| Returns structured result | to_dict() method returns expected structure | 100% |
| Exit code 0/1 | ST006 shows exit code 0 on pass, 1 on fail | 100% |
| wf.md step 0 | Template updated with preflight as step 0 | 100% |

**Overall Coverage Confidence**: 100% (all acceptance criteria explicitly tested)

---

## G) Commands Executed

```bash
# Link validation (Task↔Log, Footnote checks)
# Performed via explore subagent - validated 7 tasks

# File existence checks
ls -la /Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py
ls -la /Users/jordanknight/github/tools/enhance/src/chainglass/cli.py
ls -la /Users/jordanknight/github/tools/enhance/sample/sample_1/wf-spec/templates/wf.md

# Diff review
git diff d849a89..HEAD -- enhance/src/chainglass/preflight.py enhance/src/chainglass/cli.py enhance/sample/sample_1/wf-spec/templates/wf.md
```

---

## H) Decision & Next Steps

**Verdict**: REQUEST_CHANGES

**Required Actions** (must fix before merge):
1. **SEC-001**: Add `is_relative_to()` validation for `source_path` in Phase 2 (lines 339+)
2. **CORR-001**: Replace exists()+stat() with single stat()+try/except pattern

**Recommended Actions** (improve quality):
3. **PERF-001**: Cache output-params.json per source stage
4. **PERF-002**: Use single stat() call (addressed by CORR-001 fix)
5. **CORR-002**: Add defensive null check for error.action in CLI

**Who Approves**: Implementation author after fixing HIGH severity issues

**Next Steps**:
1. Apply fixes from `fix-tasks.subtask-001-preflight-command.md`
2. Re-run preflight tests (ST006, ST007) to verify fixes don't break functionality
3. Re-submit for review

---

## I) Footnotes Audit

| File Path | Task(s) | Footnote Stub | Status |
|-----------|---------|---------------|--------|
| `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py` | ST001-ST003 | ST001-ST003 stub | ✅ Documented |
| `/Users/jordanknight/github/tools/enhance/src/chainglass/cli.py` | ST004 | ST004 stub | ✅ Documented |
| `/Users/jordanknight/github/tools/enhance/sample/sample_1/wf-spec/templates/wf.md` | ST005 | ST005 stub | ✅ Documented |

All changed files have corresponding footnote stubs in the subtask dossier's § Phase Footnote Stubs table.

---

## Appendix: Review Methodology

This review used:
- **Step 3a**: Bidirectional link validation (Task↔Log, Task↔Footnote, Footnote↔File)
- **Step 4**: Plan compliance validation via subagent
- **Step 6**: Quality/safety review via 4 parallel subagents (Correctness, Security, Performance, Plan Compliance)
- **Testing Strategy**: Manual (per project guidelines - no TDD overhead)
