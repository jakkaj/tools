#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# Script name for help text
SCRIPT_NAME="$(basename "$0")"

show_help() {
  cat << EOF
NAME
    $SCRIPT_NAME - Rip a ChatGPT share link to clean markdown

SYNOPSIS
    $SCRIPT_NAME <share-url> <output.md>
    $SCRIPT_NAME --help

DESCRIPTION
    Downloads a chatgpt.com/share/... page and extracts the full conversation
    as markdown. A share page ships the conversation in React Router's streamed
    *flight* format, inside \`streamController.enqueue("...")\` script calls —
    not __NEXT_DATA__, not plain JSON — so curl/WebFetch alone only sees the
    page title. The zero-dependency npm package \`chatgpt-share-parser\`
    understands that format; this script fetches its tarball directly (no
    npm/npx install step) and runs it with node.

    Method credit: Jordan, 2026-08-13. Proven on a 28-email thread → 3,822 lines.

PARAMETERS
    share-url
        Required. The https://chatgpt.com/share/... URL.

    output.md
        Required. Path for the extracted markdown.

OPTIONS
    -h, --help
        Show this help.

EXAMPLES
    $SCRIPT_NAME https://chatgpt.com/share/6890... thread.md

DEPENDENCIES
    curl, python3, node (>=18), tar

NOTES
    - Images are NOT included; they appear as
      '*Image ... not included in export (source: sediment://...)*' placeholders.
    - Attachment URLs (e.g. Intercom email attachments) survive as live links in
      the markdown and are often the real prize — grep them out and download
      them before they expire.
    - Tool calls render as '### Tool' blocks, frequently 'output ... redacted'.
    - The parser tarball is resolved via the Microsoft public npm proxy first
      (registry.npmjs.org is unreachable on some of our networks — curl exit 35;
      never \`npx chatgpt-share-parser\` there), falling back to the npm registry
      when the proxy is unavailable. The package has ZERO dependencies, which is
      what makes the hand-untar approach safe.
EOF
}

case "${1:-}" in
  -h|--help|"") show_help; exit 0 ;;
esac

URL="${1:?usage: $SCRIPT_NAME <share-url> <output.md>}"
OUT="${2:?usage: $SCRIPT_NAME <share-url> <output.md>}"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"

# Absolute output path before we cd into the workdir.
OUT="$(cd "$(dirname "$OUT")" && pwd)/$(basename "$OUT")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

# 1. Fetch the share page. Browser UA matters — a bare curl UA gets rejected.
echo "==> fetching share page"
curl -sL "$URL" -o share.html -A "$UA" -w "    HTTP %{http_code}, %{size_download} bytes\n"

# 2. Get the parser WITHOUT npm/npx: resolve metadata + tarball and untar by
#    hand. MS public npm proxy first (npmjs.org is blocked on some networks),
#    plain registry as fallback.
echo "==> resolving chatgpt-share-parser"
curl -sS "https://packagefeedproxy.microsoft.io/npm/chatgpt-share-parser" -o meta.json \
  || curl -sS "https://registry.npmjs.org/chatgpt-share-parser" -o meta.json
TARBALL="$(python3 -c "
import json
m = json.load(open('meta.json'))
v = m['dist-tags']['latest']
print(m['versions'][v]['dist']['tarball'])")"
echo "    $TARBALL"

curl -sSL "$TARBALL" -o parser.tgz
tar xzf parser.tgz          # → ./package/

# 3. Parse the flight stream → markdown.
echo "==> parsing"
OUT="$OUT" node --input-type=module -e "
import { readFileSync, writeFileSync } from 'fs';
import { parseChatGptShareHtml, chatGptShareToMarkdown } from './package/dist/index.js';
const chat = parseChatGptShareHtml(readFileSync('share.html', 'utf8'));
const md = chatGptShareToMarkdown(chat);
writeFileSync(process.env.OUT, md);
console.log('    title:', chat.title);
console.log('    chars:', md.length);
"
echo "==> wrote $OUT ($(wc -l < "$OUT" | tr -d ' ') lines)"
