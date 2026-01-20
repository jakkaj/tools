"""Validator for wf-spec folder completeness and stage output validation.

Implements two-phase validation for wf-spec:
- Phase 1 (Fail-Fast): YAML structure validation - exit early if broken
- Phase 2 (Collect-All): File existence checks - collect ALL errors

Also implements stage output validation per A.12 algorithm:
- File presence checks for required outputs
- Empty file detection (0-byte files)
- JSON Schema validation using Draft202012
- Output parameter extraction
"""

import json
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal

import jsonschema
import yaml

from chainglass.parser import WorkflowParseError, parse_workflow


@dataclass
class ValidationResult:
    """Result of wf-spec validation."""

    valid: bool
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


# =============================================================================
# Stage Validation Types (A.12 Algorithm)
# =============================================================================


@dataclass
class StageValidationCheck:
    """A single validation check result per A.12 output format."""

    check: str  # "file_exists", "file_not_empty", "schema_valid"
    path: str  # Relative path to the file being checked
    status: Literal["PASS", "FAIL"]
    message: str | None = None  # Error message (only for FAIL)
    action: str | None = None  # Actionable fix instruction (only for FAIL)
    schema: str | None = None  # Schema path (only for schema_valid checks)
    json_path: str | None = None  # JSON path to error (only for schema errors)


@dataclass
class AcceptInfo:
    """Information about accept.json if present.

    Full parity with HandbackInfo: 5 fields for consistent serialization.
    """

    present: bool
    state: str | None = None  # "agent" (current state)
    timestamp: str | None = None  # ISO8601 timestamp when control was granted
    valid: bool = True
    warning: str | None = None


@dataclass
class HandbackInfo:
    """Information about handback.json if present."""

    present: bool
    reason: str | None = None  # "success" | "error" | "question"
    description: str | None = None
    error_code: str | None = None
    error_message: str | None = None
    valid: bool = True
    warning: str | None = None


@dataclass
class StageValidationResult:
    """Result of stage output validation per A.12 output format.

    This is designed for LLM consumption with actionable error messages.
    """

    status: Literal["pass", "fail"]
    stage_id: str
    checks: list[StageValidationCheck] = field(default_factory=list)
    errors: list[StageValidationCheck] = field(default_factory=list)
    output_params_written: bool = False
    output_params: dict[str, Any] = field(default_factory=dict)
    summary: str = ""
    handback: HandbackInfo | None = None
    accept: AcceptInfo | None = None

    def to_dict(self) -> dict[str, Any]:
        """Convert to JSON-serializable dict per A.12 output format."""
        result: dict[str, Any] = {
            "status": self.status,
            "stage_id": self.stage_id,
            "checks": [
                {k: v for k, v in c.__dict__.items() if v is not None}
                for c in self.checks
            ],
            "errors": [
                {k: v for k, v in e.__dict__.items() if v is not None}
                for e in self.errors
            ],
            "summary": self.summary,
        }
        if self.output_params_written:
            result["output_params_written"] = True
            result["output_params"] = self.output_params
        if self.handback:
            result["handback"] = {
                k: v for k, v in self.handback.__dict__.items() if v is not None
            }
        if self.accept:
            result["accept"] = {
                k: v for k, v in self.accept.__dict__.items() if v is not None
            }
        return result


class ValidationError(Exception):
    """Raised when wf-spec validation fails."""

    def __init__(self, result: ValidationResult) -> None:
        self.result = result
        super().__init__(self._format_message())

    def _format_message(self) -> str:
        lines = ["wf-spec validation failed:"]
        for error in self.result.errors:
            lines.append(f"  - {error}")
        return "\n".join(lines)


