# edge-switcher

One Dock icon per Microsoft Edge profile. Click it, that profile comes to the
front. If the profile isn't open yet, it opens.

Each icon is a tiny `.app` in `~/Applications/Edge Profiles/`, coloured with the
profile's own accent colour.

**Setting this up on a new machine?** Step-by-step guide:
[`docs/how/edge-switcher.md`](../docs/how/edge-switcher.md). This file covers the
design and the reasoning behind it.

## Build

```bash
python3 build.py
```

Reads your profiles straight from Edge's config, so re-running picks up renames,
new profiles, and colour changes. Then drag the apps from
`~/Applications/Edge Profiles/` into your Dock.

## Accessibility permission (required, once per profile app)

Add **each** profile app to
**System Settings → Privacy & Security → Accessibility**.

Until an app is granted, clicking it still works, but it opens a *new* window for
that profile instead of switching to the existing one. That's the deliberate
fallback: a click is never a dead end.

### Re-running `build.py` invalidates existing grants

The bundles are ad-hoc signed, which gives them no stable code identity, so macOS
treats a rebuilt app as a different app. The trap: **the checkbox still shows
ticked while the grant is dead** — macOS keeps the old entry, keyed to the
previous signature. Re-ticking it does nothing. The stale entry has to be
cleared, and macOS 26 removed the `−` button that used to do that:

```bash
tccutil reset Accessibility local.edgeprofile.default
tccutil reset Accessibility local.edgeprofile.profile-1
tccutil reset Accessibility local.edgeprofile.profile-2
```

Bundle ids follow the profile directory: `local.edgeprofile.<dir lowercased,
spaces to dashes>`. After resetting, click the app and approve the fresh prompt.

Symptom that you're hitting this: the app opens a *new* window instead of
switching, despite appearing granted.

## How it works

Edge runs every profile inside one process, so there's no per-window API saying
which profile a window belongs to. What works is pressing Edge's own
**Profiles → \<label\>** menu item through the Accessibility API.

### The approach that didn't work

The obvious design — enumerate `AXWindows`, read the profile off each window
title, `AXRaise` the match — was built first and rejected.

Edge does append the profile to each window's **accessibility** title (and only
there; the Window menu text and AppleScript window names lack it):

```
Example Page Title - Microsoft Edge - Personal
                                     ^^^^^^^^ profile
```

That part works. What kills it is that **macOS only exposes windows on the
current Space through `AXWindows`** — measured here at 1 window visible out of 5
real ones. So the switcher decided a profile was closed and opened a duplicate
window. Driving the menu has no such limit: it reaches other Spaces, never
duplicates, and opens the profile if it isn't running.

### Two pieces of Edge trivia this depends on

- **The profile label isn't stored anywhere.** Edge shows a profile's `name`
  from `Local State` only if you've renamed it; otherwise it synthesises
  `Personal` or `Work` from `edge_account_type` at display time. The menu item
  is labelled with that synthesised string, so `build.py` re-derives it.
- **The colour isn't in `Local State`.** `profile_highlight_color` there is a
  washed-out grey. The real colour is `browser.accent_color_value` in each
  profile's own `Preferences`. Profiles with none get a blue default.

## Files

| file | what |
|---|---|
| `build.py` | reads Edge config, renders icons, assembles + signs the `.app`s |
| `switcher.swift` | the binary inside each app: press Profiles → \<label\>, else launch |
| `makeicon.swift` | renders the coloured rounded-square `.iconset` |
| `cli.swift` | standalone diagnostic CLI |

## Diagnostics

```bash
swiftc -O cli.swift -o edgeswitch
./edgeswitch list       # profiles, colours, live window count per profile
./edgeswitch windows    # every Edge AX window title, raw
./edgeswitch switch 2   # AXRaise route (the rejected one — Space-limited)
./edgeswitch menu 2     # menu route (what the Dock apps actually use)
```

`list` is the one to run when something looks wrong. Its window counts only
cover the current Space — that's the AX limitation above, not a bug in the
report. If a window shows under *unattributed*, the label derivation has drifted
from what Edge is displaying.

## Known gaps

- **Which window comes forward** is Edge's choice, not ours — the menu raises
  that profile's most recent window. There's no way to target a specific one.
- The label derivation (`Personal`/`Work`) is inference, not a documented API.
  If Edge changes how it names default profiles, `build.py` needs updating.
- Grants don't survive rebuilds (see above). A self-signed certificate with a
  stable identity would fix that if it becomes annoying.
