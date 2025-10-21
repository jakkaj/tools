#!/usr/bin/env python3
"""
Coding Tools Installer
Manages installation of modern AI coding assistant tools.

Tools installed:
- Serena CLI (coding-agent toolkit)
- OpenCode (terminal coding agent)
- Claude Code CLI
- OpenAI Codex CLI

This is a Python port of install-coding-stuff.sh with improved error handling,
better subprocess management, and a beautiful Rich UI.
"""

import os
import sys
import subprocess
import platform
import shutil
import time
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
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
from rich import box

try:
    from packaging import version
except ImportError:
    # Fallback if packaging not installed
    version = None


@dataclass
class InstallResult:
    """Result of a tool installation attempt"""
    name: str
    success: bool
    message: str
    output: str
    error: str
    duration: float
    version_before: Optional[str] = None
    version_after: Optional[str] = None


class CodingToolsInstaller:
    """
    Manages installation of modern AI coding assistant tools.

    This class handles:
    - System detection (OS, package manager)
    - Prerequisite checking and installation (Node.js, Python, npm, pipx)
    - Tool installation (Serena, OpenCode, Claude Code, Codex)
    - Update mode for existing installations

    Features:
    - Clean subprocess execution (no BASH_ENV interference)
    - Rich terminal UI with progress bars
    - Comprehensive error handling
    - Version tracking (before/after)
    """

    def __init__(self, console: Optional[Console] = None, update_mode: bool = False):
        """
        Initialize the installer.

        Args:
            console: Rich Console instance (creates new one if None)
            update_mode: If True, update existing tools instead of fresh install
        """
        self.console = console if console else Console()
        self.update_mode = update_mode
        self.results: List[InstallResult] = []

        # System detection
        self.os_type = self._detect_os()
        self.pkg_manager = self._detect_package_manager()

        # Paths
        self.home = Path.home()
        self.script_dir = Path(__file__).parent.resolve()

    # ============================================================================
    # System Detection
    # ============================================================================

    def _detect_os(self) -> str:
        """
        Detect the operating system.

        Returns:
            String: "Linux", "macOS", "Windows", or "Unknown"
        """
        system = platform.system()
        if system == "Linux":
            return "Linux"
        elif system == "Darwin":
            return "macOS"
        elif system in ["Windows", "CYGWIN", "MINGW", "MSYS"]:
            return "Windows"
        else:
            return "Unknown"

    def _detect_package_manager(self) -> str:
        """
        Detect available package manager.

        Checks in order: brew, apt-get, dnf, yum, pacman, zypper, apk

        Returns:
            Package manager name or empty string if none found
        """
        managers = ["brew", "apt-get", "dnf", "yum", "pacman", "zypper", "apk"]
        for manager in managers:
            if shutil.which(manager):
                return manager
        return ""

    def _check_command(self, cmd: str) -> bool:
        """
        Check if a command exists in PATH.

        Args:
            cmd: Command name to check

        Returns:
            True if command exists, False otherwise
        """
        return shutil.which(cmd) is not None

    # ============================================================================
    # Version Utilities
    # ============================================================================

    def _get_version(self, cmd: str, version_arg: str = "--version") -> Optional[str]:
        """
        Get version string from a command.

        Args:
            cmd: Command to check
            version_arg: Argument to pass for version (default: --version)

        Returns:
            Version string or None if command doesn't exist or fails
        """
        if not self._check_command(cmd):
            return None

        try:
            # Create clean environment
            clean_env = self._get_clean_env()

            result = subprocess.run(
                [cmd, version_arg],
                capture_output=True,
                text=True,
                timeout=10,
                env=clean_env
            )

            if result.returncode == 0:
                # Clean up version output - first line, strip whitespace
                version_str = result.stdout.strip().split('\n')[0].strip()

                # Handle different formats:
                # "codex-cli 0.44.0" -> "0.44.0"
                # "2.0.8 (Claude Code)" -> "2.0.8"
                # "0.14.1" -> "0.14.1"

                # Remove tool name prefixes
                for prefix in ["codex-cli ", "opencode ", "claude "]:
                    if version_str.lower().startswith(prefix):
                        version_str = version_str[len(prefix):]

                # Remove suffixes
                version_str = version_str.replace(" (Claude Code)", "")

                return version_str.strip()

        except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError):
            pass

        return None

    def _version_gte(self, ver1: str, ver2: str) -> bool:
        """
        Check if ver1 >= ver2 using semantic versioning.

        Args:
            ver1: First version string
            ver2: Second version string

        Returns:
            True if ver1 >= ver2, False otherwise
        """
        if version is None:
            # Fallback: string comparison
            return ver1 >= ver2

        try:
            return version.parse(ver1) >= version.parse(ver2)
        except version.InvalidVersion:
            # Fallback if not valid semver
            return ver1 >= ver2

    # ============================================================================
    # Clean Subprocess Execution
    # ============================================================================

    def _get_clean_env(self) -> Dict[str, str]:
        """
        Get a clean environment dict with problematic variables filtered out.

        Filters out:
        - BASH_ENV, ENV (bash/sh startup files)
        - BASH_FUNC_* (exported bash functions - Shellshock vulnerability)
        - PROMPT_COMMAND (can execute arbitrary code)
        - CDPATH (causes unexpected cd behavior)
        - ZDOTDIR (zsh config directory)

        Returns:
            Cleaned environment dictionary
        """
        problematic_vars = {
            "BASH_ENV",
            "ENV",
            "PROMPT_COMMAND",
            "CDPATH",
            "ZDOTDIR",
        }

        clean_env = {}
        for k, v in os.environ.items():
            # Skip problematic variables and bash function exports
            if k in problematic_vars or k.startswith("BASH_FUNC_"):
                continue
            clean_env[k] = v

        # Ensure PATH is set
        if "PATH" not in clean_env:
            clean_env["PATH"] = "/usr/local/bin:/usr/bin:/bin"

        return clean_env

    def _run_command(
        self,
        cmd: List[str],
        timeout: int = 300,
        check: bool = False,
        env: Optional[Dict[str, str]] = None
    ) -> Tuple[int, str, str]:
        """
        Run a command with clean environment and return results.

        Args:
            cmd: Command and arguments as list
            timeout: Timeout in seconds (default: 300)
            check: If True, raise exception on non-zero exit
            env: Optional custom environment (uses cleaned env if None)

        Returns:
            Tuple of (returncode, stdout, stderr)
        """
        if env is None:
            env = self._get_clean_env()

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env,
                check=check
            )
            return result.returncode, result.stdout, result.stderr

        except subprocess.TimeoutExpired:
            return -1, "", f"Command timed out after {timeout}s"

        except subprocess.CalledProcessError as e:
            return e.returncode, e.stdout, e.stderr

        except Exception as e:
            return -1, "", str(e)

    def _run_shell_script(
        self,
        script_content: str,
        timeout: int = 180
    ) -> Tuple[int, str, str]:
        """
        Run a shell script by passing it to bash via stdin.

        This is safer than shell=True as it doesn't involve shell parsing
        of the command line itself.

        Args:
            script_content: Shell script content as string
            timeout: Timeout in seconds (default: 180)

        Returns:
            Tuple of (returncode, stdout, stderr)
        """
        env = self._get_clean_env()

        try:
            result = subprocess.run(
                ["bash"],
                input=script_content,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env
            )
            return result.returncode, result.stdout, result.stderr

        except subprocess.TimeoutExpired:
            return -1, "", f"Script timed out after {timeout}s"

        except Exception as e:
            return -1, "", str(e)

    def _download_and_execute(
        self,
        url: str,
        description: str,
        timeout_download: int = 60,
        timeout_execute: int = 180
    ) -> bool:
        """
        Download a script and execute it (curl | bash pattern).

        Args:
            url: URL to download script from
            description: Description for progress display
            timeout_download: Timeout for download in seconds
            timeout_execute: Timeout for execution in seconds

        Returns:
            True if successful, False otherwise
        """
        self._print_status(f"Downloading {description} installer from {url}")

        # Download script
        returncode, script_content, error = self._run_command(
            ["curl", "-fsSL", url],
            timeout=timeout_download
        )

        if returncode != 0:
            self._print_error(f"Failed to download: {error}")
            return False

        self._print_status(f"Executing {description} installer")

        # Execute script
        returncode, stdout, stderr = self._run_shell_script(
            script_content,
            timeout=timeout_execute
        )

        if returncode != 0:
            self._print_error(f"Installation failed: {stderr}")
            return False

        self._print_success(f"{description} installed successfully")
        return True

    # ============================================================================
    # Rich UI Helpers
    # ============================================================================

    def _print_status(self, msg: str) -> None:
        """Print a status message"""
        self.console.print(f"[cyan]•[/cyan] {msg}")

    def _print_success(self, msg: str) -> None:
        """Print a success message"""
        self.console.print(f"[green]✓[/green] {msg}")

    def _print_error(self, msg: str) -> None:
        """Print an error message"""
        self.console.print(f"[red]✗[/red] {msg}", style="red")

    def _print_warning(self, msg: str) -> None:
        """Print a warning message"""
        self.console.print(f"[yellow]![/yellow] {msg}")

    # ============================================================================
    # Main Entry Points
    # ============================================================================

    def run(self) -> bool:
        """
        Run the installation process.

        This is the main entry point that orchestrates the entire installation.
        Currently a stub that will be implemented in Phase 2+.

        Returns:
            True if successful, False otherwise
        """
        # Display header
        mode_text = "UPDATE MODE" if self.update_mode else "INSTALL MODE"
        self.console.print(Panel.fit(
            f"[bold cyan]Coding Tools Installer[/bold cyan]\n"
            f"[dim]OS: {self.os_type} | Package Manager: {self.pkg_manager or 'None'}[/dim]\n"
            f"[yellow]{mode_text}[/yellow]",
            border_style="cyan"
        ))

        self._print_success("Foundation loaded successfully")
        self._print_warning("Full installation logic will be implemented in Phase 2+")

        return True


def main():
    """Main entry point for standalone execution"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Install modern AI coding assistant tools",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Install all tools
  python3 coding_tools_installer.py

  # Update already installed tools
  python3 coding_tools_installer.py --update
        """
    )

    parser.add_argument(
        "--update", "-u",
        action="store_true",
        help="Update already installed tools to latest versions"
    )

    args = parser.parse_args()

    try:
        console = Console()
        installer = CodingToolsInstaller(console=console, update_mode=args.update)
        success = installer.run()
        sys.exit(0 if success else 1)

    except KeyboardInterrupt:
        console.print("\n[yellow]Installation interrupted by user[/yellow]")
        sys.exit(1)

    except Exception as e:
        console.print(f"\n[red]Error: {e}[/red]")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
