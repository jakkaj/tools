# Phase 2 Execution Log

**Phase**: Implement compose Command
**Started**: 2026-01-18
**Status**: ✅ Complete

---

## Task T001: Create chainglass module structure
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Created the chainglass Python package structure:
1. Created `/Users/jordanknight/github/tools/enhance/src/chainglass/` directory
2. Created `__init__.py` with `__version__ = "0.1.0"`

### Evidence
```
ls -la /Users/jordanknight/github/tools/enhance/src/chainglass/
total 8
drwxr-xr-x@ 3 jordanknight  staff   96 Jan 18 20:43 .
drwxr-xr-x@ 3 jordanknight  staff   96 Jan 18 20:43 ..
-rw-r--r--@ 1 jordanknight  staff  155 Jan 18 20:43 __init__.py
```

### Files Created
- `enhance/src/chainglass/__init__.py`

**Completed**: 2026-01-18

---

## Task T002: Create pyproject.toml with dependencies
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Created pyproject.toml with:
1. hatchling build system
2. Dependencies: typer[all], pyyaml, jsonschema
3. Entry point: `chainglass = chainglass.cli:app`
4. Also created minimal `cli.py` stub for the entry point

### Evidence
```
$ uv run chainglass --help
 Usage: chainglass [OPTIONS] COMMAND [ARGS]...

 Workflow Composer CLI - Transform wf-spec folders into executable run
 directories.

╭─ Options ────────────────────────────────────────────────────────────────────╮
│ --version  -v        Show version and exit.                                  │
│ --help               Show this message and exit.                             │
╰──────────────────────────────────────────────────────────────────────────────╯

$ uv run chainglass --version
chainglass 0.1.0
```

### Files Created
- `enhance/pyproject.toml`
- `enhance/src/chainglass/cli.py` (minimal stub for entry point)

**Completed**: 2026-01-18

---

## Task T004: Implement YAML parser module
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Created parser.py with:
1. `parse_workflow(wf_spec_path)` function that loads wf.yaml
2. Validates against wf.schema.json from wf-spec/schemas/
3. Raises `WorkflowParseError` with actionable messages on failure
4. Uses jsonschema Draft202012Validator for schema validation

### Evidence
```
$ uv run python -c "
from chainglass.parser import parse_workflow
from pathlib import Path
wf = parse_workflow(Path('enhance/sample/sample_1/wf-spec'))
print(f'Loaded workflow: {wf[\"metadata\"][\"name\"]}')
print(f'Stages: {[s[\"id\"] for s in wf[\"stages\"]]}')
"
Loaded workflow: explore-specify
Stages: ['explore', 'specify']
```

### Files Created
- `enhance/src/chainglass/parser.py`

**Completed**: 2026-01-18

---

## Task T004b: Implement wf-spec validator module
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Created validator.py implementing two-phase validation:
1. **Phase 1 (Fail-Fast)**: YAML structure validation via parser.py
2. **Phase 2 (Collect-All)**: File existence checks - collects ALL errors
   - Shared templates from wf.yaml shared_templates
   - Shared schemas (wf-result.schema.json)
   - Stage directories, prompts, and schemas

Key components:
- `ValidationResult` dataclass with valid, errors, warnings fields
- `validate_wf_spec(path)` returns ValidationResult
- `validate_or_raise(path)` convenience function

### Evidence
```
# Test with valid wf-spec
$ uv run python -c "
from chainglass.validator import validate_wf_spec
from pathlib import Path
result = validate_wf_spec(Path('enhance/sample/sample_1/wf-spec'))
print(f'Valid: {result.valid}')
print(f'Errors: {len(result.errors)}')
"
Valid: True
Errors: 0

# Test with non-existent wf-spec
$ uv run python -c "
from chainglass.validator import validate_wf_spec
from pathlib import Path
result = validate_wf_spec(Path('/tmp/nonexistent-wf-spec'))
print(f'Valid: {result.valid}')
print(f'Errors: {len(result.errors)}')
"
Valid: False
Errors: 1
```

### Files Created
- `enhance/src/chainglass/validator.py`

**Completed**: 2026-01-18

---

## Task T005: Implement composer module
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Created composer.py implementing the A.10 Compose Algorithm:
1. Validates wf-spec folder via validator.py
2. Creates run folder with date-ordinal naming (run-{date}-{ordinal})
3. Writes wf-run.json with run metadata
4. For each stage:
   - Creates subdirs: inputs/, prompt/, run/output-files/, run/output-data/, run/runtime-inputs/, schemas/
   - Extracts stage-config.yaml from wf.yaml (with sort_keys=False)
   - Copies prompt/main.md
   - Copies stage-specific schemas
   - Copies shared templates

