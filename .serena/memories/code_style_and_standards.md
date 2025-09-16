# Code Style & Conventions
- Shell scripts use POSIX/bash with `#!/usr/bin/env bash`, `set -e`, helper print functions, environment-aware checks, and should be idempotent.
- Python scripts (e.g., `setup_manager.py`) rely on standard library plus `rich`; follow dataclass-based structures, console-friendly output, and explicit path handling via `pathlib`.
- New CLI tools must ship `--help`, document NAME/SYNOPSIS/DESCRIPTION/PARAMETERS/OPTIONS/EXAMPLES, support no-arg help when safe, and favor descriptive dash-separated names.
- Tools should be pipe-friendly, use proper exit codes, and document dependencies. Temporary or experimental output should stay under `scratch/` (gitignored).