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
cp "${REPO_ROOT}/pyproject.toml" "${TMP_WORKSPACE}/"
cp "${REPO_ROOT}/uv.lock" "${TMP_WORKSPACE}/" 2>/dev/null || true

cat > "${TMP_HOME}/.jk-tools.env" <<'ENV'
PERPLEXITY_API_KEY=test-key
ENV

PYTHON_CMD="$(command -v python3)"
if command -v uv >/dev/null 2>&1; then
    PYTHON_CMD="uv run --no-project --with toml --with tomli-w python"
fi

validate_skills_dir() {
    local source_dir="$1"
    local skills_dir="$2"

    python3 - "${source_dir}" "${skills_dir}" <<'PY'
import re
import sys
from pathlib import Path

source_dir = Path(sys.argv[1])
skills_dir = Path(sys.argv[2])
skip_files = {"README.md", "GETTING-STARTED.md", "changes.md", "codebase.md"}

if not skills_dir.is_dir():
    print(f"Missing Copilot CLI skills directory: {skills_dir}")
    sys.exit(1)

expected_count = 0
for source_file in sorted(source_dir.glob("*.md")):
    if source_file.name in skip_files:
        continue

    expected_count += 1
    name = source_file.stem.lower().replace(" ", "-")
    skill_file = skills_dir / name / "SKILL.md"
    if not skill_file.is_file():
        print(f"Missing Copilot CLI skill file: {skill_file}")
        sys.exit(1)

    source_content = source_file.read_text(encoding="utf-8")
    source_body = source_content
    source_fm = re.match(r"^---\s*\n(.*?)\n---\s*\n", source_content, re.DOTALL)
    if source_fm:
        source_body = source_content[source_fm.end():]

    skill_content = skill_file.read_text(encoding="utf-8")
    skill_fm = re.match(r"^---\s*\n(.*?)\n---\s*\n", skill_content, re.DOTALL)
    if not skill_fm:
        print(f"Missing YAML frontmatter in {skill_file}")
        sys.exit(1)

    frontmatter = skill_fm.group(1)
    if f"name: {name}" not in frontmatter:
        print(f"Missing or invalid name frontmatter in {skill_file}")
        sys.exit(1)
    if "description:" not in frontmatter:
        print(f"Missing description frontmatter in {skill_file}")
        sys.exit(1)
    if "tools:" in frontmatter:
        print(f"Unexpected agent-only tools frontmatter in {skill_file}")
        sys.exit(1)
    if skill_content[skill_fm.end():].lstrip() != source_body.lstrip():
        print(f"Skill body does not match stripped source content in {skill_file}")
        sys.exit(1)

actual_count = len(list(skills_dir.glob("*/SKILL.md")))
if actual_count != expected_count:
    print(f"Skill count mismatch for {skills_dir}: expected={expected_count}, actual={actual_count}")
    sys.exit(1)
PY
}

pushd "${TMP_WORKSPACE}" >/dev/null
if ! HOME="${TMP_HOME}" bash ./install/agents.sh --python "${PYTHON_CMD}" >"${TMP_WORKSPACE}/install.log" 2>&1; then
    cat "${TMP_WORKSPACE}/install.log"
    exit 1
fi
popd >/dev/null

COPILOT_GLOBAL_DIR="${TMP_HOME}/.config/github-copilot/prompts"
CLAUDE_DIR="${TMP_HOME}/.claude/commands"
OPENCODE_DIR="${TMP_HOME}/.config/opencode/command"
CODEX_DIR="${TMP_HOME}/.codex/prompts"
VSCODE_PROJECT_DIR="${TMP_WORKSPACE}/.vscode"
SOURCE_DIR="${TMP_WORKSPACE}/agents/v2-commands"
COPILOT_CLI_SKILLS_DIR="${TMP_HOME}/.copilot/skills"

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

if [[ "${status}" -eq 0 ]]; then
    validate_skills_dir "${SOURCE_DIR}" "${COPILOT_CLI_SKILLS_DIR}" || status=1

    for required_skill in plan-1a-v2-explore plan-6-v2-implement-phase validate-v2 harness-v2; do
        if [[ ! -f "${COPILOT_CLI_SKILLS_DIR}/${required_skill}/SKILL.md" ]]; then
            echo "Missing required Copilot CLI skill: ${required_skill}"
            status=1
        fi
    done
fi

if [[ "${status}" -ne 0 ]]; then
    echo "Copilot copy/rename validation failed."
    exit 1
fi

XDG_CONFIG_DIR="${TMP_HOME}/xdg-config"
mkdir -p "${XDG_CONFIG_DIR}"

pushd "${TMP_WORKSPACE}" >/dev/null
if ! HOME="${TMP_HOME}" XDG_CONFIG_HOME="${XDG_CONFIG_DIR}" bash ./install/agents.sh --python "${PYTHON_CMD}" >"${TMP_WORKSPACE}/install-rerun.log" 2>&1; then
    cat "${TMP_WORKSPACE}/install-rerun.log"
    exit 1
fi
popd >/dev/null

validate_skills_dir "${SOURCE_DIR}" "${XDG_CONFIG_DIR}/.copilot/skills"
validate_skills_dir "${SOURCE_DIR}" "${COPILOT_CLI_SKILLS_DIR}"

echo "Copilot directory validation passed."
