#!/usr/bin/env bash
# check-flow-architecture.sh — lint a composable flow skill against the
# flow-architecture pattern (docs/skills-pipeline/flow-architecture.md).
#
# NAME
#   check-flow-architecture.sh — deterministic lints for flow skills
#
# SYNOPSIS
#   check-flow-architecture.sh [flow-dir]
#   check-flow-architecture.sh --help
#
# DESCRIPTION
#   Runs lints L1–L6 from the flow-architecture pattern:
#     L1  sub-skill leakage (flow commands / stage refs / sibling paths /
#         next-routing markers inside sub-skills)            — ERROR
#     L2  contract block + constant Exit line per sub-skill  — ERROR
#     L3  grammar conformance in flow-level files            — WARN until the
#         Registry table parses, then ERROR
#     L4  closure (Graph edges resolve in Registry; Registry
#         modules exist on disk)                             — WARN until the
#         Registry/Graph tables parse, then ERROR
#     L5  rendered views carry a first-line banner           — ERROR when views
#         exist; WARN-skip when the flow declares none
#     L6  frontmatter parses; description <= 1024 chars      — ERROR; files
#         without frontmatter are skipped (stubs)
#
#   The flow's command token is DERIVED per flow: first backticked /token in
#   the `## Command grammar` section, falling back to the flow directory name.
#   Nothing is hardcoded to any one flow.
#
# PARAMETERS
#   flow-dir   Path to the flow skill directory (default: skills/SDD/the-flow).
#              Resolved as given, then relative to the repo root.
#
# EXIT STATUS
#   0  clean (warnings allowed)   1  one or more ERRORs   2  usage/environment
#
# EXAMPLES
#   check-flow-architecture.sh                          # lint the-flow
#   check-flow-architecture.sh skills/SDD/my-flow       # lint another flow
#   check-flow-architecture.sh scratch/mini-flow-test/triage

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
fi

FLOW_DIR_ARG="${1:-skills/SDD/the-flow}"
if [[ -d "${FLOW_DIR_ARG}" ]]; then
    FLOW_DIR="$(cd "${FLOW_DIR_ARG}" && pwd)"
elif [[ -d "${REPO_ROOT}/${FLOW_DIR_ARG}" ]]; then
    FLOW_DIR="${REPO_ROOT}/${FLOW_DIR_ARG}"
else
    echo "ERROR: flow dir not found: ${FLOW_DIR_ARG}" >&2
    exit 2
fi

errors=0
warns=0
err()  { echo "ERROR: $*"; errors=$((errors + 1)); }
warn() { echo "WARN: $*";  warns=$((warns + 1)); }
ok()   { echo "OK: $*"; }

# ── discovery ────────────────────────────────────────────────────────────────

# Sub-skills: references/stages/ or stages/
SUB_DIR=""
[[ -d "${FLOW_DIR}/stages" ]] && SUB_DIR="${FLOW_DIR}/stages"
[[ -d "${FLOW_DIR}/references/stages" ]] && SUB_DIR="${FLOW_DIR}/references/stages"

SUB_FILES=()
if [[ -n "${SUB_DIR}" ]]; then
    while IFS= read -r f; do SUB_FILES+=("$f"); done \
        < <(find "${SUB_DIR}" -maxdepth 1 -name '*.md' | sort)
fi

# Flow-level files: *.md at the flow root and references/ root (not stages/)
FLOW_FILES=()
while IFS= read -r f; do FLOW_FILES+=("$f"); done \
    < <(find "${FLOW_DIR}" -maxdepth 1 -name '*.md' | sort;
        [[ -d "${FLOW_DIR}/references" ]] && find "${FLOW_DIR}/references" -maxdepth 1 -name '*.md' | sort)

is_banner_marked() {  # view files: first line carries a regeneration banner
    head -n 1 "$1" | grep -qiE '<!--.*(GENERATED|RENDERED|🔄)' 2>/dev/null
}

