# Phase 4: Implement validate Command - Execution Log

**Phase**: Phase 4: Implement validate Command
**Plan**: [../../first-wf-build-plan.md](../../first-wf-build-plan.md)
**Tasks**: [./tasks.md](./tasks.md)
**Started**: 2026-01-19
**Completed**: 2026-01-19

---

## Task T001-T006: Core Validation Implementation

**Started**: 2026-01-19
**Status**: ✅ Complete

### What I Did

Implemented all core validation logic in a single pass:

1. Added `StageValidationCheck` dataclass (lines 40-50)
2. Added `StageValidationResult` dataclass with `to_dict()` method (lines 53-86)
3. Implemented `validate_stage()` function (lines 245-356)
4. Implemented `_validate_output_file()` helper (lines 359-473)

Key implementation details:
- File existence check with actionable "Write this file" message
- Empty file detection (st_size == 0) with "Write content" action
- JSON Schema validation using jsonschema library
- Output parameter extraction using `resolve_query()` from stage.py
- Writes output-params.json on successful validation

### Files Changed

- `/Users/jordanknight/github/tools/enhance/src/chainglass/validator.py` — Added ~230 lines

### Evidence

```
$ uv run python -c "from chainglass.validator import validate_stage, StageValidationResult, StageValidationCheck; print('OK')"
OK
```

**Completed**: 2026-01-19

---

## Task T007: Implement validate CLI command

**Started**: 2026-01-19
**Status**: ✅ Complete

### What I Did

Added `validate` command to cli.py following the pattern of `finalize`:
- Takes stage_id and --run-dir arguments
- Calls validate_stage() function
- Outputs human-readable results with checks and errors
- Exit code 0 on pass, 1 on fail

### Files Changed

- `/Users/jordanknight/github/tools/enhance/src/chainglass/cli.py` — Added validate_cmd function (~65 lines)

### Evidence

```
$ uv run chainglass validate --help
Usage: chainglass validate [OPTIONS] STAGE_ID

  Validate stage outputs after LLM execution.
  ...
```

**Completed**: 2026-01-19

---

## Task T008-T009: Create Test Fixtures

**Started**: 2026-01-19
**Status**: ✅ Complete

### What I Did

**T008 - valid-stage fixture:**
- Copied from run-2026-01-18-003/stages/explore
- Fixed wf-result.json to include required `error` and `metrics` fields
- Fixed findings.json to include required `summary` field with nested counts
- Removed output-params.json so validate can recreate it

**T009 - invalid-stage fixture:**
- Created directory structure matching valid-stage
- Missing file: research-dossier.md (not created)
- Empty file: wf-result.json (0 bytes)
- Schema-invalid: findings.json (missing required 'summary' field)

### Files Created

- `/enhance/sample/sample_1/test-fixtures/valid-stage/stages/explore/...` — Complete valid stage
- `/enhance/sample/sample_1/test-fixtures/invalid-stage/stages/explore/...` — Deliberately broken stage

**Completed**: 2026-01-19

---

## Task T010-T012: Manual Testing

**Started**: 2026-01-19
**Status**: ✅ Complete

### Evidence

**T010 - Valid stage test:**
```
$ uv run chainglass validate explore --run-dir sample/sample_1/test-fixtures/valid-stage
Validated: explore
Checks passed:
  run/output-files/research-dossier.md
  ...
Output parameters published:
  total_findings: 15
  critical_count: 2
  top_component: auth/session.py
  complexity_score: CS-3
Result: PASS (11 checks, 0 errors)
```

**T011 - Parameter extraction verified** (4 params written to output-params.json)

**T012 - Invalid stage test:**
```
$ uv run chainglass validate explore --run-dir sample/sample_1/test-fixtures/invalid-stage
Validation failed:
  FILE_EXISTS: run/output-files/research-dossier.md
    Action: Write this file before completing the stage.
  FILE_NOT_EMPTY: run/output-data/wf-result.json
    Action: Write content to this file.
  SCHEMA_VALID: run/output-data/findings.json
    Action: Fix the JSON structure. Error at '': 'summary' is a required property...
Result: FAIL (6 passed, 3 errors)
```

**Completed**: 2026-01-19

---

## Task T013: Refactor Stage.finalize() to use shared helper

**Started**: 2026-01-19
**Status**: ✅ Complete

### What I Did

Refactored `Stage.finalize()` to delegate to `validate_stage()`:
- Removed ~40 lines of duplicate validation/extraction code
- Now calls `validate_stage(self.path)` for thorough validation
- Converts `StageValidationCheck` errors to string format for `FinalizeResult`
- Still handles wf-run.json status update separately

**Benefit**: finalize now gets enhanced validation (empty file detection, schema validation) that it previously lacked.

### Files Changed

- `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py` — Refactored finalize() method

### Evidence

```
$ uv run chainglass finalize explore --run-dir sample/sample_1/test-fixtures/valid-stage
Finalized: explore
Published parameters:
  total_findings: 15
  critical_count: 2
  top_component: auth/session.py
  complexity_score: CS-3

$ uv run chainglass finalize explore --run-dir sample/sample_1/test-fixtures/invalid-stage
Finalization failed:
  FILE_EXISTS: run/output-files/research-dossier.md
  ...
```

**Completed**: 2026-01-19

---

## Summary

**Phase 4 Complete**: All 13 tasks completed successfully.

### Key Deliverables

1. **validate_stage()** function in validator.py implementing A.12 algorithm
2. **validate** CLI command for LLM-friendly stage output validation
3. **Test fixtures** (valid-stage, invalid-stage) per A.13
4. **Refactored finalize()** to use shared validation logic

### Acceptance Criteria Status

- [x] **P4-AC-01**: validate command detects missing required files with actionable message
- [x] **P4-AC-02**: validate command detects empty files with actionable message
- [x] **P4-AC-03**: validate command validates JSON against declared schemas
- [x] **P4-AC-04**: validate command extracts output_parameters using resolve_query()
- [x] **P4-AC-05**: validate command writes output-params.json on successful validation
- [x] **P4-AC-06**: validate command returns structured result with status, checks, errors
- [x] **P4-AC-07**: Exit code 0 on pass, 1 on fail

