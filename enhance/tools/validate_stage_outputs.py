#!/usr/bin/env python3
"""
Validate workflow stage outputs against their JSON schemas.

Usage:
    python validate_stage_outputs.py <stage_dir>
    python validate_stage_outputs.py <stage_dir> --verbose
    python validate_stage_outputs.py <output_file> <schema_file>

Examples:
    # Validate all outputs in a stage directory
    python validate_stage_outputs.py enhance/run/002/runs/run-2024-01-18-001/stages/01-explore

    # Validate a single file against a schema
    python validate_stage_outputs.py output.json schema.json

    # Verbose output with schema details
    python validate_stage_outputs.py enhance/run/002/.../01-explore --verbose
"""

import argparse
import json
import sys
from pathlib import Path
from typing import Optional

try:
    from jsonschema import Draft202012Validator, ValidationError
    HAS_JSONSCHEMA = True
except ImportError:
    HAS_JSONSCHEMA = False


# ANSI colors
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
RESET = "\033[0m"
BOLD = "\033[1m"


def load_json(path: Path) -> tuple[Optional[dict], Optional[str]]:
    """Load JSON file, return (data, error)."""
    try:
        with open(path) as f:
            return json.load(f), None
    except json.JSONDecodeError as e:
        return None, f"Invalid JSON: {e}"
    except FileNotFoundError:
        return None, "File not found"
    except Exception as e:
        return None, str(e)


def validate_against_schema(
    data: dict,
    schema: dict,
    verbose: bool = False
) -> tuple[bool, list[str]]:
    """
    Validate data against JSON schema.
    Returns (is_valid, list of error messages).
    """
    if not HAS_JSONSCHEMA:
        return True, ["jsonschema not installed - skipping validation"]

    validator = Draft202012Validator(schema)
    errors = list(validator.iter_errors(data))

    if not errors:
        return True, []

    error_messages = []
    for error in errors:
        path = " -> ".join(str(p) for p in error.absolute_path) or "(root)"
        msg = f"  {path}: {error.message}"
        error_messages.append(msg)

        if verbose and error.context:
            for ctx in error.context:
                ctx_path = " -> ".join(str(p) for p in ctx.absolute_path)
                error_messages.append(f"    - {ctx_path}: {ctx.message}")

    return False, error_messages


def find_output_schema_pairs(stage_dir: Path) -> list[tuple[Path, Path, str]]:
    """
    Find output files and their corresponding schemas.
    Returns list of (output_path, schema_path, name) tuples.
    """
    pairs = []

    # Read stage-config.json to find declared outputs
    config_path = stage_dir / "stage-config.json"
    if not config_path.exists():
        return pairs

    config, err = load_json(config_path)
    if err:
        return pairs

    outputs = config.get("outputs", {})

    # Check data outputs
    for output in outputs.get("data", []):
        output_path = stage_dir / output["path"]
        schema_ref = output.get("schema")
        if schema_ref:
            schema_path = stage_dir / schema_ref
            pairs.append((output_path, schema_path, output["name"]))

    # Check runtime outputs
    for output in outputs.get("runtime", []):
        output_path = stage_dir / output["path"]
        schema_ref = output.get("schema")
        if schema_ref:
            schema_path = stage_dir / schema_ref
            pairs.append((output_path, schema_path, output["name"]))

    return pairs


def validate_pair(
    output_path: Path,
    schema_path: Path,
    name: str,
    verbose: bool = False
) -> tuple[bool, str]:
    """Validate a single output/schema pair. Returns (success, message)."""
    lines = []

    # Load schema
    schema, schema_err = load_json(schema_path)
    if schema_err:
        return False, f"{RED}✗{RESET} {name}: Schema error - {schema_err}"

    # Load output
    data, data_err = load_json(output_path)
    if data_err:
        return False, f"{RED}✗{RESET} {name}: Output error - {data_err}"

    # Validate
    is_valid, errors = validate_against_schema(data, schema, verbose)

    if is_valid:
        msg = f"{GREEN}✓{RESET} {name}"
        if verbose:
            msg += f"\n    Output: {output_path}"
            msg += f"\n    Schema: {schema_path}"
        return True, msg
    else:
        lines.append(f"{RED}✗{RESET} {name}")
        lines.append(f"    Output: {output_path}")
        lines.append(f"    Schema: {schema_path}")
        lines.append(f"    Errors:")
        lines.extend(errors)
        return False, "\n".join(lines)


def validate_stage(stage_dir: Path, verbose: bool = False) -> int:
    """Validate all outputs in a stage directory. Returns exit code."""
    print(f"\n{BOLD}Validating stage outputs{RESET}")
    print(f"Stage: {stage_dir}\n")

    if not HAS_JSONSCHEMA:
        print(f"{YELLOW}Warning: jsonschema not installed{RESET}")
        print("Install with: pip install jsonschema")
        print("Continuing with basic JSON validation only...\n")

    pairs = find_output_schema_pairs(stage_dir)

    if not pairs:
        print(f"{YELLOW}No output/schema pairs found{RESET}")
        print("Check that stage-config.json exists and declares schemas")
        return 1

    results = []
    for output_path, schema_path, name in pairs:
        success, message = validate_pair(output_path, schema_path, name, verbose)
        results.append((success, message))
        print(message)

    # Summary
    passed = sum(1 for s, _ in results if s)
    failed = len(results) - passed

    print(f"\n{BOLD}Summary{RESET}")
    print(f"  Passed: {GREEN}{passed}{RESET}")
    print(f"  Failed: {RED}{failed}{RESET}" if failed else f"  Failed: {failed}")

    return 0 if failed == 0 else 1


def validate_single_pair(
    output_path: Path,
    schema_path: Path,
    verbose: bool = False
) -> int:
    """Validate a single output/schema pair. Returns exit code."""
    print(f"\n{BOLD}Validating single file{RESET}")
    print(f"Output: {output_path}")
    print(f"Schema: {schema_path}\n")

    if not HAS_JSONSCHEMA:
        print(f"{YELLOW}Warning: jsonschema not installed{RESET}")
        print("Install with: pip install jsonschema\n")

    success, message = validate_pair(
        output_path,
        schema_path,
        output_path.name,
        verbose
    )
    print(message)

    return 0 if success else 1


def main():
    parser = argparse.ArgumentParser(
        description="Validate workflow stage outputs against JSON schemas"
    )
    parser.add_argument(
        "path",
        type=Path,
        help="Stage directory or output file"
    )
    parser.add_argument(
        "schema",
        type=Path,
        nargs="?",
        help="Schema file (when validating single file)"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show detailed output"
    )
    args = parser.parse_args()

    # Determine mode: single file or stage directory
    if args.schema:
        # Single file mode
        return validate_single_pair(args.path, args.schema, args.verbose)
    elif args.path.is_dir():
        # Stage directory mode
        return validate_stage(args.path, args.verbose)
    else:
        print(f"{RED}Error:{RESET} {args.path} is not a directory")
        print("Provide a stage directory, or both output and schema files")
        return 1


if __name__ == "__main__":
    sys.exit(main())
