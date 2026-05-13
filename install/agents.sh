#!/usr/bin/env bash

# Install MCP server configurations for Claude CLI, OpenCode CLI, Codex CLI,
# Copilot CLI, and VS Code.
#
# Skills are NOT installed by this script. They live at /skills/ and are
# distributed via `npx skills@latest add jakkaj/tools` (see /INSTALL.md).
#
# Usage: agents.sh [OPTIONS]
#   --clear-mcp:     Clear all existing MCP servers before installing new ones
#   --no-auto-sudo:  Disable automatic sudo retry on permission errors
#   --python <cmd>:  Override the Python interpreter (used by setup_manager.py)

# set -e  # Disabled to allow proper error handling and prevent killing parent process

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"

# Source the permission helper library if it exists
PERMISSION_HELPER="${SCRIPT_DIR}/lib/permission_helper.sh"
if [ -f "${PERMISSION_HELPER}" ]; then
    source "${PERMISSION_HELPER}"
else
    # Fallback functions if helper isn't available
    mkdir_with_retry() { mkdir -p "$1"; }
    cp_with_retry() { cp -r "$1" "$2"; }
fi

SYNC_SCRIPT="${REPO_ROOT}/scripts/sync-to-dist.sh"
MCP_SOURCE="${REPO_ROOT}/agents/mcp/servers.json"

# Determine the correct Python command to use.
# When running via uvx, setup_manager.py passes --python with the correct interpreter.
get_python_cmd() {
    if [ -n "${PYTHON_OVERRIDE:-}" ]; then
        echo "${PYTHON_OVERRIDE}"
    elif [ -n "${VIRTUAL_ENV:-}" ] && command -v uv >/dev/null 2>&1; then
        echo "uv run python"
    elif command -v uv >/dev/null 2>&1 && uv run python --version >/dev/null 2>&1; then
        echo "uv run python"
    else
        echo "python3"
    fi
}

# Parse command line arguments
CLEAR_MCP=false
PYTHON_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --clear-mcp)
            CLEAR_MCP=true
            shift
            ;;
        --no-auto-sudo)
            export AUTO_SUDO_ENABLED=false
            shift
            ;;
        --python)
            PYTHON_OVERRIDE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Set Python command after argument parsing (so --python override is available)
PYTHON_CMD="$(get_python_cmd)"

# Support multiple .env file locations (first found wins):
# 1. Current directory .env (project-specific)
# 2. Home directory ~/.jk-tools.env (recommended for uvx users)
# 3. Repo root .env (dev mode)
ENV_FILE=""
if [ -f "./.env" ]; then
    ENV_FILE="./.env"
elif [ -f "${HOME}/.jk-tools.env" ]; then
    ENV_FILE="${HOME}/.jk-tools.env"
elif [ -f "${REPO_ROOT}/.env" ]; then
    ENV_FILE="${REPO_ROOT}/.env"
fi

# MCP target locations
# Copilot CLI (distinct from VS Code Copilot extension) keeps mcp-config.json
# under XDG_CONFIG_HOME or ~/.copilot/. We do not write skills here — that is
# the responsibility of `npx skills add`.
COPILOT_CLI_DIR="${XDG_CONFIG_HOME:-$HOME}/.copilot"
COPILOT_CLI_MCP_CONFIG="${COPILOT_CLI_DIR}/mcp-config.json"

SYSTEM_NAME="$(uname -s)"
if [[ "${SYSTEM_NAME}" == "Darwin" ]]; then
    VSCODE_USER_DIR="${HOME}/Library/Application Support/Code/User"
else
    VSCODE_USER_DIR="${HOME}/.config/Code/User"
fi
VSCODE_USER_CONFIG="${VSCODE_USER_DIR}/mcp.json"
VSCODE_PROJECT_DIR="${REPO_ROOT}/.vscode"
VSCODE_PROJECT_CONFIG="${VSCODE_PROJECT_DIR}/mcp.json"

print_status()  { echo "[*] $1"; }
print_success() { echo "[✓] $1"; }
print_error()   { echo "[✗] $1" >&2; }
print_warning() { echo "[⚠] $1"; }

