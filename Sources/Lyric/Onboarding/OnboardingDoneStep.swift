import SwiftUI

struct OnboardingDoneStep: View {
    var body: some View {
        OnboardingHeader(
            systemImage: "checkmark.circle",
            title: "You’re All Set",
            subtitle: "Click Lyric in the menu bar to see the player and lyrics."
        )
    }
}
