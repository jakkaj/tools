// usbvol — minimal USB output volume key controller for macOS
//
// Commands:
//   usbvol probe                 List output devices + what volume controls they expose
//   usbvol run [substring]       Intercept volume keys; when the default output device is USB
//                                (or matches the optional name substring), set ITS volume and
//                                swallow the key. Other devices pass through to macOS.
//
// Build: swiftc -O usbvol.swift -o usbvol
// Permissions: `run` needs Accessibility (System Settings → Privacy & Security → Accessibility)
// granted to the terminal you launch it from.

import Foundation
import AppKit
import CoreAudio

// MARK: - CoreAudio helpers

// 'vmvc' — virtual main/master volume (device-level, balance-preserving)
let kVirtualMainVolume = AudioObjectPropertySelector(0x766D_7663)

func addr(_ selector: AudioObjectPropertySelector,
          _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
          _ element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain) -> AudioObjectPropertyAddress {
    AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element)
}

func getProp<T>(_ objectID: AudioObjectID, _ address: AudioObjectPropertyAddress, _ value: inout T) -> Bool {
    var a = address
    var size = UInt32(MemoryLayout<T>.size)
    return AudioObjectGetPropertyData(objectID, &a, 0, nil, &size, &value) == noErr
}

func setProp<T>(_ objectID: AudioObjectID, _ address: AudioObjectPropertyAddress, _ value: T) -> Bool {
    var a = address
    var v = value
    return AudioObjectSetPropertyData(objectID, &a, 0, nil, UInt32(MemoryLayout<T>.size), &v) == noErr
}

func hasProp(_ objectID: AudioObjectID, _ address: AudioObjectPropertyAddress) -> Bool {
    var a = address
    return AudioObjectHasProperty(objectID, &a)
}

func isSettable(_ objectID: AudioObjectID, _ address: AudioObjectPropertyAddress) -> Bool {
    var a = address
    var settable: DarwinBoolean = false
    return AudioObjectIsPropertySettable(objectID, &a, &settable) == noErr && settable.boolValue
}

func deviceName(_ id: AudioObjectID) -> String {
    var name: CFString = "" as CFString
    return getProp(id, addr(kAudioObjectPropertyName), &name) ? (name as String) : "<unnamed \(id)>"
}

func transportType(_ id: AudioObjectID) -> UInt32 {
    var t: UInt32 = 0
    _ = getProp(id, addr(kAudioDevicePropertyTransportType), &t)
    return t
}

func transportName(_ t: UInt32) -> String {
    switch t {
    case kAudioDeviceTransportTypeUSB: return "USB"
    case kAudioDeviceTransportTypeBuiltIn: return "Built-in"
    case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE: return "Bluetooth"
    case kAudioDeviceTransportTypeHDMI: return "HDMI"
    case kAudioDeviceTransportTypeDisplayPort: return "DisplayPort"
    case kAudioDeviceTransportTypeAggregate: return "Aggregate"
    case kAudioDeviceTransportTypeVirtual: return "Virtual"
    case kAudioDeviceTransportTypeAirPlay: return "AirPlay"
    case kAudioDeviceTransportTypeThunderbolt: return "Thunderbolt"
    default:
        var chars = [UInt8]()
        for shift in stride(from: 24, through: 0, by: -8) {
            let b = UInt8((t >> UInt32(shift)) & 0xFF)
            chars.append((b >= 32 && b < 127) ? b : UInt8(ascii: "?"))
        }
        return String(bytes: chars, encoding: .ascii) ?? "unknown"
    }
}

func hasOutput(_ id: AudioObjectID) -> Bool {
    var a = addr(kAudioDevicePropertyStreams, kAudioObjectPropertyScopeOutput)
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(id, &a, 0, nil, &size) == noErr else { return false }
    return size > 0
}

func allDevices() -> [AudioObjectID] {
    var a = addr(kAudioHardwarePropertyDevices)
    var size: UInt32 = 0
    let sys = AudioObjectID(kAudioObjectSystemObject)
    guard AudioObjectGetPropertyDataSize(sys, &a, 0, nil, &size) == noErr else { return [] }
    var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(sys, &a, 0, nil, &size, &ids) == noErr else { return [] }
    return ids
}

func defaultOutputDevice() -> AudioObjectID? {
    var id = AudioObjectID(0)
    let ok = getProp(AudioObjectID(kAudioObjectSystemObject), addr(kAudioHardwarePropertyDefaultOutputDevice), &id)
    return ok && id != 0 ? id : nil
}

// MARK: - Volume control

struct VolumeControl {
    let device: AudioObjectID

