"""Chainglass CLI - Workflow Composer commands."""

from pathlib import Path

import typer

from chainglass import __version__
from chainglass.composer import CompositionError, compose
from chainglass.preparer import prepare_wf_stage
from chainglass.stage import Stage
from chainglass.validator import ValidationError

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