# Extract a `## <Heading>` section body (fence-aware), stdin = file
section_body() {  # $1 file, $2 heading regex (without ^## )
    awk -v h="$2" '
        /^```/ { code = !code }
        code   { next }
        $0 ~ ("^## " h "[[:space:]]*$") { insec = 1; next }
        insec && /^## /                 { insec = 0 }
        insec                           { print }
    ' "$1"
}

# Find the (non-view) flow-level file owning a `## <Heading>` section
find_master() {  # $1 heading regex
    local f
    for f in "${FLOW_FILES[@]}"; do
        is_banner_marked "$f" && continue
        if awk -v h="$1" '
            /^```/ { code = !code }
            code   { next }
            $0 ~ ("^## " h "[[:space:]]*$") { found = 1; exit }
            END { exit !found }
        ' "$f"; then
            echo "$f"
            return 0
        fi
    done
    return 1
}

# ── flow token ───────────────────────────────────────────────────────────────

FLOW_TOKEN=""
GRAMMAR_FILE="$(find_master 'Command grammar' || true)"
if [[ -n "${GRAMMAR_FILE}" ]]; then
    FLOW_TOKEN="$(section_body "${GRAMMAR_FILE}" 'Command grammar' \
        | grep -oE '`/[a-z][a-z0-9_-]+' | head -n 1 | sed 's|^`/||' || true)"
fi
if [[ -z "${FLOW_TOKEN}" ]]; then
    FLOW_TOKEN="$(basename "${FLOW_DIR}")"
    warn "no \`## Command grammar\` section with a backticked /token — flow token falls back to dir name: /${FLOW_TOKEN}"
else
    ok "flow token derived from ${GRAMMAR_FILE#${FLOW_DIR}/}: /${FLOW_TOKEN}"
fi

# ── L1: sub-skill leakage ────────────────────────────────────────────────────

if [[ ${#SUB_FILES[@]} -eq 0 ]]; then
    warn "L1/L2: no sub-skills found under ${FLOW_DIR} (expected stages/ or references/stages/)"
else
    l1_total=0
    for f in "${SUB_FILES[@]}"; do
        hits="$( { grep -nE "/${FLOW_TOKEN} [0-9]|references/stages/[0-9A-Za-z]|(^|[^/a-z])stages/[0-9A-Za-z][^[:space:]]*\.md" "$f" || true; \
                   grep -inE 'stage [0-9]+[a-z]?|\*\*next (routing|steps?)\*\*|^#{1,6} next (routing|steps?)\b|^next steps?\b' "$f" || true; } \
                | grep -vE '^[0-9]+:\*\*Delegates\*\*' | cut -d: -f1 | sort -nu || true)"
        count=0
        [[ -n "${hits}" ]] && count="$(echo "${hits}" | wc -l | tr -d ' ')"
        if [[ "${count}" -gt 0 ]]; then
            err "L1: $(basename "$f") leaks flow knowledge on ${count} line(s): $(echo "${hits}" | tr '\n' ',' | sed 's/,$//;s/,/, /g')"
            l1_total=$((l1_total + count))
        fi
    done
    if [[ ${l1_total} -eq 0 ]]; then
        ok "L1: 0 leak lines across ${#SUB_FILES[@]} sub-skill(s)"
    else
        echo "ERROR: L1 total: ${l1_total} leak line(s) across sub-skills"
    fi
fi

# ── L2: contract block + constant Exit line ──────────────────────────────────

EXIT_LINE="Routing is the flow's job — run the parent flow bare to continue."
if [[ ${#SUB_FILES[@]} -gt 0 ]]; then
    l2_bad=0
    for f in "${SUB_FILES[@]}"; do
        missing=()
        for field in '**Verb**' '**Purpose**' '**Consumes**' '**Flags**' '**Produces**' '**Side effects**'; do
            grep -qF "${field}" "$f" || missing+=("${field}")
        done
        grep -qF "${EXIT_LINE}" "$f" || missing+=('<Exit line>')
        if [[ ${#missing[@]} -gt 0 ]]; then
            err "L2: $(basename "$f") missing: ${missing[*]}"
            l2_bad=$((l2_bad + 1))
        fi
    done
    [[ ${l2_bad} -eq 0 ]] && ok "L2: contract block + Exit line present in ${#SUB_FILES[@]}/${#SUB_FILES[@]} sub-skills"
fi

# ── Registry / Graph parsing (for L3/L4 hardening per the pattern doc) ───────

REGISTRY_FILE="$(find_master 'Registry' || true)"
REGISTRY_PARSED=0
REG_IDS=""; REG_VERBS=""; REG_MODULES=""
if [[ -n "${REGISTRY_FILE}" ]]; then
    reg_rows="$(section_body "${REGISTRY_FILE}" 'Registry' \
        | grep -E '^\|' | grep -vE '^\|[[:space:]]*-+' | grep -viE '^\|[[:space:]]*id[[:space:]]*\|' || true)"
    if [[ -n "${reg_rows}" ]]; then
        REGISTRY_PARSED=1
        REG_IDS="$(echo "${reg_rows}"     | awk -F'|' '{gsub(/[[:space:]`]/,"",$2); print $2}')"
        REG_VERBS="$(echo "${reg_rows}"   | awk -F'|' '{gsub(/[[:space:]`]/,"",$3); print $3}')"
        REG_MODULES="$(echo "${reg_rows}" | awk -F'|' '{gsub(/[[:space:]`]/,"",$4); print $4}')"
        ok "Registry parsed (${REGISTRY_FILE#${FLOW_DIR}/}): $(echo "${REG_IDS}" | wc -l | tr -d ' ') row(s)"
    fi
