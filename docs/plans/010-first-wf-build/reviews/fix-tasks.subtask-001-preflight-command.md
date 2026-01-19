# Fix Tasks: Subtask 001 - Preflight Command

**Plan**: first-wf-build-plan.md
**Phase**: Phase 4: Implement validate Command
**Subtask**: 001-subtask-preflight-command
**Date**: 2026-01-19

---

## Required Fixes (Must Complete Before Merge)

### Fix 1: SEC-001 - Add Path Security for source_path

**Severity**: HIGH
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py`
**Lines**: After line 339

**Issue**: Missing `is_relative_to()` validation for `source_path` in Phase 2, allowing potential path traversal attacks.

**Patch**:
```python
# After line 339: source_file_path = source_stage_path / source_path
# Add this block:

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

**Verification**:
- Create test config with malicious `source: "../../../etc/passwd"`
- Run preflight
- Should FAIL with path_security error, NOT crash or read file

---

### Fix 2: CORR-001 - Replace TOCTOU Pattern with Safe stat()

**Severity**: HIGH
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py`
**Lines**: 156-197 (prompts), 199-271 (inputs)

**Issue**: Race condition between `exists()` and `stat()` calls. File deletion between calls causes unhandled exception.

**Patch for prompts (lines 156-197)**:

Replace:
```python
        if not full_path.exists():
            result.status = "fail"
            result.errors.append(
                PreflightCheck(
                    check="prompt_exists",
                    path=prompt_path,
                    status="FAIL",
                    message=f"Missing prompt file: {prompt_path}",
                    action=f"Create {prompt_path} with stage prompt content.",
                )
            )
        elif full_path.stat().st_size == 0:
            result.status = "fail"
            result.errors.append(
                PreflightCheck(
                    check="prompt_not_empty",
                    path=prompt_path,
                    status="FAIL",
                    message=f"Prompt file is empty: {prompt_path}",
                    action=f"Add content to {prompt_path}.",
                )
            )
        else:
            result.checks.append(
                PreflightCheck(check="prompt_exists", path=prompt_path, status="PASS")
            )
```

With:
```python
        try:
            stat_result = full_path.stat()
            if stat_result.st_size == 0:
                result.status = "fail"
                result.errors.append(
                    PreflightCheck(
                        check="prompt_not_empty",
                        path=prompt_path,
                        status="FAIL",
                        message=f"Prompt file is empty: {prompt_path}",
                        action=f"Add content to {prompt_path}.",
                    )
                )
            else:
                result.checks.append(
                    PreflightCheck(check="prompt_exists", path=prompt_path, status="PASS")
                )
        except FileNotFoundError:
            result.status = "fail"
            result.errors.append(
                PreflightCheck(
                    check="prompt_exists",
                    path=prompt_path,
                    status="FAIL",
                    message=f"Missing prompt file: {prompt_path}",
                    action=f"Create {prompt_path} with stage prompt content.",
                )
            )
```

**Patch for inputs (lines 233-271)**: Apply same pattern - replace `exists()` + `stat()` with single `stat()` in try/except.

**Verification**:
- Run existing ST006 tests
- Should still pass with same output
- No unhandled exceptions if file deleted during check

---

## Recommended Fixes (Improve Quality)

### Fix 3: PERF-001 - Cache output-params.json Reads

**Severity**: MEDIUM
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preflight.py`
**Lines**: 296-416

**Issue**: output-params.json read twice per parameter (existence check + content parse).

**Approach**:
1. Build `cached_output_params: dict[str, dict]` during finalization check loop
2. Reuse cached data in parameter resolution loop

**Sketch**:
```python
# During finalization check (around line 296):
cached_output_params: dict[str, dict] = {}
for source_stage_id in source_stages:
    output_params_path = ...
    if output_params_path.exists():
        try:
            cached_output_params[source_stage_id] = json.loads(output_params_path.read_text())
            finalized_stages.add(source_stage_id)
            # ... success check
        except json.JSONDecodeError:
            # ... error handling
    else:
        # ... not finalized error

# During parameter resolution (around line 365):
# Use cached_output_params[source_stage_id] instead of re-reading
```

---

### Fix 4: CORR-002 - Defensive Null Check for action

**Severity**: LOW
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/cli.py`
**Lines**: 257-258

**Issue**: `error.action` could be None (per type signature), but CLI assumes it's set.

**Patch**:
```python
# Replace line 258:
            typer.echo(f"    Action: {error.action}", err=True)
# With:
            if error.action:
                typer.echo(f"    Action: {error.action}", err=True)
```

---

## Fix Order

1. **Fix 2 (CORR-001)** first - foundational pattern change
2. **Fix 1 (SEC-001)** second - security boundary
3. **Fix 3 (PERF-001)** optional - performance optimization
4. **Fix 4 (CORR-002)** optional - defensive coding

---

## Re-test After Fixes

```bash
cd /Users/jordanknight/github/tools/enhance

# Test 1: First stage with missing input (ST006)
uv run chainglass preflight explore --run-dir ./sample/sample_1/runs/run-2026-01-19-002
# Expected: FAIL with actionable error about missing inputs/user-description.md

# Test 2: After creating input
echo "Test content" > ./sample/sample_1/runs/run-2026-01-19-002/stages/explore/inputs/user-description.md
uv run chainglass preflight explore --run-dir ./sample/sample_1/runs/run-2026-01-19-002
# Expected: PASS (4 checks, 0 errors)

# Test 3: Second stage with unfinalized from_stage (ST007)
uv run chainglass preflight specify --run-dir ./sample/sample_1/runs/run-2026-01-19-002
# Expected: FAIL with "Source stage 'explore' not finalized" error

# Test 4: Path traversal security (new test for SEC-001)
# Create malicious config temporarily and verify rejection
```
