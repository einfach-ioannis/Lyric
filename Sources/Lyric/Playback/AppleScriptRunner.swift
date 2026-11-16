import AppKit

/// Compiles and runs AppleScript sources, caching each compiled script by its text.
///
/// `NSAppleScript` is only safe on the main thread, so every caller wraps its script in a
/// short `with timeout` to keep a hung player from stalling the interface.
final class AppleScriptRunner {
    private var compiledScripts: [String: NSAppleScript] = [:]
    /// Scripts whose text varies with a value (seek, volume) would otherwise grow the cache forever.
    private let cacheLimit = 64

    func run(_ source: String) -> Result<NSAppleEventDescriptor, ScriptError> {
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
        return .success(result)
    }
}
