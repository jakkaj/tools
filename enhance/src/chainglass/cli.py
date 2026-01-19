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
        passed = len(result.checks)
        typer.echo(f"Result: PASS ({passed} checks, 0 errors)")
    else:
        typer.echo("Validation failed:", err=True)
        for error in result.errors:
            typer.echo(f"  {error.check.upper()}: {error.path}", err=True)
            typer.echo(f"    Action: {error.action}", err=True)
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