fi

GRAPH_FILE="$(find_master 'Graph' || true)"
GRAPH_PARSED=0
GRAPH_EDGE_VERBS=""
if [[ -n "${GRAPH_FILE}" ]]; then
    graph_rows="$(section_body "${GRAPH_FILE}" 'Graph' \
        | grep -E '^\|' | grep -vE '^\|[[:space:]]*-+' | grep -viE '^\|[[:space:]]*state[[:space:]]*\|' || true)"
    graph_header="$(section_body "${GRAPH_FILE}" 'Graph' | grep -iE '^\|[[:space:]]*state[[:space:]]*\|' | head -n 1 || true)"
    if [[ -n "${graph_rows}" && -n "${graph_header}" ]]; then
        edge_col="$(echo "${graph_header}" | awk -F'|' '{for (i=2; i<=NF; i++) { c=tolower($i); if (c ~ /edge/) { print i; exit } }}')"
        if [[ -n "${edge_col}" ]]; then
            GRAPH_PARSED=1
            GRAPH_EDGE_VERBS="$(echo "${graph_rows}" | awk -F'|' -v c="${edge_col}" '{print $c}' \
                | grep -oE '\*\*[a-z][a-z0-9_-]*\*\*' | sed 's/\*\*//g' | sort -u || true)"
            ok "Graph parsed (${GRAPH_FILE#${FLOW_DIR}/}): $(echo "${graph_rows}" | wc -l | tr -d ' ') state row(s)"
        fi
    fi
fi

# ── L3: grammar conformance in flow-level files ──────────────────────────────

l3_violation() {
    if [[ ${REGISTRY_PARSED} -eq 1 ]]; then err "L3: $*"; else warn "L3 (warn-mode — Registry not yet parsed): $*"; fi
}

