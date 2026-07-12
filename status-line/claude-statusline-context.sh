#!/bin/bash
# Claude Code status line: folder • model • effort • context % • used/size • 5h rate
# Installed to ~/.claude/statusline-context.sh by install/claude-statusline.sh
# Wire via: `statusLine: { type: "command", command: "~/.claude/statusline-context.sh" }` in ~/.claude/settings.json
input=$(cat)

# Running under the isolated alt profile? `cc-alt` sets CLAUDE_CONFIG_DIR to
# ~/.claude-alt. Prepend a yellow "alt" tag so the profile is unmistakable.
ALT_FMT=""
case "$CLAUDE_CONFIG_DIR" in
  *.claude-alt*) ALT_FMT=$(printf '\033[33malt\033[0m ') ;;
esac

MODEL=$(echo "$input" | jq -r '.model.display_name // .model.id // "?"')
CWD=$(echo "$input" | jq -r '.workspace.current_dir // "."')
DIR=$(basename "$CWD")

# Current git branch (empty when not in a repo / detached without a name)
BRANCH=$(git -C "$CWD" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ "$BRANCH" = "HEAD" ] && BRANCH=$(git -C "$CWD" rev-parse --short HEAD 2>/dev/null)
BRANCH_FMT=""
[ -n "$BRANCH" ] && BRANCH_FMT=$(printf ' \033[32m⎇ %s\033[0m' "$BRANCH")

# pij session id for this pane, if adopted/bound; blank otherwise
PIJID=$(pij whoami --json 2>/dev/null | jq -r '.id // empty' 2>/dev/null)
PIJ_FMT=""
[ -n "$PIJID" ] && PIJ_FMT=$(printf ' \033[34m⛓ %s\033[0m' "$PIJID")

# Effort precedence:
#   1. $CLAUDE_CODE_EFFORT_LEVEL env var (catches session-only `max` exports)
#   2. Per-session transcript: last `/effort` invocation in this session's
#      transcript_path. This is the authoritative per-session signal — stdin's
#      `.effort.level` claims to be session-scoped per the docs but in practice
#      leaks across tabs because Claude Code persists effort globally.
#   3. stdin `.effort.level` (handles object or string) — fallback for sessions
#      where `/effort` was never invoked (initial state from settings).
#   4. settings files (project-local, project, user)
#   5. fallback `auto`
EFFORT=""
if [ -n "$CLAUDE_CODE_EFFORT_LEVEL" ]; then
  EFFORT="$CLAUDE_CODE_EFFORT_LEVEL"
else
  TRANSCRIPT=$(echo "$input" | jq -r '.transcript_path // empty' 2>/dev/null)
  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    EFFORT=$(jq -rc 'select(.type=="user"
                            and (.message.content // "" | type=="string")
                            and (.message.content | test("<command-name>/effort</command-name>")))
                     | .message.content
                     | capture("<command-args>(?<v>[^<]+)</command-args>")
                     | .v' "$TRANSCRIPT" 2>/dev/null | tail -1)
  fi
  if [ -z "$EFFORT" ]; then
    v=$(echo "$input" | jq -r '
      .effort_level // .effortLevel //
      (.effort | if type=="object" then .level
                 elif type=="string" then .
                 else empty end) //
      empty' 2>/dev/null)
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

RL5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' 2>/dev/null)
RL5_AT=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty' 2>/dev/null)
RL5_FMT=""
if [ -n "$RL5" ]; then
  RESET=""
  [ -n "$RL5_AT" ] && RESET=$(date -r "$RL5_AT" +%H:%M 2>/dev/null || date -d "@$RL5_AT" +%H:%M 2>/dev/null)
  [ -n "$RESET" ] && RL5_FMT=$(printf ' • \033[2m%d%% ↻%s\033[0m' "${RL5%.*}" "$RESET") \
                  || RL5_FMT=$(printf ' • \033[2m%d%%\033[0m' "${RL5%.*}")
fi

printf '\033[2m%s%%\033[0m %b\033[36m%s\033[0m%s%s • %s • \033[35m%s\033[0m • \033[2m%s/%s\033[0m%b' \
  "$PCT_INT" "$ALT_FMT" "$DIR" "$BRANCH_FMT" "$PIJ_FMT" "$MODEL" "$EFFORT" "$(fmt "$USED")" "$(fmt "$SIZE")" "$RL5_FMT"
