"""Chainglass CLI - Workflow Composer commands."""

from pathlib import Path

import typer

from chainglass import __version__
from chainglass.composer import CompositionError, compose
from chainglass.preflight import preflight
from chainglass.preparer import prepare_wf_stage
from chainglass.stage import Stage
from chainglass.validator import ValidationError, validate_stage

app = typer.Typer(
    name="chainglass",
    help="Workflow Composer CLI - Transform wf-spec folders into executable run directories.",
    add_completion=False,
)


def version_callback(value: bool) -> None:
    """Print version and exit."""
    if value:
        typer.echo(f"chainglass {__version__}")
        raise typer.Exit()


@app.callback()
def main(
    version: bool = typer.Option(
        None,
        "--version",
        "-v",
        help="Show version and exit.",
        callback=version_callback,
        is_eager=True,
    ),
) -> None:
    """Chainglass - Workflow Composer CLI."""
    pass


@app.command(name="compose")
def compose_cmd(
    wf_spec: Path = typer.Argument(
        ...,
        help="Path to wf-spec folder containing wf.yaml",
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
    ),
    output: Path = typer.Option(
        ...,
        "--output",
        "-o",
        help="Output directory for run folder",
        resolve_path=True,
    ),
) -> None:
    """Create a run folder from a wf-spec folder.

    Transforms a wf-spec folder into an executable run directory where
    coding agents can execute workflow stages.

    Example:
        chainglass compose ./wf-spec --output ./runs
    """
    try:
        run_folder = compose(wf_spec, output)
        typer.echo(f"Created: {run_folder}")
    except ValidationError as e:
        typer.echo(f"Validation failed:\n", err=True)
        for error in e.result.errors:
            typer.echo(f"  {error}\n", err=True)
        raise typer.Exit(code=1)
    except CompositionError as e:
        typer.echo(f"Composition failed: {e}", err=True)
        raise typer.Exit(code=1)


@app.command(name="finalize")
def finalize_cmd(
    stage_id: str = typer.Argument(
        ...,
        help="Stage ID to finalize (e.g., 'explore')",
    ),
    run_dir: Path = typer.Option(
        ...,
        "--run-dir",
        "-r",
        help="Path to run directory containing stages/",
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
    ),
) -> None:
    """Finalize a stage after LLM execution.

    Validates all required outputs exist, extracts output parameters,
    writes output-params.json, and updates wf-run.json status.

    Run this after the LLM completes a stage to publish its outputs
    for downstream stages.

    Example:
        chainglass finalize explore --run-dir ./run/run-2026-01-18-001
    """
    stage_path = run_dir / "stages" / stage_id

    if not stage_path.exists():
        typer.echo(
            f"Stage folder not found: {stage_path}\n"
            f"Action: Verify stage_id is correct and run compose first.",
            err=True,
        )
        raise typer.Exit(code=1)

    stage = Stage(stage_path)
    result = stage.finalize()

    if result.success:
        typer.echo(f"Finalized: {stage_id}")
        if result.parameters:
            typer.echo("Published parameters:")
            for key, value in result.parameters.items():
                typer.echo(f"  {key}: {value}")
    else:
        typer.echo("Finalization failed:\n", err=True)
        for error in result.errors:
            typer.echo(f"  {error}\n", err=True)
        raise typer.Exit(code=1)


