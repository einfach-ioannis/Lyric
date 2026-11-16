import SwiftUI

/// A softly filled card that brightens on hover and presses down slightly.
struct CardButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovering = false

    var body: some View {
        configuration.label
            .background(
                isHovering ? AnyShapeStyle(.white.opacity(0.14)) : AnyShapeStyle(.white.opacity(0.07)),
                in: .rect(cornerRadius: 14)
            )
            .contentShape(.rect(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Theme.Motion.quick, value: configuration.isPressed)
            .animation(Theme.Motion.quick, value: isHovering)
            .onHover { isHovering = $0 }
    }
}
