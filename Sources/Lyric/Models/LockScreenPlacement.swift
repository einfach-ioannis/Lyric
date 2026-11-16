import Foundation

/// Where the lock screen card sits. Every option stays clear of the password field.
nonisolated enum LockScreenPlacement: String, CaseIterable, Identifiable, Sendable {
    case belowClock
    case left
    case right

    var id: Self { self }

    var localizedName: String {
        switch self {
        case .belowClock: String(localized: "Below the Clock")
        case .left: String(localized: "Left")
        case .right: String(localized: "Right")
        }
    }
}