generate_mcp_configs() {
    local mcp_source="$1"
    local vscode_user_config="$2"
    local vscode_project_config="$3"

    if [ ! -f "${mcp_source}" ]; then
        print_status "No MCP configuration source found at ${mcp_source}, skipping MCP setup"
        return 1
    fi

    # Load environment variables if .env exists
    local openrouter_key=""
    local perplexity_key=""
    local perplexity_model="sonar"
    if [ -f "${ENV_FILE}" ]; then
        source "${ENV_FILE}"
        openrouter_key="${MCP_LLM_OPENROUTER_API_KEY}"
        perplexity_key="${PERPLEXITY_API_KEY}"
        perplexity_model="${PERPLEXITY_MODEL:-sonar}"
    fi

    # Check if Perplexity is enabled in servers.json and validate API key
    if grep -A 10 '"perplexity"' "${mcp_source}" | grep -q '"enabled".*:.*true'; then
        if [ -z "${perplexity_key}" ] || [ "${perplexity_key}" = "your_perplexity_api_key_here" ]; then
            echo ""
            print_error "Perplexity MCP server is enabled but PERPLEXITY_API_KEY is not set"
            echo ""

            # Determine which .env file to create
            local env_file_to_create=""
            if [ -f "${REPO_ROOT}/.git/config" ]; then
                # Dev mode - use local .env
                env_file_to_create="${REPO_ROOT}/.env"
            else
                # uvx/packaged mode - use ~/.jk-tools.env
                env_file_to_create="${HOME}/.jk-tools.env"
            fi

            # Create template .env file if it doesn't exist
            if [ ! -f "${env_file_to_create}" ]; then
                print_status "Creating template environment file: ${env_file_to_create}"
                cat > "${env_file_to_create}" <<'EOF'
# Perplexity MCP Server Configuration
PERPLEXITY_API_KEY=your_perplexity_api_key_here

# MCP Browser Use Configuration (optional)
# MCP_LLM_PROVIDER=openrouter
# MCP_LLM_OPENROUTER_API_KEY=your_openrouter_api_key_here
# MCP_LLM_MODEL_NAME=openai/gpt-5-mini
# MCP_BROWSER_HEADLESS=true
# MCP_AGENT_TOOL_USE_VISION=false
EOF
                print_success "Created ${env_file_to_create}"
                echo ""
            fi

            echo "Please edit ${env_file_to_create} and add your Perplexity API key,"
            echo "then re-run the installer."
            echo ""
            echo "Or disable Perplexity in agents/mcp/servers.json by setting \"enabled\": false"
            echo ""
            return 1
        fi
    fi

    local opencode_global="${HOME}/.config/opencode/opencode.json"
    local opencode_project="${REPO_ROOT}/opencode.json"
    local claude_global="${HOME}/.claude.json"
    local codex_global="${HOME}/.codex/config.toml"

    mkdir_with_retry "${HOME}/.config/opencode"
    mkdir_with_retry "${HOME}/.codex"
    mkdir_with_retry "$(dirname "${vscode_user_config}")"
    mkdir_with_retry "$(dirname "${vscode_project_config}")"

    local copilot_cli_mcp="${COPILOT_CLI_MCP_CONFIG}"
    mkdir_with_retry "$(dirname "${copilot_cli_mcp}")"

    $PYTHON_CMD - "$mcp_source" "$opencode_global" "$opencode_project" "$claude_global" "$codex_global" "$vscode_user_config" "$vscode_project_config" "$openrouter_key" "$perplexity_key" "$perplexity_model" "$CLEAR_MCP" "$copilot_cli_mcp" <<'PYTHON'
import json
import sys
from pathlib import Path

try:
    import tomllib  # Python 3.11+
    load_toml = tomllib.loads
except ModuleNotFoundError:
    try:
        import tomli  # type: ignore
        load_toml = tomli.loads
    except ModuleNotFoundError as exc:  # pragma: no cover - handled at runtime
        print("[✗] tomllib or tomli is required to manage Codex MCP configuration", file=sys.stderr)
        raise exc

try:
    import tomli_w  # type: ignore
except ModuleNotFoundError:
    tomli_w = None

try:
    import toml  # type: ignore
except ModuleNotFoundError:
    toml = None

if toml is None and tomli_w is None:
    print("[✗] Python package 'toml' (preferred) or 'tomli-w' is required to manage Codex MCP configuration", file=sys.stderr)
    sys.exit(1)


TYPE_MAP = {"stdio": "local", "sse": "remote"}


def create_backup(path: Path) -> None:
    """Create a timestamped backup of a file before modifying it"""
    if not path.exists():
        return

    from datetime import datetime
    timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
    backup_path = path.with_suffix(f"{path.suffix}.backup-{timestamp}")

    import shutil
    shutil.copy2(path, backup_path)
    print(f"[Backup] Created backup: {backup_path}")


def dump_toml(data):
    if toml is not None:
        return toml.dumps(data)
    return tomli_w.dumps(data)


def load_json(path: Path):
    if path.exists():
        try:
            with path.open("r", encoding="utf-8") as fh:
                return json.load(fh)
        except json.JSONDecodeError:
            backup = path.with_suffix(path.suffix + ".bak")
            path.rename(backup)
            print(f"[!] Existing JSON at {path} was invalid and has been backed up to {backup}")
    return {}


def write_json(path: Path, data):
    with path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")


def load_toml_file(path: Path):
    if path.exists():
        text = path.read_text(encoding="utf-8")
        try:
            return load_toml(text)
        except Exception:
            backup = path.with_suffix(path.suffix + ".bak")
            path.rename(backup)
            print(f"[!] Existing TOML at {path} was invalid and has been backed up to {backup}")
    return {}


def write_toml_file(path: Path, data):
    text = dump_toml(data)
    path.write_text(text, encoding="utf-8")


def normalize_type(value):
    if isinstance(value, str):
        return TYPE_MAP.get(value, value)
    return value


def to_list(value):
    if isinstance(value, (list, tuple)):
        return [str(item) for item in value]
    if isinstance(value, str):
        stripped = value.strip()
        return [stripped] if stripped else []
    return []


def merge_command_and_args(command, args):
    command_list = to_list(command)
    if isinstance(args, (list, tuple)):
        arg_list = [str(item) for item in args]
    elif isinstance(args, str):
        arg_list = [args]
    else:
        arg_list = []
    if arg_list:
        if command_list:
            command_list = [*command_list, *arg_list]
        else:
            command_list = arg_list
    return command_list


def migrate_opencode_config(data):
    if not isinstance(data, dict):
        data = {}
    data.setdefault("$schema", "https://opencode.ai/config.json")
    mcp = data.setdefault("mcp", {})

    legacy = data.pop("mcpServers", {})
    if isinstance(legacy, dict):
        for name, legacy_entry in legacy.items():
            if not isinstance(legacy_entry, dict):
                continue
            server_type = normalize_type(legacy_entry.get("type")) or "local"
            new_entry = {"type": server_type}
            enabled = legacy_entry.get("enabled")
            if enabled is not None:
                new_entry["enabled"] = bool(enabled)
            environment = legacy_entry.get("environment") or legacy_entry.get("env")
            if environment:
                new_entry["environment"] = environment
            if server_type == "remote":
                url = legacy_entry.get("url")
                if url:
                    new_entry["url"] = url
                headers = legacy_entry.get("headers")
                if headers:
                    new_entry["headers"] = headers
            else:
                command_list = merge_command_and_args(
                    legacy_entry.get("command"),
                    legacy_entry.get("args"),
                )
                if command_list:
                    new_entry["command"] = command_list
            existing = mcp.setdefault(name, {})
            existing.update(new_entry)

    for name, entry in list(mcp.items()):
        if not isinstance(entry, dict):
            mcp[name] = {}
            continue
        entry["type"] = normalize_type(entry.get("type")) or "local"
        args = entry.pop("args", None)
        if entry["type"] == "local":
            command_list = merge_command_and_args(entry.get("command"), args)
            if command_list:
                entry["command"] = command_list
            elif "command" in entry:
                entry.pop("command", None)
        env_value = entry.pop("env", None)
        if env_value and "environment" not in entry:
            entry["environment"] = env_value
        if entry.get("environment") in ({}, []):
            entry.pop("environment", None)
        if "enabled" in entry:
            entry["enabled"] = bool(entry["enabled"])
        mcp[name] = entry

    return data


source_path = Path(sys.argv[1])
opencode_global_path = Path(sys.argv[2])
opencode_project_path = Path(sys.argv[3])
claude_global_path = Path(sys.argv[4])
codex_global_path = Path(sys.argv[5])
vscode_user_path = Path(sys.argv[6])
vscode_project_path = Path(sys.argv[7])
openrouter_key = sys.argv[8] if len(sys.argv) > 8 else ""
perplexity_key = sys.argv[9] if len(sys.argv) > 9 else ""
perplexity_model = sys.argv[10] if len(sys.argv) > 10 else "sonar"
clear_mcp = sys.argv[11].lower() == "true" if len(sys.argv) > 11 else False
copilot_cli_mcp_path = Path(sys.argv[12]) if len(sys.argv) > 12 else None

servers_text = source_path.read_text(encoding="utf-8")
if openrouter_key:
    servers_text = servers_text.replace("${OPENROUTER_API_KEY}", openrouter_key)
if perplexity_key:
    servers_text = servers_text.replace("${PERPLEXITY_API_KEY}", perplexity_key)
if perplexity_model:
    servers_text = servers_text.replace("${PERPLEXITY_MODEL}", perplexity_model)
servers = json.loads(servers_text)

opencode_global = migrate_opencode_config(load_json(opencode_global_path))
opencode_project = migrate_opencode_config(load_json(opencode_project_path))
claude_global_config = load_json(claude_global_path)
codex_config = load_toml_file(codex_global_path)
vscode_user_config = load_json(vscode_user_path)
vscode_project_config = load_json(vscode_project_path)

# Load existing Copilot CLI MCP config (for merge)
copilot_cli_config = {}
if copilot_cli_mcp_path:
    copilot_cli_config = load_json(copilot_cli_mcp_path)

# Clear existing MCP sections if --clear-mcp flag is set
if clear_mcp:
    print("[Clear MCP] Removing all existing MCP servers before installing new ones")
    opencode_global.pop("mcp", None)
    opencode_project.pop("mcp", None)
    claude_global_config.pop("mcpServers", None)
    codex_config.pop("mcp_servers", None)
    vscode_user_config.pop("mcpServers", None)
    vscode_project_config.pop("mcpServers", None)
    copilot_cli_config.pop("mcpServers", None)

opencode_global_mcp = opencode_global.setdefault("mcp", {})
opencode_project_mcp = opencode_project.setdefault("mcp", {})
claude_global_servers = claude_global_config.setdefault("mcpServers", {})
codex_servers = codex_config.setdefault("mcp_servers", {})
vscode_user_servers = vscode_user_config.setdefault("mcpServers", {})
vscode_project_servers = vscode_project_config.setdefault("mcpServers", {})
copilot_cli_servers = copilot_cli_config.setdefault("mcpServers", {})

for name, config in servers.items():
    if not isinstance(config, dict):
        continue
    # Skip disabled servers (either explicitly disabled or prefixed with underscore)
    if name.startswith("_") or not config.get("enabled", True):
        continue
    server_type = normalize_type(config.get("type")) or "local"
    enabled = bool(config.get("enabled", True))
    environment = config.get("environment") or config.get("env") or {}
    command_list = merge_command_and_args(config.get("command"), config.get("args"))
    url = config.get("url")
    headers = config.get("headers")

    opencode_entry = {"type": server_type, "enabled": enabled}
    if server_type == "remote":
        if url:
            opencode_entry["url"] = url
        if headers:
            opencode_entry["headers"] = headers
    else:
        if command_list:
            opencode_entry["command"] = command_list
    if environment:
        opencode_entry["environment"] = environment

    opencode_global_mcp[name] = dict(opencode_entry)
    opencode_project_mcp[name] = dict(opencode_entry)

    # Claude uses "type" instead of transport, and "stdio" for local
    claude_global_servers[name] = {
        "type": "stdio",
        "command": config.get("command"),
        "args": config.get("args", []),
        "env": environment if isinstance(environment, dict) else {},
    }

    codex_server = {"command": config.get("command"), "args": config.get("args", [])}
    if environment and isinstance(environment, dict):
        codex_server["env"] = environment
    if server_type == "remote":
        if url:
            codex_server["url"] = url
        if headers:
            codex_server["headers"] = headers
    codex_servers[name] = codex_server

    vscode_entry = {
        "command": config.get("command"),
        "args": config.get("args", []),
        "enabled": enabled,
    }
    if environment and isinstance(environment, dict):
        vscode_entry["env"] = environment
    elif environment:
        vscode_entry["env"] = {}
    if server_type == "remote":
        if url:
            vscode_entry["url"] = url
        if headers:
            vscode_entry["headers"] = headers
    vscode_user_servers[name] = dict(vscode_entry)
    vscode_project_servers[name] = dict(vscode_entry)

    # Copilot CLI requires "type": "local" and mandatory "tools": ["*"]
    copilot_cli_entry = {
        "type": "local",  # Copilot CLI uses "local" (not "stdio")
        "command": config.get("command"),
        "args": config.get("args", []),
        "tools": ["*"],  # REQUIRED for Copilot CLI
    }
    if environment and isinstance(environment, dict):
        copilot_cli_entry["env"] = environment
    copilot_cli_servers[name] = copilot_cli_entry

# Always create backups before writing (with ISO timestamps)
create_backup(opencode_global_path)
create_backup(opencode_project_path)
create_backup(claude_global_path)
create_backup(codex_global_path)
create_backup(vscode_user_path)
create_backup(vscode_project_path)
if copilot_cli_mcp_path:
    create_backup(copilot_cli_mcp_path)

# Write updated configurations
write_json(opencode_global_path, opencode_global)
write_json(opencode_project_path, opencode_project)
write_json(claude_global_path, claude_global_config)
write_toml_file(codex_global_path, codex_config)
write_json(vscode_user_path, vscode_user_config)
write_json(vscode_project_path, vscode_project_config)
if copilot_cli_mcp_path:
    write_json(copilot_cli_mcp_path, copilot_cli_config)
    print(f"[✓] Copilot CLI MCP config written: {copilot_cli_mcp_path}")

PYTHON
    return $?
}

