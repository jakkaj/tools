# usbvol — volume keys for volume-less USB DACs (minimal SoundSource replacement)

macOS refuses to map the keyboard volume keys to USB audio devices that expose no
volume control over USB Audio Class (bit-perfect DACs like the SMSL — the crossed-out
volume bezel). Windows silently applies software volume for these devices; macOS
doesn't. SoundSource fixes it with its ACE/ARK kernel-adjacent HAL driver — this tool
does it with **Apple's public process-tap API (macOS 14.2+), no driver at all**.

## How it works

- A `CGEventTap` intercepts the volume/mute media keys. When the **default output is a
  USB device** (or matches an optional name filter), usbvol handles the keys itself and
  swallows them; for any other device the keys pass through to macOS untouched.
- Devices **with** CoreAudio volume controls get those set directly
  (`VirtualMainVolume`, falling back to per-channel `VolumeScalar`).
- Devices **without** any (the SMSL case) get a software gain stage: a system-wide
  process tap (`AudioHardwareCreateProcessTap`, `.mutedWhenTapped`, own PID excluded)
  mutes the direct path, and a private aggregate device re-renders the captured audio
  to the DAC through an IOProc that applies a cubic-curve gain.
- Draws its own on-screen HUD bezel (the native one is private API), persists the level
  in `UserDefaults`, and prints a capture-health line every 3s so a dead tap is visible.

## Build & run

```bash
swiftc -O usbvol.swift -o usbvol
codesign -s - -f --identifier com.jk.usbvol usbvol

./usbvol probe          # list output devices + the volume controls each exposes
./usbvol run            # intercept volume keys for USB outputs
./usbvol run SMSL       # ...or only for devices whose name matches a substring
```

## Permissions (attach to your TERMINAL app, not usbvol — it's an unbundled CLI)

1. **Accessibility** (intercepting the keys): System Settings → Privacy & Security →
   Accessibility → enable/add the terminal you launch usbvol from, then restart it.
2. **System audio capture** (the tap): Privacy & Security → Screen & System Audio
   Recording → same terminal app.

## Known limitations (prototype)

- Runs only while its terminal stays open; Ctrl-C cleanly reverts audio to the direct path.
- If `coreaudiod` restarts (audio driver installs/uninstalls), the tap dies — relaunch.
- Default-output changes mid-session are logged but the software engine is only started
  for the device that was default at launch.
- The DAC's own volume/display can never move: the SMSL exposes no UAC volume control
  and its HID interface is vendor-defined (0xFF00 feature reports) — software
  attenuation is the only path on macOS, same as SoundSource used.

Next step when wanted: wrap as a menu-bar `.app` agent (own TCC identity, launch at
login, engage/disengage on default-device changes).
