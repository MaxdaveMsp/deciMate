import SwiftUI

struct CompanionView: View {
    let state: CompanionState
    @State private var pulse = false
    @State private var bob = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(state.color.opacity(0.22)).frame(width: 136, height: 136).scaleEffect(pulse ? 1.12 : 0.92)
                Image("Logo").resizable().scaledToFit().frame(width: 106, height: 106)
                    .rotationEffect(.degrees(state == .peak ? (bob ? -7 : 7) : 0))
                    .offset(y: bob ? -5 : 5)
                Text(state.emoji).font(.system(size: 46)).offset(y: 2).opacity(0.95)
            }
            Text(state.message).font(.headline)
        }
        .padding().frame(maxWidth: .infinity)
        .background(state.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 28))
        .onAppear { startAnimations() }
        .onChange(of: state) { _, _ in startAnimations() }
    }
    private func startAnimations() {
        withAnimation(.easeInOut(duration: state == .peak ? 0.28 : 1.2).repeatForever(autoreverses: true)) { pulse.toggle(); bob.toggle() }
    }
}
