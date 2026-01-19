# Phase 3: Fix Tasks – prepare-wf-stage Command

**Review**: [review.phase-3-implement-prepare-wf-stage-command.md](./review.phase-3-implement-prepare-wf-stage-command.md)
**Generated**: 2026-01-19
**Severity Order**: CRITICAL → HIGH → MEDIUM → LOW

---

## Blocking Fixes (MUST fix before merge)

### FIX-001: Schema Field Name Mismatch [CRITICAL]

**ID**: SEM-001
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Lines**: 260-264

**Issue**: output-params.json uses `finalized_at` instead of spec's `published_at` field name.

**Impact**: Violates A.5d schema contract. Downstream tools expecting `published_at` will fail validation.

**Fix**:
```python
# Change line 262 from:
"finalized_at": datetime.now(timezone.utc).isoformat(),

# To:
"published_at": datetime.now(timezone.utc).isoformat(),
```

**Verification**: After fix, `cat output-params.json | jq '.published_at'` should return timestamp.

---

### FIX-002: Missing Directory Creation in finalize() [CRITICAL]

**ID**: COR-001
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Lines**: 258-265

**Issue**: `finalize()` writes output-params.json without ensuring parent directory exists.

**Impact**: Crashes with `FileNotFoundError` if `run/output-data/` directory doesn't exist.

**Fix**:
```python
# Insert after line 259 (after output_params_path assignment):
output_params_path.parent.mkdir(parents=True, exist_ok=True)
```

**Full context**:
```python
# Step 3: Write output-params.json
output_params_path = self.path / "run" / "output-data" / "output-params.json"
output_params_path.parent.mkdir(parents=True, exist_ok=True)  # ADD THIS LINE
output_params_data = {
    "stage_id": self.stage_id,
    "published_at": datetime.now(timezone.utc).isoformat(),  # Also fix SEM-001
    "parameters": parameters,
}
output_params_path.write_text(json.dumps(output_params_data, indent=2))
```

**Verification**: Create test run with missing `output-data/` dir, run finalize - should succeed.

---

### FIX-003: Path Traversal Vulnerability in preparer.py [HIGH]

**ID**: SEC-001
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preparer.py`
**Lines**: 119-146

**Issue**: File paths from stage-config.yaml are used without validation, allowing `../` traversal.

**Impact**: Attacker-crafted stage-config.yaml could read/write files outside stage directory.

**Fix**: Add path validation before file operations.

```python
# Add at top of file with other imports:
from pathlib import Path

# In prepare_wf_stage(), add after line 126 (after source_path assignment):
# Validate source path stays within source stage
source_abs = source_path.resolve()
if not source_abs.is_relative_to(source.path):
    result.errors.append(
        f"Path traversal detected in input source: {source_rel_path}\n"
        f"  Action: Remove '../' from path in stage-config.yaml."
    )
    result.success = False
    continue

# And after line 138 (after target_path_file assignment):
# Validate target path stays within target stage
target_abs = target_path_file.resolve()
if not target_abs.is_relative_to(target.path):
    result.errors.append(
        f"Path traversal detected in input path: {target_rel_path}\n"
        f"  Action: Remove '../' from path in stage-config.yaml."
    )
    result.success = False
    continue
```

**Verification**: Create test config with `source: "../../../etc/passwd"`, run prepare - should fail with "Path traversal detected".

---

### FIX-004: Path Traversal in Stage Output Accessors [HIGH]

**ID**: SEC-002
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Lines**: 302-337

**Issue**: `get_output_data()`, `get_output_file()`, and `query_output()` don't validate path arguments.

**Fix**: Add validation in each method.

```python
def get_output_data(self, filename: str) -> dict | None:
    """Load JSON from run/output-data/."""
    # Validate filename
    if '..' in filename or filename.startswith('/'):
        return None
    path = self.path / "run" / "output-data" / filename
    # Verify path is within stage
    if not path.resolve().is_relative_to(self.path):
        return None
    if path.exists():
        return json.loads(path.read_text())
    return None

