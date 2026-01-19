# Phase 4: Implement validate Command - Fix Tasks

**Review**: [./review.phase-4-implement-validate-command.md](./review.phase-4-implement-validate-command.md)
**Verdict**: REQUEST_CHANGES
**Date**: 2026-01-19

---

## Blocking Fixes (Must Complete Before Merge)

### FIX-001: Path Traversal Validation in Output Path (QS-005) — HIGH

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/validator.py`
**Lines**: 377-393 (inside `_validate_output_file()`)

**Issue**: No validation that `output["path"]` doesn't escape stage directory via `..` or absolute paths.

**Fix**: Add path traversal check after constructing `output_path`:

```python
# Line 377: Current code
output_path = stage_path / output["path"]
rel_path = output["path"]

# Insert AFTER line 378:
# Check for path traversal
if not output_path.resolve().is_relative_to(stage_path):
    result.status = "fail"
    result.errors.append(
        StageValidationCheck(
            check="path_security",
            path=rel_path,
            status="FAIL",
            message=f"Invalid path: escapes stage directory",
            action="Remove '..' or absolute path components from output path in stage-config.yaml.",
        )
    )
    return  # Skip further checks for this file
```

**Validation**: Create a test stage-config.yaml with `path: "../../../etc/passwd"` and verify it returns FAIL with security message.

---

### FIX-002: Path Traversal Validation in Schema Path (QS-006) — HIGH

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/validator.py`
**Lines**: 419-420 (inside `_validate_output_file()`)

**Issue**: No validation that `schema_ref` doesn't escape stage directory.

**Fix**: Add path traversal check before reading schema:

```python
# Line 419: Current code
schema_ref = output["schema"]
schema_path = stage_path / schema_ref

# Insert AFTER line 420:
# Check for path traversal on schema
if not schema_path.resolve().is_relative_to(stage_path):
    result.status = "fail"
    result.errors.append(
        StageValidationCheck(
            check="schema_security",
            path=rel_path,
            schema=schema_ref,
            status="FAIL",
            message=f"Invalid schema path: escapes stage directory",
            action="Remove '..' or absolute path components from schema path in stage-config.yaml.",
        )
    )
    return
```

**Validation**: Create a test with `schema: "../../../sensitive.json"` and verify security error.

---

## Recommended Fixes (Non-Blocking)

### FIX-003: Null Check for yaml.safe_load in validate_stage (QS-001) — MEDIUM

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/validator.py`
**Line**: 290

**Current**:
```python
config = yaml.safe_load(config_path.read_text())
```

**Fix**:
```python
config = yaml.safe_load(config_path.read_text()) or {}
```

**Validation**: Create empty stage-config.yaml file and verify graceful handling.

---

### FIX-004: Path Traversal in Output Parameter Source (QS-007) — MEDIUM

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/validator.py`
**Lines**: 322-323

**Current**:
```python
source_path = stage_path / param["source"]
if source_path.exists():
```

**Fix**:
```python
source_path = stage_path / param["source"]
# Security: validate source path is within stage
if not source_path.resolve().is_relative_to(stage_path):
    continue  # Skip malicious source
if source_path.exists():
```

---

### FIX-005: Separate Schema and Data JSON Parse Errors (QS-002) — MEDIUM

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/validator.py`
**Lines**: 436-459

**Current**: Single try block handles both schema and data parsing.

**Fix**: Separate into two try blocks with distinct error messages:

```python
# Load schema first
try:
    schema = json.loads(schema_path.read_text())
except json.JSONDecodeError as e:
    result.status = "fail"
    result.errors.append(
        StageValidationCheck(
            check="schema_valid",
            path=rel_path,
            schema=schema_ref,
            status="FAIL",
            message=f"Schema file contains invalid JSON: {e.msg}",
            action=f"Fix JSON syntax in schema file: {schema_ref}",
        )
    )
    return

# Then load and validate data
try:
    data = json.loads(output_path.read_text())
    jsonschema.validate(data, schema)
    # ... rest of existing code
except json.JSONDecodeError as e:
    # ... existing data file JSON error handling
```

---

### FIX-006: Null Check in Stage.config (QS-012) — MEDIUM

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Line**: 143

**Current**:
```python
self._config = yaml.safe_load(config_path.read_text())
```

**Fix**:
```python
loaded = yaml.safe_load(config_path.read_text())
if loaded is None:
    raise ValueError(f"stage-config.yaml is empty: {config_path}")
self._config = loaded
```

---

### FIX-007: Handle Corrupted wf-run.json (QS-013) — MEDIUM

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Line**: 272

**Current**:
```python
wf_run = json.loads(self.wf_run_path.read_text())
```

**Fix**:
```python
try:
    wf_run = json.loads(self.wf_run_path.read_text())
except json.JSONDecodeError:
    return  # Silent no-op if wf-run.json is corrupted (matches missing file behavior)
```

---

## Low Priority Fixes (Optional)

### FIX-008: Root-level JSON path display (QS-003) — LOW

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/validator.py`
**Line**: 462

**Current**:
```python
json_path_str = ".".join(str(p) for p in e.absolute_path) or ""
```

**Fix**:
```python
json_path_str = ".".join(str(p) for p in e.absolute_path) or "<root>"
```

---

### FIX-009: Remove trailing newlines in CLI output (QS-008, QS-009) — LOW

**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/cli.py`
**Lines**: 72, 74, 129, 131, 254, 256

**Fix**: Remove `\n` from f-strings in error output calls.

---

## Verification Steps

After implementing fixes:

1. **Security Tests** (for FIX-001, FIX-002, FIX-004):
```bash
# Create malicious stage-config.yaml and verify rejection
cd /Users/jordanknight/github/tools/enhance
# Test path traversal in output path
# Test path traversal in schema path
# Test path traversal in output_parameter source
```

2. **Robustness Tests** (for FIX-003, FIX-005, FIX-006, FIX-007):
```bash
# Test empty stage-config.yaml
# Test invalid JSON in schema file vs data file
# Test corrupted wf-run.json
```

3. **Re-run Manual Tests**:
```bash
uv run chainglass validate explore --run-dir sample/sample_1/test-fixtures/valid-stage
uv run chainglass validate explore --run-dir sample/sample_1/test-fixtures/invalid-stage
```

---

## Summary

| Priority | Count | Estimated Effort |
|----------|-------|------------------|
| HIGH (blocking) | 2 | ~30 lines of code |
| MEDIUM (recommended) | 5 | ~40 lines of code |
| LOW (optional) | 2 | ~10 lines of code |

**Recommended Approach**: Fix HIGH issues first (FIX-001, FIX-002), then MEDIUM issues in a second pass. LOW issues can be deferred.
