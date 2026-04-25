#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ghcp-idempotent-home.XXXXXX")"
TMP_WORKSPACE="$(mktemp -d "${TMPDIR:-/tmp}/ghcp-idempotent-workspace.XXXXXX")"

cleanup() {
    rm -rf "${TMP_HOME}" "${TMP_WORKSPACE}"
}
trap cleanup EXIT

cp -R "${REPO_ROOT}/install" "${TMP_WORKSPACE}/"
cp -R "${REPO_ROOT}/agents" "${TMP_WORKSPACE}/"
cp "${REPO_ROOT}/pyproject.toml" "${TMP_WORKSPACE}/"
cp "${REPO_ROOT}/uv.lock" "${TMP_WORKSPACE}/" 2>/dev/null || true

cat > "${TMP_HOME}/.jk-tools.env" <<'ENV'
PERPLEXITY_API_KEY=test-key
ENV

PYTHON_CMD="$(command -v python3)"
if command -v uv >/dev/null 2>&1; then
    PYTHON_CMD="uv run --no-project --with toml --with tomli-w python"
fi

pushd "${TMP_WORKSPACE}" >/dev/null

FIRST_RUN_LOG="${TMP_WORKSPACE}/install-first.log"
SECOND_RUN_LOG="${TMP_WORKSPACE}/install-second.log"

if ! HOME="${TMP_HOME}" bash ./install/agents.sh --python "${PYTHON_CMD}" >"${FIRST_RUN_LOG}" 2>&1; then
    cat "${FIRST_RUN_LOG}"
    exit 1
fi

if ! HOME="${TMP_HOME}" bash ./install/agents.sh --python "${PYTHON_CMD}" >"${SECOND_RUN_LOG}" 2>&1; then
    cat "${SECOND_RUN_LOG}"
    exit 1
fi

popd >/dev/null

SOURCE_DIR="${TMP_WORKSPACE}/agents/v2-commands"
COPILOT_GLOBAL_DIR="${TMP_HOME}/.config/github-copilot/prompts"
COPILOT_CLI_SKILLS_DIR="${TMP_HOME}/.copilot/skills"

source_count=$(find "${SOURCE_DIR}" -maxdepth 1 -type f -name "*.md" | wc -l | tr -d ' ')
skill_source_count=$(find "${SOURCE_DIR}" -maxdepth 1 -type f -name "*.md" \
    ! -name "README.md" \
    ! -name "GETTING-STARTED.md" \
    ! -name "changes.md" \
    ! -name "codebase.md" | wc -l | tr -d ' ')
global_prompt_count=0
skill_count=0
workspace_prompt_count=0

if [[ -d "${COPILOT_GLOBAL_DIR}" ]]; then
    global_prompt_count=$(find "${COPILOT_GLOBAL_DIR}" -maxdepth 1 -type f -name "*.prompt.md" | wc -l | tr -d ' ')
else
    echo "Missing Copilot global directory after installer runs: ${COPILOT_GLOBAL_DIR}"
    exit 1
fi

if [[ "${source_count}" -ne "${global_prompt_count}" ]]; then
    echo "Global prompt count mismatch: sources=${source_count}, prompts=${global_prompt_count}"
    exit 1
fi

if [[ -d "${COPILOT_CLI_SKILLS_DIR}" ]]; then
    skill_count=$(find "${COPILOT_CLI_SKILLS_DIR}" -mindepth 2 -maxdepth 2 -type f -name "SKILL.md" | wc -l | tr -d ' ')
else
    echo "Missing Copilot CLI skills directory after installer runs: ${COPILOT_CLI_SKILLS_DIR}"
    exit 1
fi

if [[ "${skill_source_count}" -ne "${skill_count}" ]]; then
    echo "Copilot CLI skill count mismatch: sources=${skill_source_count}, skills=${skill_count}"
    exit 1
fi

if ! grep -q "\[✓ Idempotent\]" "${SECOND_RUN_LOG}"; then
    echo "Missing idempotency summary indicator in second run output."
    echo "--- Second run log ---"
    cat "${SECOND_RUN_LOG}"
    echo "----------------------"
    exit 1
fi

echo "Idempotency smoke test passed."
