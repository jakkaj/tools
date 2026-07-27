// EdgeProfileSwitch — the binary inside each per-profile .app bundle.
//
// Reads its target profile from its own Info.plist, brings that profile forward,
// and exits. No UI, no run loop.
//
// Mechanism: press Edge's own "Profiles > <label>" menu item via Accessibility.
//
// The obvious alternative — enumerate AXWindows, match the profile from the
// window title, AXRaise the winner — was built first and rejected. macOS only
// exposes windows on the *current Space* through AXWindows (measured: 1 of 5
// visible), so it silently concluded a profile was closed and opened a duplicate
// window. Edge's own menu has no such limit: it reaches windows on other Spaces,
// never duplicates, and opens the profile when it isn't running yet.

import AppKit
import ApplicationServices
import Foundation

let edgeBundleID = "com.microsoft.edgemac"

let profileDir = Bundle.main.object(forInfoDictionaryKey: "EdgeProfileDirectory") as? String ?? "Default"
let profileLabel = Bundle.main.object(forInfoDictionaryKey: "EdgeProfileLabel") as? String ?? "Personal"

func axAttr(_ el: AXUIElement, _ attr: String) -> AnyObject? {
    var value: AnyObject?
    return AXUIElementCopyAttributeValue(el, attr as CFString, &value) == .success ? value : nil
}

func edgeApp() -> NSRunningApplication? {
    NSRunningApplication.runningApplications(withBundleIdentifier: edgeBundleID).first
}

/// Cold-start Edge on this profile. Also the fallback whenever the menu route
/// can't run, so a Dock click is never a dead end.
func launch() {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = ["-n", "-a", "Microsoft Edge", "--args", "--profile-directory=\(profileDir)"]
    try? p.run()
    p.waitUntilExit()
}

/// Press "Profiles > <label>" in Edge's menu bar.
func pressProfileMenuItem() -> Bool {
    guard let app = edgeApp() else { return false }
    let appEl = AXUIElementCreateApplication(app.processIdentifier)

    guard let menuBar = axAttr(appEl, kAXMenuBarAttribute),
          let topLevel = axAttr(menuBar as! AXUIElement, kAXChildrenAttribute) as? [AXUIElement]
    else { return false }

    for item in topLevel where (axAttr(item, kAXTitleAttribute) as? String) == "Profiles" {
        guard let menus = axAttr(item, kAXChildrenAttribute) as? [AXUIElement],
              let first = menus.first,
              let entries = axAttr(first, kAXChildrenAttribute) as? [AXUIElement]
        else { return false }

        for entry in entries where (axAttr(entry, kAXTitleAttribute) as? String) == profileLabel {
            return AXUIElementPerformAction(entry, kAXPressAction as CFString) == .success
        }
    }
    return false
}

// Accessibility is granted per bundle id, so each profile app needs its own tick
// in System Settings. Until then, fall back to launching the profile.
let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
guard AXIsProcessTrustedWithOptions(opts) else {
    launch()
    exit(0)
}

if edgeApp() == nil {
    launch()
} else if pressProfileMenuItem() {
    edgeApp()?.activate(options: [])
} else {
    // Menu missing or renamed by an Edge update — still get the user somewhere useful.
    launch()
}
exit(0)
