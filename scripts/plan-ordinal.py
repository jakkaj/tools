#!/usr/bin/env python3
"""
plan-ordinal - Cross-branch plan ordinal counter

Scans all git branches to find existing plan folders (docs/plans/NNN-*)
and returns the next available ordinal number, preventing collisions
when multiple branches create plans concurrently.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

# Version
__version__ = "1.0.0"

# Help text following repository conventions
HELP_TEXT = """
NAME
    plan-ordinal - Get next available plan ordinal across all git branches

SYNOPSIS
    plan-ordinal [OPTIONS]

DESCRIPTION
    Scans all local and remote git branches for existing plan folders
    (docs/plans/NNN-*) and returns the next available ordinal number.

    This prevents ordinal collisions when multiple branches create plans
    concurrently. The tool uses 'git ls-tree' to read branch contents
    without checking them out.

OPTIONS
    --next
        Output the next available ordinal (default behavior)

    --current
        Output the current highest ordinal found

    --json
        Output as JSON instead of plain text

    --all
        Show all ordinals found across branches (with --json shows full data)

    --help, -h
        Show this help message and exit

    --version
        Show version number and exit

OUTPUT
    Plain text (default): 3-digit zero-padded ordinal (e.g., "011")
    JSON (--json): {"next": 11} or {"current": 10}

EXAMPLES
    # Get next available ordinal
    plan-ordinal
    # Output: 011

    # Get current highest ordinal
    plan-ordinal --current
    # Output: 010

    # Get next ordinal as JSON
    plan-ordinal --json
    # Output: {"next": 11}

    # Show all ordinals found
    plan-ordinal --all
    # Output: 001 002 003 ... 010

    # Full data as JSON
    plan-ordinal --all --json
    # Output: {"ordinals": [1,2,3,...], "current": 10, "next": 11, ...}

PREREQUISITES
    - Must be run from within a git repository
    - For accurate results, run 'git fetch' first to update remote refs

ALIAS
    jk-po - Shortened alias available after running setup.sh

AUTHOR
    Part of the jk-tools collection
