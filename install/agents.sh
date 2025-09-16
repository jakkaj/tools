#!/usr/bin/env bash

# Install agent commands and MCP server configs for Claude CLI, OpenCode CLI, and Codex CLI

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
SOURCE_DIR="${REPO_ROOT}/agents/commands"
MCP_SOURCE="${REPO_ROOT}/agents/mcp/servers.json"
TARGET_DIR="${HOME}/.claude/commands"
OPENCODE_DIR="${HOME}/.config/opencode/command"
CODEX_DIR="${HOME}/.codex/prompts"

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

    if [ ! -f "${mcp_source}" ]; then
        print_status "No MCP configuration source found at ${mcp_source}, skipping MCP setup"
        return 1
    fi

    local opencode_global="${HOME}/.config/opencode/opencode.json"
    local opencode_project="${REPO_ROOT}/opencode.json"
    local claude_project="${REPO_ROOT}/.mcp.json"
    local codex_global="${HOME}/.codex/config.toml"

    mkdir -p "${HOME}/.config/opencode"
    mkdir -p "${HOME}/.codex"

    python3 - "$mcp_source" "$opencode_global" "$opencode_project" "$claude_project" "$codex_global" <<'PYTHON'
import json
import os
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


def dump_toml(data):
    if toml is not None:
        return toml.dumps(data)
    return tomli_w.dumps(data)


def load_json(path):
    if path.exists():
        try:
            with path.open("r", encoding="utf-8") as fh:
                return json.load(fh)
        except json.JSONDecodeError:
            backup = path.with_suffix(path.suffix + ".bak")
            path.rename(backup)
            print(f"[!] Existing JSON at {path} was invalid and has been backed up to {backup}")
    return {}


def write_json(path, data):
    with path.open("w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")


def load_toml_file(path):
    if path.exists():
        text = path.read_text(encoding="utf-8")
        try:
            return load_toml(text)
        except Exception:
            backup = path.with_suffix(path.suffix + ".bak")
            path.rename(backup)
            print(f"[!] Existing TOML at {path} was invalid and has been backed up to {backup}")
    return {}


def write_toml_file(path, data):
    text = dump_toml(data)
    path.write_text(text, encoding="utf-8")


source_path = Path(sys.argv[1])
opencode_global_path = Path(sys.argv[2])
opencode_project_path = Path(sys.argv[3])
claude_project_path = Path(sys.argv[4])
codex_global_path = Path(sys.argv[5])

servers = json.loads(source_path.read_text(encoding="utf-8"))

for name, config in servers.items():
    command = config["command"]
    args = config.get("args", [])
    env = config.get("env", {})
    enabled = config.get("enabled", True)
    server_type = config.get("type", "local")

    # OpenCode global
    opencode_global = load_json(opencode_global_path)
    opencode_global.setdefault("$schema", "https://opencode.ai/config.json")
    opencode_global.setdefault("mcp", {})[name] = {
        "type": server_type,
        "command": [command, *args],
        "enabled": bool(enabled)
    }
    write_json(opencode_global_path, opencode_global)

    # OpenCode project
    opencode_project = load_json(opencode_project_path)
    opencode_project.setdefault("$schema", "https://opencode.ai/config.json")
    opencode_project.setdefault("mcp", {})[name] = {
        "type": server_type,
        "command": [command, *args],
        "enabled": bool(enabled)
    }
    write_json(opencode_project_path, opencode_project)

    # Claude project
    claude_config = load_json(claude_project_path)
    claude_config.setdefault("mcpServers", {})[name] = {
        "command": command,
        "args": args,
        "env": env
    }
    write_json(claude_project_path, claude_config)

    # Codex global
    codex_config = load_toml_file(codex_global_path)
    codex_servers = codex_config.setdefault("mcp_servers", {})
    codex_server = {"command": command, "args": args}
    if env:
        codex_server["env"] = env
    codex_servers[name] = codex_server
    write_toml_file(codex_global_path, codex_config)

PYTHON
    return $?
}

main() {
    echo "======================================"
    echo "     Agent Commands Setup Script      "
    echo "======================================"
    echo ""
    
    # Check if source directory exists
    if [ ! -d "${SOURCE_DIR}" ]; then
        print_error "Source directory not found: ${SOURCE_DIR}"
        exit 1
    fi
    
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

            # Copy to all three directories
            cp "${file}" "${target_file}"
            cp "${file}" "${opencode_file}"
            cp "${file}" "${codex_file}"
            echo "  [↻] ${filename} (copied to all locations)"
        fi
    done

    echo ""
    print_status "Configuring MCP servers from ${MCP_SOURCE}"
    if generate_mcp_configs "${MCP_SOURCE}"; then
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
    echo "======================================"
}

main "$@"
