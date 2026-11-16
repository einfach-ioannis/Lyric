import Foundation

/// Which side of the lock screen the player card sits on, clear of the clock and password field.
nonisolated enum LockScreenPlacement: String, CaseIterable, Identifiable, Sendable {
    case left
    case right

    var id: Self { self }

    var localizedName: String {
        switch self {
        case .left: String(localized: "Left")
        case .right: String(localized: "Right")
        }
    }
}
