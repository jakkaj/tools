#!/usr/bin/env bash

# Install agent commands and MCP server configs for Claude CLI, OpenCode CLI, Codex CLI, and VS Code
# This script also syncs all source files to the distribution package (src/jk_tools/)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
SOURCE_DIR="${REPO_ROOT}/agents/commands"
SYNC_SCRIPT="${REPO_ROOT}/scripts/sync-to-dist.sh"
MCP_SOURCE="${REPO_ROOT}/agents/mcp/servers.json"
ENV_FILE="${REPO_ROOT}/.env"
TARGET_DIR="${HOME}/.claude/commands"
OPENCODE_DIR="${HOME}/.config/opencode/command"
CODEX_DIR="${HOME}/.codex/prompts"
COPILOT_GLOBAL_DIR="${HOME}/.config/github-copilot/prompts"
SYSTEM_NAME="$(uname -s)"

if [[ "${SYSTEM_NAME}" == "Darwin" ]]; then
    VSCODE_USER_DIR="${HOME}/Library/Application Support/Code/User"
else
    VSCODE_USER_DIR="${HOME}/.config/Code/User"
fi
VSCODE_USER_CONFIG="${VSCODE_USER_DIR}/mcp.json"
VSCODE_PROJECT_DIR="${REPO_ROOT}/.vscode"
VSCODE_PROJECT_CONFIG="${VSCODE_PROJECT_DIR}/mcp.json"

print_status() {
    echo "[*] $1"
}

print_success() {
    echo "[✓] $1"
}

print_error() {
    echo "[✗] $1" >&2
}

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
    if [ -f "${ENV_FILE}" ]; then
        source "${ENV_FILE}"
        openrouter_key="${MCP_LLM_OPENROUTER_API_KEY}"
    fi

    local opencode_global="${HOME}/.config/opencode/opencode.json"
    local opencode_project="${REPO_ROOT}/opencode.json"
    local claude_project="${REPO_ROOT}/.mcp.json"
    local codex_global="${HOME}/.codex/config.toml"

    mkdir -p "${HOME}/.config/opencode"
    mkdir -p "${HOME}/.codex"
    mkdir -p "$(dirname "${vscode_user_config}")"
    mkdir -p "$(dirname "${vscode_project_config}")"

    python3 - "$mcp_source" "$opencode_global" "$opencode_project" "$claude_project" "$codex_global" "$vscode_user_config" "$vscode_project_config" "$openrouter_key" <<'PYTHON'
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
claude_project_path = Path(sys.argv[4])
codex_global_path = Path(sys.argv[5])
vscode_user_path = Path(sys.argv[6])
vscode_project_path = Path(sys.argv[7])
openrouter_key = sys.argv[8] if len(sys.argv) > 8 else ""

servers_text = source_path.read_text(encoding="utf-8")
if openrouter_key:
    servers_text = servers_text.replace("${OPENROUTER_API_KEY}", openrouter_key)
servers = json.loads(servers_text)

opencode_global = migrate_opencode_config(load_json(opencode_global_path))
opencode_project = migrate_opencode_config(load_json(opencode_project_path))
claude_config = load_json(claude_project_path)
codex_config = load_toml_file(codex_global_path)
vscode_user_config = load_json(vscode_user_path)
vscode_project_config = load_json(vscode_project_path)

opencode_global_mcp = opencode_global.setdefault("mcp", {})
opencode_project_mcp = opencode_project.setdefault("mcp", {})
claude_servers = claude_config.setdefault("mcpServers", {})
codex_servers = codex_config.setdefault("mcp_servers", {})
vscode_user_servers = vscode_user_config.setdefault("mcpServers", {})
vscode_project_servers = vscode_project_config.setdefault("mcpServers", {})

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

    claude_servers[name] = {
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

write_json(opencode_global_path, opencode_global)
write_json(opencode_project_path, opencode_project)
write_json(claude_project_path, claude_config)
write_toml_file(codex_global_path, codex_config)
write_json(vscode_user_path, vscode_user_config)
write_json(vscode_project_path, vscode_project_config)

PYTHON
    return $?
}

