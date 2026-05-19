#!/usr/bin/env bash
# check-skill-slugs.sh — fail if any two skills under skills/<category>/<slug>/
# share the same <slug>. `npx skills` flattens categories on install, so
# slug collisions would cause one skill to silently overwrite another.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"

if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "ERROR: ${SKILLS_DIR} does not exist" >&2
    exit 2
fi

# List every leaf folder name (depth=3: skills/<cat>/<slug>/SKILL.md)
slugs="$(find "${SKILLS_DIR}" -mindepth 3 -maxdepth 3 -name SKILL.md -print 2>/dev/null \
    | awk -F/ '{print $(NF-1)}' | sort)"

if [[ -z "${slugs}" ]]; then
    echo "WARN: no skills found under ${SKILLS_DIR}" >&2
    exit 0
fi

dupes="$(echo "${slugs}" | uniq -d)"

if [[ -n "${dupes}" ]]; then
    echo "ERROR: duplicate skill slugs detected:" >&2
    echo "${dupes}" | sed 's/^/  /' >&2
    exit 1
fi

count="$(echo "${slugs}" | wc -l | tr -d ' ')"
echo "OK: ${count} skills, no slug collisions"
