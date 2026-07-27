// edgeswitch — PoC: attribute Edge windows to profiles and raise one.
//
//   edgeswitch list          list profiles (index, dir, name, colour) + live window count
//   edgeswitch windows       dump every AX window title raw (diagnosis)
//   edgeswitch switch <n>    raise profile n's window, or launch it if none
//   edgeswitch menu <n>      fallback: drive Edge's own Profiles menu
//
// Throwaway. No error handling beyond what the experiment needs.

import AppKit
import ApplicationServices
import Foundation

let edgeBundleID = "com.microsoft.edgemac"
let titleSeparator = " - Microsoft Edge - "

// MARK: - Profiles from Local State

struct Profile {
    let dir: String        // on-disk dir: "Default", "Profile 1", ...
    let name: String       // Local State `name`
    let label: String      // what Edge actually SHOWS — the window-title suffix
    let colour: String?    // #rrggbb from profile_highlight_color
}

func loadProfiles() -> [Profile] {
    let path = ("~/Library/Application Support/Microsoft Edge/Local State" as NSString)
        .expandingTildeInPath
    guard let data = FileManager.default.contents(atPath: path),
          let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let cache = (root["profile"] as? [String: Any])?["info_cache"] as? [String: Any]
    else { return [] }

    let profiles: [Profile] = cache.compactMap { dir, raw in
        guard let info = raw as? [String: Any] else { return nil }
        let name = info["name"] as? String ?? dir

        // Edge only shows `name` when the user has renamed the profile. Otherwise it
        // synthesises a label from the account type: 1 = personal MSA, 2 = work/AAD.
        // Nothing in Local State stores the synthesised string, so re-derive it.
        let usingDefaultName = info["is_using_default_name"] as? Bool ?? false
        let accountType = info["edge_account_type"] as? Int ?? 0
        let label = usingDefaultName ? (accountType == 1 ? "Personal" : "Work") : name

        var colour: String?
        if let argb = info["profile_highlight_color"] as? Int {
            let bits = UInt32(bitPattern: Int32(truncatingIfNeeded: argb))
            colour = String(format: "#%02X%02X%02X",
                            (bits >> 16) & 0xFF, (bits >> 8) & 0xFF, bits & 0xFF)
        }
        return Profile(dir: dir, name: name, label: label, colour: colour)
    }

    // Stable order: Default first, then Profile 1, Profile 2, ...
    return profiles.sorted { a, b in
        if a.dir == "Default" { return true }
        if b.dir == "Default" { return false }
        return a.dir.compare(b.dir, options: .numeric) == .orderedAscending
    }
}

// MARK: - Accessibility

func requireTrust() {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    if !AXIsProcessTrustedWithOptions(opts) {
        FileHandle.standardError.write(
            "edgeswitch: no Accessibility permission. Grant it to this terminal in\n"
            .data(using: .utf8)!)
        FileHandle.standardError.write(
            "  System Settings > Privacy & Security > Accessibility, then re-run.\n"
            .data(using: .utf8)!)
        exit(2)
    }
}

func edgeApp() -> NSRunningApplication? {
    NSRunningApplication.runningApplications(withBundleIdentifier: edgeBundleID).first
}

func axAttr(_ el: AXUIElement, _ attr: String) -> AnyObject? {
    var value: AnyObject?
    return AXUIElementCopyAttributeValue(el, attr as CFString, &value) == .success ? value : nil
}

/// Every Edge AX window paired with the profile name parsed from its title suffix.
///
/// Chromium builds its accessibility tree lazily, so a cold first query under-reports
/// windows. `AXManualAccessibility` is Chromium's opt-in switch; set it and let the
/// tree settle, otherwise callers conclude a profile is closed when it isn't.
func edgeWindows() -> [(window: AXUIElement, title: String, profile: String?)] {
    guard let app = edgeApp() else { return [] }
    let appEl = AXUIElementCreateApplication(app.processIdentifier)
    AXUIElementSetAttributeValue(appEl, "AXManualAccessibility" as CFString, kCFBooleanTrue)

    var windows = axAttr(appEl, kAXWindowsAttribute) as? [AXUIElement] ?? []
    for _ in 0..<10 where windows.isEmpty {
        usleep(150_000)
        windows = axAttr(appEl, kAXWindowsAttribute) as? [AXUIElement] ?? []
    }

    return windows.map { win in
        let title = axAttr(win, kAXTitleAttribute) as? String ?? ""
        // "<page> - Microsoft Edge - <ProfileName>"  ->  trailing component
        let profile = title.range(of: titleSeparator, options: .backwards).map {
            String(title[$0.upperBound...])
        }
        return (win, title, profile)
    }
}

