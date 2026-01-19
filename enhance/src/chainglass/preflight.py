"""Preflight validation for stage inputs before LLM execution.

This module validates that a stage is ready to execute by checking:
- Stage configuration is valid (stage-config.yaml exists and is valid YAML)
- Prompt files exist (prompt/wf.md, prompt/main.md)
- Required input files exist and are non-empty
- Source stages are finalized (for inputs with from_stage)
- Parameters can be resolved from upstream output-params.json

This complements validator.py which checks OUTPUTS after execution.
Preflight checks INPUTS before execution starts.

Two-Phase Validation (per DYK-01):
- Phase 1: Config + prompt + file existence checks (fast, no JSON parsing)
- Phase 2: Source stage finalization + parameter resolution (requires finalization gate)
"""

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal

import yaml


@dataclass
class PreflightCheck:
    """A single preflight check result.

    Mirrors StageValidationCheck from validator.py but for input validation.
    """

    check: str  # "config_exists", "prompt_exists", "input_exists", "source_finalized", "param_resolved"
    path: str  # Relative path or identifier being checked
    status: Literal["PASS", "FAIL"]
    message: str | None = None  # Error message (only for FAIL)
    action: str | None = None  # Actionable fix instruction (only for FAIL)
    name: str | None = None  # Input/param name for context
    description: str | None = None  # Input description for actionable errors (per DYK-04)