"""


def get_clean_env() -> dict:
    """
    Get a clean environment for subprocess calls.
    Filters out problematic variables that could interfere with git operations.
    Pattern from setup_manager.py.
    """
    problematic_vars = {
        "BASH_ENV", "ENV", "PROMPT_COMMAND", "CDPATH", "ZDOTDIR"
    }
    clean_env = {}
    for k, v in os.environ.items():
        if k in problematic_vars or k.startswith("BASH_FUNC_"):
            continue
        clean_env[k] = v
    return clean_env


def run_git(args: list[str], cwd: Optional[Path] = None) -> tuple[int, str, str]:
    """
    Run a git command and return (returncode, stdout, stderr).
    Uses clean environment to prevent shell interference.
    """
    try:
        result = subprocess.run(
            ["git"] + args,
            capture_output=True,
            text=True,
            cwd=cwd,
            env=get_clean_env()
        )
        return result.returncode, result.stdout.strip(), result.stderr.strip()
    except FileNotFoundError:
        return -1, "", "git command not found"
    except Exception as e:
        return -1, "", str(e)


def get_repo_root() -> Optional[Path]:
    """
    Get the git repository root directory.
    Returns None if not in a git repository.
    """
    code, stdout, _ = run_git(["rev-parse", "--show-toplevel"])
    if code == 0 and stdout:
        return Path(stdout)
    return None


def get_all_branches() -> list[str]:
    """
    Get all local and remote branch names, deduplicated.
    Filters out symbolic refs and deduplicates local/remote branches.
    """
    code, stdout, _ = run_git(["branch", "-a", "--format=%(refname:short)"])
    if code != 0 or not stdout:
        return []

    branches = []
    seen_names = set()

    for line in stdout.split('\n'):
        branch = line.strip()
        if not branch:
            continue

        # Skip symbolic refs like 'origin' (points to HEAD)
        if branch == 'origin' or branch.endswith('/HEAD'):
            continue

        # Normalize: remove 'origin/' prefix for deduplication
        normalized = branch.replace('origin/', '')

        if normalized not in seen_names:
            seen_names.add(normalized)
            branches.append(branch)

    return branches


def get_ordinals_from_branch(branch: str) -> list[int]:
    """
    Get all plan ordinals from a specific branch using git ls-tree.
    Returns empty list if branch has no docs/plans/ or on error.
    """
    code, stdout, _ = run_git(["ls-tree", "--name-only", branch, "docs/plans/"])

    # Empty output (no docs/plans/) is valid, not an error
    if code != 0 or not stdout:
        return []

    ordinals = []
    for line in stdout.split('\n'):
        if not line:
            continue
        # Extract folder name from path like "docs/plans/001-project-setup"
        folder_name = Path(line).name
        # Match 3-digit prefix
        match = re.match(r'^(\d{3})-', folder_name)
        if match:
            ordinals.append(int(match.group(1)))

    return ordinals


def get_ordinals_from_branch_names(branches: list[str]) -> set[int]:
    """
    Extract ordinals from branch names that follow the NNN-* pattern.
    This catches branches like '013-feature' even if they don't have docs/plans/ folders yet.
    """
    ordinals = set()
    for branch in branches:
        # Normalize: remove 'origin/' prefix
        name = branch.replace('origin/', '')
        # Match 3-digit prefix at start of branch name
        match = re.match(r'^(\d{3})-', name)
        if match:
            ordinals.add(int(match.group(1)))
    return ordinals


def get_all_ordinals() -> dict:
    """
    Get all ordinals across all branches.
    Scans both docs/plans/ folders AND branch names with NNN-* pattern.
    Returns dict with 'ordinals', 'by_branch', 'current', 'next'.
    """
    branches = get_all_branches()
    by_branch = {}
    all_ordinals = set()

    # Get ordinals from docs/plans/ folders on each branch
    for branch in branches:
        ordinals = get_ordinals_from_branch(branch)
        if ordinals:
            by_branch[branch] = sorted(ordinals)
            all_ordinals.update(ordinals)

    # Also get ordinals from branch names themselves (e.g., "013-feature")
    branch_ordinals = get_ordinals_from_branch_names(branches)
    all_ordinals.update(branch_ordinals)

    current = max(all_ordinals) if all_ordinals else 0
    next_ord = current + 1

    return {
        "ordinals": sorted(all_ordinals),
        "by_branch": by_branch,
        "branch_ordinals": sorted(branch_ordinals),
        "current": current,
        "next": next_ord
    }


def create_parser() -> argparse.ArgumentParser:
    """Create argument parser with all options."""
    parser = argparse.ArgumentParser(
        prog='plan-ordinal',
        description='Get next available plan ordinal across all git branches',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=HELP_TEXT,
        add_help=False  # We'll handle --help ourselves for custom formatting
    )

    parser.add_argument(
        '--next',
        action='store_true',
        default=True,
        help='Output the next available ordinal (default)'
    )
    parser.add_argument(
        '--current',
        action='store_true',
        help='Output the current highest ordinal'
    )
    parser.add_argument(
        '--json',
        action='store_true',
        help='Output as JSON instead of plain text'
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='Show all ordinals found'
    )
    parser.add_argument(
        '--help', '-h',
        action='store_true',
        help='Show this help message and exit'
    )
    parser.add_argument(
        '--version',
        action='store_true',
        help='Show version number and exit'
    )

    return parser


def main() -> int:
    """Main entry point."""
    parser = create_parser()
    args = parser.parse_args()

    # Handle --help
    if args.help:
        print(HELP_TEXT)
        return 0

    # Handle --version
    if args.version:
        print(f"plan-ordinal {__version__}")
        return 0

    # Check if in git repository
    repo_root = get_repo_root()
    if repo_root is None:
        print("Error: Not in a git repository", file=sys.stderr)
        print("Run this command from within a git repository.", file=sys.stderr)
        return 1

    # Get all ordinals
    data = get_all_ordinals()

    # Output based on flags
    if args.json:
        if args.all:
            print(json.dumps(data))
        elif args.current:
            print(json.dumps({"current": data["current"]}))
        else:
            print(json.dumps({"next": data["next"]}))
    else:
        if args.all:
            # Print each ordinal on same line, space-separated
            print(" ".join(f"{o:03d}" for o in data["ordinals"]))
        elif args.current:
            print(f"{data['current']:03d}")
        else:
            print(f"{data['next']:03d}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
