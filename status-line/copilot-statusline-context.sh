#!/bin/bash
# Copilot CLI status line: context % • folder/branch/pij • model • effort • used/size • usage
# Ported from ~/.claude/statusline-context.sh. Wire via ~/.copilot/settings.json:
#   "statusLine": { "type": "command", "command": "~/.copilot/statusline-context.sh" }
# Copilot CLI reloads this user setting without requiring experimental mode.
#
# Payload schema (from Copilot CLI app.js): model.{id,display_name},
# workspace.current_dir, context_window.{current_context_tokens,displayed_context_limit,
# context_window_size,current_context_used_percentage,used_percentage(last-call!)},
# cost.{total_duration_ms,total_premium_requests}, ai_used.formatted.
# NOTE: prefer current_context_* (matches /context); used_percentage is last-call only.
input=$(cat)

# ---- single jq pass: all fields joined by unit-separator (perf: one subprocess, no
#      transcript scan). \x1f (not tab) avoids read() collapsing empty fields, since
#      tab is an IFS-whitespace char and would shift columns when e.g. AIU is empty. ----
IFS=$'\x1f' read -r CWD MODEL USED SIZE PCT AIU PREMIUM DURMS < <(
  printf '%s' "$input" | jq -j '
    . as $r
    | ($r.context_window // {}) as $c
    | (($c.displayed_context_limit // $c.context_window_size) // 200000) as $size
    | ($size | if . > 0 then . else 200000 end) as $size
    | ($c.current_context_tokens
        // (if   $c.current_context_used_percentage != null then $c.current_context_used_percentage * $size / 100
            elif $c.used_percentage                 != null then $c.used_percentage                 * $size / 100
            else 0 end)) as $used
    | ($c.current_context_used_percentage
        // (if $size > 0 then ($used / $size * 100) else 0 end)) as $pct
    | [ ($r.workspace.current_dir // $r.cwd // ".")
      , ($r.model.display_name // $r.model.id // "?")
      , ($used  | floor)
      , ($size  | floor)
      , ($pct   | floor)
      , ($r.ai_used.formatted // "")
      , ($r.cost.total_premium_requests // 0)
      , ($r.cost.total_duration_ms // 0)
      ] | map(tostring) | join("\u001f")'
)
CWD=${CWD:-.}
DIR=$(basename "$CWD")
MODEL=${MODEL:-?}
PCT_INT=${PCT:-0}

# ---- current git branch and pij identity, matching the Claude status line ----
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ "$BRANCH" = "HEAD" ] && BRANCH=$(git -C "$CWD" rev-parse --short HEAD 2>/dev/null)
BRANCH_FMT=""
[ -n "$BRANCH" ] && BRANCH_FMT=$(printf ' \033[32m⎇ %s\033[0m' "$BRANCH")

PIJID=$(pij whoami --json 2>/dev/null | jq -r '.id // empty' 2>/dev/null)
PIJ_FMT=""
[ -n "$PIJID" ] && PIJ_FMT=$(printf ' \033[34m⛓ %s\033[0m' "$PIJID")

# ---- effort: not in payload; read from settings.json (cheap jq on a tiny file) ----
EFFORT=""
for f in "$PWD/.github/copilot/settings.local.json" "$PWD/.github/copilot/settings.json" "$HOME/.copilot/settings.json"; do
  if [ -f "$f" ]; then
    v=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null)
    if [ -n "$v" ]; then EFFORT="$v"; break; fi
  fi
done
EFFORT=${EFFORT:-auto}

fmt() {  # 12345 -> 12.3k; 180000 -> 180k; 1000000 -> 1.0M
  awk -v n="${1:-0}" 'BEGIN{
    if (n>=1000000) printf "%.1fM", n/1000000;
    else if (n>=10000) printf "%dk", n/1000;
    else if (n>=1000) printf "%.1fk", n/1000;
    else printf "%d", n;
  }'
}

# ---- session duration (cost.total_duration_ms -> 1h2m / 3m) ----
DUR_FMT=""
if [ -n "$DURMS" ] && [ "$DURMS" -gt 0 ] 2>/dev/null; then
  SECS=$(( DURMS / 1000 )); H=$(( SECS / 3600 )); M=$(( (SECS % 3600) / 60 ))
  if [ "$H" -gt 0 ]; then DUR_FMT=$(printf ' • \033[2m%dh%dm\033[0m' "$H" "$M")
  else DUR_FMT=$(printf ' • \033[2m%dm\033[0m' "$M"); fi
fi

# ---- usage tail: AI units and/or premium requests (Copilot analog of Claude 5h rate) ----
USAGE_FMT=""
[ -n "$AIU" ] && USAGE_FMT=$(printf ' • \033[2m%s AIU\033[0m' "$AIU")
if [ -n "$PREMIUM" ] && awk -v p="$PREMIUM" 'BEGIN{exit !(p+0>0)}'; then
  USAGE_FMT="$USAGE_FMT$(printf ' • \033[2m%s prem\033[0m' "$(printf '%.2f' "$PREMIUM" 2>/dev/null || echo "$PREMIUM")")"
fi

printf '\033[2m%s%%\033[0m \033[36m%s\033[0m%s%s • %s • \033[35m%s\033[0m • \033[2m%s/%s\033[0m%b%b' \
  "$PCT_INT" "$DIR" "$BRANCH_FMT" "$PIJ_FMT" "$MODEL" "$EFFORT" "$(fmt "$USED")" "$(fmt "$SIZE")" "$USAGE_FMT" "$DUR_FMT"