main() {
    echo "======================================"
    echo "     Agent Commands Setup Script      "
    echo "======================================"
    echo ""

    # Sync all source files to distribution package (only in dev mode)
    # Dev mode = running from local git repository
    # Packaged mode = installed via uvx/pip (sync not needed, already packaged)
    if [ -f "${REPO_ROOT}/.git/config" ] && [ -f "${SYNC_SCRIPT}" ]; then
        # Dev mode: running from local git repository with sync script
        print_status "Running comprehensive sync to distribution package..."
        "${SYNC_SCRIPT}"
        echo ""
    elif [ ! -f "${SYNC_SCRIPT}" ]; then
        # Packaged mode: installed via uvx/pip, sync script not present (expected)
        print_status "Running in packaged mode (sync not needed)"
    else
        # Unexpected state: sync script exists but not in git repository
        print_error "Sync script found but not in git repository: ${SYNC_SCRIPT}"
        exit 1
    fi

    print_status "Copilot global directory target: ${COPILOT_GLOBAL_DIR}"

    # Check if source directory exists
    if [ ! -d "${SOURCE_DIR}" ]; then
        print_error "Source directory not found: ${SOURCE_DIR}"
        exit 1
    fi
    echo ""

    # Create target directories if they don't exist
    if [ ! -d "${TARGET_DIR}" ]; then
        mkdir -p "${TARGET_DIR}"
        print_success "Created directory: ${TARGET_DIR}"
    else
        print_status "Target directory already exists: ${TARGET_DIR}"
    fi

    if [ ! -d "${OPENCODE_DIR}" ]; then
        mkdir -p "${OPENCODE_DIR}"
        print_success "Created directory: ${OPENCODE_DIR}"
    else
        print_status "OpenCode directory already exists: ${OPENCODE_DIR}"
    fi

    if [ ! -d "${CODEX_DIR}" ]; then
        mkdir -p "${CODEX_DIR}"
        print_success "Created directory: ${CODEX_DIR}"
    else
        print_status "Codex directory already exists: ${CODEX_DIR}"
    fi

    if [ ! -d "${VSCODE_USER_DIR}" ]; then
        mkdir -p "${VSCODE_USER_DIR}"
        print_success "Created VS Code user directory: ${VSCODE_USER_DIR}"
    else
        print_status "VS Code user directory already exists: ${VSCODE_USER_DIR}"
    fi

    if [ ! -d "${VSCODE_PROJECT_DIR}" ]; then
        mkdir -p "${VSCODE_PROJECT_DIR}"
        print_success "Created VS Code project directory: ${VSCODE_PROJECT_DIR}"
    else
        print_status "VS Code project directory already exists: ${VSCODE_PROJECT_DIR}"
    fi

    if [ ! -d "${COPILOT_GLOBAL_DIR}" ]; then
        if mkdir -p "${COPILOT_GLOBAL_DIR}"; then
            print_success "Created Copilot global directory: ${COPILOT_GLOBAL_DIR}"
        else
            print_error "Could not create Copilot global directory: ${COPILOT_GLOBAL_DIR} (continuing)"
        fi
    else
        print_status "Copilot global directory already exists: ${COPILOT_GLOBAL_DIR}"
    fi

    
    # Count files to copy
    file_count=$(find "${SOURCE_DIR}" -maxdepth 1 -name "*.md" -type f | wc -l | tr -d ' ')

    if [ "${file_count}" -eq 0 ]; then
        print_error "No .md files found in ${SOURCE_DIR}"
        exit 1
    fi

    print_status "Found ${file_count} command file(s) to copy"
    echo ""
    
    for file in "${SOURCE_DIR}"/*.md; do
        if [ -f "${file}" ]; then
            filename=$(basename "${file}")
            target_file="${TARGET_DIR}/${filename}"
            opencode_file="${OPENCODE_DIR}/${filename}"
            codex_file="${CODEX_DIR}/${filename}"
            vscode_project_file="${VSCODE_PROJECT_DIR}/${filename}"
            copilot_prompt_name="${filename%.md}.prompt.md"
            copilot_global_file="${COPILOT_GLOBAL_DIR}/${copilot_prompt_name}"

            # Copy to destinations
            cp "${file}" "${target_file}"
            cp "${file}" "${opencode_file}"
            cp "${file}" "${codex_file}"
            cp "${file}" "${vscode_project_file}"
            cp "${file}" "${copilot_global_file}"
            echo "  [↻] ${filename} (updated Claude/OpenCode/Codex/VS Code)"
            echo "  [↻ Copilot] ${filename} -> ${copilot_prompt_name}"
        fi
    done

    # Idempotency: installer overwrites prompt copies on each run (validated by tests/install/test_complete_flow.sh).
    copilot_global_count=$(find "${COPILOT_GLOBAL_DIR}" -maxdepth 1 -type f -name "*.prompt.md" | wc -l | tr -d ' ')
    if [ "${copilot_global_count}" -eq "${file_count}" ]; then
        echo "[✓ Idempotent] Copilot prompts mirrored (${copilot_global_count} of ${file_count} sources)"
    else
        print_error "[Idempotent] Copilot prompt count mismatch (sources=${file_count}, global=${copilot_global_count})"
    fi

    echo ""
    print_status "Configuring MCP servers from ${MCP_SOURCE}"
    if generate_mcp_configs "${MCP_SOURCE}" "${VSCODE_USER_CONFIG}" "${VSCODE_PROJECT_CONFIG}"; then
        print_success "MCP server configuration updated"
    else
        print_status "MCP configuration skipped"
    fi
    
    echo ""
    echo "======================================"
    print_success "Setup complete!"
    echo ""
    echo "Copied ${file_count} agent command file(s) to:"
    echo "  ${TARGET_DIR}"
    echo "  ${OPENCODE_DIR}"
    echo "  ${CODEX_DIR}"
    echo "  ${VSCODE_PROJECT_DIR}"
    echo "======================================"
}

main "$@"