@app.command(name="validate")
def validate_cmd(
    stage_id: str = typer.Argument(
        ...,
        help="Stage ID to validate (e.g., 'explore')",
    ),
    run_dir: Path = typer.Option(
        ...,
        "--run-dir",
        "-r",
        help="Path to run directory containing stages/",
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
    ),
) -> None:
    """Validate stage outputs after LLM execution.

    Checks all required outputs exist, validates JSON files against schemas,
    extracts output parameters, and writes output-params.json on success.

    Designed to be called by an LLM at the end of stage execution to verify
    completion. Provides actionable error messages telling you exactly what to fix.

    Example:
        chainglass validate explore --run-dir ./run/run-2026-01-18-001
    """
    stage_path = run_dir / "stages" / stage_id

    if not stage_path.exists():
        typer.echo(
            f"Stage folder not found: {stage_path}\n"
            f"Action: Verify stage_id is correct and run compose first.",
            err=True,
        )
        raise typer.Exit(code=1)

    result = validate_stage(stage_path)

    if result.status == "pass":
        typer.echo(f"Validated: {stage_id}")
        if result.checks:
            typer.echo("Checks passed:")
            for check in result.checks:
                if check.schema:
                    typer.echo(f"  {check.path} (schema valid)")
                else:
                    typer.echo(f"  {check.path}")
        if result.output_params_written:
            typer.echo("Output parameters published:")
            for key, value in result.output_params.items():
                typer.echo(f"  {key}: {value}")
        # Display accept info (informational)
        if result.accept:
            if result.accept.present:
                typer.echo(f"Accept: PRESENT (state={result.accept.state})")
            elif result.accept.warning:
                typer.echo(f"Accept: ABSENT")
        # Display handback info
        if result.handback:
            if result.handback.present:
                typer.echo(f"Handback: {result.handback.reason}")
                if result.handback.reason == "error":
                    typer.echo(
                        f"  Error: {result.handback.error_code} - {result.handback.error_message}"
                    )
            elif result.handback.warning:
                typer.echo(f"Warning: {result.handback.warning}")
        passed = len(result.checks)
        typer.echo(f"Result: PASS ({passed} checks, 0 errors)")
    else:
        typer.echo("Validation failed:", err=True)
        for error in result.errors:
            typer.echo(f"  {error.check.upper()}: {error.path}", err=True)
            typer.echo(f"    Action: {error.action}", err=True)
        # Display accept status even on failure (informational)
        if result.accept:
            if result.accept.present:
                typer.echo(f"Accept: PRESENT (state={result.accept.state})", err=True)
            elif result.accept.warning:
                typer.echo(f"Accept: ABSENT", err=True)
        # Display handback warning even on failure
        if result.handback and result.handback.warning:
            typer.echo(f"Warning: {result.handback.warning}", err=True)
        passed = len(result.checks)
        failed = len(result.errors)
        typer.echo(f"Result: FAIL ({passed} passed, {failed} errors)", err=True)
        raise typer.Exit(code=1)


@app.command(name="preflight")
def preflight_cmd(
    stage_id: str = typer.Argument(
        ...,
        help="Stage ID to preflight check (e.g., 'explore')",
    ),
    run_dir: Path = typer.Option(
        ...,
        "--run-dir",
        "-r",
        help="Path to run directory containing stages/",
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
    ),
) -> None:
    """Validate stage inputs before LLM execution.

    Checks all required inputs exist, validates source stages are finalized
    (for inputs with from_stage), and verifies parameters can be resolved.

    Designed to be called by an LLM before starting stage work to verify
    prerequisites are met. Provides actionable error messages telling you
    exactly what to fix before proceeding.

    Example:
        chainglass preflight explore --run-dir ./run/run-2026-01-18-001
    """
    stage_path = run_dir / "stages" / stage_id

    if not stage_path.exists():
        typer.echo(
            f"Stage folder not found: {stage_path}\n"
            f"Action: Verify stage_id is correct and run compose first.",
            err=True,
        )
        raise typer.Exit(code=1)

    result = preflight(stage_path)

    if result.status == "pass":
        typer.echo(f"Preflight: {stage_id}")
        if result.checks:
            typer.echo("Checks passed:")
            for check in result.checks:
                if check.name:
                    typer.echo(f"  {check.path} ({check.name})")
                else:
                    typer.echo(f"  {check.path}")
        passed = len(result.checks)
        typer.echo(f"Result: PASS ({passed} checks, 0 errors)")
    else:
        typer.echo("Preflight failed:", err=True)
        for error in result.errors:
            typer.echo(f"  {error.check.upper()}: {error.path}", err=True)
            if error.action:
                typer.echo(f"    Action: {error.action}", err=True)
        passed = len(result.checks)
        failed = len(result.errors)
        typer.echo(f"Result: FAIL ({passed} passed, {failed} errors)", err=True)
        raise typer.Exit(code=1)


