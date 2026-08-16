#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

# Script name for help text
SCRIPT_NAME="$(basename "$0")"

show_help() {
  cat << EOF
NAME
    $SCRIPT_NAME - Route the keyboard volume keys to a USB DAC that has no volume control

SYNOPSIS
    $SCRIPT_NAME [run] [name-substring]
    $SCRIPT_NAME probe
    $SCRIPT_NAME stop
    $SCRIPT_NAME rebuild
    $SCRIPT_NAME --help

DESCRIPTION
    macOS refuses to map the volume keys to USB audio devices that expose no
    volume control over USB Audio Class (bit-perfect DACs such as the SMSL —
    the crossed-out volume bezel). Windows silently applies software volume for
    these; macOS does not. This is a minimal SoundSource replacement that fixes
    it with Apple's public process-tap API — no kernel or HAL driver.

    A CGEventTap intercepts the volume/mute keys. When the default output is a
    USB device (or matches an optional name substring) it handles them itself
    and draws its own HUD bezel; every other output device passes through to
    macOS untouched. Devices WITH CoreAudio volume controls get those set
    directly; devices without get a software gain stage (system-wide tap mutes
    the direct path, a private aggregate re-renders to the DAC with gain).

    Source of truth: apps/usbvol/usbvol.swift in this repo. The binary is built
    on first run and cached; \`rebuild\` forces a fresh build after edits.

COMMANDS
    run [name-substring]
        Default. Intercept the volume keys until Ctrl-C. Optionally restrict to
        devices whose name contains the given substring (e.g. SMSL).

    probe
        List every output device and the volume controls it exposes, then exit.

    stop
        Terminate a running instance.

    rebuild
        Force a rebuild of the cached binary from source.

OPTIONS
    -h, --help
        Show this help.

EXAMPLES
    $SCRIPT_NAME                 # intercept keys for any USB output
    $SCRIPT_NAME run SMSL        # ...only for devices matching "SMSL"
    $SCRIPT_NAME probe           # what can each device actually do?
    $SCRIPT_NAME stop

PERMISSIONS
    Both attach to the TERMINAL app you launch this from (it is an unbundled
    CLI, so it never appears under its own name):
      1. Privacy & Security -> Accessibility            (intercepting keys)
      2. Privacy & Security -> Screen & System Audio Recording  (the tap)
    Restart the terminal after granting.

NOTES
    - Runs only while the terminal stays open; Ctrl-C reverts audio cleanly.
    - If coreaudiod restarts (audio driver install/uninstall), the tap dies —
      just run again.
    - The DAC's own display can never move: such devices expose no UAC volume
      control and their HID interface is vendor-defined, so software
      attenuation is the only path on macOS (same as SoundSource did).

DEPENDENCIES
    macOS 14.2+ (process-tap API), swiftc (Xcode command line tools)
EOF
}

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../apps/usbvol" && pwd)"
SRC="$SRC_DIR/usbvol.swift"
BIN_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/usbvol"
BIN="$BIN_DIR/usbvol"

build() {
  command -v swiftc >/dev/null 2>&1 || {
    echo "error: swiftc not found — install Xcode command line tools (xcode-select --install)" >&2
    exit 1
  }
  echo "==> building usbvol from $SRC"
  mkdir -p "$BIN_DIR"
  # -suppress-warnings: the CoreAudio generic get/setProp helpers trip a benign
  # "forming UnsafeRawPointer to a variable of type T" warning on every call site.
  swiftc -O -suppress-warnings "$SRC" -o "$BIN"
  codesign -s - -f --identifier com.jk.usbvol "$BIN" >/dev/null 2>&1 || true
  echo "==> built $BIN"
}

# Rebuild when the binary is missing or older than the source.
ensure_built() {
  [[ -x "$BIN" && "$BIN" -nt "$SRC" ]] || build
}

case "${1:-run}" in
  -h|--help)
    show_help
    ;;
  rebuild)
    build
    ;;
  stop)
    if pkill -f "$BIN run"; then echo "stopped usbvol"; else echo "usbvol not running"; fi
    ;;
  probe)
    ensure_built
    exec "$BIN" probe
    ;;
  run)
    ensure_built
    # `shift` returns non-zero when invoked bare (`jk-uv` with no args), which
    # under `set -e` would exit silently before we ever start. Guard it.
    (($# > 0)) && shift
    exec "$BIN" run "$@"
    ;;
  *)
    # Bare substring: `usb-volume.sh SMSL` behaves as `run SMSL`
    ensure_built
    exec "$BIN" run "$1"
    ;;
esac
