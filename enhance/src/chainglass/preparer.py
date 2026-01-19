"""Preparer module for prepare-wf-stage command.

Copies inputs from prior stages and resolves parameters.
"""

import json
import shutil
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from chainglass.stage import Stage


@dataclass
class PrepareResult:
    """Result of preparing a stage."""

    success: bool
    files_copied: list[str] = field(default_factory=list)
    params_resolved: dict[str, Any] = field(default_factory=dict)
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


def prepare_wf_stage(
    stage_id: str,
    run_dir: Path,
    dry_run: bool = False,
) -> PrepareResult:
    """
    Prepare a stage by copying inputs from prior stages and resolving parameters.

    Algorithm (A.11 from plan):
    1. Load target stage config
    2. For each input with from_stage:
       a. Load source stage
       b. Get output file/data path
       c. Copy to target inputs folder (unless dry_run)
    3. For each parameter with from_stage:
       a. Load source stage
       b. Get parameter from output-params.json
       c. Collect in params dict
    4. Write params.json to inputs folder (unless dry_run)

    Args:
        stage_id: ID of the stage to prepare (e.g., "specify")
        run_dir: Path to the run directory
        dry_run: If True, validate without writing

    Returns:
        PrepareResult with success status and details
    """
    run_dir = Path(run_dir).resolve()
    result = PrepareResult(success=True)

    # Load target stage
    target_path = run_dir / "stages" / stage_id
    if not target_path.exists():
        result.success = False
        result.errors.append(
            f"Stage folder not found: {target_path}\n"
            f"Action: Run compose first to create the run folder."
        )
        return result

    target = Stage(target_path)

    # Cache for source stages to avoid reloading
    source_stages: dict[str, Stage] = {}
    # Track which stages have already reported errors (to avoid duplicate messages)
    reported_errors: set[str] = set()

    def get_source_stage(from_stage: str) -> Stage | None:
        """Get or load source stage, checking if finalized."""
        if from_stage in source_stages:
            return source_stages[from_stage]

        # If we already reported an error for this stage, just return None
        if from_stage in reported_errors:
            return None

        source_path = run_dir / "stages" / from_stage
        if not source_path.exists():
            result.errors.append(
                f"Source stage folder not found: {from_stage}\n"
                f"Action: Ensure stage '{from_stage}' exists in the run folder."
            )
            reported_errors.add(from_stage)
            return None

        source = Stage(source_path)

        # Check if source stage has been finalized
        if not source.is_finalized:
            result.errors.append(
                f"Source stage not finalized: {from_stage}\n"
                f"Action: Run 'chainglass finalize {from_stage} --run-dir {run_dir}' first."
            )
            reported_errors.add(from_stage)
            return None

        source_stages[from_stage] = source
        return source

    # Step 2: Copy inputs with from_stage
    inputs = target.config.get("inputs", {})
    for input_def in inputs.get("required", []):
        from_stage = input_def.get("from_stage")
        if not from_stage:
            continue  # No from_stage means user must provide

        source = get_source_stage(from_stage)
        if not source:
            result.success = False
            continue

        # Get source path from input definition
        source_rel_path = input_def.get("source")
        if not source_rel_path:
            result.errors.append(
                f"Input '{input_def['name']}' has from_stage but no source path."
            )
            result.success = False
            continue

        source_path = source.path / source_rel_path

        # FIX-003: Validate source path stays within source stage
        source_abs = source_path.resolve()
        if not source_abs.is_relative_to(source.path):
            result.errors.append(
                f"Path traversal detected in input source: {source_rel_path}\n"
                f"  Action: Remove '../' from path in stage-config.yaml."
            )
            result.success = False
            continue

        if not source_path.exists():
            result.errors.append(
                f"Missing source file for input '{input_def['name']}':\n"
                f"  Expected: {source_path}\n"
                f"  Action: Ensure the source stage has this output."
            )
            result.success = False
            continue

        # Target path
        target_rel_path = input_def.get("path")
        target_path_file = target.path / target_rel_path

        # FIX-003: Validate target path stays within target stage
        target_abs = target_path_file.resolve()
        if not target_abs.is_relative_to(target.path):
            result.errors.append(
                f"Path traversal detected in input path: {target_rel_path}\n"
                f"  Action: Remove '../' from path in stage-config.yaml."
            )
            result.success = False
            continue

        if not dry_run:
            # FIX-012: Add error handling for file copy
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

        result.files_copied.append(f"{input_def['name']}: {source_path} -> {target_path_file}")

    # Step 3: Resolve parameters with from_stage
    parameters = target.config.get("parameters", [])
    resolved_params: dict[str, Any] = {}

    for param_def in parameters:
        from_stage = param_def.get("from_stage")
        if not from_stage:
            continue  # No from_stage means user must provide

        source = get_source_stage(from_stage)
        if not source:
            result.success = False
            continue

        # Get parameter name from output_parameter
        output_param_name = param_def.get("output_parameter")
        if not output_param_name:
            result.errors.append(
                f"Parameter '{param_def['name']}' has from_stage but no output_parameter."
            )
            result.success = False
            continue

        # Get parameter value from source stage's output-params.json
        source_params = source.get_output_params()
        if output_param_name not in source_params:
            result.errors.append(
                f"Parameter '{param_def['name']}' not found in source stage '{from_stage}':\n"
                f"  Looking for: {output_param_name}\n"
                f"  Available: {list(source_params.keys())}\n"
                f"  Action: Check the source stage's output_parameters definition."
            )
            result.success = False
            continue

        resolved_params[param_def["name"]] = source_params[output_param_name]

    result.params_resolved = resolved_params

    # Step 4: Write params.json (unless dry_run or errors)
    # FIX-006: Write even if params dict is empty (removed `and resolved_params` check)
    if result.success and not dry_run:
        params_path = target.path / "inputs" / "params.json"
        # FIX-013: Add error handling for params write
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

    # Set final success state
    if result.errors:
        result.success = False

    return result
