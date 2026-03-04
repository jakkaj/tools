#!/usr/bin/env python3
"""
Tools Repository Setup Manager
An elegant Python-based setup system with rich terminal output.

Uses ToolInstaller from installers.py for all tool installations —
no bash dependency.
"""

import os
import sys
import platform
import time
from pathlib import Path
from typing import Callable, List, Optional, Tuple

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
from rich.text import Text
from rich import box

from jk_tools.installers import ToolInstaller, InstallResult

console = Console()

class SetupManager:
    """Manages the setup process for the tools repository"""

    def __init__(self, resource_root: Optional[Path] = None):
        if resource_root:
            self.script_dir = resource_root.resolve()
        else:
            self.script_dir = Path(__file__).parent.resolve()

        self.scripts_path = self.script_dir / "scripts"
        self.install_path = self.script_dir / "install"
        self.path_marker = "# Added by tools repository setup"
        self.os_type = self._detect_os()
        self.is_windows = self.os_type == "Windows"
        self.path_sep = ";" if self.is_windows else ":"
        self.shell_config = Path.home() / ".zshrc"
        self.results: List[InstallResult] = []

        # Optional flags (set by cli.py)
        self.clear_mcp = False
        self.commands_local = ""
        self.local_dir = str(Path.cwd())
        self.verbose = False

        # Cross-platform tool installer — no bash needed
        self.installer = ToolInstaller(self.script_dir, verbose=self.verbose)

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

    def check_prerequisites(self) -> bool:
        """Check if prerequisites are met"""
        if not self.scripts_path.exists():
            console.print(f"[red]✗[/red] Scripts directory not found at {self.scripts_path}")
            return False
        return True

    def add_to_path(self) -> bool:
        """Add scripts directory to PATH"""
        if self.is_windows:
            # On Windows, add to the current session PATH only.
            current_path = os.environ.get("PATH", "")
            if str(self.scripts_path) not in current_path:
                os.environ["PATH"] = f"{self.scripts_path};{current_path}"
                console.print(f"[green]✓[/green] Scripts directory added to current session PATH")
            else:
                console.print(f"[yellow]•[/yellow] Scripts directory already in PATH")
            console.print(f"[dim]  To persist, add to your User PATH via System Environment Variables:[/dim]")
            console.print(f"[dim]  {self.scripts_path}[/dim]")
            return True

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

        if self.is_windows:
            # chmod is not meaningful on Windows
            script_count = sum(1 for s in self.scripts_path.iterdir() if s.is_file())
            if script_count > 0:
                console.print(f"[green]✓[/green] Found {script_count} script(s) (chmod not needed on Windows)")
            return script_count

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

    def get_install_steps(self) -> List[Tuple[str, Callable[[], InstallResult]]]:
        """Return ordered list of (name, installer_function) tuples."""
        i = self.installer
        steps = [
            ("just", i.install_just),
            ("rust", i.install_rust),
            ("code2prompt", i.install_code2prompt),
            ("fs2", i.install_fs2),
            ("agents", lambda: i.install_agents(
                clear_mcp=self.clear_mcp,
                commands_local=self.commands_local,
                local_dir=self.local_dir,
            )),
            ("claude-code", i.install_claude_code),
            ("codex", i.install_codex),
            ("copilot-cli", i.install_copilot_cli),
            ("aliases", i.install_aliases),
        ]
        return steps

    def run_install_step(
        self,
        name: str,
        fn: Callable[[], InstallResult],
        progress: Optional[Progress] = None,
        task_id: Optional[int] = None,
    ) -> InstallResult:
        """Run a single install step and update progress."""
        if progress and task_id is not None:
            progress.update(task_id, description=f"[cyan]Installing {name}...[/cyan]")

        result = fn()

        if progress and task_id is not None:
            if result.success:
                progress.update(task_id, description=f"[green]✓ {name}[/green]")
            else:
                progress.update(task_id, description=f"[red]✗ {name}[/red]")

        return result

    def install_tools(self, update_mode: bool = False) -> None:
        """Install all tools with progress tracking"""
        is_local_mode = hasattr(self, 'commands_local') and self.commands_local

        if is_local_mode:
            # In local mode, only run agents
            steps = [("agents", lambda: self.installer.install_agents(
                clear_mcp=self.clear_mcp,
                commands_local=self.commands_local,
                local_dir=self.local_dir,
            ))]
            action = "install local commands"
        else:
            steps = self.get_install_steps()
            action = "update" if update_mode else "install"

        console.print(f"\n[bold cyan]Found {len(steps)} installer(s) to {action}[/bold cyan]\n")

        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            BarColumn(),
            TaskProgressColumn(),
            TimeRemainingColumn(),
            console=console,
        ) as progress:
            action_title = "Updating" if update_mode else "Installing"
            overall_task = progress.add_task(f"[cyan]{action_title} tools...[/cyan]", total=len(steps))

            for name, fn in steps:
                task = progress.add_task(f"[cyan]{action_title} {name}...[/cyan]", total=1)
                result = self.run_install_step(name, fn, progress, task)
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
        version_tracked_tools = ["codex", "claude-code"]  # Removed opencode
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

    def dry_run(self) -> None:
        """Show what would be installed and check prerequisites."""
        console.print(Panel.fit(
            "[bold cyan]Tools Repository Setup Manager[/bold cyan]\n"
            f"[dim]OS: {self.os_type} | Path: {self.script_dir}[/dim]\n"
            "[yellow]DRY RUN — no changes will be made[/yellow]",
            border_style="cyan"
        ))
        console.print()

        report = self.installer.preflight()

        table = Table(title="Installation Plan", box=box.ROUNDED)
        table.add_column("Tool", style="cyan", no_wrap=True)
        table.add_column("Status", justify="center")
        table.add_column("Action", no_wrap=False)
        table.add_column("Prerequisites", no_wrap=False)

        ready = skip = blocked = 0
        for step in report:
            # Status badge
            if step["status"] == "skip":
                status = "[green]✓ Installed[/green]"
                skip += 1
            elif step["status"] == "ready":
                status = "[cyan]● Ready[/cyan]"
                ready += 1
            else:
                status = "[red]✗ Blocked[/red]"
                blocked += 1

            # Prerequisites column
            prereq_parts = []
            for p in step["prereqs"]:
                icon = "[green]✓[/green]" if p["found"] else "[red]✗[/red]"
                prereq_parts.append(f"{icon} {p['name']}")
            prereqs_str = ", ".join(prereq_parts) if prereq_parts else "[dim]none[/dim]"

            # Action/reason
            action = step.get("reason") or step["action"]

            table.add_row(step["name"], status, action, prereqs_str)

        console.print(table)
        console.print()
        console.print(f"[bold]Summary:[/bold]  "
                      f"[cyan]{ready} ready[/cyan]  "
                      f"[green]{skip} already installed[/green]  "
                      f"[red]{blocked} blocked[/red]")
        if blocked:
            console.print("\n[yellow]Install missing prerequisites to unblock the blocked steps.[/yellow]")
        console.print()

    def run(self, update_mode: bool = False) -> None:
        """Run the complete setup process"""
        # Check if we're in local-commands-only mode
        is_local_mode = hasattr(self, 'commands_local') and self.commands_local

        # Display header
        if is_local_mode:
            mode_text = "LOCAL COMMANDS MODE"
        else:
            mode_text = "UPDATE MODE" if update_mode else "INSTALL MODE"

        console.print(Panel.fit(
            f"[bold cyan]Tools Repository Setup Manager[/bold cyan]\n"
            f"[dim]OS: {self.os_type} | Path: {self.script_dir}[/dim]\n"
            f"[yellow]{mode_text}[/yellow]",
            border_style="cyan"
        ))

        # In local mode, skip most setup steps
        if is_local_mode:
            # Only install local commands via agents.sh
            console.print("\n[bold]Installing local commands...[/bold]")
            console.print(f"[dim]Target: {self.local_dir}[/dim]")
            console.print(f"[dim]CLIs: {self.commands_local}[/dim]\n")
            self.install_tools(update_mode)

            # Show summary
            self.show_summary()

            # Custom final message for local mode
            console.print(Panel(
                "[green]Local commands installed![/green]\n\n"
                f"Commands have been installed to:\n"
                f"  [cyan]{self.local_dir}[/cyan]\n\n"
                "The commands are now available for your project.",
                border_style="green"
            ))
        else:
            # Standard full setup mode
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
            if self.is_windows:
                console.print(Panel(
                    "[green]Setup complete![/green]\n\n"
                    "Tools have been installed natively (no bash required).\n"
                    "Open a new terminal window to use the tools.",
                    border_style="green"
                ))
            else:
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
    parser.add_argument(
        "--commands-local",
        type=str,
        default="",
        metavar="CLIS",
        help="Install commands locally to project directory (comma-separated: claude,opencode,ghcp,copilot-cli,codex)"
    )
    parser.add_argument(
        "--local-dir",
        type=str,
        default=os.getcwd(),
        metavar="PATH",
        help="Target directory for local commands (default: current directory)"
    )
    parser.add_argument(
        "--no-auto-sudo",
        action="store_true",
        help="Disable automatic sudo retry on permission errors"
    )

    args = parser.parse_args()

    try:
        manager = SetupManager()
        manager.clear_mcp = args.clear_mcp
        manager.commands_local = args.commands_local
        manager.no_auto_sudo = args.no_auto_sudo
        if args.local_dir:
            manager.local_dir = args.local_dir
        manager.run(update_mode=args.update)
    except KeyboardInterrupt:
        console.print("\n[yellow]Setup interrupted by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"\n[red]Error: {e}[/red]")
        sys.exit(1)


if __name__ == "__main__":
    main()