#!/usr/bin/env bash
# Install the Claude Code status line script + wire ~/.claude/settings.json.
# Idempotent: safe to rerun.

set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SRC="${REPO_ROOT}/scripts/claude-statusline-context.sh"
DEST="${HOME}/.claude/statusline-context.sh"
SETTINGS="${HOME}/.claude/settings.json"
EXPECTED_CMD="~/.claude/statusline-context.sh"

print_info()    { echo "[*] $1"; }
print_success() { echo "[✓] $1"; }
print_warn()    { echo "[!] $1" >&2; }

if [ ! -f "$SRC" ]; then
  print_warn "Source script not found: $SRC"
  exit 1
fi

mkdir -p "$(dirname "$DEST")"

# Install script (skip copy if content already identical)
if [ -f "$DEST" ] && cmp -s "$SRC" "$DEST"; then
  print_success "Status line script up to date: $DEST"
else
  cp "$SRC" "$DEST"
  chmod +x "$DEST"
  print_success "Installed status line script → $DEST"
fi

# Wire settings.json — only if jq is available; otherwise just tell the user.
if ! command -v jq >/dev/null 2>&1; then
  print_warn "jq not found — add this to $SETTINGS manually:"
  echo '    "statusLine": { "type": "command", "command": "'"$EXPECTED_CMD"'" }'
  exit 0
fi

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

CURRENT_CMD=$(jq -r '.statusLine.command // empty' "$SETTINGS" 2>/dev/null)
if [ "$CURRENT_CMD" = "$EXPECTED_CMD" ]; then
  print_success "settings.json already wired to status line"
else
  TMP=$(mktemp)
  jq --arg cmd "$EXPECTED_CMD" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$TMP" \
    && mv "$TMP" "$SETTINGS"
  print_success "Wired statusLine into $SETTINGS"
fi
