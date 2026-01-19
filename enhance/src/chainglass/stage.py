"""Stage class for accessing stage folder contents.

A Stage represents a stage in a run folder. It is atomic and self-contained,
reading everything from stage-config.yaml. Validation is separate from loading.
"""

import json
from dataclasses import dataclass, field
from functools import cached_property
from pathlib import Path
from typing import Any

import yaml

from chainglass.validator import ValidationResult


def resolve_query(data: dict | list | Any, query: str) -> Any:
    """
    Resolve a dot-notation query with optional array indexing.

    Examples:
        resolve_query({"a": {"b": 1}}, "a.b") → 1
        resolve_query({"items": [{"name": "x"}]}, "items[0].name") → "x"
        resolve_query({"a": {"b": {"c": 2}}}, "a.b.c") → 2
        resolve_query({"items": [1, 2, 3]}, "items.length") → 3

    Returns None if path doesn't exist (no exceptions for missing keys).
    """
    import re

    if data is None or query is None or query == "":
        return None

    current = data

    # Split query into segments, handling array indexing
    # Pattern: property name optionally followed by [index]
    # Examples: "a", "items[0]", "components[1]"
    segment_pattern = re.compile(r"([^.\[\]]+)(?:\[(\d+)\])?")

    parts = query.split(".")
    for part in parts:
        if current is None:
            return None

        match = segment_pattern.fullmatch(part)
        if not match:
            return None

        key, index = match.groups()

        # Special case: "length" on a list returns len()
        if key == "length" and isinstance(current, list):
            return len(current)

        # Navigate to key
        if isinstance(current, dict):
            if key not in current:
                return None
            current = current[key]
        elif isinstance(current, list):
            # For lists, key might be a numeric index without brackets
            try:
                idx = int(key)
                if idx < 0 or idx >= len(current):
                    return None
                current = current[idx]
            except ValueError:
                return None
        else:
            return None

        # Handle array index if present
        if index is not None:
            if not isinstance(current, list):
                return None
            idx = int(index)
            if idx < 0 or idx >= len(current):
                return None
            current = current[idx]

    return current


