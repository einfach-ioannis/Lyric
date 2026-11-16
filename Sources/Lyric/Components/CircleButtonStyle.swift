import SwiftUI

/// A small filled circle behind an icon, like the heart button in the mockup.
struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: Theme.Popover.circleButtonSize, height: Theme.Popover.circleButtonSize)
            .background(.white.opacity(0.12), in: .circle)
            .contentShape(.circle)
            .scaleEffect(configuration.isPressed ? Theme.Motion.pressedScale : 1)
            .animation(Theme.Motion.quick, value: configuration.isPressed)
    }
}