def validate_wf_spec(wf_spec_path: Path) -> ValidationResult:
    """Validate wf-spec folder completeness.

    Two-phase validation:
    1. Phase 1 (Fail-Fast): YAML structure validation - exit early if broken
       - wf.yaml exists
       - wf.yaml is valid YAML syntax
       - wf.yaml validates against wf.schema.json
    2. Phase 2 (Collect-All): File existence checks - collect ALL errors
       - All shared templates exist
       - All shared schemas exist
       - For each stage: prompt/main.md exists, all schemas exist

    Args:
        wf_spec_path: Path to the wf-spec folder

    Returns:
        ValidationResult with valid=True if all checks pass, else errors populated
    """
    wf_spec_path = Path(wf_spec_path).resolve()
    result = ValidationResult(valid=True)

    # =========================================================================
    # PHASE 1: Fail-Fast YAML Validation
    # Must fail-fast because we need valid wf.yaml to check stage files
    # =========================================================================
    try:
        workflow = parse_workflow(wf_spec_path)
    except WorkflowParseError as e:
        result.valid = False
        result.errors.append(str(e))
        return result  # Fail fast - can't continue without valid wf.yaml

    # =========================================================================
    # PHASE 2: Collect-All File Existence Checks
    # Collect ALL errors so users see complete picture in one run
    # =========================================================================

    # Check shared templates from shared_templates config
    shared_templates = workflow.get("shared_templates", [])
    for template in shared_templates:
        source = wf_spec_path / template["source"]
        if not source.exists():
            result.valid = False
            result.errors.append(
                f"Missing required file: {source}\n"
                f"Action: Create this file in the wf-spec folder.\n"
                f"See: wf.yaml shared_templates section."
            )

    # Check shared schemas
    shared_schemas = ["wf-result.schema.json"]  # Required shared schema
    for schema_name in shared_schemas:
        schema_path = wf_spec_path / "schemas" / schema_name
        if not schema_path.exists():
            result.valid = False
            result.errors.append(
                f"Missing required schema: {schema_path}\n"
                f"Action: Create {schema_name} in wf-spec/schemas/.\n"
                f"See: Plan Appendix A.5 for schema content."
            )

    # Check each stage's required files
    stages = workflow.get("stages", [])
    for stage in stages:
        stage_id = stage["id"]
        stage_dir = wf_spec_path / "stages" / stage_id

        # Check stage directory exists
        if not stage_dir.exists():
            result.valid = False
            result.errors.append(
                f"Missing stage directory: {stage_dir}\n"
                f"Action: Create stages/{stage_id}/ directory with prompt/main.md."
            )
            continue  # Can't check files in missing directory

        # Check prompt/main.md exists
        prompt_path = stage_dir / "prompt" / "main.md"
        if not prompt_path.exists():
            result.valid = False
            result.errors.append(
                f"Missing required file: {prompt_path}\n"
                f"Action: Create main.md with the stage prompt content.\n"
                f"See: stages/{stage_id}/prompt/ directory."
            )

        # Check stage-specific schemas exist
        # Extract schema names from outputs.data entries
        outputs = stage.get("outputs", {})
        data_outputs = outputs.get("data", [])
        for output in data_outputs:
            schema_ref = output.get("schema")
            if schema_ref:
                # Schema paths in wf.yaml are relative to stage (e.g., "schemas/findings.schema.json")
                # For stages, schemas are in wf-spec/stages/{stage_id}/schemas/
                if schema_ref.startswith("schemas/"):
                    schema_name = schema_ref[len("schemas/") :]
                    # Check if it's the shared wf-result.schema.json
                    if schema_name == "wf-result.schema.json":
                        # Shared schema - checked above
                        continue
                    # Stage-specific schema
                    schema_path = stage_dir / "schemas" / schema_name
                    if not schema_path.exists():
                        result.valid = False
                        result.errors.append(
                            f"Missing stage schema: {schema_path}\n"
                            f"Action: Create {schema_name} in stages/{stage_id}/schemas/.\n"
                            f"See: Stage output definition in wf.yaml."
                        )

    return result


