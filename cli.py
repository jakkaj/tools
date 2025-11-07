#!/usr/bin/env python3
"""
CLI entry point for jk-tools setup
"""

import sys
from pathlib import Path

from jk_tools.setup_manager import SetupManager, console


def main():
    """Main entry point for the jk-tools-setup CLI"""
    import argparse

    parser = argparse.ArgumentParser(
        description="JK Tools Repository Setup Manager",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Install all tools
  jk-tools-setup

  # Update already installed tools
  jk-tools-setup --update

  # Clear old MCP servers and install fresh
  jk-tools-setup --clear-mcp

  # Install commands locally (no global setup)
  jk-tools-setup --commands-local claude,ghcp

  # Install to specific directory
  jk-tools-setup --commands-local claude --local-dir ~/my-project

  # Use local development version
  jk-tools-setup --dev-mode /path/to/tools
        """
    )
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
        "--dev-mode",
        type=Path,
        metavar="PATH",
        help="Run in development mode using local filesystem at PATH (for contributors)"
    )
    parser.add_argument(
        "--commands-local",
        type=str,
        default="",
        metavar="CLIS",
        help="Install commands locally to project directory (comma-separated: claude,opencode,ghcp,codex)"
    )
    parser.add_argument(
        "--local-dir",
        type=str,
        metavar="PATH",
        help="Target directory for local commands (default: current directory)"
    )

    args = parser.parse_args()

    try:
        # Create manager with optional dev mode path
        manager = SetupManager(resource_root=args.dev_mode)
        manager.clear_mcp = args.clear_mcp
        if args.commands_local:
            manager.commands_local = args.commands_local
        if args.local_dir:
            manager.local_dir = args.local_dir
        manager.run(update_mode=args.update)
    except KeyboardInterrupt:
        console.print("\n[yellow]Setup interrupted by user[/yellow]")
        sys.exit(1)
    except Exception as e:
        console.print(f"\n[red]Error: {e}[/red]")
        import traceback
        if args.dev_mode:
            # Show full traceback in dev mode
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