    var virtualMainAddr: AudioObjectPropertyAddress {
        addr(kVirtualMainVolume, kAudioObjectPropertyScopeOutput)
    }
    func channelAddr(_ ch: AudioObjectPropertyElement) -> AudioObjectPropertyAddress {
        addr(kAudioDevicePropertyVolumeScalar, kAudioObjectPropertyScopeOutput, ch)
    }
    var muteAddr: AudioObjectPropertyAddress {
        addr(kAudioDevicePropertyMute, kAudioObjectPropertyScopeOutput)
    }

    var canSetVirtualMain: Bool { hasProp(device, virtualMainAddr) && isSettable(device, virtualMainAddr) }
    var settableChannels: [AudioObjectPropertyElement] {
        (0...2).filter { hasProp(device, channelAddr($0)) && isSettable(device, channelAddr($0)) }
    }
    var canSetAnyVolume: Bool { canSetVirtualMain || !settableChannels.isEmpty }
    var canMute: Bool { hasProp(device, muteAddr) && isSettable(device, muteAddr) }

    func read() -> Float32? {
        var v: Float32 = 0
        if canSetVirtualMain, getProp(device, virtualMainAddr, &v) { return v }
        for ch in settableChannels where getProp(device, channelAddr(ch), &v) { return v }
        return nil
    }

    @discardableResult
    func write(_ value: Float32) -> Bool {
        let v = max(0, min(1, value))
        if canSetVirtualMain { return setProp(device, virtualMainAddr, v) }
        var ok = false
        for ch in settableChannels { ok = setProp(device, channelAddr(ch), v) || ok }
        return ok
    }

    func toggleMute() -> Bool? {
        guard canMute else { return nil }
        var m: UInt32 = 0
        guard getProp(device, muteAddr, &m) else { return nil }
        let next: UInt32 = m == 0 ? 1 : 0
        return setProp(device, muteAddr, next) ? (next == 1) : nil
    }
}

// MARK: - Software volume engine (for devices with NO hardware volume, e.g. bit-perfect USB DACs)
//
// Uses macOS 14.2+ Core Audio process taps: a system-wide tap (muteBehavior=.mutedWhenTapped)
// captures all process audio and mutes the direct path; we re-render it to the target device
// through an aggregate, applying our own gain. No kernel/HAL driver needed.

final class SoftwareVolumeEngine {
    private(set) var gain: Float32 = 0.5      // user-facing 0..1; cubic curve applied at render
    private var savedGain: Float32 = 0.5
    private(set) var muted = false
    private var tapID = AudioObjectID(kAudioObjectUnknown)
    private var aggID = AudioObjectID(kAudioObjectUnknown)
    private var ioProcID: AudioDeviceIOProcID?
    private var renderGain: Float32 = 0.125   // gain^3, read on the IO thread
    var capturePeak: Float32 = 0              // written on IO thread, read for diagnostics

    init() {
        let saved = UserDefaults.standard.object(forKey: "usbvol.gain") as? Float
        gain = saved.map { max(0, min(1, Float32($0))) } ?? 0.5
        savedGain = gain
    }

    func setGain(_ g: Float32) {
        gain = max(0, min(1, g))
        muted = false
        renderGain = gain * gain * gain
        UserDefaults.standard.set(gain, forKey: "usbvol.gain")
    }

    func toggleMute() -> Bool {
        muted.toggle()
        if muted { savedGain = gain; renderGain = 0 }
        else { setGain(savedGain) }
        return muted
    }

    func start(outputDevice: AudioObjectID) throws {
        // Exclude our own process from the tap (avoid feedback)
        var pid = pid_t(ProcessInfo.processInfo.processIdentifier)
        var selfProcObj = AudioObjectID(kAudioObjectUnknown)
        var tAddr = addr(kAudioHardwarePropertyTranslatePIDToProcessObject)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        _ = withUnsafePointer(to: &pid) { pidPtr in
            AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &tAddr,
                                       UInt32(MemoryLayout<pid_t>.size), pidPtr, &size, &selfProcObj)
        }

        let desc = CATapDescription(stereoGlobalTapButExcludeProcesses:
            selfProcObj != kAudioObjectUnknown ? [selfProcObj] : [])
        desc.name = "usbvol system tap"
        desc.muteBehavior = .mutedWhenTapped
        desc.isPrivate = true

        var status = AudioHardwareCreateProcessTap(desc, &tapID)
        guard status == noErr else { throw err("AudioHardwareCreateProcessTap", status) }

        var uid: CFString = "" as CFString
        guard getProp(outputDevice, addr(kAudioDevicePropertyDeviceUID), &uid) else {
            throw err("get device UID", -1)
        }

