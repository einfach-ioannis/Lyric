import SwiftUI

struct OnboardingFooter: View {
    let step: OnboardingStep
    let onBack: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button("Back", action: onBack)
                .opacity(step.previous == nil ? 0 : 1)
                .disabled(step.previous == nil)

            Spacer()

            HStack(spacing: Theme.Spacing.compact) {
                ForEach(OnboardingStep.allCases) { item in
                    Circle()
                        .fill(item == step ? AnyShapeStyle(.primary) : AnyShapeStyle(.quaternary))
                        .frame(width: 6, height: 6)
                }
            }
            .accessibilityHidden(true)

            Spacer()

            Button(step.next == nil ? LocalizedStringKey("Get Started") : "Continue", action: onNext)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .controlSize(.large)
        .padding(Theme.Spacing.extraLarge)
    }
}