### Evidence
```
$ uv run python -c "
from chainglass.composer import compose
from pathlib import Path
run_folder = compose(
    Path('enhance/sample/sample_1/wf-spec'),
    Path('enhance/sample/sample_1/runs')
)
print(f'Created: {run_folder}')
"
Created: /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2026-01-18-001

$ ls -R enhance/sample/sample_1/runs/run-2026-01-18-001/
stages
wf-run.json

./stages:
explore
specify

./stages/explore:
inputs prompt run schemas stage-config.yaml

./stages/explore/prompt:
main.md wf.md

./stages/explore/schemas:
explore-metrics.schema.json findings.schema.json read-files.schema.json wf-result.schema.json
```

### Files Created
- `enhance/src/chainglass/composer.py`
- `enhance/sample/sample_1/runs/run-2026-01-18-001/` (test output)

**Completed**: 2026-01-18

---

## Task T006: Implement compose CLI command
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Updated cli.py to add the `compose` command:
1. Added typer command with WF_SPEC argument and --output option
2. Calls composer.compose() with paths
3. Handles ValidationError and CompositionError with user-friendly messages
4. Returns exit code 1 on error

### Evidence
```
$ uv run chainglass compose --help
Usage: chainglass compose [OPTIONS] WF_SPEC

 Create a run folder from a wf-spec folder.

 Transforms a wf-spec folder into an executable run directory where
 coding agents can execute workflow stages.

 Example:
     chainglass compose ./wf-spec --output ./runs

╭─ Arguments ────────────────────────────────────────────────────────────────╮
│ *    wf_spec      DIRECTORY  Path to wf-spec folder containing wf.yaml    │
╰────────────────────────────────────────────────────────────────────────────╯
╭─ Options ──────────────────────────────────────────────────────────────────╮
│ *  --output  -o      PATH  Output directory for run folder [required]     │
╰────────────────────────────────────────────────────────────────────────────╯

$ uv run chainglass compose ./enhance/sample/sample_1/wf-spec --output ./enhance/sample/sample_1/runs
Created: /Users/jordanknight/github/tools/enhance/sample/sample_1/runs/run-2026-01-18-002
```

### Files Modified
- `enhance/src/chainglass/cli.py`

**Completed**: 2026-01-18

---

## Task T007: Implement idempotent compose
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Verified idempotency is already implemented in composer.py:
1. Stages sorted by ID: `sorted(stages, key=lambda s: s["id"])`
2. Schema files sorted by name: `sorted(src_schemas_dir.iterdir())`
3. YAML output preserves field order: `sort_keys=False`

Ran compose twice and compared outputs (excluding wf-run.json timestamps).

### Evidence
```
$ uv run chainglass compose ./enhance/sample/sample_1/wf-spec --output /tmp/idempotency-test
Created: /private/tmp/idempotency-test/run-2026-01-18-001

$ uv run chainglass compose ./enhance/sample/sample_1/wf-spec --output /tmp/idempotency-test
Created: /private/tmp/idempotency-test/run-2026-01-18-002

$ diff -rq /tmp/idempotency-test/run-2026-01-18-001/stages /tmp/idempotency-test/run-2026-01-18-002/stages
(no output = no differences)

$ diff /tmp/idempotency-test/run-2026-01-18-001/stages/explore/stage-config.yaml /tmp/idempotency-test/run-2026-01-18-002/stages/explore/stage-config.yaml
(no output = identical)
```

### Files Modified
- None (verification task)

**Completed**: 2026-01-18

---

## Task T008: Manual test compose creates correct structure
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Verified compose output matches A.8 structure requirements:
1. Run folder naming: `run-{date}-{ordinal}` format ✓
2. wf-run.json present at root ✓
3. stages/ directory with explore and specify ✓
4. Each stage has required subdirs:
   - inputs/ ✓
   - prompt/ ✓
   - run/output-data/ ✓
   - run/output-files/ ✓
   - run/runtime-inputs/ ✓
   - schemas/ ✓
   - stage-config.yaml ✓
5. Prompt files copied:
   - main.md ✓
   - wf.md (shared template) ✓

