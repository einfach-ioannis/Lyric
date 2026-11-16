import SwiftUI

/// The current lyric line, pushed up gently as the song moves on.
struct MenuBarLyricText: View {
    let text: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Text(text)
                .id(text)
                .transition(reduceMotion ? .opacity : .push(from: .bottom))
        }
        .clipped()
        .animation(Theme.Motion.menuBarLine, value: text)
    }
}