l3_count=0
for f in "${FLOW_FILES[@]}"; do
    rel="${f#${FLOW_DIR}/}"
    # Build the set of exempt line numbers: the Command grammar section and any
    # section explicitly preceded by <!-- lint:allow-flow-commands -->.
    exempt_lines="$(awk '
        /^```/   { code = !code }
        !code && /^<!-- lint:allow-flow-commands -->/ { pend = 1; next }
        !code && /^#/ { insec = 0
                        if (pend || $0 ~ /^## Command grammar[[:space:]]*$/) { insec = 1 }
                        pend = 0 }
        insec    { print NR }
    ' "$f")"
    # Catch both id-led (/flow 6 implement) and verb-led (/flow implement) literals.
    matches="$(grep -noE "/${FLOW_TOKEN} ([0-9][0-9a-z]*|[a-z][a-z0-9_-]*)( [a-z][a-z0-9_-]*)?" "$f" || true)"
    [[ -z "${matches}" ]] && continue
    banner=0; is_banner_marked "$f" && banner=1
    while IFS= read -r m; do
        ln="${m%%:*}"; cmd="${m#*:}"
        echo "${exempt_lines}" | grep -qx "${ln}" && continue
        cid="$(echo "${cmd}" | awk '{print $2}')"
        cverb="$(echo "${cmd}" | awk '{print $3}')"
        if [[ ! "${cid}" =~ ^[0-9] ]]; then
            # Verb-led candidate. Only a command literal if the token is a real
            # Registry verb — otherwise it's prose ("… /the-flow and …"). Needs
            # the Registry, so this check is silent in warn-mode (D-C).
            if [[ ${REGISTRY_PARSED} -eq 1 ]] && echo "${REG_VERBS}" | grep -qx "${cid}"; then
                l3_violation "${rel}:${ln} literal \`${cmd}\` is verb-led — printed form must carry the Registry id first"
                l3_count=$((l3_count + 1))
            fi
            continue
        fi
        if [[ ${banner} -eq 1 ]]; then
            # Views may carry literals, but the printed form must be id+verb
            # and the pair must exist in the Registry.
            if [[ ${REGISTRY_PARSED} -eq 1 ]]; then
                row_verb="$(paste -d' ' <(echo "${REG_IDS}") <(echo "${REG_VERBS}") | awk -v id="${cid}" '$1 == id {print $2}')"
                if [[ -z "${row_verb}" ]]; then
                    l3_violation "${rel}:${ln} view literal \`${cmd}\` — id \`${cid}\` not in Registry"
                    l3_count=$((l3_count + 1))
                elif [[ -z "${cverb}" ]]; then
                    l3_violation "${rel}:${ln} view literal \`${cmd}\` is missing the Registry verb (printed form carries both)"
                    l3_count=$((l3_count + 1))
                elif [[ "${cverb}" != "${row_verb}" ]]; then
                    l3_violation "${rel}:${ln} view literal \`${cmd}\` — verb \`${cverb}\` mismatches Registry (\`${row_verb}\`)"
                    l3_count=$((l3_count + 1))
                fi
            fi
        else
            l3_violation "${rel}:${ln} literal flow command \`${cmd}\` outside the Command grammar section"
            l3_count=$((l3_count + 1))
        fi
    done <<< "${matches}"
done
[[ ${l3_count} -eq 0 ]] && ok "L3: no unauthorized flow-command literals in flow-level files"

# ── L4: closure ──────────────────────────────────────────────────────────────

if [[ ${REGISTRY_PARSED} -eq 0 ]]; then
    warn "L4 (warn-mode): no parseable \`## Registry\` table — closure checks skipped"
else
    l4_bad=0
    while IFS= read -r mod; do
        [[ -z "${mod}" || "${mod}" == "—" || "${mod}" == "-" ]] && continue
        if [[ ! -f "${FLOW_DIR}/${mod}" ]]; then
            err "L4: Registry module does not exist on disk: ${mod}"
            l4_bad=$((l4_bad + 1))
        fi
    done <<< "${REG_MODULES}"
    if [[ ${GRAPH_PARSED} -eq 0 ]]; then
        warn "L4 (warn-mode): no parseable \`## Graph\` table — edge-closure check skipped"
    else
        while IFS= read -r v; do
            [[ -z "${v}" ]] && continue
            echo "${REG_VERBS}" | grep -qx "${v}" || { err "L4: Graph edge names verb \`${v}\` not present in the Registry"; l4_bad=$((l4_bad + 1)); }
        done <<< "${GRAPH_EDGE_VERBS}"
    fi
    [[ ${l4_bad} -eq 0 ]] && ok "L4: closure holds (modules exist$( [[ ${GRAPH_PARSED} -eq 1 ]] && echo '; Graph edges resolve in Registry'))"
fi

# ── L5: view banners ─────────────────────────────────────────────────────────

VIEW_FILES=()
for f in "${FLOW_FILES[@]}"; do
    base="$(basename "$f")"
    case "${base}" in
        getting-started.md|quick-ref*.md) VIEW_FILES+=("$f") ;;
    esac
done
# plus any files listed in a `## Views` section of a flow-level file
VIEWS_FILE="$(find_master 'Views' || true)"
if [[ -n "${VIEWS_FILE}" ]]; then
    while IFS= read -r v; do
        [[ -z "${v}" ]] && continue
        for cand in "${FLOW_DIR}/${v}" "${FLOW_DIR}/references/${v}"; do
            [[ -f "${cand}" ]] && VIEW_FILES+=("${cand}")
        done
    done < <(section_body "${VIEWS_FILE}" 'Views' | grep -oE '`[^`]+\.md`' | tr -d '`' | sort -u)