@app.command(name="handback")
def handback_cmd(
    stage_id: str = typer.Argument(
        ...,
        help="Stage ID to read handback from (e.g., 'explore')",
    ),
    run_dir: Path = typer.Option(
        ...,
        "--run-dir",
        "-r",
        help="Path to run directory containing stages/",
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
    ),
) -> None:
    """Read and echo agent handback after stage completion.

    Reads handback.json from the stage output-data folder, validates it
    against the schema, and echoes the handback reason and description.
    For error handbacks, also displays the error code description.

    This command always exits 0. The handback reason is communicated
    via the JSON output structure (reason: "success" | "error" | "question").

    Example:
        chainglass handback explore --run-dir ./run/run-2026-01-18-001
    """
    import json

    import jsonschema

    stage_path = run_dir / "stages" / stage_id

    if not stage_path.exists():
        typer.echo(
            f"Stage folder not found: {stage_path}\n"
            f"Action: Verify stage_id is correct and run compose first.",
            err=True,
        )
        raise typer.Exit(code=1)

    # Load handback.json
    handback_path = stage_path / "run" / "output-data" / "handback.json"
    if not handback_path.exists():
        typer.echo(
            f"Handback not found: {handback_path}\n"
            f"Action: Write handback.json before calling handback command.",
            err=True,
        )
        raise typer.Exit(code=1)

    try:
        handback = json.loads(handback_path.read_text())
    except json.JSONDecodeError as e:
        typer.echo(
            f"Invalid JSON in handback.json: {e.msg}\n"
            f"Action: Fix the JSON syntax error in handback.json.",
            err=True,
        )
        raise typer.Exit(code=1)

    # Load and validate against schema (from stage's schemas/ folder)
    schema_path = stage_path / "schemas" / "handback.schema.json"
    if schema_path.exists():
        try:
            schema = json.loads(schema_path.read_text())
            jsonschema.validate(handback, schema)
        except json.JSONDecodeError:
            # Schema file is invalid - log but continue
            typer.echo(
                "Warning: handback.schema.json is invalid JSON, skipping validation",
                err=True,
            )
        except jsonschema.ValidationError as e:
            typer.echo(
                f"Handback validation failed: {e.message}\n"
                f"Action: Fix handback.json to match handback.schema.json.",
                err=True,
            )
            raise typer.Exit(code=1)

    # Load error codes for description lookup (if error reason)
    error_codes = {}
    error_codes_path = stage_path / "schemas" / "error-codes.json"
    if error_codes_path.exists():
        try:
            error_codes_data = json.loads(error_codes_path.read_text())
            error_codes = error_codes_data.get("ERROR_CODES", {})
        except json.JSONDecodeError:
            pass  # Ignore invalid error-codes.json

    # Echo handback information
    reason = handback.get("reason", "unknown")
    description = handback.get("description", "")

    typer.echo(f"Handback: {stage_id}")
    typer.echo(f"Reason: {reason}")
    typer.echo(f"Description: {description}")

    # For error reason, show error details
    if reason == "error" and "error" in handback:
        error = handback["error"]
        error_code = error.get("code", "UNKNOWN")
        error_message = error.get("message", "")
        code_description = error_codes.get(error_code, "Unknown error code")

        typer.echo(f"Error Code: {error_code} ({code_description})")
        typer.echo(f"Error Message: {error_message}")

        # Show context if present
        context = error.get("context")
        if context:
            typer.echo("Error Context:")
            for key, value in context.items():
                typer.echo(f"  {key}: {value}")

    # Load and report accept.json status (ST006)
    from datetime import datetime, timezone

    accept_path = stage_path / "run" / "output-data" / "accept.json"
    accept_timestamp = None
    if accept_path.exists():
        try:
            accept_data = json.loads(accept_path.read_text())
            accept_state = accept_data.get("state", "unknown")
            accept_timestamp = accept_data.get("timestamp")
            # Display state transition (ST007)
            typer.echo(f"State: {accept_state} → orchestrator")
            typer.echo(f"Accepted at: {accept_timestamp}")
            now = datetime.now(timezone.utc).isoformat()
            typer.echo(f"Handed back: {now}")
        except json.JSONDecodeError:
            typer.echo("Accept: PRESENT (invalid JSON)")
    else:
        typer.echo("Accept: ABSENT")

    # Output JSON summary (for programmatic consumption)
    typer.echo("")
    typer.echo("JSON Output:")
    typer.echo(json.dumps(handback, indent=2))

    # Always exit 0 - reason is communicated via JSON output
    # No raise typer.Exit() needed - implicit exit 0


