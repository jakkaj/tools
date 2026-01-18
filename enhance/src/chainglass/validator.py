"""Validator for wf-spec folder completeness.

Implements two-phase validation:
- Phase 1 (Fail-Fast): YAML structure validation - exit early if broken
- Phase 2 (Collect-All): File existence checks - collect ALL errors
"""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from chainglass.parser import WorkflowParseError, parse_workflow


@dataclass
class ValidationResult:
    """Result of wf-spec validation."""

    valid: bool
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


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
