#!/usr/bin/env python3
"""
Tools Repository Setup Manager
An elegant Python-based setup system with rich terminal output
"""

import os
import sys
import subprocess
import platform
import time
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass

from rich.console import Console
from rich.progress import (
    Progress,
    SpinnerColumn,
    TextColumn,
    BarColumn,
    TaskProgressColumn,
    TimeRemainingColumn,
)
from rich.table import Table
from rich.panel import Panel
from rich.layout import Layout
from rich.live import Live
from rich.text import Text
from rich import box
from rich.syntax import Syntax

console = Console()

@dataclass
class InstallResult:
    """Result of an installation attempt"""
    name: str
    success: bool
    message: str
    output: str
    error: str
    duration: float
    version_before: Optional[str] = None
    version_after: Optional[str] = None


class SetupManager:
    """Manages the setup process for the tools repository"""

    def __init__(self, resource_root: Optional[Path] = None):
        """
        Initialize SetupManager

        Args:
            resource_root: Optional path to tools repository for dev mode.
                          If None, uses package installation location.
        """
        if resource_root:
            # Dev mode: use provided local filesystem path
            self.script_dir = resource_root.resolve()
        else:
            # Normal mode: use package installation location
            self.script_dir = Path(__file__).parent.resolve()

        self.scripts_path = self.script_dir / "scripts"
        self.install_path = self.script_dir / "install"
        self.shell_config = Path.home() / ".zshrc"
        self.path_marker = "# Added by tools repository setup"
        self.os_type = self._detect_os()
        self.results: List[InstallResult] = []

    def _detect_os(self) -> str:
        """Detect the operating system"""
        system = platform.system()
        if system == "Linux":
            return "Linux"
        elif system == "Darwin":
            return "macOS"
        elif system in ["Windows", "CYGWIN", "MINGW", "MSYS"]:
            return "Windows"
        else:
            return "Unknown"

    def _run_command(self, cmd: List[str], timeout: Optional[int] = None) -> Tuple[int, str, str]:
        """Run a command and return exit code, stdout, and stderr"""
        try:
            # Create clean environment to prevent BASH_ENV and other startup file interference
            # Remove BASH_ENV and ENV entirely, AND use bash -p (privileged mode)
            # See: https://www.gnu.org/software/bash/manual/bash.html
            clean_env = {k: v for k, v in os.environ.items() if k not in ("BASH_ENV", "ENV")}
            clean_env.pop("PROMPT_COMMAND", None)     # Sometimes abused
            clean_env.pop("CDPATH", None)             # Avoid cd surprises

            # Add Cargo to PATH
            clean_env["PATH"] = f"{os.environ.get('HOME', '')}/.cargo/bin:{os.environ.get('PATH', '')}"

            # If executing a shell script, wrap with bash -p (privileged mode)
            # -p tells bash to ignore BASH_ENV and ENV completely
            if cmd and cmd[0].endswith('.sh'):
                script = cmd[0]
                args = cmd[1:]
                cmd = ["/bin/bash", "-p", "--noprofile", "--norc", script, *args]

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=clean_env
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except Exception as e:
            return -1, "", str(e)

    def _get_version(self, command: str) -> Optional[str]:
        """Get version from a command, handling different output formats"""
        try:
            # Use clean environment (same as _run_command)
            clean_env = {k: v for k, v in os.environ.items() if k not in ("BASH_ENV", "ENV")}
            clean_env["PATH"] = f"{os.environ.get('HOME', '')}/.cargo/bin:{os.environ.get('PATH', '')}"

            result = subprocess.run(
                [command, "--version"],
                capture_output=True,
                text=True,
                timeout=10,
                env=clean_env
            )
            if result.returncode == 0:
                # Clean up version output - remove extra whitespace and normalize
                version = result.stdout.strip().split('\n')[0].strip()
                # Handle different formats:
                # "codex-cli 0.44.0" -> "0.44.0"
                # "2.0.8 (Claude Code)" -> "2.0.8"
                # "0.14.1" -> "0.14.1"
                if command == "codex" and version.startswith("codex-cli "):
                    return version.replace("codex-cli ", "")
                elif command == "claude" and " (Claude Code)" in version:
                    return version.replace(" (Claude Code)", "")
                else:
                    return version
        except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError):
            pass
        return None

    def check_prerequisites(self) -> bool:
        """Check if prerequisites are met"""
        if not self.scripts_path.exists():
            console.print(f"[red]✗[/red] Scripts directory not found at {self.scripts_path}")
            return False
        return True

    def add_to_path(self) -> bool:
        """Add scripts directory to PATH"""
        path_export = f'export PATH="{self.scripts_path}:$PATH"'

        # Check if already in shell config
        if self.shell_config.exists():
            content = self.shell_config.read_text()
            if str(self.scripts_path) in content:
                console.print(f"[yellow]•[/yellow] Scripts directory already in {self.shell_config}")
                return True

        # Add to shell config
        with open(self.shell_config, 'a') as f:
            f.write(f"\n{self.path_marker}\n")
            f.write(f"{path_export}\n")

        console.print(f"[green]✓[/green] Added scripts directory to {self.shell_config}")

        # Add to current session PATH
        current_path = os.environ.get("PATH", "")
        if str(self.scripts_path) not in current_path:
            os.environ["PATH"] = f"{self.scripts_path}:{current_path}"
            console.print(f"[green]✓[/green] Scripts directory added to current shell PATH")

        return True

    def make_scripts_executable(self) -> int:
        """Make all scripts in the scripts directory executable"""
        if not self.scripts_path.exists():
            return 0

        script_count = 0
        for script in self.scripts_path.iterdir():
            if script.is_file():
                script.chmod(0o755)
                script_count += 1

        if script_count > 0:
            console.print(f"[green]✓[/green] Made {script_count} script(s) executable")
        else:
            console.print(f"[yellow]•[/yellow] No scripts found to make executable")

        return script_count

    def get_installers(self) -> List[Path]:
        """Get list of installer scripts in the correct order"""
        if not self.install_path.exists():
            return []

        # Specified order for dependencies
        install_order = [
            "rust.sh",
            "just.sh",
            "code2prompt.sh",
            "agents.sh",
            "opencode.sh",
            "claude-code.sh",
            "codex.sh",
            "aliases.py"
        ]

        installers = []

        # Add installers in specified order first
        for name in install_order:
            installer = self.install_path / name
            if installer.exists():
                installers.append(installer)

        # Add any remaining installers
        for installer in self.install_path.iterdir():
            if installer.suffix in ['.sh', '.py'] and installer not in installers:
                installers.append(installer)

        return installers

    def run_installer(self, installer: Path, progress: Optional[Progress] = None, task_id: Optional[int] = None, update_mode: bool = False) -> InstallResult:
        """Run a single installer script"""
        name = installer.stem
        start_time = time.time()

        # Get version before installation for version-tracked tools
        version_before = None
        if name in ["codex", "claude-code", "opencode"]:
            if name == "codex":
                version_before = self._get_version("codex")
            elif name == "claude-code":
                version_before = self._get_version("claude")
            elif name == "opencode":
                version_before = self._get_version("opencode")

        if progress and task_id is not None:
            action = "Updating" if update_mode else "Installing"
            progress.update(task_id, description=f"[cyan]{action} {name}...[/cyan]")

        # Make installer executable
        installer.chmod(0o755)

        # Build command with update flag if needed
        cmd = [str(installer)]
        if update_mode:
            # Add update flag for installers that support it
            updatable_installers = ["opencode", "claude-code", "codex", "install-coding-stuff"]
            if name in updatable_installers:
                cmd.append("--update")

        # Add --clear-mcp flag for agents installer if requested
        if name == "agents" and hasattr(self, 'clear_mcp') and self.clear_mcp:
            cmd.append("--clear-mcp")

        # Run the installer
        returncode, stdout, stderr = self._run_command(cmd, timeout=300)

        duration = time.time() - start_time
        success = returncode == 0

        # Get version after installation for version-tracked tools
        version_after = None
        if name in ["codex", "claude-code", "opencode"]:
            if name == "codex":
                version_after = self._get_version("codex")
            elif name == "claude-code":
                version_after = self._get_version("claude")
            elif name == "opencode":
                version_after = self._get_version("opencode")

        if success:
            message = f"Successfully installed {name}"
            if progress and task_id is not None:
                progress.update(task_id, description=f"[green]✓ {name}[/green]")
        else:
            message = f"Failed to install {name}"
            if progress and task_id is not None:
                progress.update(task_id, description=f"[red]✗ {name}[/red]")

        return InstallResult(
            name=name,
            success=success,
            message=message,
            output=stdout,
            error=stderr,
            duration=duration,
            version_before=version_before,
            version_after=version_after
        )

    def install_tools(self, update_mode: bool = False) -> None:
        """Install all tools with progress tracking"""
        installers = self.get_installers()

        if not installers:
            console.print("[yellow]No installers found[/yellow]")
            return

        action = "update" if update_mode else "install"
        console.print(f"\n[bold cyan]Found {len(installers)} installer(s) to {action}[/bold cyan]\n")

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            TimeRemainingColumn(),
            console=console,
        ) as progress:
            # Sequential installation
            action_title = "Updating" if update_mode else "Installing"
            overall_task = progress.add_task(f"[cyan]{action_title} tools...[/cyan]", total=len(installers))

            for installer in installers:
                task = progress.add_task(f"[cyan]{action_title} {installer.stem}...[/cyan]", total=1)
                result = self.run_installer(installer, progress, task, update_mode)
                self.results.append(result)
                progress.update(task, completed=1)
                progress.update(overall_task, advance=1)

    def show_summary(self) -> None:
        """Display installation summary"""
        if not self.results:
            return

        # Create summary table
        table = Table(title="Installation Summary", box=box.ROUNDED)
        table.add_column("Tool", style="cyan", no_wrap=True)
        table.add_column("Status", justify="center")
        table.add_column("Duration", justify="right")
        table.add_column("Message", no_wrap=False)

        successful = 0
        failed = 0

        for result in self.results:
            status = "[green]✓ Success[/green]" if result.success else "[red]✗ Failed[/red]"
            duration = f"{result.duration:.2f}s"

            # Truncate message if too long
            message = result.message
            if len(message) > 50:
                message = message[:47] + "..."

            table.add_row(result.name, status, duration, message)

            if result.success:
                successful += 1
            else:
                failed += 1

        console.print("\n")
        console.print(table)

        # Print statistics
        console.print(f"\n[bold]Statistics:[/bold]")
        console.print(f"  [green]✓[/green] Successful: {successful}")
        console.print(f"  [red]✗[/red] Failed: {failed}")
        console.print(f"  Total time: {sum(r.duration for r in self.results):.2f}s")

        # Show version summary for tracked tools
        version_tracked_tools = ["codex", "claude-code", "opencode"]
        version_results = [r for r in self.results if r.name in version_tracked_tools and r.success]

        if version_results:
            console.print("\n[bold cyan]Version Summary:[/bold cyan]")
            version_table = Table(box=box.ROUNDED)
            version_table.add_column("Tool", style="cyan", no_wrap=True)
            version_table.add_column("Before", justify="center")
            version_table.add_column("After", justify="center")
            version_table.add_column("Status", justify="center")

            for result in version_results:
                before = result.version_before or "N/A"
                after = result.version_after or "N/A"
                if result.version_before and result.version_after and result.version_before != result.version_after:
                    status = "[green]Updated[/green]"
                elif result.version_before and result.version_after and result.version_before == result.version_after:
                    status = "[yellow]No change[/yellow]"
                elif result.version_after:
                    status = "[green]Installed[/green]"
                else:
                    status = "[dim]Unknown[/dim]"

                version_table.add_row(result.name, before, after, status)

            console.print(version_table)

        # Show failed installers details
        failed_results = [r for r in self.results if not r.success]
        if failed_results:
            console.print("\n[bold red]Failed installations:[/bold red]")
            for result in failed_results:
                console.print(f"\n[yellow]━━━ {result.name} ━━━[/yellow]")
                if result.error:
                    console.print("[dim]Error output:[/dim]")
                    console.print(Text(result.error[:500], style="red"))
                if result.output:
                    console.print("[dim]Standard output:[/dim]")
                    console.print(Text(result.output[:500], style="dim"))

    def run(self, update_mode: bool = False) -> None:
        """Run the complete setup process"""
        # Display header
        mode_text = "UPDATE MODE" if update_mode else "INSTALL MODE"
        console.print(Panel.fit(
            f"[bold cyan]Tools Repository Setup Manager[/bold cyan]\n"
            f"[dim]OS: {self.os_type} | Path: {self.script_dir}[/dim]\n"
            f"[yellow]{mode_text}[/yellow]",
            border_style="cyan"
        ))

        # Check prerequisites
        console.print("\n[bold]Checking prerequisites...[/bold]")
        if not self.check_prerequisites():
            console.print("[red]Prerequisites check failed. Exiting.[/red]")
            sys.exit(1)
        console.print("[green]✓[/green] Prerequisites check passed")

        # Add to PATH
        console.print("\n[bold]Configuring PATH...[/bold]")
        self.add_to_path()

        # Make scripts executable
        console.print("\n[bold]Setting permissions...[/bold]")
        self.make_scripts_executable()

        # Install/Update tools
        action = "Updating" if update_mode else "Installing"
        console.print(f"\n[bold]{action} tools...[/bold]")
        self.install_tools(update_mode)

        # Show summary
        self.show_summary()

        # Final message
        console.print(Panel(
            "[green]Setup complete![/green]\n\n"
            "To use the changes in your current shell:\n"
            "  [cyan]source ~/.zshrc[/cyan]\n\n"
            "Or simply open a new terminal window.",
            border_style="green"
        ))


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Tools Repository Setup Manager")
    parser.add_argument(
        "--update", "-u",
        action="store_true",
        help="Update already installed tools to latest versions"
    )
    parser.add_argument(
        "--clear-mcp",
        action="store_true",
        help="Clear all existing MCP servers before installing new ones"
    )

    args = parser.parse_args()

    try:
        manager = SetupManager()
        manager.clear_mcp = args.clear_mcp
        manager.run(update_mode=args.update)
    except KeyboardInterrupt:
        console.print("\n[yellow]Setup interrupted by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"\n[red]Error: {e}[/red]")
        sys.exit(1)


if __name__ == "__main__":
    main()