### Evidence
```
$ find /tmp/a8-test/run-2026-01-18-001 -type f -o -type d | sort
/tmp/a8-test/run-2026-01-18-001
/tmp/a8-test/run-2026-01-18-001/stages
/tmp/a8-test/run-2026-01-18-001/stages/explore
/tmp/a8-test/run-2026-01-18-001/stages/explore/inputs
/tmp/a8-test/run-2026-01-18-001/stages/explore/prompt
/tmp/a8-test/run-2026-01-18-001/stages/explore/prompt/main.md
/tmp/a8-test/run-2026-01-18-001/stages/explore/prompt/wf.md
/tmp/a8-test/run-2026-01-18-001/stages/explore/run
/tmp/a8-test/run-2026-01-18-001/stages/explore/run/output-data
/tmp/a8-test/run-2026-01-18-001/stages/explore/run/output-files
/tmp/a8-test/run-2026-01-18-001/stages/explore/run/runtime-inputs
/tmp/a8-test/run-2026-01-18-001/stages/explore/schemas
...
/tmp/a8-test/run-2026-01-18-001/stages/specify/stage-config.yaml
/tmp/a8-test/run-2026-01-18-001/wf-run.json

All A.8 structure requirements verified: PASS
```

### Files Modified
- None (verification task)

**Completed**: 2026-01-18

---

## Task T009: Manual test compose fails with actionable errors
**Started**: 2026-01-18
**Status**: ✅ Complete

### What I Did
Created an incomplete wf-spec and verified compose produces actionable error messages:
1. Test case 1: Missing wf.yaml → Clear error with "Action: Create wf.yaml..."
2. Test case 2: Missing wf.schema.json → Clear error with "Action: Add wf.schema.json..."
3. Test case 3: Schema validation failure → Clear error pointing to exact field
4. Test case 4: Multiple missing files → ALL errors collected and shown in one run

Verified:
- Two-phase validation (fail-fast for YAML, collect-all for files) ✓
- Actionable error messages with "Action:" guidance ✓
- Exit code 1 on failure ✓

### Evidence
```
$ uv run chainglass compose /tmp/incomplete-wf-spec --output /tmp/test-output
Validation failed:

  Missing required file: /private/tmp/incomplete-wf-spec/templates/wf.md
Action: Create this file in the wf-spec folder.
See: wf.yaml shared_templates section.

  Missing required schema: /private/tmp/incomplete-wf-spec/schemas/wf-result.schema.json
Action: Create wf-result.schema.json in wf-spec/schemas/.
See: Plan Appendix A.5 for schema content.

  Missing required file: /private/tmp/incomplete-wf-spec/stages/test/prompt/main.md
Action: Create main.md with the stage prompt content.
See: stages/test/prompt/ directory.

Exit code: 1
```

### Files Modified
- None (verification task)

**Completed**: 2026-01-18

---

## Phase 2 Summary

**All 9 tasks completed successfully.**

### Files Created (6 total)
1. `enhance/src/chainglass/__init__.py` - Package with version
2. `enhance/pyproject.toml` - Build config with dependencies
3. `enhance/src/chainglass/cli.py` - Typer CLI with compose command
4. `enhance/src/chainglass/parser.py` - YAML parser with schema validation
5. `enhance/src/chainglass/validator.py` - Two-phase wf-spec validator
6. `enhance/src/chainglass/composer.py` - Core compose algorithm (A.10)

### Acceptance Criteria Status
- [x] **P2-AC-01**: `chainglass compose --help` shows correct usage
- [x] **P2-AC-02**: `chainglass compose ./wf-spec --output ./runs` creates run folder
- [x] **P2-AC-03**: Run folder structure matches A.8 exactly
- [x] **P2-AC-04**: stage-config.yaml extracted from wf.yaml for each stage
- [x] **P2-AC-05**: Shared templates copied to each stage
- [x] **P2-AC-06**: Two-phase validation with fail-fast + collect-all
- [x] **P2-AC-07**: Actionable error messages with "Action:" guidance
- [x] **P2-AC-08**: Idempotent compose (same input → same structure)

### Critical Insights Applied
1. Validation: A+C hybrid (fail-fast YAML + collect-all files)
2. Idempotency: New folder each time with date-ordinal naming
3. Schema location: Read from wf-spec/schemas/ at runtime
4. YAML ordering: sort_keys=False preserves logical field order
5. Templates: Copy files (not symlinks) per plan

### Next Steps
Run `/plan-7-code-review --phase 2` for code review, or proceed to Phase 3.

