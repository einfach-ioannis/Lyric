import SwiftUI

struct PlayPauseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 38))
            .foregroundStyle(.white)
            .frame(width: Theme.Popover.playButtonSize, height: Theme.Popover.playButtonSize)
            .contentShape(.circle)
            .scaleEffect(configuration.isPressed ? Theme.Motion.pressedScale : 1)
            .animation(Theme.Motion.quick, value: configuration.isPressed)
    }
}
