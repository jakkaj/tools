#!/usr/bin/env python3
"""Build one .app per Edge profile into ~/Applications/Edge Profiles/.

Reads profile identity from Edge's own config so re-running picks up renames,
new profiles, and colour changes:

  Local State           -> which profiles exist, their names, account type
  <profile>/Preferences -> accent_color_value, the real profile colour

Run:  python3 build.py
"""

import json
import os
import plistlib
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
EDGE = os.path.expanduser("~/Library/Application Support/Microsoft Edge")
DEST = os.path.expanduser("~/Applications/Edge Profiles")
DEFAULT_COLOUR = "#0F6CBD"  # blueish, for profiles with no accent set


def argb_to_hex(value):
    """Edge stores colours as signed 32-bit ARGB ints."""
    return "#%06X" % (value & 0xFFFFFF)


def profiles():
    with open(os.path.join(EDGE, "Local State")) as fh:
        cache = json.load(fh)["profile"]["info_cache"]

    out = []
    for directory, info in cache.items():
        name = info.get("name", directory)

        # Edge shows `name` only when the user renamed the profile; otherwise it
        # synthesises a label from the account type (1 = personal MSA, 2 = work).
        # The synthesised string is stored nowhere, and it is what the window
        # title suffix uses, so it has to be re-derived.
        if info.get("is_using_default_name"):
            label = "Personal" if info.get("edge_account_type") == 1 else "Work"
        else:
            label = name

        colour = DEFAULT_COLOUR
        prefs = os.path.join(EDGE, directory, "Preferences")
        if os.path.exists(prefs):
            with open(prefs) as fh:
                accent = json.load(fh).get("browser", {}).get("accent_color_value")
            if isinstance(accent, int):
                colour = argb_to_hex(accent)

        out.append({"dir": directory, "name": name, "label": label, "colour": colour})

    out.sort(key=lambda p: (p["dir"] != "Default", p["dir"]))
    return out


def build_binaries():
    for src, exe in (("switcher.swift", "EdgeProfileSwitch"), ("makeicon.swift", "makeicon")):
        subprocess.run(
            ["swiftc", "-O", os.path.join(HERE, src), "-o", os.path.join(HERE, exe)],
            check=True,
        )


def build_app(p):
    app = os.path.join(DEST, "Edge %s.app" % p["label"])
    contents = os.path.join(app, "Contents")
    shutil.rmtree(app, ignore_errors=True)
    os.makedirs(os.path.join(contents, "MacOS"))
    os.makedirs(os.path.join(contents, "Resources"))

    shutil.copy2(os.path.join(HERE, "EdgeProfileSwitch"),
                 os.path.join(contents, "MacOS", "EdgeProfileSwitch"))

    iconset = os.path.join(HERE, "build", "%s.iconset" % p["dir"].replace(" ", "_"))
    shutil.rmtree(iconset, ignore_errors=True)
    subprocess.run([os.path.join(HERE, "makeicon"), p["colour"], p["label"][0], iconset],
                   check=True)
    subprocess.run(["iconutil", "-c", "icns", iconset,
                    "-o", os.path.join(contents, "Resources", "icon.icns")], check=True)

    plist = {
        "CFBundleName": "Edge %s" % p["label"],
        "CFBundleDisplayName": "Edge %s" % p["label"],
        "CFBundleIdentifier": "local.edgeprofile.%s" % p["dir"].replace(" ", "-").lower(),
        "CFBundleExecutable": "EdgeProfileSwitch",
        "CFBundleIconFile": "icon",
        "CFBundlePackageType": "APPL",
        "CFBundleShortVersionString": "1.0",
        "CFBundleVersion": "1",
        "LSMinimumSystemVersion": "13.0",
        # No menu bar, and clicking must not steal focus from Edge itself.
        "LSUIElement": True,
        # Read by the binary at launch — this is what makes the bundles differ.
        "EdgeProfileDirectory": p["dir"],
        "EdgeProfileLabel": p["label"],
    }
    with open(os.path.join(contents, "Info.plist"), "wb") as fh:
        plistlib.dump(plist, fh)

    # Ad-hoc sign so the Accessibility grant sticks to a stable identity instead
    # of being invalidated every rebuild.
    subprocess.run(["codesign", "--force", "--deep", "--sign", "-", app],
                   check=True, capture_output=True)
    return app


def main():
    os.makedirs(DEST, exist_ok=True)
    build_binaries()
    found = profiles()
    if not found:
        sys.exit("no Edge profiles found in %s" % EDGE)
    for p in found:
        app = build_app(p)
        print("built %-28s dir=%-10s colour=%s" % (os.path.basename(app), p["dir"], p["colour"]))
    print("\n-> %s" % DEST)


if __name__ == "__main__":
    main()
