import Foundation

nonisolated struct ScriptError: Error, Sendable {
    let code: Int

    /// `errAEEventNotPermitted`: the person declined Automation access in Privacy & Security.
    var isPermissionDenied: Bool { code == -1743 }
}
