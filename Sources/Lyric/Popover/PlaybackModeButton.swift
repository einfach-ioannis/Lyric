import SwiftUI

/// Shuffle or repeat: tinted with the artwork accent while on, disabled while unknown.
struct PlaybackModeButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let isOn: Bool?
    let action: () -> Void

    @Environment(NowPlayingController.self) private var nowPlaying
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    private var isActive: Bool { isOn == true }

    var body: some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isActive ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color.white.opacity(0.45)))
            .background {
                if isActive {
                    Circle().fill(.white.opacity(0.16)).frame(width: 32, height: 32)
                }
            }
            .overlay(alignment: .bottom) {
                if isActive && differentiateWithoutColor {
                    Circle()
                        .fill(.primary)
                        .frame(width: Theme.Spacing.tight, height: Theme.Spacing.tight)
                }
            }
            .buttonStyle(TransportButtonStyle())
            .disabled(isOn == nil)
            .accessibilityValue(isActive ? Text("On") : Text("Off"))
            .help(title)
    }
}