def validate_or_raise(wf_spec_path: Path) -> dict[str, Any]:
    """Validate wf-spec and return workflow dict, or raise ValidationError.

    Convenience function that combines validation and parsing.

    Args:
        wf_spec_path: Path to the wf-spec folder

    Returns:
        Parsed workflow definition dict

    Raises:
        ValidationError: If validation fails
    """
    result = validate_wf_spec(wf_spec_path)
    if not result.valid:
        raise ValidationError(result)

    # Re-parse to get workflow dict (validation already passed)
    return parse_workflow(wf_spec_path)


# =============================================================================
# Stage Output Validation (A.12 Algorithm)
# =============================================================================


def validate_stage(stage_path: Path) -> StageValidationResult:
    """Validate stage outputs per A.12 algorithm.

    This function is designed to be called by an LLM at the end of stage
    execution to verify completion. It provides actionable error messages.

    Steps (per A.12):
    1. Load stage-config.yaml
    2. For each output in files, data, runtime:
       - Check file exists (if required)
       - Check file is not empty
       - Validate against schema (if declared)
    3. If validation passes, extract output_parameters
    4. Write output-params.json on success
    5. Generate summary

    Args:
        stage_path: Path to stage folder (e.g., "run/stages/explore")

    Returns:
        StageValidationResult with status, checks, errors, and output_params
    """
    # Import here to avoid circular import
    from chainglass.stage import resolve_query

    stage_path = Path(stage_path).resolve()

    # Load stage-config.yaml
    config_path = stage_path / "stage-config.yaml"
    if not config_path.exists():
        return StageValidationResult(
            status="fail",
            stage_id=stage_path.name,
            errors=[
                StageValidationCheck(
                    check="config_exists",
                    path="stage-config.yaml",
                    status="FAIL",
                    message="stage-config.yaml not found",
                    action="Run 'chainglass compose' first to create the stage structure.",
                )
            ],
            summary=f"Stage '{stage_path.name}': 0 checks passed, 1 error",
        )

    config = yaml.safe_load(config_path.read_text()) or {}
    stage_id = config.get("id", stage_path.name)

    result = StageValidationResult(status="pass", stage_id=stage_id)

    # Validate outputs from all categories: files, data, runtime
    outputs_config = config.get("outputs", {})

    # Category: files
    for output in outputs_config.get("files", []):
        _validate_output_file(stage_path, output, result, has_schema=False)

    # Category: data
    for output in outputs_config.get("data", []):
        is_required = output.get("required", True)
        _validate_output_file(
            stage_path, output, result, has_schema=True, required=is_required
        )

    # Category: runtime (if present in config)
    for output in outputs_config.get("runtime", []):
        is_required = output.get("required", False)  # Runtime often optional
        _validate_output_file(
            stage_path, output, result, has_schema=True, required=is_required
        )

    # Extract output_parameters if validation passed
    if result.status == "pass":
        output_params = config.get("output_parameters", [])
        if output_params:
            extracted = {}
            for param in output_params:
                source_path = stage_path / param["source"]
                # Security: validate source path is within stage
                if not source_path.resolve().is_relative_to(stage_path):
                    continue  # Skip malicious source
                if source_path.exists():
                    try:
                        data = json.loads(source_path.read_text())
                        value = resolve_query(data, param["query"])
                        if value is not None:
                            extracted[param["name"]] = value
                    except (json.JSONDecodeError, KeyError):
                        pass  # Already validated, shouldn't happen

            if extracted:
                # Write output-params.json
                output_params_path = (
                    stage_path / "run" / "output-data" / "output-params.json"
                )
                output_params_path.parent.mkdir(parents=True, exist_ok=True)
                output_params_data = {
                    "stage_id": stage_id,
                    "published_at": datetime.now(timezone.utc).isoformat(),
                    "parameters": extracted,
                }
                output_params_path.write_text(json.dumps(output_params_data, indent=2))
                result.output_params_written = True
                result.output_params = extracted

    # Detect and validate accept.json (informational, does not affect pass/fail)
    accept_path = stage_path / "run" / "output-data" / "accept.json"
    if not accept_path.exists():
        # Accept is optional - just note absence
        result.accept = AcceptInfo(
            present=False,
            warning="accept.json not found - orchestrator has not granted control",
        )
    else:
        # Load accept.json
        accept_info = AcceptInfo(present=True)
        try:
            accept_data = json.loads(accept_path.read_text())
            accept_info.state = accept_data.get("state")
            accept_info.timestamp = accept_data.get("timestamp")

            # Validate against schema if available (informational only)
            schema_path = stage_path / "schemas" / "accept.schema.json"
            if schema_path.exists():
                try:
                    schema = json.loads(schema_path.read_text())
                    jsonschema.validate(accept_data, schema)
                except json.JSONDecodeError:
                    accept_info.valid = False
                    accept_info.warning = "accept.schema.json is invalid JSON"
                except jsonschema.ValidationError as e:
                    accept_info.valid = False
                    accept_info.warning = f"accept.json validation failed: {e.message}"
                    # Note: This is informational only - does NOT fail validation

        except json.JSONDecodeError as e:
            accept_info.valid = False
            accept_info.warning = f"Invalid JSON in accept.json: {e.msg}"
            # Note: This is informational only - does NOT fail validation

        result.accept = accept_info

    # Detect and validate handback.json
    handback_path = stage_path / "run" / "output-data" / "handback.json"
    if not handback_path.exists():
        # Handback is optional - warn but don't fail
        result.handback = HandbackInfo(
            present=False,
            warning="handback.json not found - remember to write handback.json before calling handback command",
        )
    else:
        # Load and validate handback
        handback_info = HandbackInfo(present=True)
        try:
            handback_data = json.loads(handback_path.read_text())
            handback_info.reason = handback_data.get("reason")
            handback_info.description = handback_data.get("description")

            # Extract error details if reason is error
            if handback_info.reason == "error" and "error" in handback_data:
                error_obj = handback_data["error"]
                handback_info.error_code = error_obj.get("code")
                handback_info.error_message = error_obj.get("message")

            # Validate against schema if available
            schema_path = stage_path / "schemas" / "handback.schema.json"
            if schema_path.exists():
                try:
                    schema = json.loads(schema_path.read_text())
                    jsonschema.validate(handback_data, schema)
                except json.JSONDecodeError:
                    handback_info.valid = False
                    handback_info.warning = "handback.schema.json is invalid JSON"
                except jsonschema.ValidationError as e:
                    handback_info.valid = False
                    # Add validation error to result
                    result.errors.append(
                        StageValidationCheck(
                            check="schema_valid",
                            path="run/output-data/handback.json",
                            schema="schemas/handback.schema.json",
                            status="FAIL",
                            message=f"Handback validation failed: {e.message}",
                            action="Fix handback.json to match handback.schema.json.",
                        )
                    )
                    result.status = "fail"

        except json.JSONDecodeError as e:
            handback_info.valid = False
            result.errors.append(
                StageValidationCheck(
                    check="schema_valid",
                    path="run/output-data/handback.json",
                    status="FAIL",
                    message=f"Invalid JSON in handback.json: {e.msg}",
                    action="Fix the JSON syntax error in handback.json.",
                )
            )
            result.status = "fail"

        result.handback = handback_info

    # Generate summary
    passed = len(result.checks)
    failed = len(result.errors)
    summary_parts = [f"Stage '{stage_id}': {passed} checks passed, {failed} errors"]
    if result.output_params_written:
        param_count = len(result.output_params)
        summary_parts.append(f"{param_count} output_parameters published")
    if result.handback and result.handback.present:
        summary_parts.append(f"Handback: {result.handback.reason}")
    result.summary = ", ".join(summary_parts)

    return result


