import SwiftUI

struct CompanionView: View {
    let state: CompanionState

    var body: some View {
        VStack(spacing: 8) {
            Text(state.emoji)
                .font(.system(size: 72))
                .scaleEffect(state == .peak ? 1.15 : 1.0)
                .animation(.spring, value: state)
            Text(state.message)
                .font(.headline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(state.color.opacity(0.18), in: RoundedRectangle(cornerRadius: 28))
    }
}
