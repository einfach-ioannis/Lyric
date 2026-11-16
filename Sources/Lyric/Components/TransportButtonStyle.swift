import SwiftUI

struct TransportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        TransportButtonBody(configuration: configuration)
    }
}