func raise(_ win: AXUIElement) {
    AXUIElementPerformAction(win, kAXRaiseAction as CFString)
    AXUIElementSetAttributeValue(win, kAXMainAttribute as CFString, kCFBooleanTrue)
    edgeApp()?.activate(options: [])
    // Second raise after activation — activation can re-order windows underneath us.
    usleep(120_000)
    AXUIElementPerformAction(win, kAXRaiseAction as CFString)
}

func launch(_ profile: Profile) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    p.arguments = ["-n", "-a", "Microsoft Edge", "--args",
                   "--profile-directory=\(profile.dir)"]
    try? p.run()
    p.waitUntilExit()
}

// MARK: - Profiles-menu fallback

func clickProfileMenu(named label: String) -> Bool {
    guard let app = edgeApp() else { return false }
    let appEl = AXUIElementCreateApplication(app.processIdentifier)
    guard let bar = axAttr(appEl, kAXMenuBarAttribute),
          let bars = axAttr(bar as! AXUIElement, kAXChildrenAttribute) as? [AXUIElement]
    else { return false }

    for item in bars where (axAttr(item, kAXTitleAttribute) as? String) == "Profiles" {
        guard let menus = axAttr(item, kAXChildrenAttribute) as? [AXUIElement],
              let entries = axAttr(menus[0], kAXChildrenAttribute) as? [AXUIElement]
        else { return false }
        for entry in entries where (axAttr(entry, kAXTitleAttribute) as? String) == label {
            AXUIElementPerformAction(entry, kAXPressAction as CFString)
            return true
        }
    }
    return false
}

// MARK: - Commands

let profiles = loadProfiles()
let args = Array(CommandLine.arguments.dropFirst())
let command = args.first ?? "list"

func profileArg() -> Profile {
    guard args.count > 1, let n = Int(args[1]), n >= 1, n <= profiles.count else {
        print("usage: edgeswitch \(command) <1..\(profiles.count)>")
        exit(1)
    }
    return profiles[n - 1]
}

switch command {
case "list":
    requireTrust()
    let live = edgeWindows()
    print("Edge running: \(edgeApp() != nil)   AX windows visible: \(live.count)\n")
    func pad(_ s: String, _ w: Int) -> String {
        s.count >= w ? s : s + String(repeating: " ", count: w - s.count)
    }
    for (i, p) in profiles.enumerated() {
        let n = live.filter { $0.profile == p.label }.count
        print("\(i + 1)) \(pad(p.label, 10)) dir=\(pad(p.dir, 10)) "
            + "name=\(pad(p.name, 10)) colour=\(pad(p.colour ?? "-", 8)) windows=\(n)")
    }
    let unmatched = live.filter { w in !profiles.contains { $0.label == w.profile } }
    if !unmatched.isEmpty {
        print("\nunattributed windows:")
        unmatched.forEach { print("   \($0.title)") }
    }

case "windows":
    requireTrust()
    let live = edgeWindows()
    print("AX window count: \(live.count)")
    for w in live {
        print("  profile=\(w.profile ?? "??")")
        print("  title  =\(w.title)\n")
    }

case "switch":
    requireTrust()
    let p = profileArg()
    if let hit = edgeWindows().first(where: { $0.profile == p.label }) {
        print("raising existing window for \(p.label): \(hit.title)")
        raise(hit.window)
    } else {
        print("no window found for \(p.label) — launching \(p.dir)")
        launch(p)
    }

case "menu":
    requireTrust()
    let p = profileArg()
    let label = args.count > 2 ? args[2] : p.label
    print("pressing Profiles > \(label)")
    print(clickProfileMenu(named: label) ? "pressed" : "menu item not found")

default:
    print("usage: edgeswitch [list|windows|switch <n>|menu <n> [label]]")
}
