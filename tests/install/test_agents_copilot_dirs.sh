#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ghcp-home.XXXXXX")"
TMP_WORKSPACE="$(mktemp -d "${TMPDIR:-/tmp}/ghcp-workspace.XXXXXX")"

cleanup() {
    rm -rf "${TMP_HOME}" "${TMP_WORKSPACE}"
}
trap cleanup EXIT

cp -R "${REPO_ROOT}/install" "${TMP_WORKSPACE}/"
cp -R "${REPO_ROOT}/agents" "${TMP_WORKSPACE}/"

pushd "${TMP_WORKSPACE}" >/dev/null
if ! HOME="${TMP_HOME}" bash ./install/agents.sh >"${TMP_WORKSPACE}/install.log" 2>&1; then
    cat "${TMP_WORKSPACE}/install.log"
    exit 1
fi
popd >/dev/null

COPILOT_GLOBAL_DIR="${TMP_HOME}/.config/github-copilot/prompts"
CLAUDE_DIR="${TMP_HOME}/.claude/commands"
OPENCODE_DIR="${TMP_HOME}/.config/opencode/command"
CODEX_DIR="${TMP_HOME}/.codex/prompts"
VSCODE_PROJECT_DIR="${TMP_WORKSPACE}/.vscode"
SOURCE_DIR="${TMP_WORKSPACE}/agents/commands"

status=0

if [[ ! -d "${COPILOT_GLOBAL_DIR}" ]]; then
    echo "Missing Copilot global directory: ${COPILOT_GLOBAL_DIR}"
    status=1
fi

if [[ "${status}" -eq 0 ]]; then
    for source_file in "${SOURCE_DIR}"/*.md; do
        [[ -f "${source_file}" ]] || continue
        filename=$(basename "${source_file}")
        stem="${filename%.md}"

        global_prompt="${COPILOT_GLOBAL_DIR}/${stem}.prompt.md"
        claude_copy="${CLAUDE_DIR}/${filename}"
        opencode_copy="${OPENCODE_DIR}/${filename}"
        codex_copy="${CODEX_DIR}/${filename}"
        vscode_copy="${VSCODE_PROJECT_DIR}/${filename}"

        if [[ ! -f "${global_prompt}" ]]; then
            echo "Missing Copilot global prompt copy: ${global_prompt}"
            status=1
        fi

        if [[ ! -f "${claude_copy}" ]]; then
            echo "Missing Claude copy: ${claude_copy}"
            status=1
        fi

        if [[ ! -f "${opencode_copy}" ]]; then
            echo "Missing OpenCode copy: ${opencode_copy}"
            status=1
        fi

        if [[ ! -f "${codex_copy}" ]]; then
            echo "Missing Codex copy: ${codex_copy}"
            status=1
        fi

        if [[ ! -f "${vscode_copy}" ]]; then
            echo "Missing VS Code project copy: ${vscode_copy}"
            status=1
        fi
    done

    if [[ -d "${COPILOT_GLOBAL_DIR}" ]]; then
        source_count=$(find "${SOURCE_DIR}" -maxdepth 1 -type f -name "*.md" | wc -l | tr -d ' ')
        prompt_count=$(find "${COPILOT_GLOBAL_DIR}" -maxdepth 1 -type f -name "*.prompt.md" | wc -l | tr -d ' ')
        if [[ "${source_count}" -ne "${prompt_count}" ]]; then
            echo "Mismatch between source files (${source_count}) and Copilot global prompts (${prompt_count})"
            status=1
        fi
    fi

fi

if [[ "${status}" -ne 0 ]]; then
    echo "Copilot copy/rename validation failed."
    exit 1
fi

pushd "${TMP_WORKSPACE}" >/dev/null
if ! HOME="${TMP_HOME}" bash ./install/agents.sh >"${TMP_WORKSPACE}/install-rerun.log" 2>&1; then
    cat "${TMP_WORKSPACE}/install-rerun.log"
    exit 1
fi
popd >/dev/null

echo "Copilot directory validation passed."