class Stage:
    """
    Represents a stage in a run folder.

    Atomic and self-contained - reads everything from stage-config.yaml.
    Always loadable if folder exists - validation is separate.
    Provides graceful access to outputs (None/empty if not present).

    Args:
        path: Path to stage folder (e.g., "run/stages/explore")

    Example:
        >>> stage = Stage(Path("run/stages/explore"))
        >>> stage.path
        PosixPath('/abs/path/run/stages/explore')
        >>> stage.config["id"]
        'explore'
        >>> stage.get_output_params()
        {'total_findings': 15, 'critical_count': 2}
        >>> stage.is_complete
        True
    """

    def __init__(self, path: Path):
        self.path = Path(path).resolve()
        self._config: dict | None = None
        self._json_cache: dict[Path, Any] = {}  # FIX-008: JSON caching

    # =========================================================================
    # Path Discovery (derived from stage folder location)
    # =========================================================================

    @property
    def stage_id(self) -> str:
        """Stage ID from folder name."""
        return self.path.name

    @property
    def run_dir(self) -> Path:
        """Parent run directory (two levels up from stage folder)."""
        return self.path.parent.parent

    @property
    def wf_run_path(self) -> Path:
        """Path to wf-run.json (discovered from run_dir)."""
        return self.run_dir / "wf-run.json"

    # =========================================================================
    # Configuration (lazy loading)
    # =========================================================================

    @property
    def config(self) -> dict:
        """Load stage-config.yaml (lazy, cached)."""
        if self._config is None:
            config_path = self.path / "stage-config.yaml"
            try:
                self._config = yaml.safe_load(config_path.read_text())
            except FileNotFoundError:
                raise ValueError(f"stage-config.yaml not found: {config_path}")
            except yaml.YAMLError as e:
                raise ValueError(f"Invalid YAML in {config_path}: {e}")
        return self._config

    @property
    def name(self) -> str:
        """Stage display name from config."""
        return self.config.get("name", self.stage_id)

    # =========================================================================
    # Validation (separate from loading) - T003
    # =========================================================================

    def validate(self) -> ValidationResult:
        """
        Check if stage is complete. Returns result, doesn't raise.

        Checks:
        - All required output files exist
        - All required output data files exist
        - All output_parameters can be extracted

        Returns ValidationResult with valid=True if complete, else errors populated.
        """
        result = ValidationResult(valid=True)

        # Check required output files exist
        for output in self.config.get("outputs", {}).get("files", []):
            path = self.path / output["path"]
            if not path.exists():
                result.valid = False
                result.errors.append(
                    f"Missing output file: {output['name']}\n"
                    f"  Expected at: {path}\n"
                    f"  Action: Create this file with the stage output content."
                )

        # Check required output data files exist
        for output in self.config.get("outputs", {}).get("data", []):
            if output.get("required", True):
                path = self.path / output["path"]
                if not path.exists():
                    result.valid = False
                    result.errors.append(
                        f"Missing output data: {output['name']}\n"
                        f"  Expected at: {path}\n"
                        f"  Action: Create this JSON file with required data."
                    )

        # Check output_parameters can be extracted (if declared)
        for param in self.config.get("output_parameters", []):
            value = self.query_output(param["source"], param["query"])
            if value is None:
                result.valid = False
                result.errors.append(
                    f"Cannot extract output_parameter: {param['name']}\n"
                    f"  Source: {param['source']}\n"
                    f"  Query: {param['query']}\n"
                    f"  Action: Ensure the source file exists and contains the expected data."
                )

        return result

    @cached_property
    def is_complete(self) -> bool:
        """Convenience: True if validate() passes."""
        return self.validate().valid

    @property
    def is_finalized(self) -> bool:
        """True if output-params.json exists (stage has been finalized)."""
        return (self.path / "run" / "output-data" / "output-params.json").exists()

    # =========================================================================
    # Finalization (validates + writes output-params.json) - T004
    # =========================================================================

    def finalize(self) -> "FinalizeResult":
        """
        Validate stage completion and publish output parameters.

        This is the "official" way to mark a stage as complete after the LLM
        finishes its work. It:
        1. Runs validate() to check all outputs exist
        2. Extracts output_parameters using source + query definitions
        3. Writes extracted parameters to run/output-data/output-params.json
        4. Updates stage status in wf-run.json to "completed"

        Returns:
            FinalizeResult with success=True if finalized, else errors populated.
        """
        from datetime import datetime, timezone

        result = FinalizeResult(success=True)

        # Step 1: Validate outputs exist
        validation = self.validate()
        if not validation.valid:
            result.success = False
            result.errors = validation.errors
            return result

        # Step 2: Extract output_parameters
        parameters: dict[str, Any] = {}
        for param in self.config.get("output_parameters", []):
            value = self.query_output(param["source"], param["query"])
            if value is not None:
                parameters[param["name"]] = value
            else:
                result.success = False
                result.errors.append(
                    f"Cannot extract parameter: {param['name']}\n"
                    f"  Source: {param['source']}\n"
                    f"  Query: {param['query']}"
                )

        if not result.success:
            return result

        # Step 3: Write output-params.json
        output_params_path = self.path / "run" / "output-data" / "output-params.json"
        output_params_path.parent.mkdir(parents=True, exist_ok=True)  # FIX-002
        output_params_data = {
            "stage_id": self.stage_id,
            "published_at": datetime.now(timezone.utc).isoformat(),  # FIX-001
            "parameters": parameters,
        }
        output_params_path.write_text(json.dumps(output_params_data, indent=2))

        # Step 4: Update wf-run.json status
        self._update_wf_run_status("completed")

        result.parameters = parameters
        return result

    def _update_wf_run_status(self, status: str) -> None:
        """Update this stage's status in wf-run.json."""
        from datetime import datetime, timezone

        # FIX-007: Check wf-run.json exists
        if not self.wf_run_path.exists():
            return  # Silent no-op if wf-run.json missing

        wf_run = json.loads(self.wf_run_path.read_text())
        stage_found = False  # FIX-011: Track if stage found
        for stage in wf_run.get("stages", []):
            if stage["id"] == self.stage_id:
                stage["status"] = status
                if status == "completed":
                    stage["completed_at"] = datetime.now(timezone.utc).isoformat()
                stage_found = True
                break

        if not stage_found:
            return  # FIX-011: Silent no-op if stage not in wf-run.json

        self.wf_run_path.write_text(json.dumps(wf_run, indent=2))

    # =========================================================================
    # Output Access (graceful - returns None/empty if not present)
    # =========================================================================

    def get_output_params(self) -> dict:
        """
        Get published output parameters dict.

        Returns empty dict if output-params.json not yet written.
        """
        path = self.path / "run" / "output-data" / "output-params.json"
        if path.exists():
            data = json.loads(path.read_text())
            return data.get("parameters", {})
        return {}

    def get_output_data(self, filename: str) -> dict | None:
        """
        Load JSON from run/output-data/.

        Returns None if file doesn't exist or path traversal detected.
        """
        # FIX-004: Validate filename
        if ".." in filename or filename.startswith("/"):
            return None
        path = self.path / "run" / "output-data" / filename
        # FIX-004: Verify path is within stage
        if not path.resolve().is_relative_to(self.path):
            return None
        if path.exists():
            return json.loads(path.read_text())
        return None

    def get_output_file(self, filename: str) -> Path | None:
        """
        Get path to file in run/output-files/.

        Returns None if file doesn't exist or path traversal detected.
        """
        # FIX-004: Validate filename
        if ".." in filename or filename.startswith("/"):
            return None
        path = self.path / "run" / "output-files" / filename
        # FIX-004: Verify path is within stage
        if not path.resolve().is_relative_to(self.path):
            return None
        return path if path.exists() else None

    def query_output(self, source: str, query: str) -> Any | None:
        """
        Query a JSON output file using dot notation.

        Args:
            source: Path relative to stage (e.g., "run/output-data/metrics.json")
            query: Dot notation query (e.g., "summary.total_findings")

        Returns None if file missing, path traversal detected, or query path doesn't exist.
        """
        # FIX-004: Validate source path
        if ".." in source or source.startswith("/"):
            return None
        source_path = self.path / source
        # FIX-004: Verify path is within stage
        if not source_path.resolve().is_relative_to(self.path):
            return None
        if not source_path.exists():
            return None

        # FIX-008: Use cache
        resolved_path = source_path.resolve()
        if resolved_path not in self._json_cache:
            self._json_cache[resolved_path] = json.loads(source_path.read_text())

        data = self._json_cache[resolved_path]
        return resolve_query(data, query)


@dataclass
class FinalizeResult:
    """Result of stage finalization."""

    success: bool
    errors: list[str] = field(default_factory=list)
    parameters: dict[str, Any] = field(default_factory=dict)
