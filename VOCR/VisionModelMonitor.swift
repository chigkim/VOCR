//
//  VisionModelMonitor.swift
//  VOCR
//

import Foundation
import Vision

/// Detects when Vision compiles its text recognition models instead of loading them from cache.
/// A compile can make a scan take up to a minute, for example on the first scan after a macOS update.
///
/// There is no public API for this, so the monitor uses the private `os_log_set_hook` to see Vision's
/// own log message for a model cache miss. Both private functions are looked up at runtime; if either
/// is missing, `start` does nothing and scans just run without the compile announcement.
///
/// The same hook can also record everything the process logs during a scan, including Vision's own
/// errors, so VOCR's log shows what happened inside Vision when a scan fails.
enum VisionModelMonitor {
    private typealias Hook = @convention(block) (UInt8, UnsafeMutableRawPointer?) -> Void
    private typealias SetHook = @convention(c) (UInt8, Hook?) -> Hook?
    private typealias CopyMessage =
        @convention(c) (UnsafeMutableRawPointer?) -> UnsafeMutablePointer<
            CChar
        >?

    /// Logged by the E5 runtime when a compiled model is not in the cache.
    private static let cacheMissMarker = "E5BundleCache Lookup"
    private static let cacheMissValue = "exists=0"
    /// The hook receives this level and above: info, default, error and fault, but not debug.
    private static let infoLevel: UInt8 = 0x01
    /// A warm scan logs about 25 messages; the cap only matters for an unusually noisy scan.
    private static let maxMessages = 500

    private static let lock = NSLock()
    private static var onCompile: (() -> Void)?
    /// Messages logged during the current scan, or nil when not capturing.
    private static var messages: [String]?
    private static var droppedMessages = 0
    private static var scanStart = Date()
    private static var installed = false

    /// Calls `handler` on the main thread the first time Vision starts compiling a model,
    /// until `stop()` is called. If `captureLog` is true, also records the process's log messages
    /// until then. Call on the main thread.
    static func start(captureLog: Bool, onCompile handler: @escaping () -> Void) {
        guard installHook() else { return }
        lock.withLock {
            onCompile = handler
            messages = captureLog ? [] : nil
            droppedMessages = 0
            scanStart = Date()
        }
    }

    /// Stops watching and returns the messages recorded since `start`, each prefixed with the
    /// seconds since the scan started and its level.
    @discardableResult
    static func stop() -> [String] {
        lock.withLock {
            var result = messages ?? []
            if droppedMessages > 0 {
                result.append("\(droppedMessages) more messages not recorded")
            }
            onCompile = nil
            messages = nil
            return result
        }
    }

    private static func levelName(_ type: UInt8) -> String {
        switch type {
        case 0x00: return "default"
        case 0x01: return "info"
        case 0x10: return "error"
        case 0x11: return "fault"
        default: return String(format: "0x%02x", type)
        }
    }

    private static func installHook() -> Bool {
        if installed { return true }
        let process = UnsafeMutableRawPointer(bitPattern: -2)  // RTLD_DEFAULT
        guard let setHookSymbol = dlsym(process, "os_log_set_hook"),
            let copySymbol = dlsym(process, "os_log_copy_formatted_message")
        else {
            log("Vision model monitor unavailable")
            return false
        }
        let setHook = unsafeBitCast(setHookSymbol, to: SetHook.self)
        let copyMessage = unsafeBitCast(copySymbol, to: CopyMessage.self)

        // The hook runs synchronously on whichever thread logs, for every message in the process.
        // It must stay cheap and must not log itself.
        var previous: Hook?
        let hook: Hook = { type, message in
            previous?(type, message)
            guard lock.withLock({ onCompile != nil || messages != nil }),
                let text = copyMessage(message)
            else {
                return
            }
            defer { free(text) }
            let line = String(cString: text)
            let isCacheMiss = line.contains(cacheMissMarker) && line.contains(cacheMissValue)
            let handler = lock.withLock { () -> (() -> Void)? in
                if messages != nil {
                    if messages!.count < maxMessages {
                        let seconds = String(format: "%.3f", Date().timeIntervalSince(scanStart))
                        messages!.append("+\(seconds)s \(levelName(type)): \(line)")
                    } else {
                        droppedMessages += 1
                    }
                }
                guard isCacheMiss else { return nil }
                defer { onCompile = nil }
                return onCompile
            }
            if let handler {
                DispatchQueue.main.async(execute: handler)
            }
        }
        previous = setHook(infoLevel, hook)
        installed = true
        return true
    }
}

/// Details for VOCR's log that help explain a failed or empty scan.
enum VisionDiagnostics {
    /// VOCR, macOS and Mac model, plus the text recognition revision Vision uses by default.
    static var environment: String {
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        return
            "VOCR \(Bundle.main.version), macOS \(os), \(macModel), "
            + "text recognition revision \(VNRecognizeTextRequest.defaultRevision)"
    }

    private static var macModel: String {
        var size = 0
        guard sysctlbyname("hw.model", nil, &size, nil, 0) == 0, size > 0 else {
            return "unknown Mac"
        }
        var model = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.model", &model, &size, nil, 0) == 0 else { return "unknown Mac" }
        return String(cString: model)
    }

    /// Lists the compiled models Vision keeps for VOCR: one folder per macOS build, one entry per model.
    static func modelCache() -> String {
        let fileManager = FileManager.default
        guard
            let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first,
            let bundleID = Bundle.main.bundleIdentifier
        else { return "Model cache: unknown location" }
        let root = caches.appendingPathComponent(bundleID)
            .appendingPathComponent("com.apple.e5rt.e5bundlecache")
        guard
            let builds = try? fileManager.contentsOfDirectory(
                at: root, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        else { return "Model cache: none at \(root.path)" }
        let formatter = ByteCountFormatter()
        var lines = ["Model cache at \(root.path):"]
        for build in builds.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let models =
                (try? fileManager.contentsOfDirectory(
                    at: build, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? []
            var bytes: Int64 = 0
            var newest = Date.distantPast
            let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
            if let files = fileManager.enumerator(at: build, includingPropertiesForKeys: keys) {
                for case let file as URL in files {
                    let values = try? file.resourceValues(forKeys: Set(keys))
                    bytes += Int64(values?.fileSize ?? 0)
                    newest = max(newest, values?.contentModificationDate ?? .distantPast)
                }
            }
            lines.append(
                "  \(build.lastPathComponent): \(models.count) models, "
                    + "\(formatter.string(fromByteCount: bytes)), newest \(newest)")
        }
        return lines.joined(separator: "\n")
    }

    /// The full error, including the NSError domain, code and underlying errors.
    static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        return
            "\(String(reflecting: error)); domain \(nsError.domain), code \(nsError.code), "
            + "userInfo \(nsError.userInfo)"
    }
}
