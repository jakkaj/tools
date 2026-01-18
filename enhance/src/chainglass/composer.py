"""Composer module for creating run folders from wf-spec.

Implements the A.10 Compose Algorithm from the plan.
"""

import json
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import yaml

from chainglass.validator import ValidationError, validate_or_raise


class CompositionError(Exception):
    """Raised when composition fails."""

    pass


def compose(wf_spec_path: Path, output_path: Path) -> Path:
    """Create a run folder from a wf-spec folder.

    Implements the A.10 Compose Algorithm:
    1. Load and validate wf.yaml against wf.schema.json
    2. Create run folder: output_path/run-{date}-{ordinal}/
    3. Write wf-run.json with initial metadata
    4. For each stage in wf.yaml.stages (in order):
       a. Create stage folder: stages/{stage.id}/
       b. Create subdirs: inputs/, prompt/, run/output-files/,
          run/output-data/, run/runtime-inputs/, schemas/
       c. EXTRACT stage config from wf.yaml and write to stage-config.yaml
       d. Copy prompt/main.md from wf-spec/stages/{stage.id}/prompt/
       e. Copy stage-specific schemas from wf-spec/stages/{stage.id}/schemas/
       f. For each shared_template in wf.yaml:
          - Copy source to target location in stage
    5. Return path to created run folder

    Args:
        wf_spec_path: Path to the wf-spec folder
        output_path: Path to the output directory

    Returns:
        Path to the created run folder

    Raises:
        ValidationError: If wf-spec validation fails
        CompositionError: If composition fails
    """
    wf_spec_path = Path(wf_spec_path).resolve()
    output_path = Path(output_path).resolve()

    # Step 1: Validate and load wf.yaml
    try:
        workflow = validate_or_raise(wf_spec_path)
    except ValidationError:
        raise  # Re-raise validation errors as-is

    # Step 2: Create run folder with unique ordinal
    run_folder = _create_run_folder(output_path)

    try:
        # Step 3: Write wf-run.json
        _write_wf_run_json(run_folder, workflow, wf_spec_path)

        # Step 4: Process each stage
        stages = workflow.get("stages", [])
        shared_templates = workflow.get("shared_templates", [])

        # Sort stages by id for deterministic ordering
        for stage in sorted(stages, key=lambda s: s["id"]):
            _compose_stage(
                run_folder=run_folder,
                stage=stage,
                wf_spec_path=wf_spec_path,
                shared_templates=shared_templates,
            )

    except Exception as e:
        # Clean up on failure
        if run_folder.exists():
            shutil.rmtree(run_folder)
        raise CompositionError(f"Failed to compose run folder: {e}") from e

    return run_folder


def _create_run_folder(output_path: Path) -> Path:
    """Create a unique run folder with date-ordinal naming."""
    output_path.mkdir(parents=True, exist_ok=True)

    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    ordinal = 1

    # Find unique ordinal
    while True:
        run_name = f"run-{today}-{ordinal:03d}"
        run_folder = output_path / run_name
        if not run_folder.exists():
            break
        ordinal += 1

    run_folder.mkdir(parents=True)
    return run_folder


def _write_wf_run_json(run_folder: Path, workflow: dict[str, Any], wf_spec_path: Path) -> None:
    """Write wf-run.json with run metadata."""
    metadata = workflow.get("metadata", {})
    stages = workflow.get("stages", [])

    wf_run = {
        "run_id": run_folder.name,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "workflow": {
            "name": metadata.get("name", "unknown"),
            "version": workflow.get("version", "1.0"),
            "source": str(wf_spec_path),
        },
        "stages": [
            {
                "id": stage["id"],
                "status": "pending",
                "started_at": None,
                "completed_at": None,
            }
            for stage in sorted(stages, key=lambda s: s["id"])
        ],
    }

    wf_run_path = run_folder / "wf-run.json"
    with open(wf_run_path, "w") as f:
        json.dump(wf_run, f, indent=2)


def _compose_stage(
    run_folder: Path,
    stage: dict[str, Any],
    wf_spec_path: Path,
    shared_templates: list[dict[str, str]],
) -> None:
    """Compose a single stage in the run folder."""
    stage_id = stage["id"]
    stage_dir = run_folder / "stages" / stage_id

    # Step 4a-b: Create stage folder and subdirectories
    subdirs = [
        "inputs",
        "prompt",
        "run/output-files",
        "run/output-data",
        "run/runtime-inputs",
        "schemas",
    ]
    for subdir in subdirs:
        (stage_dir / subdir).mkdir(parents=True, exist_ok=True)

    # Step 4c: Extract stage config and write to stage-config.yaml
    _write_stage_config(stage_dir, stage, wf_spec_path)

    # Step 4d: Copy prompt/main.md
    src_prompt = wf_spec_path / "stages" / stage_id / "prompt" / "main.md"
    dst_prompt = stage_dir / "prompt" / "main.md"
    if src_prompt.exists():
        shutil.copy2(src_prompt, dst_prompt)

    # Step 4e: Copy stage-specific schemas
    src_schemas_dir = wf_spec_path / "stages" / stage_id / "schemas"
    if src_schemas_dir.exists():
        for schema_file in sorted(src_schemas_dir.iterdir()):
            if schema_file.is_file():
                shutil.copy2(schema_file, stage_dir / "schemas" / schema_file.name)

    # Step 4f: Copy shared templates
    for template in shared_templates:
        src = wf_spec_path / template["source"]
        dst = stage_dir / template["target"]
        if src.exists():
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)


def _write_stage_config(stage_dir: Path, stage: dict[str, Any], wf_spec_path: Path) -> None:
    """Extract stage config from wf.yaml and write as stage-config.yaml."""
    # Extract relevant fields for stage config
    stage_config = {
        "id": stage["id"],
        "name": stage.get("name", stage["id"]),
        "description": stage.get("description", ""),
        "inputs": stage.get("inputs", {"required": [], "optional": []}),
        "outputs": stage.get("outputs", {"files": [], "data": []}),
        "prompt": stage.get("prompt", {}),
    }

    # Include parameters if present
    if "parameters" in stage:
        stage_config["parameters"] = stage["parameters"]

    # Include output_parameters if present
    if "output_parameters" in stage:
        stage_config["output_parameters"] = stage["output_parameters"]

    # Write with header comment
    config_path = stage_dir / "stage-config.yaml"
    with open(config_path, "w") as f:
        f.write(f"# Extracted from wf.yaml during compose\n")
        f.write(f"# Source: {wf_spec_path}/wf.yaml\n")
        f.write(f"# Stage: {stage['id']}\n\n")
        # Use sort_keys=False to preserve logical field ordering
        yaml.dump(stage_config, f, default_flow_style=False, sort_keys=False, allow_unicode=True)