def _validate_output_file(
    stage_path: Path,
    output: dict,
    result: StageValidationResult,
    has_schema: bool,
    required: bool = True,
) -> None:
    """Validate a single output file per A.12 checks.

    Modifies result in-place, adding checks and errors.

    Args:
        stage_path: Path to stage folder
        output: Output definition dict with path, schema (optional)
        result: StageValidationResult to update
        has_schema: Whether this output type can have schemas
        required: Whether the file is required
    """
    output_path = stage_path / output["path"]
    rel_path = output["path"]

    # Security: Check for path traversal
    if not output_path.resolve().is_relative_to(stage_path):
        result.status = "fail"
        result.errors.append(
            StageValidationCheck(
                check="path_security",
                path=rel_path,
                status="FAIL",
                message="Invalid path: escapes stage directory",
                action="Remove '..' or absolute path components from output path in stage-config.yaml.",
            )
        )
        return  # Skip further checks for this file

    # Check 1: File exists
    if not output_path.exists():
        if required:
            result.status = "fail"
            result.errors.append(
                StageValidationCheck(
                    check="file_exists",
                    path=rel_path,
                    status="FAIL",
                    message=f"Missing required output: {rel_path}",
                    action="Write this file before completing the stage.",
                )
            )
        return  # Skip further checks if file missing

    result.checks.append(
        StageValidationCheck(check="file_exists", path=rel_path, status="PASS")
    )

    # Check 2: File is not empty
    if output_path.stat().st_size == 0:
        result.status = "fail"
        result.errors.append(
            StageValidationCheck(
                check="file_not_empty",
                path=rel_path,
                status="FAIL",
                message=f"Output file is empty: {rel_path}",
                action="Write content to this file.",
            )
        )
        return  # Skip schema check if empty

    result.checks.append(
        StageValidationCheck(check="file_not_empty", path=rel_path, status="PASS")
    )

    # Check 3: Schema validation (if schema declared)
    if has_schema and "schema" in output:
        schema_ref = output["schema"]
        schema_path = stage_path / schema_ref

        # Security: Check for path traversal on schema
        if not schema_path.resolve().is_relative_to(stage_path):
            result.status = "fail"
            result.errors.append(
                StageValidationCheck(
                    check="schema_security",
                    path=rel_path,
                    schema=schema_ref,
                    status="FAIL",
                    message="Invalid schema path: escapes stage directory",
                    action="Remove '..' or absolute path components from schema path in stage-config.yaml.",
                )
            )
            return

        if not schema_path.exists():
            result.status = "fail"
            result.errors.append(
                StageValidationCheck(
                    check="schema_valid",
                    path=rel_path,
                    schema=schema_ref,
                    status="FAIL",
                    message=f"Schema file not found: {schema_ref}",
                    action=f"Create the schema file at {schema_ref}.",
                )
            )
            return

        # Load schema first (separate error handling)
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
            result.checks.append(
                StageValidationCheck(
                    check="schema_valid",
                    path=rel_path,
                    schema=schema_ref,
                    status="PASS",
                )
            )
        except json.JSONDecodeError as e:
            result.status = "fail"
            result.errors.append(
                StageValidationCheck(
                    check="schema_valid",
                    path=rel_path,
                    schema=schema_ref,
                    status="FAIL",
                    message=f"Invalid JSON in data file: {e.msg}",
                    action="Fix the JSON syntax error in the data file.",
                )
            )
        except jsonschema.ValidationError as e:
            result.status = "fail"
            json_path_str = ".".join(str(p) for p in e.absolute_path) or ""
            result.errors.append(
                StageValidationCheck(
                    check="schema_valid",
                    path=rel_path,
                    schema=schema_ref,
                    status="FAIL",
                    message=f"Schema validation failed: {e.message}",
                    json_path=json_path_str,
                    action=f"Fix the JSON structure. Error at '{json_path_str}': {e.message}. See {schema_ref} for required format.",
                )
            )