def get_output_file(self, filename: str) -> Path | None:
    """Get path to file in run/output-files/."""
    # Validate filename
    if '..' in filename or filename.startswith('/'):
        return None
    path = self.path / "run" / "output-files" / filename
    # Verify path is within stage
    if not path.resolve().is_relative_to(self.path):
        return None
    return path if path.exists() else None

def query_output(self, source: str, query: str) -> Any | None:
    """Query a JSON output file using dot notation."""
    # Validate source path
    if '..' in source or source.startswith('/'):
        return None
    source_path = self.path / source
    # Verify path is within stage
    if not source_path.resolve().is_relative_to(self.path):
        return None
    if not source_path.exists():
        return None
    data = json.loads(source_path.read_text())
    return resolve_query(data, query)
```

---

### FIX-005: Consolidate Footnote Stubs in Dossier [CRITICAL]

**ID**: LINK-001
**File**: `/Users/jordanknight/github/tools/docs/plans/010-first-wf-build/tasks/phase-3-implement-prepare-wf-stage-command/tasks.md`
**Lines**: 900-918

**Issue**: Phase Footnote Stubs section has 16 rows (11 for [^17], 3 for [^18], 2 for [^19]). Should have exactly 3 rows (one per footnote).

**Fix**: Replace lines 900-918 with consolidated format:

```markdown
## Phase Footnote Stubs

| Footnote | Task(s) | Node ID(s) | Notes |
|----------|---------|------------|-------|
| [^17] | T001, T002, T003, T004 | `file:enhance/src/chainglass/stage.py`, `class:Stage`, `function:resolve_query`, `class:FinalizeResult`, `method:Stage.validate`, `method:Stage.finalize`, `method:Stage.get_output_params`, `method:Stage.get_output_data`, `method:Stage.get_output_file`, `method:Stage.query_output` | Stage class with lazy loading, validation, finalization |
| [^18] | T007, T008, T009, T010, T011 | `file:enhance/src/chainglass/preparer.py`, `class:PrepareResult`, `function:prepare_wf_stage` | Preparer module |
| [^19] | T005, T010, T011 | `function:enhance/src/chainglass/cli.py:finalize_cmd`, `function:enhance/src/chainglass/cli.py:prepare_wf_stage_cmd` | finalize and prepare-wf-stage CLI commands |
```

**Note**: Also fix ValidationResult node ID - it's defined in `validator.py`, not `stage.py`. Remove from [^17] list.

---

## Recommended Fixes (Non-Blocking)

### FIX-006: Empty Params Dict Skips Write [HIGH]

**ID**: COR-002
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preparer.py`
**Lines**: 187-191

**Issue**: If no parameters need resolution, `resolved_params` is empty dict (falsy), so params.json isn't written.

**Fix**:
```python
# Change line 188 from:
if result.success and resolved_params and not dry_run:

# To:
if result.success and not dry_run:
```

---

### FIX-007: wf-run.json Existence Check [HIGH]

**ID**: COR-003
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Lines**: 273-284

**Issue**: `_update_wf_run_status()` crashes if wf-run.json doesn't exist.

**Fix**:
```python
def _update_wf_run_status(self, status: str) -> None:
    """Update this stage's status in wf-run.json."""
    from datetime import datetime, timezone

    if not self.wf_run_path.exists():
        return  # Silent no-op if wf-run.json missing

    wf_run = json.loads(self.wf_run_path.read_text())
    # ... rest of method
```

---

### FIX-008: Add JSON Caching in Stage Class [HIGH]

**ID**: PERF-002
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`

**Issue**: `query_output()` re-reads and re-parses JSON files on every call.

**Fix**:
```python
def __init__(self, path: Path):
    self.path = Path(path).resolve()
    self._config: dict | None = None
    self._json_cache: dict[Path, Any] = {}  # ADD THIS

