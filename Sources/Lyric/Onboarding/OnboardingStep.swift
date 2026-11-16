import Foundation

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case access
    case menuBar
    case spotify
    case done

    var id: Self { self }

    var next: OnboardingStep? { OnboardingStep(rawValue: rawValue + 1) }
    var previous: OnboardingStep? { OnboardingStep(rawValue: rawValue - 1) }
}