main() {
    echo "======================================"
    echo "       MCP Server Setup Script        "
    echo "======================================"
    echo ""

    # Show information about .env file for MCP server configuration
    if [ -f "${REPO_ROOT}/.git/config" ]; then
        # Dev mode
        if [ -f "${REPO_ROOT}/.env" ]; then
            print_status "Environment file found: ${REPO_ROOT}/.env"
        else
            print_status "Tip: Create ${REPO_ROOT}/.env to configure MCP servers (e.g., Perplexity)"
        fi
    else
        # uvx/packaged mode
        if [ -f "${HOME}/.jk-tools.env" ]; then
            print_status "Environment file found: ${HOME}/.jk-tools.env"
        else
            print_status "Tip: Create ~/.jk-tools.env to configure MCP servers (e.g., Perplexity)"
        fi
    fi
    echo ""

    # Sync source files to distribution package (dev mode only).
    # Dev mode = running from a local git checkout.
    # Packaged mode = installed via uvx/pip; nothing to sync.
    if [ -f "${REPO_ROOT}/.git/config" ]; then
        if [ -f "${SYNC_SCRIPT}" ]; then
            print_status "Running comprehensive sync to distribution package..."
            "${SYNC_SCRIPT}"
            echo ""
        else
            print_error "Git repository detected but sync script not found: ${SYNC_SCRIPT}"
            exit 1
        fi
    else
        print_status "Running in packaged mode (sync not needed)"
    fi

    # Ensure the Copilot CLI dir exists (for MCP config write).
    if [ ! -d "${COPILOT_CLI_DIR}" ]; then
        if mkdir_with_retry "${COPILOT_CLI_DIR}"; then
            print_success "Created Copilot CLI directory: ${COPILOT_CLI_DIR}"
        else
            print_error "Could not create Copilot CLI directory: ${COPILOT_CLI_DIR} (continuing)"
        fi
    fi

    echo ""
    print_status "Configuring MCP servers from ${MCP_SOURCE}"
    if generate_mcp_configs "${MCP_SOURCE}" "${VSCODE_USER_CONFIG}" "${VSCODE_PROJECT_CONFIG}"; then
        print_success "MCP server configuration updated"
    else
        print_error "MCP configuration failed - see error above"
        echo ""
        echo "MCP server configuration requires additional setup. Please follow"
        echo "the instructions above."
        echo ""
        exit 1
    fi

    echo ""
    echo "======================================"
    print_success "MCP setup complete!"
    echo ""
    echo "Note: Skills are installed separately. See INSTALL.md for"
    echo "      'npx skills add jakkaj/tools' patterns."
    echo "======================================"
}

main "$@"