fi

if [[ ${#VIEW_FILES[@]} -eq 0 ]]; then
    warn "L5: no rendered views declared/found — skipping banner check"
else
    l5_bad=0
    seen=""
    for f in "${VIEW_FILES[@]}"; do
        echo "${seen}" | grep -qxF "$f" && continue
        seen="${seen}${f}"$'\n'
        if ! is_banner_marked "$f"; then
            err "L5: view ${f#${FLOW_DIR}/} has no first-line regeneration banner"
            l5_bad=$((l5_bad + 1))
        fi
    done
    [[ ${l5_bad} -eq 0 ]] && ok "L5: all rendered views carry the regeneration banner"
fi

# ── L6: host limits (frontmatter + description budget) ───────────────────────

l6_checked=0
l6_bad=0
for f in "${FLOW_FILES[@]}"; do
    head -n 1 "$f" | grep -qx -- '---' || continue   # stubs without frontmatter skip L6
    l6_checked=$((l6_checked + 1))
    desc_len="$(awk '
        NR == 1 { next }
        /^---[[:space:]]*$/ { exit }
        block && /^[[:space:]]/ { line = $0; gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                                  desc = desc (desc == "" ? "" : " ") line; next }
        block { exit }
        /^description:[[:space:]]*[|>][-+]?[[:space:]]*$/ { block = 1; next }
        /^description:/ { line = $0; sub(/^description:[[:space:]]*/, "", line); desc = line; exit }
        END { print length(desc) }
    ' "$f")"
    if [[ "${desc_len:-0}" -gt 1024 ]]; then
        err "L6: ${f#${FLOW_DIR}/} description is ${desc_len} chars (limit 1024)"
        l6_bad=$((l6_bad + 1))
    fi
done
if [[ ${l6_checked} -eq 0 ]]; then
    warn "L6: no frontmatter found in flow-level files — skipped"
elif [[ ${l6_bad} -eq 0 ]]; then
    ok "L6: descriptions within the 1024-char budget (${l6_checked} file(s) checked)"
fi

# ── summary ──────────────────────────────────────────────────────────────────

echo
if [[ ${errors} -gt 0 ]]; then
    echo "ERROR: check-flow-architecture: ${errors} error(s), ${warns} warning(s) — ${FLOW_DIR#${REPO_ROOT}/}"
    exit 1
fi
echo "OK: check-flow-architecture clean (${warns} warning(s)) — ${FLOW_DIR#${REPO_ROOT}/}"
