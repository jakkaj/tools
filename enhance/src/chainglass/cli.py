"""Chainglass CLI - Workflow Composer commands."""

from pathlib import Path

import typer

from chainglass import __version__
from chainglass.composer import CompositionError, compose
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


if __name__ == "__main__":
    app()
