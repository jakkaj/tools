# Tools Repository Overview
- Provides a centralized, version-controlled collection of setup and utility scripts to install and configure developer tooling consistently across macOS, Linux, and Windows (WSL/Git Bash).
- Primary entrypoint is `setup.sh`, which bootstraps Python dependencies then delegates to `setup_manager.py` for orchestrating installers inside `install/`.
- Ships reusable agent command markdown and MCP server definitions under `agents/` plus helper scripts in `scripts/`.
- Targets both local shell use and AI assistant CLIs by syncing command files and MCP configs.