import SwiftUI

/// Compact, monochrome buttons sized for the menu bar.
struct MenuBarControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout)
            .frame(width: Theme.MenuBar.controlSize, height: Theme.MenuBar.controlSize)
            .contentShape(.rect)
            .foregroundStyle(configuration.isPressed ? HierarchicalShapeStyle.secondary : .primary)
    }
}
