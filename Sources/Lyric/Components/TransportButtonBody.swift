import SwiftUI

/// Circular hover highlight with a gentle press-down, as in Control Center.
struct TransportButtonBody: View {
    let configuration: ButtonStyleConfiguration
    @State private var isHovering = false

    var body: some View {
        configuration.label
            .frame(minWidth: 36, minHeight: 36)
            .contentShape(.circle)
            .background {
                Circle()
                    .fill(.white.opacity(0.1))
                    .opacity(isHovering ? 1 : 0)
            }
            .scaleEffect(configuration.isPressed ? 0.86 : 1)
            .animation(Theme.Motion.quick, value: configuration.isPressed)
            .animation(Theme.Motion.quick, value: isHovering)
            .onHover { isHovering = $0 }
    }
}
