#!/usr/bin/env bash
# check-skill-frontmatter.sh — validate every skill's SKILL.md frontmatter.
#
# For each skills/<category>/<slug>/SKILL.md it asserts:
#   1. the file opens with a `---` YAML frontmatter block
#   2. `name:` is present and equals the leaf folder <slug>
#      (npx skills flattens by slug; a mismatch installs under the wrong name)
#   3. `description:` is present and non-empty
#      (the description is what an LLM reads to decide whether to invoke a skill)
#   4. the description is within the host budget (default 1024 chars; the same
#      cap scripts/check-flow-architecture.sh enforces on flow-level files)
#
# Exit 0 if every skill passes, 1 if any fail, 2 on a usage/setup error.
#
# SYNOPSIS
#   check-skill-frontmatter.sh [--max-desc N] [skills-dir]
#
# OPTIONS
#   --max-desc N   description character budget (default 1024)
#   skills-dir     root to scan (default: <repo>/skills)
#   -h, --help     show this help

set -euo pipefail

MAX_DESC=1024
SKILLS_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        --max-desc)
            MAX_DESC="${2:?--max-desc needs a value}"; shift 2 ;;
        --max-desc=*)
            MAX_DESC="${1#*=}"; shift ;;
        *)
            SKILLS_DIR="$1"; shift ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${SKILLS_DIR:-${REPO_ROOT}/skills}"

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "ERROR: ${SKILLS_DIR} does not exist" >&2
    exit 2
fi

# Extract the value of a top-level frontmatter key, honouring `|`/`>` block
# scalars. Prints the (whitespace-trimmed) value; empty if absent.
fm_value() {
    local file="$1" key="$2"
    awk -v key="${key}" '
        /^---[[:space:]]*$/ { c++; next }
        c==1 && $0 ~ "^" key ":[[:space:]]*[|>]" { blk=1; next }
        c==1 && blk && /^[^[:space:]]/ { blk=0 }
        c==1 && blk { v = v $0 " "; next }
        c==1 && $0 ~ "^" key ":" { line=$0; sub("^" key ":[[:space:]]*", "", line); v=line }
        c>=2 { exit }
        END { gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); print v }
    ' "${file}"
}

has_frontmatter() {
    head -n 1 "$1" | grep -qx -- '---'
}

errors=0
count=0

while IFS= read -r skill; do
    count=$((count + 1))
    slug="$(basename "$(dirname "${skill}")")"
    rel="${skill#"${REPO_ROOT}/"}"

    if ! has_frontmatter "${skill}"; then
        echo "ERROR: ${rel}: no frontmatter (first line is not '---')" >&2
        errors=$((errors + 1))
        continue
    fi

    name="$(fm_value "${skill}" name)"
    desc="$(fm_value "${skill}" description)"

    if [[ -z "${name}" ]]; then
        echo "ERROR: ${rel}: missing 'name:'" >&2
        errors=$((errors + 1))
    elif [[ "${name}" != "${slug}" ]]; then
        echo "ERROR: ${rel}: name '${name}' != folder slug '${slug}'" >&2
        errors=$((errors + 1))
    fi

    if [[ -z "${desc}" ]]; then
        echo "ERROR: ${rel}: missing or empty 'description:'" >&2
        errors=$((errors + 1))
    elif (( ${#desc} > MAX_DESC )); then
        echo "ERROR: ${rel}: description is ${#desc} chars (limit ${MAX_DESC})" >&2
        errors=$((errors + 1))
    fi
done < <(find "${SKILLS_DIR}" -mindepth 3 -maxdepth 3 -name SKILL.md | sort)

if [[ "${count}" -eq 0 ]]; then
    echo "WARN: no skills found under ${SKILLS_DIR}" >&2
    exit 0
fi

if [[ "${errors}" -gt 0 ]]; then
    echo "FAIL: ${errors} frontmatter problem(s) across ${count} skills" >&2
    exit 1
fi

echo "OK: ${count} skills, frontmatter valid (name matches slug, description <= ${MAX_DESC} chars)"