@app.command(name="accept")
def accept_cmd(
    stage_id: str = typer.Argument(
        ...,
        help="Stage ID to accept (e.g., 'explore')",
    ),
    run_dir: Path = typer.Option(
        ...,
        "--run-dir",
        "-r",
        help="Path to run directory containing stages/",
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
    ),
) -> None:
    """Grant control to an agent for stage execution.

    Writes accept.json to the stage output-data folder, signaling that the
    orchestrator has granted control to the agent. The agent should read this
    file to confirm permission before executing stage work.

    This command is idempotent - calling it multiple times overwrites the
    accept.json file with a new timestamp.

    This command always exits 0. The state is communicated via the JSON output.

    Example:
        chainglass accept explore --run-dir ./run/run-2026-01-18-001
    """
    import json
    from datetime import datetime, timezone

    stage_path = run_dir / "stages" / stage_id

    if not stage_path.exists():
        typer.echo(
            f"Stage folder not found: {stage_path}\n"
            f"Action: Verify stage_id is correct and run compose first.",
            err=True,
        )
        raise typer.Exit(code=1)

    # Create output-data directory if needed
    output_data_path = stage_path / "run" / "output-data"
    output_data_path.mkdir(parents=True, exist_ok=True)

    # Write accept.json
    accept_path = output_data_path / "accept.json"
    timestamp = datetime.now(timezone.utc).isoformat()
    accept_data = {
        "state": "agent",
        "timestamp": timestamp,
    }
    accept_path.write_text(json.dumps(accept_data, indent=2))

    # Echo confirmation
    typer.echo(f"Accept: {stage_id}")
    typer.echo(f"State: agent")
    typer.echo(f"Timestamp: {timestamp}")

    # Always exit 0 - state is communicated via JSON output
    # No raise typer.Exit() needed - implicit exit 0


@app.command(name="prepare-wf-stage")
def prepare_wf_stage_cmd(
    stage_id: str = typer.Argument(
        ...,
        help="Stage ID to prepare (e.g., 'specify')",
    ),
    run_dir: Path = typer.Option(
        ...,
        "--run-dir",
        "-r",
        help="Path to run directory containing stages/",
        exists=True,
        file_okay=False,
        dir_okay=True,
        resolve_path=True,
    ),
    dry_run: bool = typer.Option(
        False,
        "--dry-run",
        "-n",
        help="Validate without copying files or writing params.json",
    ),
) -> None:
    """Prepare a stage by copying inputs from prior stages.

    Copies input files from prior stage outputs and resolves parameters
    from prior stage output-params.json. Prior stages must be finalized
    first (run 'chainglass finalize' on them).

    Example:
        chainglass prepare-wf-stage specify --run-dir ./run/run-2026-01-18-001

    Dry-run mode:
        chainglass prepare-wf-stage specify --run-dir ./run --dry-run
    """
    result = prepare_wf_stage(stage_id, run_dir, dry_run=dry_run)

    if result.success:
        if dry_run:
            typer.echo(f"Dry-run: {stage_id} ready for preparation")
        else:
            typer.echo(f"Prepared: {stage_id}")

        if result.files_copied:
            typer.echo("Files copied:")
            for file_info in result.files_copied:
                typer.echo(f"  {file_info}")

        if result.params_resolved:
            typer.echo("Parameters resolved:")
            for key, value in result.params_resolved.items():
                typer.echo(f"  {key}: {value}")
    else:
        typer.echo("Preparation failed:\n", err=True)
        for error in result.errors:
            typer.echo(f"  {error}\n", err=True)
        raise typer.Exit(code=1)


if __name__ == "__main__":
    app()
