#!/bin/bash
# Claude Code status line: folder • model • effort • context bar/% • used/size • 5h rate
# Installed to ~/.claude/statusline-context.sh by install/claude-statusline.sh
# Wire via: `statusLine: { type: "command", command: "~/.claude/statusline-context.sh" }` in ~/.claude/settings.json
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
CWD=$(echo "$input" | jq -r '.workspace.current_dir // "."')
DIR=$(basename "$CWD")

# Effort: env var (catches session-only `max`) → stdin JSON (future-proofing)
# → project local → project → user settings.
EFFORT=""
if [ -n "$CLAUDE_CODE_EFFORT_LEVEL" ]; then
  EFFORT="$CLAUDE_CODE_EFFORT_LEVEL"
else
  # Check stdin for any effort-ish field (newer CC versions may expose it)
  v=$(echo "$input" | jq -r '.effort_level // .effortLevel // .effort // empty' 2>/dev/null)
  if [ -n "$v" ]; then
    EFFORT="$v"
  else
    for f in "$CWD/.claude/settings.local.json" "$CWD/.claude/settings.json" "$HOME/.claude/settings.json"; do
      if [ -f "$f" ]; then
        v=$(jq -r '.effortLevel // empty' "$f" 2>/dev/null)
        if [ -n "$v" ]; then EFFORT="$v"; break; fi
      fi
    done
  fi
fi
EFFORT=${EFFORT:-auto}
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
PCT_INT=$(printf '%.0f' "$PCT" 2>/dev/null || echo 0)
SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')

# Tokens currently in context — derive from percentage × window size so it
# always matches the bar/percent display. (current_usage.* reflects only the
# last turn and is misleading mid-session.)
USED=$(awk -v s="$SIZE" -v p="$PCT" 'BEGIN{printf "%d", s*p/100}')
REMAIN=$(( SIZE - USED ))

fmt() {  # 12345 -> 12.3k; 180000 -> 180k; 1000000 -> 1.0M
  local n=$1
  awk -v n="$n" 'BEGIN{
    if (n>=1000000) printf "%.1fM", n/1000000;
    else if (n>=10000) printf "%dk", n/1000;
    else if (n>=1000) printf "%.1fk", n/1000;
    else printf "%d", n;
  }'
}

WIDTH=12
FILLED=$(( PCT_INT * WIDTH / 100 ))
(( FILLED > WIDTH )) && FILLED=$WIDTH
EMPTY=$(( WIDTH - FILLED ))
printf -v F "%${FILLED}s"
printf -v E "%${EMPTY}s"
BAR="${F// /█}${E// /░}"

RL5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
RL5_AT=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
RL5_FMT=""
if [ -n "$RL5" ]; then
  RESET=""
  [ -n "$RL5_AT" ] && RESET=$(date -r "$RL5_AT" +%H:%M 2>/dev/null || date -d "@$RL5_AT" +%H:%M 2>/dev/null)
  [ -n "$RESET" ] && RL5_FMT=$(printf ' • \033[2m5h %d%% ↻%s\033[0m' "${RL5%.*}" "$RESET") \
                  || RL5_FMT=$(printf ' • \033[2m5h %d%%\033[0m' "${RL5%.*}")
fi

printf '\033[36m%s\033[0m • %s • \033[35m⚡%s\033[0m • \033[2m%s %s%% • %s / %s\033[0m%b' \
  "$DIR" "$MODEL" "$EFFORT" "$BAR" "$PCT_INT" "$(fmt "$USED")" "$(fmt "$SIZE")" "$RL5_FMT"
