import SwiftUI

// MARK: - CompanionView
// Clean status panel for deciMate. No mascot, no face, no EQ-bar character.
// The motion language is now professional: subtle rings, SPL status color, and a compact live indicator.

struct CompanionView: View {
    let state: CompanionState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                StatusRings(state: state, isAnimating: isAnimating && !reduceMotion)

                Circle()
                    .fill(Color(red: 0.07, green: 0.10, blue: 0.16))
                    .frame(width: 108, height: 108)
                    .overlay(
                        Circle()
                            .strokeBorder(state.accentColor.opacity(0.32), lineWidth: 1.2)
                    )
                    .shadow(color: state.accentColor.opacity(0.18), radius: 18, y: 8)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)
                    .scaleEffect(isAnimating && !reduceMotion ? state.logoPulseScale : 1.0)
                    .animation(state.logoAnimation, value: isAnimating)

                Circle()
                    .fill(state.accentColor)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1))
                    .shadow(color: state.accentColor.opacity(0.8), radius: 6)
                    .offset(x: 42, y: -42)
            }
            .frame(height: 130)

            VStack(spacing: 5) {
                Text(state.message)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.opacity)

                Text(state.detailMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
            }

            StatusPill(state: state)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
        .shadow(color: state.accentColor.opacity(0.12), radius: 22, y: 8)
        .onAppear { isAnimating = true }
        .onChange(of: state) { _, _ in
            isAnimating = false
            DispatchQueue.main.async { isAnimating = true }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color(red: 0.09, green: 0.11, blue: 0.17))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [state.accentColor.opacity(0.34), state.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

private struct StatusRings: View {
    let state: CompanionState
    let isAnimating: Bool

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(state.accentColor.opacity(0.20 - Double(index) * 0.045), lineWidth: 1.4)
                    .frame(width: 104 + CGFloat(index * 18), height: 104 + CGFloat(index * 18))
                    .scaleEffect(isAnimating ? state.ringScale + CGFloat(index) * 0.018 : 0.98)
                    .opacity(isAnimating ? 0.28 : 0.56)
                    .animation(
                        .easeInOut(duration: state.ringDuration + Double(index) * 0.14)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.06),
                        value: isAnimating
                    )
            }
        }
    }
}

private struct StatusPill: View {
    let state: CompanionState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: state.symbolName)
                .font(.system(size: 12, weight: .bold))
            Text(state.statusLabel)
                .font(.system(.caption, design: .rounded, weight: .semibold))
        }
        .foregroundStyle(state.accentColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(state.accentColor.opacity(0.12), in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).strokeBorder(state.accentColor.opacity(0.22), lineWidth: 1))
    }
}

private extension CompanionState {
    var detailMessage: String {
        switch self {
        case .idle:    return "Tap Start to begin monitoring"
        case .focused: return "Levels are within practical range"
        case .worried: return "Approaching the warning threshold"
        case .alarmed: return "Reduce level or increase distance"
        case .peak:    return "Short high-energy event detected"
        }
    }

    var statusLabel: String {
        switch self {
        case .idle:    return "STANDBY"
        case .focused: return "SAFE"
        case .worried: return "WARNING"
        case .alarmed: return "CRITICAL"
        case .peak:    return "PEAK"
        }
    }

    var symbolName: String {
        switch self {
        case .idle:    return "waveform"
        case .focused: return "checkmark.circle.fill"
        case .worried: return "exclamationmark.triangle.fill"
        case .alarmed: return "exclamationmark.octagon.fill"
        case .peak:    return "bolt.circle.fill"
        }
    }

    var ringScale: CGFloat {
        switch self {
        case .idle:    return 1.010
        case .focused: return 1.025
        case .worried: return 1.045
        case .alarmed: return 1.065
        case .peak:    return 1.085
        }
    }

    var ringDuration: Double {
        switch self {
        case .idle:    return 2.4
        case .focused: return 2.0
        case .worried: return 1.5
        case .alarmed: return 1.1
        case .peak:    return 0.8
        }
    }

    var logoPulseScale: CGFloat {
        switch self {
        case .idle, .focused: return 1.010
        case .worried: return 1.016
        case .alarmed: return 1.022
        case .peak: return 1.030
        }
    }

    var logoAnimation: Animation {
        .easeInOut(duration: self == .peak ? 0.75 : 1.8).repeatForever(autoreverses: true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            ForEach([CompanionState.idle, .focused, .worried, .alarmed, .peak], id: \.message) { state in
                CompanionView(state: state)
            }
        }
        .padding(16)
    }
    .background(Color(red: 0.05, green: 0.07, blue: 0.11).ignoresSafeArea())
}