@dataclass
class PreflightResult:
    """Result of preflight validation.

    Mirrors StageValidationResult from validator.py.
    """

    status: Literal["pass", "fail"]
    stage_id: str
    checks: list[PreflightCheck] = field(default_factory=list)
    errors: list[PreflightCheck] = field(default_factory=list)
    summary: str = ""

    def to_dict(self) -> dict[str, Any]:
        """Convert to JSON-serializable dict."""
        return {
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


def preflight(stage_path: Path) -> PreflightResult:
    """Validate stage inputs are ready for LLM execution.

    Two-phase validation (per DYK-01):
    - Phase 1: Config, prompts, file existence (fast, no JSON)
    - Phase 2: Source finalization, parameter resolution (requires finalization gate)

    Args:
        stage_path: Path to stage folder (e.g., "run/stages/explore")

    Returns:
        PreflightResult with status, checks, and errors
    """
    stage_path = Path(stage_path).resolve()

    # =========================================================================
    # PHASE 1: Config + Prompt + File Existence (fail-fast on config)
    # =========================================================================

    # Check 1: stage-config.yaml exists
    config_path = stage_path / "stage-config.yaml"
    if not config_path.exists():
        return PreflightResult(
            status="fail",
            stage_id=stage_path.name,
            errors=[
                PreflightCheck(
                    check="config_exists",
                    path="stage-config.yaml",
                    status="FAIL",
                    message="stage-config.yaml not found",
                    action="Run 'chainglass compose' first to create the stage structure.",
                )
            ],
            summary=f"Stage '{stage_path.name}': 0 checks passed, 1 error",
        )

    # Check 2: stage-config.yaml is valid YAML
    try:
        config = yaml.safe_load(config_path.read_text())
        if config is None:
            return PreflightResult(
                status="fail",
                stage_id=stage_path.name,
                errors=[
                    PreflightCheck(
                        check="config_valid",
                        path="stage-config.yaml",
                        status="FAIL",
                        message="stage-config.yaml is empty",
                        action="Regenerate with 'chainglass compose'.",
                    )
                ],
                summary=f"Stage '{stage_path.name}': 0 checks passed, 1 error",
            )
    except yaml.YAMLError as e:
        return PreflightResult(
            status="fail",
            stage_id=stage_path.name,
            errors=[
                PreflightCheck(
                    check="config_valid",
                    path="stage-config.yaml",
                    status="FAIL",
                    message=f"Invalid YAML: {e}",
                    action="Fix YAML syntax errors in stage-config.yaml.",
                )
            ],
            summary=f"Stage '{stage_path.name}': 0 checks passed, 1 error",
        )

    stage_id = config.get("id", stage_path.name)
    result = PreflightResult(status="pass", stage_id=stage_id)

    # Config is valid
    result.checks.append(
        PreflightCheck(check="config_exists", path="stage-config.yaml", status="PASS")
    )

    # Check 3: Prompt files exist
    prompt_config = config.get("prompt", {})
    entry_prompt = prompt_config.get("entry", "prompt/wf.md")
    main_prompt = prompt_config.get("main", "prompt/main.md")

    for prompt_path in [entry_prompt, main_prompt]:
        full_path = stage_path / prompt_path
        # Security: validate path is within stage
        if not full_path.resolve().is_relative_to(stage_path):
            result.status = "fail"
            result.errors.append(
                PreflightCheck(
                    check="path_security",
                    path=prompt_path,
                    status="FAIL",
                    message="Invalid path: escapes stage directory",
                    action="Remove '..' from path in stage-config.yaml.",
                )
            )
            continue

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

    # Check 4: Required input files exist (user-provided, not from_stage)
    inputs_config = config.get("inputs", {})
    required_inputs = inputs_config.get("required", [])

    # Collect from_stage inputs for Phase 2
    from_stage_inputs: list[dict] = []
    from_stage_params: list[dict] = []

    for input_def in required_inputs:
        input_path = input_def.get("path", "")
        input_name = input_def.get("name", input_path)
        input_desc = input_def.get("description", "")

        # Security: validate path
        full_path = stage_path / input_path
        if not full_path.resolve().is_relative_to(stage_path):
            result.status = "fail"
            result.errors.append(
                PreflightCheck(
                    check="path_security",
                    path=input_path,
                    status="FAIL",
                    message="Invalid path: escapes stage directory",
                    action="Remove '..' from path in stage-config.yaml.",
                    name=input_name,
                )
            )
            continue

        # Check if this is a from_stage input (handled in Phase 2)
        if "from_stage" in input_def:
            from_stage_inputs.append(input_def)
            continue

        # User-provided input - check existence with atomic stat()
        try:
            stat_result = full_path.stat()
            if stat_result.st_size == 0:
                result.status = "fail"
                result.errors.append(
                    PreflightCheck(
                        check="input_not_empty",
                        path=input_path,
                        status="FAIL",
                        message=f"Input file is empty: {input_path}",
                        action=f"Add content to {input_path}.",
                        name=input_name,
                        description=input_desc,
                    )
                )
            else:
                result.checks.append(
                    PreflightCheck(
                        check="input_exists",
                        path=input_path,
                        status="PASS",
                        name=input_name,
                    )
                )
        except FileNotFoundError:
            result.status = "fail"
            action_msg = "Create this file"
            if input_desc:
                action_msg += f" with: {input_desc}"
            result.errors.append(
                PreflightCheck(
                    check="input_exists",
                    path=input_path,
                    status="FAIL",
                    message=f"Missing required input: {input_path}",
                    action=action_msg,
                    name=input_name,
                    description=input_desc,
                )
            )

    # Collect parameters with from_stage for Phase 2
    params_config = config.get("parameters", [])
    for param_def in params_config:
        if "from_stage" in param_def:
            from_stage_params.append(param_def)

    # =========================================================================
    # PHASE 2: Source Stage Finalization + Parameter Resolution
    # Only run if Phase 1 passed (per DYK-01 two-phase pattern)
    # =========================================================================

    if result.status == "pass" and (from_stage_inputs or from_stage_params):
        # Collect unique source stages
        source_stages: set[str] = set()
        for inp in from_stage_inputs:
            source_stages.add(inp["from_stage"])
        for param in from_stage_params:
            source_stages.add(param["from_stage"])

        # Check each source stage is finalized
        run_dir = stage_path.parent.parent  # stages/ -> run/
        finalized_stages: set[str] = set()

        for source_stage_id in source_stages:
            source_stage_path = run_dir / "stages" / source_stage_id
            output_params_path = (
                source_stage_path / "run" / "output-data" / "output-params.json"
            )

            # Simple finalization check (per DYK-05)
            if output_params_path.exists():
                finalized_stages.add(source_stage_id)
                result.checks.append(
                    PreflightCheck(
                        check="source_finalized",
                        path=f"stages/{source_stage_id}",
                        status="PASS",
                        name=source_stage_id,
                    )
                )
            else:
                result.status = "fail"
                result.errors.append(
                    PreflightCheck(
                        check="source_finalized",
                        path=f"stages/{source_stage_id}",
                        status="FAIL",
                        message=f"Source stage '{source_stage_id}' not finalized",
                        action=f"Run 'chainglass finalize {source_stage_id} --run-dir <run_dir>' first.",
                        name=source_stage_id,
                    )
                )

        # Check from_stage input files exist (only if source is finalized)
        for input_def in from_stage_inputs:
            source_stage_id = input_def["from_stage"]
            if source_stage_id not in finalized_stages:
                continue  # Already reported as not finalized

            input_path = input_def.get("path", "")
            input_name = input_def.get("name", input_path)
            input_desc = input_def.get("description", "")
            source_path = input_def.get("source", "")

            # Check if source file exists in source stage
            source_stage_path = run_dir / "stages" / source_stage_id
            source_file_path = source_stage_path / source_path

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

            if source_file_path.exists():
                result.checks.append(
                    PreflightCheck(
                        check="input_source_exists",
                        path=input_path,
                        status="PASS",
                        name=input_name,
                    )
                )
            else:
                result.status = "fail"
                result.errors.append(
                    PreflightCheck(
                        check="input_source_exists",
                        path=input_path,
                        status="FAIL",
                        message=f"Source file not found: {source_stage_id}/{source_path}",
                        action=f"Ensure stage '{source_stage_id}' produces '{source_path}' before finalization.",
                        name=input_name,
                        description=input_desc,
                    )
                )

        # Check parameters can be resolved (only if source is finalized)
        for param_def in from_stage_params:
            source_stage_id = param_def["from_stage"]
            if source_stage_id not in finalized_stages:
                continue  # Already reported as not finalized

            param_name = param_def.get("name", "")
            output_param_name = param_def.get("output_parameter", param_name)

            # Load output-params.json from source stage
            source_stage_path = run_dir / "stages" / source_stage_id
            output_params_path = (
                source_stage_path / "run" / "output-data" / "output-params.json"
            )

            try:
                output_params_data = json.loads(output_params_path.read_text())
                params = output_params_data.get("parameters", {})

                if output_param_name in params:
                    result.checks.append(
                        PreflightCheck(
                            check="param_resolved",
                            path=f"{source_stage_id}.{output_param_name}",
                            status="PASS",
                            name=param_name,
                        )
                    )
                else:
                    result.status = "fail"
                    result.errors.append(
                        PreflightCheck(
                            check="param_resolved",
                            path=f"{source_stage_id}.{output_param_name}",
                            status="FAIL",
                            message=f"Parameter '{output_param_name}' not found in {source_stage_id} output-params.json",
                            action=f"Ensure stage '{source_stage_id}' declares output_parameter '{output_param_name}'.",
                            name=param_name,
                        )
                    )
            except (json.JSONDecodeError, FileNotFoundError):
                # Shouldn't happen since we checked finalization, but be safe
                result.status = "fail"
                result.errors.append(
                    PreflightCheck(
                        check="param_resolved",
                        path=f"{source_stage_id}.{output_param_name}",
                        status="FAIL",
                        message=f"Cannot read output-params.json from {source_stage_id}",
                        action=f"Re-finalize stage '{source_stage_id}'.",
                        name=param_name,
                    )
                )

    # Generate summary
    passed = len(result.checks)
    failed = len(result.errors)
    result.summary = f"Stage '{stage_id}': {passed} checks passed, {failed} errors"

    return result
