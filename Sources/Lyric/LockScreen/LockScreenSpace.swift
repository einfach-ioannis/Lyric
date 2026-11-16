import AppKit

/// Puts windows into a private window-server space that is drawn above the lock screen.
///
/// macOS has no public API for this. SkyLight's space functions are looked up at runtime, so
/// when a future macOS removes or renames them the feature simply turns itself off instead of
/// crashing. No entitlement is needed.
final class LockScreenSpace {
    private typealias MainConnectionID = @convention(c) () -> Int32
    private typealias SpaceCreate = @convention(c) (Int32, Int32, Int32) -> UInt64
    private typealias SpaceDestroy = @convention(c) (Int32, UInt64) -> Int32
    private typealias SpaceSetAbsoluteLevel = @convention(c) (Int32, UInt64, Int32) -> Int32
    private typealias ShowSpaces = @convention(c) (Int32, CFArray) -> Int32
    private typealias HideSpaces = @convention(c) (Int32, CFArray) -> Int32
    private typealias AddWindowsToSpace = @convention(c) (Int32, UInt64, CFArray, Int32) -> Int32
    private typealias RemoveWindowsFromSpaces = @convention(c) (Int32, CFArray, CFArray) -> Int32

    private nonisolated struct Functions: Sendable {
        let mainConnectionID: MainConnectionID
        let spaceCreate: SpaceCreate
        let spaceDestroy: SpaceDestroy
        let setAbsoluteLevel: SpaceSetAbsoluteLevel
        let showSpaces: ShowSpaces
        let hideSpaces: HideSpaces
        let addWindows: AddWindowsToSpace
        let removeWindows: RemoveWindowsFromSpaces
    }

    /// The level macOS uses for notifications on the lock screen: above the lock screen
    /// itself (300), below boot progress and VoiceOver.
    private static let lockScreenLevel: Int32 = 400

    private static let functions: Functions? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) else {
            return nil
        }
        func load<T>(_ name: String, as type: T.Type) -> T? {
            guard let symbol = dlsym(handle, name) else { return nil }
            return unsafeBitCast(symbol, to: type)
        }
        guard let mainConnectionID = load("SLSMainConnectionID", as: MainConnectionID.self),
              let spaceCreate = load("SLSSpaceCreate", as: SpaceCreate.self),
              let spaceDestroy = load("SLSSpaceDestroy", as: SpaceDestroy.self),
              let setAbsoluteLevel = load("SLSSpaceSetAbsoluteLevel", as: SpaceSetAbsoluteLevel.self),
              let showSpaces = load("SLSShowSpaces", as: ShowSpaces.self),
              let hideSpaces = load("SLSHideSpaces", as: HideSpaces.self),
              let addWindows = load("SLSSpaceAddWindowsAndRemoveFromSpaces", as: AddWindowsToSpace.self),
              let removeWindows = load("SLSRemoveWindowsFromSpaces", as: RemoveWindowsFromSpaces.self)
        else { return nil }
        return Functions(
            mainConnectionID: mainConnectionID,
            spaceCreate: spaceCreate,
            spaceDestroy: spaceDestroy,
            setAbsoluteLevel: setAbsoluteLevel,
            showSpaces: showSpaces,
            hideSpaces: hideSpaces,
            addWindows: addWindows,
            removeWindows: removeWindows
        )
    }()

    /// Whether this macOS still offers what the lock screen player needs.
    static var isAvailable: Bool { functions != nil }

    private let functions: Functions
    private let connection: Int32
    private let space: UInt64

    init?() {
        guard let functions = Self.functions else { return nil }
        let connection = functions.mainConnectionID()
        let space = functions.spaceCreate(connection, 1, 0)
        guard space != 0 else { return nil }
        _ = functions.setAbsoluteLevel(connection, space, Self.lockScreenLevel)
        _ = functions.showSpaces(connection, [NSNumber(value: space)] as CFArray)
        self.functions = functions
        self.connection = connection
        self.space = space
    }

    deinit {
        _ = functions.hideSpaces(connection, [NSNumber(value: space)] as CFArray)
        _ = functions.spaceDestroy(connection, space)
    }

    func add(_ window: NSWindow) {
        // 7 = remove the window from every other space it was in.
        _ = functions.addWindows(connection, space, [window.windowNumber] as CFArray, 7)
    }

    func remove(_ window: NSWindow) {
        _ = functions.removeWindows(connection, [window.windowNumber] as CFArray, [NSNumber(value: space)] as CFArray)
    }
}