def query_output(self, source: str, query: str) -> Any | None:
    # ... path validation ...
    source_path = self.path / source
    if not source_path.exists():
        return None

    # Use cache
    resolved_path = source_path.resolve()
    if resolved_path not in self._json_cache:
        self._json_cache[resolved_path] = json.loads(source_path.read_text())

    data = self._json_cache[resolved_path]
    return resolve_query(data, query)
```

---

### FIX-009: Cache is_complete Property [HIGH]

**ID**: PERF-001
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Lines**: 202-205

**Fix**:
```python
from functools import cached_property

@cached_property
def is_complete(self) -> bool:
    """Convenience: True if validate() passes."""
    return self.validate().valid
```

---

### FIX-010: YAML Parsing Error Handling [HIGH]

**ID**: OBS-001
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Lines**: 136-141

**Fix**:
```python
@property
def config(self) -> dict:
    """Load stage-config.yaml (lazy, cached)."""
    if self._config is None:
        config_path = self.path / "stage-config.yaml"
        try:
            self._config = yaml.safe_load(config_path.read_text())
        except FileNotFoundError:
            raise ValueError(f"stage-config.yaml not found: {config_path}")
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML in {config_path}: {e}")
    return self._config
```

---

### FIX-011: Stage ID Not Found Validation [HIGH]

**ID**: OBS-002
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/stage.py`
**Lines**: 273-284

**Fix**:
```python
def _update_wf_run_status(self, status: str) -> None:
    """Update this stage's status in wf-run.json."""
    from datetime import datetime, timezone

    if not self.wf_run_path.exists():
        return

    wf_run = json.loads(self.wf_run_path.read_text())
    stage_found = False
    for stage in wf_run.get("stages", []):
        if stage["id"] == self.stage_id:
            stage["status"] = status
            if status == "completed":
                stage["completed_at"] = datetime.now(timezone.utc).isoformat()
            stage_found = True
            break

    if not stage_found:
        # Log warning or raise error - stage not in wf-run.json
        return  # For now, silent no-op

    self.wf_run_path.write_text(json.dumps(wf_run, indent=2))
```

---

### FIX-012: File Copy Error Handling [MEDIUM]

**ID**: OBS-003
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preparer.py`
**Lines**: 141-146

**Fix**:
```python
if not dry_run:
    try:
        target_path_file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source_path, target_path_file)
    except (IOError, OSError) as e:
        result.errors.append(
            f"Failed to copy file '{input_def['name']}':\n"
            f"  From: {source_path}\n"
            f"  To: {target_path_file}\n"
            f"  Error: {e}"
        )
        result.success = False
        continue
```

---

### FIX-013: Params Write Error Handling [MEDIUM]

**ID**: OBS-004
**File**: `/Users/jordanknight/github/tools/enhance/src/chainglass/preparer.py`
**Lines**: 188-191

**Fix**:
```python
if result.success and not dry_run:
    params_path = target.path / "inputs" / "params.json"
    try:
        params_path.parent.mkdir(parents=True, exist_ok=True)
        params_path.write_text(json.dumps(resolved_params, indent=2))
    except (IOError, OSError) as e:
        result.errors.append(
            f"Failed to write params.json:\n"
            f"  Path: {params_path}\n"
            f"  Error: {e}"
        )
        result.success = False
```

---

## Verification Checklist

After implementing fixes, verify:

- [ ] `uv run chainglass finalize --help` still works
- [ ] `uv run chainglass prepare-wf-stage --help` still works
- [ ] Create fresh run folder, finalize explore, prepare specify - full workflow passes
- [ ] Test path traversal rejection: config with `../etc/passwd` fails with clear error
- [ ] Output-params.json has `published_at` field (not `finalized_at`)
- [ ] Footnote stubs in dossier have exactly 3 rows

---

**Fix implementation complete. Re-run `/plan-6` for fixes, then `/plan-7` to verify.**
