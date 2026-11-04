//
//  VisionModelMonitor.swift
//  VOCR
//

import Foundation

/// Detects when Vision compiles its text recognition models instead of loading them from cache.
/// A compile can make a scan take up to a minute, for example on the first scan after a macOS update.
///
/// There is no public API for this, so the monitor uses the private `os_log_set_hook` to see Vision's
/// own log message for a model cache miss. Both private functions are looked up at runtime; if either
/// is missing, `start` does nothing and scans just run without the compile announcement.
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
    private static let infoLevel: UInt8 = 0x01

    private static let lock = NSLock()
    private static var onCompile: (() -> Void)?
    private static var installed = false

    /// Calls `handler` on the main thread the first time Vision starts compiling a model,
    /// until `stop()` is called. Call on the main thread.
    static func start(onCompile handler: @escaping () -> Void) {
        guard installHook() else { return }
        lock.withLock { onCompile = handler }
    }

    static func stop() {
        lock.withLock { onCompile = nil }
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
            guard lock.withLock({ onCompile != nil }), let text = copyMessage(message) else {
                return
            }
            defer { free(text) }
            let line = String(cString: text)
            guard line.contains(cacheMissMarker), line.contains(cacheMissValue) else { return }
            let handler = lock.withLock { () -> (() -> Void)? in
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
