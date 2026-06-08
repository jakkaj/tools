#!/usr/bin/env bash
# compound-value.sh — render harness-4-retro --harvest --json output as a compact terminal view.
# Reads JSON on stdin. Per workshop 007 § RV-002 + FX001 § RV-002.
#
# Usage:
#   <json-source> | just compound-value
#   echo '<json>' | scripts/compound-value.sh
#
# The JSON source is whatever produces harness-4-retro --harvest --json output —
# typically the active agent CLI invoking the skill. Cross-CLI portable
# because this script is just a pretty-printer (no skill invocation here).

set -e

if ! command -v jq &>/dev/null; then
  echo "Error: jq required but not in PATH." >&2
  exit 2
fi

INPUT=$(cat)
if [ -z "$INPUT" ]; then
  echo "Error: empty stdin. Usage: <json-source> | just compound-value" >&2
  exit 2
fi

jq -r '
  # Compact view: harness / compound counts / blank / top-friction header / up to 2 clusters
  "Harness: \(.harness.maturity // "Unknown"), last validation \((.harness.verdict // "unknown") | ascii_upcase), boot \((.harness.boot_ms // 0) / 1000 | floor)s",
  "Compound: \(.entries.total // 0) entries — \(.entries.open // 0) open, \(.entries.encoded // 0) encoded, \(.entries.suggested // 0) suggested",
  "",
  (if ((.top_clusters // []) | length) == 0 then "Top friction: (none)" else "Top friction:" end),
  ((.top_clusters // [])[:2] | to_entries | .[] |
    "  \(.key + 1). \(.value.target)/\(.value.kind) — \(.value.count) entries — \((.value.representative // "")[0:60])")
' <<< "$INPUT"
