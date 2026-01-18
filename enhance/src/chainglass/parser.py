"""YAML parser for wf.yaml workflow definitions."""

import json
from pathlib import Path
from typing import Any

import yaml
from jsonschema import Draft202012Validator, ValidationError


class WorkflowParseError(Exception):
    """Raised when workflow parsing or validation fails."""

    def __init__(self, message: str, path: Path | None = None) -> None:
        self.path = path
        super().__init__(message)


def parse_workflow(wf_spec_path: Path) -> dict[str, Any]:
    """Load and validate wf.yaml from a wf-spec folder.

    Args:
        wf_spec_path: Path to the wf-spec folder containing wf.yaml

    Returns:
        Parsed and validated workflow definition as a dict

    Raises:
        WorkflowParseError: If wf.yaml is missing, invalid YAML, or fails schema validation
    """
    wf_spec_path = Path(wf_spec_path).resolve()
    wf_yaml_path = wf_spec_path / "wf.yaml"
    schema_path = wf_spec_path / "schemas" / "wf.schema.json"

    # Check wf.yaml exists
    if not wf_yaml_path.exists():
        raise WorkflowParseError(
            f"Missing required file: {wf_yaml_path}\n"
            f"Action: Create wf.yaml in the wf-spec folder with your workflow definition.",
            path=wf_yaml_path,
        )

    # Parse YAML
    try:
        with open(wf_yaml_path) as f:
            workflow = yaml.safe_load(f)
    except yaml.YAMLError as e:
        raise WorkflowParseError(
            f"Invalid YAML in {wf_yaml_path}:\n{e}\n"
            f"Action: Fix the YAML syntax errors in wf.yaml.",
            path=wf_yaml_path,
        ) from e

    if workflow is None:
        raise WorkflowParseError(
            f"Empty workflow file: {wf_yaml_path}\n"
            f"Action: Add workflow definition content to wf.yaml.",
            path=wf_yaml_path,
        )

    # Validate against schema
    if not schema_path.exists():
        raise WorkflowParseError(
            f"Missing schema file: {schema_path}\n"
            f"Action: Add wf.schema.json to the wf-spec/schemas/ folder.",
            path=schema_path,
        )

    try:
        with open(schema_path) as f:
            schema = json.load(f)
    except json.JSONDecodeError as e:
        raise WorkflowParseError(
            f"Invalid JSON in schema file: {schema_path}:\n{e}\n"
            f"Action: Fix the JSON syntax errors in wf.schema.json.",
            path=schema_path,
        ) from e

    # Validate workflow against schema
    validator = Draft202012Validator(schema)
    errors = list(validator.iter_errors(workflow))

    if errors:
        error_messages = []
        for error in errors:
            path_str = ".".join(str(p) for p in error.absolute_path) if error.absolute_path else "(root)"
            error_messages.append(f"  - At '{path_str}': {error.message}")

        raise WorkflowParseError(
            f"Schema validation failed for {wf_yaml_path}:\n"
            + "\n".join(error_messages)
            + f"\n\nAction: Fix the errors in wf.yaml to match the schema in {schema_path}.",
            path=wf_yaml_path,
        )

    return workflow
