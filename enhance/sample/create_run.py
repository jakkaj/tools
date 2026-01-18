#!/usr/bin/env python3
"""
Create a clean workflow run from a sample template.

Copies a sample workflow structure to enhance/run/<ordinal>, stripping out
any output artifacts so a coding agent can execute the stage fresh.

Usage:
    python create_run.py [sample_name]

    sample_name: Name of sample folder (default: sample_1)

Examples:
    python create_run.py              # Uses sample_1
    python create_run.py sample_2     # Uses sample_2
"""

import argparse
import json
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path


# Directories/files to clear (keep structure, remove contents)
OUTPUT_DIRS = [
    "run/output-files",
    "run/output-data",
    "run/runtime-inputs",
]

# Files to always exclude from copy
EXCLUDE_PATTERNS = [
    ".DS_Store",
    "__pycache__",
    "*.pyc",
]


def get_next_ordinal(run_dir: Path) -> int:
    """Get the next available ordinal for run directories."""
    if not run_dir.exists():
        return 1

    existing = [
        int(d.name) for d in run_dir.iterdir()
        if d.is_dir() and d.name.isdigit()
    ]
    return max(existing, default=0) + 1


def should_exclude(path: Path) -> bool:
    """Check if a path should be excluded from copy."""
    name = path.name
    for pattern in EXCLUDE_PATTERNS:
        if pattern.startswith("*"):
            if name.endswith(pattern[1:]):
                return True
        elif name == pattern:
            return True
    return False


def is_output_dir(rel_path: str) -> bool:
    """Check if a relative path is within an output directory."""
    for output_dir in OUTPUT_DIRS:
        if rel_path.startswith(output_dir) or f"/{output_dir}" in rel_path:
            return True
    return False


def copy_sample_to_run(sample_path: Path, run_path: Path) -> dict:
    """
    Copy sample to run directory, stripping output artifacts.

    Returns dict with copy statistics.
    """
    stats = {
        "copied_files": 0,
        "copied_dirs": 0,
        "skipped_outputs": 0,
        "created_empty_dirs": 0,
    }

    for src_path in sample_path.rglob("*"):
        if should_exclude(src_path):
            continue

        # Get path relative to sample
        rel_path = src_path.relative_to(sample_path)
        dst_path = run_path / rel_path

        # Check if this is in an output directory (within any stage)
        rel_str = str(rel_path)
        in_output = is_output_dir(rel_str)

        if src_path.is_dir():
            dst_path.mkdir(parents=True, exist_ok=True)
            stats["copied_dirs"] += 1
            if in_output:
                stats["created_empty_dirs"] += 1
        elif src_path.is_file():
            if in_output:
                # Skip output files - just ensure parent dir exists
                dst_path.parent.mkdir(parents=True, exist_ok=True)
                stats["skipped_outputs"] += 1
            else:
                # Copy non-output files
                dst_path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src_path, dst_path)
                stats["copied_files"] += 1

    return stats


def update_run_metadata(run_path: Path, ordinal: int, sample_name: str):
    """Update wf-run.json with run metadata."""
    # Find wf-run.json in the runs subdirectory
    for wf_run_file in run_path.rglob("wf-run.json"):
        metadata = {
            "run_id": ordinal,
            "created_at": datetime.now().isoformat(),
            "source_sample": sample_name,
            "status": "pending",
        }
        with open(wf_run_file, "w") as f:
            json.dump(metadata, f, indent=2)
        return wf_run_file
    return None


def main():
    parser = argparse.ArgumentParser(
        description="Create a clean workflow run from a sample template"
    )
    parser.add_argument(
        "sample_name",
        nargs="?",
        default="sample_1",
        help="Name of sample folder (default: sample_1)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without copying"
    )
    args = parser.parse_args()

    # Resolve paths
    script_dir = Path(__file__).parent.resolve()
    sample_path = script_dir / args.sample_name
    run_base = script_dir.parent / "run"

    # Validate sample exists
    if not sample_path.exists():
        print(f"Error: Sample '{args.sample_name}' not found at {sample_path}")
        sys.exit(1)

    # Get next ordinal
    ordinal = get_next_ordinal(run_base)
    run_path = run_base / f"{ordinal:03d}"

    if args.dry_run:
        print(f"DRY RUN - would create: {run_path}")
        print(f"  Source: {sample_path}")
        print(f"  Would strip outputs from: {OUTPUT_DIRS}")
        return

    # Create run directory
    run_path.mkdir(parents=True, exist_ok=True)

    # Copy sample to run
    print(f"Creating run {ordinal:03d} from {args.sample_name}...")
    stats = copy_sample_to_run(sample_path, run_path)

    # Update run metadata
    wf_run_file = update_run_metadata(run_path, ordinal, args.sample_name)

    # Print summary
    print(f"\n✅ Created: {run_path}")
    print(f"   Files copied: {stats['copied_files']}")
    print(f"   Outputs stripped: {stats['skipped_outputs']}")
    print(f"   Empty output dirs created: {stats['created_empty_dirs']}")
    if wf_run_file:
        print(f"   Updated: {wf_run_file.relative_to(run_path)}")

    # Print next steps
    print(f"\n📋 To test with a coding agent:")
    print(f"   Point agent at: {run_path}/runs/run-2024-01-18-001/stages/01-explore/prompt/wf.md")


if __name__ == "__main__":
    main()