        let aggDesc: [String: Any] = [
            kAudioAggregateDeviceNameKey: "usbvol",
            kAudioAggregateDeviceUIDKey: "com.jk.usbvol.agg",
            kAudioAggregateDeviceIsPrivateKey: true,
            kAudioAggregateDeviceIsStackedKey: false,
            kAudioAggregateDeviceTapAutoStartKey: true,
            kAudioAggregateDeviceSubDeviceListKey: [[kAudioSubDeviceUIDKey: uid as String]],
            kAudioAggregateDeviceTapListKey: [[
                kAudioSubTapUIDKey: desc.uuid.uuidString,
                kAudioSubTapDriftCompensationKey: true,
            ]],
        ]
        status = AudioHardwareCreateAggregateDevice(aggDesc as CFDictionary, &aggID)
        guard status == noErr else { throw err("AudioHardwareCreateAggregateDevice", status) }

        status = AudioDeviceCreateIOProcIDWithBlock(&ioProcID, aggID, nil) {
            [weak self] _, inInputData, _, outOutputData, _ in
            guard let self else { return }
            let g = self.renderGain
            var peak: Float32 = self.capturePeak
            let inBufs = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: inInputData))
            let outBufs = UnsafeMutableAudioBufferListPointer(outOutputData)
            for (i, outBuf) in outBufs.enumerated() {
                guard let outData = outBuf.mData else { continue }
                let outFloats = outData.assumingMemoryBound(to: Float32.self)
                let outCount = Int(outBuf.mDataByteSize) / MemoryLayout<Float32>.size
                if i < inBufs.count, let inData = inBufs[i].mData {
                    let inFloats = inData.assumingMemoryBound(to: Float32.self)
                    let n = min(outCount, Int(inBufs[i].mDataByteSize) / MemoryLayout<Float32>.size)
                    for f in 0..<n {
                        let s = inFloats[f]
                        peak = max(peak, abs(s))
                        outFloats[f] = s * g
                    }
                    if n < outCount { for f in n..<outCount { outFloats[f] = 0 } }
                } else {
                    for f in 0..<outCount { outFloats[f] = 0 }
                }
            }
            self.capturePeak = peak
        }
        guard status == noErr, let ioProcID else { throw err("AudioDeviceCreateIOProcIDWithBlock", status) }

        status = AudioDeviceStart(aggID, ioProcID)
        guard status == noErr else { throw err("AudioDeviceStart", status) }
        renderGain = gain * gain * gain
    }

    func stop() {
        if let ioProcID, aggID != kAudioObjectUnknown {
            AudioDeviceStop(aggID, ioProcID)
            AudioDeviceDestroyIOProcID(aggID, ioProcID)
        }
        ioProcID = nil
        if aggID != kAudioObjectUnknown { AudioHardwareDestroyAggregateDevice(aggID); aggID = AudioObjectID(kAudioObjectUnknown) }
        if tapID != kAudioObjectUnknown { AudioHardwareDestroyProcessTap(tapID); tapID = AudioObjectID(kAudioObjectUnknown) }
    }

    private func err(_ what: String, _ status: OSStatus) -> NSError {
        NSError(domain: "usbvol", code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "\(what) failed (OSStatus \(status))"])
    }
}

// MARK: - HUD (our own volume bezel — the native macOS one is private API)

final class HUD {
    static let shared = HUD()
    private let window: NSWindow
    private let barBg = NSView()
    private let bar = NSView()
    private let label = NSTextField(labelWithString: "")
    private var hideTimer: Timer?

    private init() {
        let size = NSSize(width: 280, height: 68)
        window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                          styleMask: .borderless, backing: .buffered, defer: false)
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]

        let content = NSView(frame: NSRect(origin: .zero, size: size))
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
        content.layer?.cornerRadius = 16

        label.frame = NSRect(x: 20, y: 36, width: size.width - 40, height: 20)
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.lineBreakMode = .byTruncatingTail
        content.addSubview(label)

        barBg.frame = NSRect(x: 20, y: 18, width: size.width - 40, height: 8)
        barBg.wantsLayer = true
        barBg.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.25).cgColor
        barBg.layer?.cornerRadius = 4
        content.addSubview(barBg)

        bar.frame = NSRect(x: 0, y: 0, width: 0, height: 8)
        bar.wantsLayer = true
        bar.layer?.backgroundColor = NSColor.white.cgColor
        bar.layer?.cornerRadius = 4
        barBg.addSubview(bar)

        window.contentView = content
    }

    func show(name: String, level: Float32, muted: Bool) {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let wf = window.frame
        window.setFrameOrigin(NSPoint(x: sf.midX - wf.width / 2, y: sf.minY + 140))

        label.stringValue = muted ? "\(name) — muted" : String(format: "%@ — %.0f%%", name, level * 100)
        bar.frame.size.width = muted ? 0 : (barBg.frame.width * CGFloat(level))
        bar.layer?.backgroundColor = (muted ? NSColor.systemRed : .white).cgColor

        window.alphaValue = 1
        window.orderFrontRegardless()

        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { [weak self] _ in
            guard let self else { return }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.35
                self.window.animator().alphaValue = 0
            }, completionHandler: { self.window.orderOut(nil) })
        }
    }
}

