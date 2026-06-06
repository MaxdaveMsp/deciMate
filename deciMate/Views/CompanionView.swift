import SwiftUI

struct CompanionView: View {
    let state: CompanionState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                AmbientRings(state: state, isAnimating: isAnimating && !reduceMotion)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 116, height: 116)
                    .overlay(
                        Circle()
                            .strokeBorder(state.color.opacity(0.32), lineWidth: 1.5)
                    )
                    .shadow(color: state.color.opacity(0.18), radius: 18, y: 8)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 78)
                    .opacity(0.92)
                    .scaleEffect(isAnimating && !reduceMotion ? state.logoScale : 1.0)
                    .animation(state.logoAnimation, value: isAnimating)

                StatusBadge(state: state)
                    .offset(x: 42, y: -42)
            }
            .frame(height: 148)

            VStack(spacing: 5) {
                Text(state.message)
                    .font(.headline.weight(.semibold))

                Text(state.detailMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            LevelActivityBars(state: state, isAnimating: isAnimating && !reduceMotion)
                .frame(height: 24)
                .padding(.top, 2)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(state.color.opacity(0.22), lineWidth: 1)
                )
        )
        .onAppear { isAnimating = true }
        .onChange(of: state) { _, _ in
            isAnimating = false
            DispatchQueue.main.async { isAnimating = true }
        }
    }
}

private struct AmbientRings: View {
    let state: CompanionState
    let isAnimating: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(state.color.opacity(0.22 - Double(index) * 0.045), lineWidth: 1.6)
                    .frame(width: 104 + CGFloat(index * 20), height: 104 + CGFloat(index * 20))
                    .scaleEffect(isAnimating ? state.ringScale + CGFloat(index) * 0.025 : 0.98)
                    .opacity(isAnimating ? 0.28 : 0.58)
                    .animation(
                        .easeInOut(duration: state.ringDuration + Double(index) * 0.18)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.08),
                        value: isAnimating
                    )
            }
        }
    }
}

private struct StatusBadge: View {
    let state: CompanionState

    var body: some View {
        Image(systemName: state.symbolName)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(state.color.gradient, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
            .shadow(color: state.color.opacity(0.28), radius: 10, y: 5)
    }
}

private struct LevelActivityBars: View {
    let state: CompanionState
    let isAnimating: Bool

    private let heights: [CGFloat] = [0.36, 0.66, 0.48, 0.86, 0.54, 0.74, 0.42]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(heights.indices, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(state.color.opacity(0.72))
                    .frame(width: 5, height: 22 * heights[index])
                    .scaleEffect(y: isAnimating ? state.barScale(for: index) : 0.72, anchor: .center)
                    .animation(
                        .easeInOut(duration: state.barDuration(for: index))
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .opacity(state == .idle ? 0.45 : 0.95)
    }
}

private extension CompanionState {
    var symbolName: String {
        switch self {
        case .idle: "waveform"
        case .focused: "checkmark.circle.fill"
        case .worried: "exclamationmark.triangle.fill"
        case .alarmed: "exclamationmark.octagon.fill"
        case .peak: "bolt.circle.fill"
        }
    }

    var detailMessage: String {
        switch self {
        case .idle: "Microphone standby"
        case .focused: "Clean headroom for practical monitoring"
        case .worried: "Watch the warning threshold"
        case .alarmed: "Reduce level or increase distance"
        case .peak: "Short high-energy event detected"
        }
    }

    var ringScale: CGFloat {
        switch self {
        case .idle: 1.015
        case .focused: 1.035
        case .worried: 1.055
        case .alarmed: 1.075
        case .peak: 1.095
        }
    }

    var ringDuration: Double {
        switch self {
        case .idle: 2.4
        case .focused: 2.0
        case .worried: 1.55
        case .alarmed: 1.15
        case .peak: 0.82
        }
    }

    var logoScale: CGFloat {
        switch self {
        case .idle, .focused: 1.012
        case .worried: 1.018
        case .alarmed: 1.024
        case .peak: 1.032
        }
    }

    var logoAnimation: Animation {
        .easeInOut(duration: self == .peak ? 0.75 : 1.8).repeatForever(autoreverses: true)
    }

    func barScale(for index: Int) -> CGFloat {
        let energy: CGFloat
        switch self {
        case .idle: energy = 0.78
        case .focused: energy = 0.92
        case .worried: energy = 1.08
        case .alarmed: energy = 1.22
        case .peak: energy = 1.38
        }
        return energy + CGFloat(index % 3) * 0.06
    }

    func barDuration(for index: Int) -> Double {
        let base: Double
        switch self {
        case .idle: base = 1.35
        case .focused: base = 1.1
        case .worried: base = 0.82
        case .alarmed: base = 0.62
        case .peak: base = 0.42
        }
        return base + Double(index) * 0.035
    }
}

#Preview {
    VStack(spacing: 20) {
        CompanionView(state: .focused)
        CompanionView(state: .peak)
    }
    .padding()
}
