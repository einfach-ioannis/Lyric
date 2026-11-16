import AppKit

/// Compiles and runs AppleScript sources, caching each compiled script by its text.
///
/// Talking to a player takes 100–200 ms, far too long for the main thread, so every script
/// runs on one shared serial queue: the interface never waits, and no compiled script is
/// ever used from two threads at once. Each caller still wraps its script in a short
/// `with timeout`, so a hung player only holds up the queue briefly.
nonisolated final class AppleScriptRunner: @unchecked Sendable {
    /// What a script returned, copied out of its descriptor so it can cross threads.
    struct Output: Sendable {
        let string: String?
        let data: Data
    }

    private static let queue = DispatchQueue(label: "lyric.applescript", qos: .userInitiated)

    /// Only touched on `queue`.
    private var compiledScripts: [String: NSAppleScript] = [:]
    /// Scripts whose text varies with a value (seek, volume) would otherwise grow the cache forever.
    private let cacheLimit = 64

    /// Runs the script off the main thread and returns its result.
    func run(_ source: String) async -> Result<Output, ScriptError> {
        await withCheckedContinuation { continuation in
            Self.queue.async {
                continuation.resume(returning: self.execute(source))
            }
        }
    }

    /// Queues the script without waiting for it. Scripts run in the order they're queued.
    func enqueue(_ source: String) {
        Self.queue.async {
            _ = self.execute(source)
        }
    }

    /// Runs the script and waits for it. Only for rare, on-demand reads.
    func runAndWait(_ source: String) -> Result<Output, ScriptError> {
        Self.queue.sync { execute(source) }
    }

    private func execute(_ source: String) -> Result<Output, ScriptError> {
        let script: NSAppleScript
        if let cached = compiledScripts[source] {
            script = cached
        } else if let created = NSAppleScript(source: source) {
            if compiledScripts.count >= cacheLimit {
                compiledScripts.removeAll(keepingCapacity: true)
            }
            compiledScripts[source] = created
            script = created
        } else {
            return .failure(ScriptError(code: 0))
        }

        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let code = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            return .failure(ScriptError(code: code))
        }
        return .success(Output(string: result.stringValue, data: result.data))
    }
}