// MARK: - probe

func probe() {
    let def = defaultOutputDevice()
    print("Output devices:\n")
    for id in allDevices() where hasOutput(id) {
        let vc = VolumeControl(device: id)
        let marker = id == def ? "  ← DEFAULT OUTPUT" : ""
        print("• \(deviceName(id)) [id \(id), \(transportName(transportType(id)))]\(marker)")
        print("    virtual main volume: \(hasProp(id, vc.virtualMainAddr) ? (vc.canSetVirtualMain ? "settable" : "read-only") : "absent")")
        let chs = (0...2).map { ch -> String in
            let a = vc.channelAddr(AudioObjectPropertyElement(ch))
            let state = hasProp(id, a) ? (isSettable(id, a) ? "settable" : "read-only") : "absent"
            return "ch\(ch)=\(state)"
        }
        print("    volume scalar:       \(chs.joined(separator: "  "))")
        print("    mute:                \(hasProp(id, vc.muteAddr) ? (vc.canMute ? "settable" : "read-only") : "absent")")
        if let v = vc.read() { print(String(format: "    current volume:      %.0f%%", v * 100)) }
        print("")
    }
    if def == nil { print("(no default output device)") }
}

// MARK: - run (event tap)

let NX_KEYTYPE_SOUND_UP: Int32 = 0
let NX_KEYTYPE_SOUND_DOWN: Int32 = 1
let NX_KEYTYPE_MUTE: Int32 = 7

var targetSubstring: String? = nil
let volumeStep: Float32 = 1.0 / 16.0
var engine: SoftwareVolumeEngine? = nil

func shouldHandle(_ device: AudioObjectID) -> Bool {
    if let sub = targetSubstring {
        return deviceName(device).localizedCaseInsensitiveContains(sub)
    }
    return transportType(device) == kAudioDeviceTransportTypeUSB
}

func printLevel(_ name: String, _ level: Float32, muted: Bool = false) {
    let bars = String(repeating: "█", count: Int((level * 16).rounded()))
    print(String(format: "%@: %3.0f%%  %@%@", name, level * 100, bars, muted ? "  (muted)" : ""))
}

func handleVolumeKey(_ keyType: Int32) -> Bool {
    guard let dev = defaultOutputDevice(), shouldHandle(dev) else { return false }
    if let engine {   // software-volume mode
        switch keyType {
        case NX_KEYTYPE_MUTE:
            let muted = engine.toggleMute()
            printLevel(deviceName(dev), engine.gain, muted: muted)
            HUD.shared.show(name: deviceName(dev), level: engine.gain, muted: muted)
        case NX_KEYTYPE_SOUND_UP, NX_KEYTYPE_SOUND_DOWN:
            engine.setGain(engine.gain + (keyType == NX_KEYTYPE_SOUND_UP ? volumeStep : -volumeStep))
            printLevel(deviceName(dev), engine.gain)
            HUD.shared.show(name: deviceName(dev), level: engine.gain, muted: false)
        default:
            return false
        }
        return true
    }
    let vc = VolumeControl(device: dev)
    guard vc.canSetAnyVolume else {
        print("⚠️  \(deviceName(dev)): no settable hardware volume — cannot control (software tap would be needed)")
        return false
    }
    switch keyType {
    case NX_KEYTYPE_MUTE:
        if let muted = vc.toggleMute() {
            print("\(deviceName(dev)): \(muted ? "muted" : "unmuted")")
            HUD.shared.show(name: deviceName(dev), level: vc.read() ?? 0, muted: muted)
        } else if let cur = vc.read() {
            // no mute control: emulate by dropping to 0 / restoring step
            vc.write(cur > 0 ? 0 : volumeStep * 4)
            print("\(deviceName(dev)): mute emulated via volume")
            HUD.shared.show(name: deviceName(dev), level: vc.read() ?? 0, muted: cur > 0)
        }
    case NX_KEYTYPE_SOUND_UP, NX_KEYTYPE_SOUND_DOWN:
        let cur = vc.read() ?? 0
        let next = cur + (keyType == NX_KEYTYPE_SOUND_UP ? volumeStep : -volumeStep)
        vc.write(next)
        let now = vc.read() ?? next
        printLevel(deviceName(dev), now)
        HUD.shared.show(name: deviceName(dev), level: now, muted: false)
    default:
        return false
    }
    return true
}

func tapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                 refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = refcon?.assumingMemoryBound(to: CFMachPort?.self).pointee {
            CGEvent.tapEnable(tap: tap, enable: true)
            print("(event tap re-enabled)")
        }
        return Unmanaged.passUnretained(event)
    }
    // NX_SYSDEFINED = 14
    guard type.rawValue == 14, let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype.rawValue == 8 else {
        return Unmanaged.passUnretained(event)
    }
    let data1 = nsEvent.data1
    let keyType = Int32((data1 & 0xFFFF_0000) >> 16)
    let keyFlags = data1 & 0xFFFF
    let keyDown = ((keyFlags & 0xFF00) >> 8) == 0x0A
    guard keyType == NX_KEYTYPE_SOUND_UP || keyType == NX_KEYTYPE_SOUND_DOWN || keyType == NX_KEYTYPE_MUTE else {
        return Unmanaged.passUnretained(event)
    }
    // Swallow both key-down and key-up when we own the device (act on key-down only,
    // but letting the key-up through would confuse macOS's own handler).
    guard let dev = defaultOutputDevice(), shouldHandle(dev) else {
        return Unmanaged.passUnretained(event)
    }
    if keyDown { _ = handleVolumeKey(keyType) }
    return nil
}

func run() {
    // App context so the HUD window can be shown (no Dock icon)
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let trusted = AXIsProcessTrustedWithOptions(
        ["AXTrustedCheckOptionPrompt": true] as CFDictionary)
    if !trusted {
        print("""
        ⛔ Accessibility permission needed.
        Grant it to your terminal app in System Settings → Privacy & Security → Accessibility,
        then run again.
        """)
        exit(1)
    }

    var tapStorage: CFMachPort? = nil
    let mask = CGEventMask(1 << 14) // NX_SYSDEFINED
    guard let tap = withUnsafeMutablePointer(to: &tapStorage, { ptr in
        CGEvent.tapCreate(tap: .cgSessionEventTap,
                          place: .headInsertEventTap,
                          options: .defaultTap,
                          eventsOfInterest: mask,
                          callback: tapCallback,
                          userInfo: UnsafeMutableRawPointer(ptr))
    }) else {
        print("⛔ Failed to create event tap (permission issue?)")
        exit(1)
    }
    tapStorage = tap

    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    if let dev = defaultOutputDevice() {
        let owned = shouldHandle(dev)
        print("Default output: \(deviceName(dev))\(owned ? " → controlling this device" : " (passing through — not a target)")")
        if owned {
            let vc = VolumeControl(device: dev)
            if vc.canSetAnyVolume {
                print("Mode: hardware volume (device exposes CoreAudio volume controls)")
            } else {
                print("Mode: software volume (device has no volume controls — starting system audio tap)")
                let e = SoftwareVolumeEngine()
                do {
                    try e.start(outputDevice: dev)
                    engine = e
                    printLevel(deviceName(dev), e.gain)
                } catch {
                    print("⛔ Could not start software volume engine: \(error.localizedDescription)")
                    print("   (System audio recording permission may be needed — check System Settings → Privacy & Security → Screen & System Audio Recording)")
                    exit(1)
                }
            }
        }
    }
    print("usbvol running — volume keys now target \(targetSubstring.map { "devices matching \"\($0)\"" } ?? "USB output devices"). Ctrl-C to quit.")

    signal(SIGINT, { _ in
        engine?.stop()
        print("\nbye")
        exit(0)
    })

    // Log default-device changes
    var defAddr = addr(kAudioHardwarePropertyDefaultOutputDevice)
    AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defAddr, DispatchQueue.main) { _, _ in
        if let dev = defaultOutputDevice() {
            let owned = shouldHandle(dev) ? " → controlling this device" : " (passing through)"
            print("Default output changed: \(deviceName(dev))\(owned)")
        }
    }

    app.run()
}

// MARK: - main

let args = CommandLine.arguments
switch args.count > 1 ? args[1] : "help" {
case "probe":
    probe()
case "run":
    targetSubstring = args.count > 2 ? args[2] : nil
    run()
default:
    print("""
    usbvol — route macOS volume keys to a USB output device's own volume
      usbvol probe            list output devices and their volume capabilities
      usbvol run [name]       intercept volume keys for USB outputs (or devices matching [name])
    """)
}
