# edge-switcher — build & install on a new machine

One Dock icon per Microsoft Edge profile. Click it, that profile comes to the
front; if it isn't open yet, it opens. Icons are coloured with each profile's own
accent colour.

Source: [`edge-switcher/`](../../edge-switcher/) · design notes and the rejected
approach: [`edge-switcher/README.md`](../../edge-switcher/README.md)

## Requirements

- macOS 13 or later (developed on macOS 26)
- Microsoft Edge, with at least one profile signed in
- Xcode command line tools — `swiftc`, `iconutil`, `codesign`:

  ```bash
  xcode-select --install     # no-op if already present
  ```

- Python 3 (system Python is fine — stdlib only, no packages)

## 1. Build

```bash
cd ~/github/tools/edge-switcher
python3 build.py
```

Output:

```
built Edge Personal.app            dir=Default    colour=#0F6CBD
built Edge Work.app                dir=Profile 1  colour=#FF0000
built Edge <name>.app              dir=Profile 2  colour=#FD70A1

-> /Users/<you>/Applications/Edge Profiles
```

One `.app` per profile in `~/Applications/Edge Profiles/`. Everything is read
from Edge's own config at build time, so the output matches whatever profiles
that machine actually has — no per-machine editing.

## 2. Add to the Dock

Open `~/Applications/Edge Profiles/` in Finder and drag each app to the Dock.

```bash
open ~/Applications/Edge\ Profiles/
```

## 3. Grant Accessibility — required, once per app

Switching profiles drives Edge's own **Profiles** menu through the Accessibility
API, and macOS grants that **per bundle id**. Each profile app needs its own
approval.

System Settings → Privacy & Security → Accessibility → **`+`** → navigate to
`~/Applications/Edge Profiles/` → add **each** app → confirm each toggle is on.

Add them with the `+` button rather than waiting for the automatic prompt. The
apps are `LSUIElement` (no menu bar, no Dock tile of their own), so their prompt
can appear behind other windows, and macOS throttles repeat prompts.

**Until an app is granted it still works — it just opens a *new* window for that
profile instead of switching to the existing one.** That's the deliberate
fallback so a Dock click is never a dead end. It's also the symptom to look for.

## 4. Verify

```bash
cd ~/github/tools/edge-switcher
swiftc -O cli.swift -o edgeswitch
./edgeswitch list
```

Then click each Dock icon. Correct behaviour: the profile comes forward and **no
new window appears**. A new empty window means that app's grant isn't live —
see the trap below.

## The one trap: rebuilding silently kills the grants

The apps are ad-hoc signed, so they have no stable code identity. Re-running
`build.py` produces what macOS considers a *different* app, and the old grant no
longer applies.

**The checkbox still shows ticked while the grant is dead.** Unticking and
re-ticking does not fix it — the stale entry has to be cleared, and macOS 26
removed the `−` button that used to do that:

```bash
tccutil reset Accessibility local.edgeprofile.default
tccutil reset Accessibility local.edgeprofile.profile-1
tccutil reset Accessibility local.edgeprofile.profile-2
```

Bundle ids follow the profile directory: `local.edgeprofile.<dir lowercased,
spaces → dashes>`. Confirm them with:

```bash
for a in ~/Applications/Edge\ Profiles/*.app; do
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$a/Contents/Info.plist"
done
```

After resetting, re-add the apps in Accessibility.

So: **only rebuild when you actually need to** — adding, renaming, or recolouring
a profile. Day to day the apps need no maintenance.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| Click opens a new empty window | that app has no live Accessibility grant | `tccutil reset` the bundle id, then re-add via `+` |
| Icon has the wrong name or colour | profile renamed/recoloured since the build | re-run `build.py`, then re-do the grants |
| A profile has no app | profile added after the build | re-run `build.py` |
| `swiftc: command not found` | no command line tools | `xcode-select --install` |
| `./edgeswitch list` shows fewer windows than you have | expected — `AXWindows` only exposes the current Space | not a bug; the Dock apps don't rely on it |

## Uninstall

```bash
rm -rf ~/Applications/Edge\ Profiles
for id in default profile-1 profile-2; do
  tccutil reset Accessibility local.edgeprofile.$id
done
```

Then drag the icons off the Dock.
