import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step = OnboardingStep.welcome

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch step {
                case .welcome: OnboardingWelcomeStep()
                case .access: OnboardingAccessStep()
                case .menuBar: OnboardingMenuBarStep()
                case .spotify: OnboardingSpotifyStep()
                case .done: OnboardingDoneStep()
                }
            }
            .id(step)
            .transition(.push(from: .trailing))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, Theme.Spacing.extraLarge * 2)
            .padding(.top, Theme.Spacing.extraLarge * 2)

            OnboardingFooter(step: step, onBack: goBack, onNext: goNext)
        }
        .frame(width: 520, height: 480)
    }

    private func goBack() {
        guard let previous = step.previous else { return }
        withAnimation(.smooth) { step = previous }
    }

    private func goNext() {
        if let next = step.next {
            withAnimation(.smooth) { step = next }
        } else {
            onFinish()
        }
    }
}
