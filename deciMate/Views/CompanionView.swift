import SwiftUI

// MARK: - CompanionView
// deciMate's original mascot. Inspired by Taby but audio-native:
//  Body  → tall rounded pill, like a standing mic capsule
//  Ears  → three tiny sound bars on each side, animated to the state
//  Face  → minimal white eyes on dark body — shape alone tells the emotion
//  Top   → single glowing signal dot (the "on air" LED)

struct CompanionView: View {
    let state: CompanionState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isAnimating = false
    @State private var blinkOpen   = true
    @State private var floatY: CGFloat = 0
    @State private var shakeX: CGFloat = 0
    @State private var squishX: CGFloat = 1
    @State private var squishY: CGFloat = 1

    var body: some View {
        VStack(spacing: 14) {

            // ── Character ────────────────────────────────────────────────
            ZStack(alignment: .bottom) {
                // Ground glow
                Ellipse()
                    .fill(state.accentColor.opacity(0.20))
                    .blur(radius: 18)
                    .frame(width: 80, height: 10)
                    .scaleEffect(x: isAnimating ? 0.78 : 1.0)
                    .animation(
                        .easeInOut(duration: state.floatDuration)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                DeciMascot(state: state, blinkOpen: blinkOpen, isAnimating: isAnimating && !reduceMotion)
                    .frame(width: 110, height: 118)
                    .scaleEffect(x: squishX, y: squishY, anchor: .bottom)
                    .offset(x: reduceMotion ? 0 : shakeX,
                            y: reduceMotion ? 0 : floatY)
            }
            .frame(height: 132)

            // ── Message ──────────────────────────────────────────────────
            VStack(spacing: 4) {
                Text(state.message)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: state)

                Text(state.detailMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: state)
            }

            // ── EQ bars ──────────────────────────────────────────────────
            EQLevelBars(state: state, isAnimating: isAnimating && !reduceMotion)
                .frame(height: 24)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(cardBG)
        .shadow(color: state.accentColor.opacity(0.14), radius: 24, y: 8)
        .onAppear {
            isAnimating = true
            startFloat()
            scheduleBlink()
        }
        .onChange(of: state) { _, newState in
            bounce()
            if newState == .peak { shake() }
            floatY = 0; isAnimating = false
            DispatchQueue.main.async { isAnimating = true; startFloat() }
        }
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color(red: 0.09, green: 0.11, blue: 0.17))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [state.accentColor.opacity(0.40), state.accentColor.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ), lineWidth: 1.0
                    )
            )
    }

    private func startFloat() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: state.floatDuration).repeatForever(autoreverses: true)) {
            floatY = -7
        }
    }

    private func scheduleBlink() {
        guard !reduceMotion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...5.5)) {
            withAnimation(.easeInOut(duration: 0.06)) { blinkOpen = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                withAnimation(.easeInOut(duration: 0.06)) { blinkOpen = true }
                scheduleBlink()
            }
        }
    }

    private func bounce() {
        withAnimation(.spring(response: 0.15, dampingFraction: 0.36)) {
            squishX = 1.15; squishY = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.38)) {
                squishX = 0.88; squishY = 1.14
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.55)) {
                    squishX = 1.0; squishY = 1.0
                }
            }
        }
    }

    private func shake() {
        guard !reduceMotion else { return }
        for (i, v) in [9.0, -9.0, 6.0, -6.0, 3.0, 0.0].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                withAnimation(.easeInOut(duration: 0.045)) { shakeX = v }
            }
        }
    }
}

// MARK: - DeciMascot
// The full character assembly: pill body + sound-bar ears + face + signal dot.

private struct DeciMascot: View {
    let state: CompanionState
    let blinkOpen: Bool
    let isAnimating: Bool

    var body: some View {
        ZStack {
            // Left sound-bar ear
            SoundBarEar(state: state, isAnimating: isAnimating, mirrored: false)
                .offset(x: -52, y: 8)

            // Right sound-bar ear
            SoundBarEar(state: state, isAnimating: isAnimating, mirrored: true)
                .offset(x: 52, y: 8)

            // Body — tall mic-capsule pill
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [bodyColor, bodyColor.opacity(0.80)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    // Top gloss sheen
                    LinearGradient(
                        colors: [.white.opacity(0.12), .clear],
                        startPoint: .top, endPoint: .center
                    )
                    .clipShape(Capsule(style: .continuous))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(.white.opacity(0.09), lineWidth: 1)
                )
                .frame(width: 86, height: 104)

            // Face drawn on body
            FaceCanvas(state: state, blinkOpen: blinkOpen)
                .frame(width: 66, height: 54)
                .offset(y: 4)

            // Signal dot — top center, glows in accent color
            SignalDot(color: state.accentColor)
                .offset(y: -48)
        }
    }

    private var bodyColor: Color {
        switch state {
        case .idle:    return Color(red: 0.14, green: 0.16, blue: 0.24)
        case .focused: return Color(red: 0.11, green: 0.17, blue: 0.20)
        case .worried: return Color(red: 0.18, green: 0.15, blue: 0.09)
        case .alarmed: return Color(red: 0.20, green: 0.12, blue: 0.08)
        case .peak:    return Color(red: 0.18, green: 0.09, blue: 0.09)
        }
    }
}

// MARK: - Sound Bar Ear
// Three tiny capsule bars on each side — a mini EQ column.

private struct SoundBarEar: View {
    let state: CompanionState
    let isAnimating: Bool
    let mirrored: Bool

    private let heights: [CGFloat] = [10, 16, 22]
    private let delays:  [Double]  = [0.0, 0.08, 0.16]

    var body: some View {
        let orderedHeights = mirrored ? heights.reversed() : heights
        HStack(spacing: 3) {
            ForEach(orderedHeights.indices, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 3, height: orderedHeights[i])
                    .scaleEffect(y: isAnimating ? earScale(i) : 0.5, anchor: .center)
                    .animation(
                        .easeInOut(duration: earDuration)
                            .repeatForever(autoreverses: true)
                            .delay(delays[i]),
                        value: isAnimating
                    )
            }
        }
    }

    private func earScale(_ i: Int) -> CGFloat {
        let base: CGFloat
        switch state {
        case .idle:    base = 0.55
        case .focused: base = 0.75
        case .worried: base = 1.05
        case .alarmed: base = 1.30
        case .peak:    base = 1.55
        }
        return base + CGFloat(i) * 0.08
    }

    private var earDuration: Double {
        switch state {
        case .idle:    return 1.6
        case .focused: return 1.3
        case .worried: return 0.9
        case .alarmed: return 0.6
        case .peak:    return 0.32
        }
    }
}

// MARK: - Signal Dot

private struct SignalDot: View {
    let color: Color
    @State private var pulse: CGFloat = 0.6

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(Double(pulse) * 0.45))
                .blur(radius: 6)
                .frame(width: 16, height: 16)
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color, radius: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = 1.0
            }
        }
    }
}

// MARK: - Face Canvas
// All white. No color. Eye SHAPE is the entire emotional vocabulary.
// Idle mouth = ∿ waveform squiggle (deciMate's signature detail).

private struct FaceCanvas: View {
    let state: CompanionState
    let blinkOpen: Bool

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let cx = w / 2, cy = h / 2

            let eyeSpacing: CGFloat = 18
            let lx = cx - eyeSpacing
            let rx = cx + eyeSpacing
            let eyeY = cy - 6

            let (eW, eH, eR) = eyeDimensions

            // Eyebrows (worried / alarmed / peak only)
            drawBrows(ctx: ctx, lx: lx, rx: rx, eyeY: eyeY)

            // Eyes
            let eyeH = blinkOpen ? eH : CGFloat(3)
            let leftRect  = CGRect(x: lx - eW/2, y: eyeY - eyeH/2, width: eW, height: eyeH)
            let rightRect = CGRect(x: rx - eW/2, y: eyeY - eyeH/2, width: eW, height: eyeH)
            ctx.fill(Path(roundedRect: leftRect,  cornerRadius: eR, style: .continuous), with: .color(.white))
            ctx.fill(Path(roundedRect: rightRect, cornerRadius: eR, style: .continuous), with: .color(.white))

            // X eyes on peak
            if state == .peak && blinkOpen {
                drawX(ctx: ctx, center: CGPoint(x: lx, y: eyeY), size: eW * 0.7)
                drawX(ctx: ctx, center: CGPoint(x: rx, y: eyeY), size: eW * 0.7)
            }

            // Mouth
            drawMouth(ctx: ctx, cx: cx, cy: cy)
        }
    }

    private var eyeDimensions: (CGFloat, CGFloat, CGFloat) {
        switch state {
        case .idle:    return (20, 16, 8)
        case .focused: return (22, 18, 9)
        case .worried: return (18, 12, 6)
        case .alarmed: return (22, 20, 10)
        case .peak:    return (20, 16, 8)
        }
    }

    private func drawBrows(ctx: GraphicsContext, lx: CGFloat, rx: CGFloat, eyeY: CGFloat) {
        guard state == .worried || state == .alarmed || state == .peak else { return }
        let angle: CGFloat = state == .worried ? 12 : 20
        let browY = eyeY - 14
        let browW: CGFloat = 16
        func brow(cx: CGFloat, flipY: Bool) {
            let dx = browW / 2 * cos(angle * .pi / 180)
            let dy = browW / 2 * sin(angle * .pi / 180)
            var p = Path()
            p.move(to: CGPoint(x: cx - dx, y: browY + (flipY ? -dy : dy)))
            p.addLine(to: CGPoint(x: cx + dx, y: browY + (flipY ? dy : -dy)))
            ctx.stroke(p, with: .color(.white.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
        brow(cx: lx, flipY: false)
        brow(cx: rx, flipY: true)
    }

    private func drawX(ctx: GraphicsContext, center: CGPoint, size: CGFloat) {
        let h = size / 2
        let bodyDark = Color(red: 0.14, green: 0.16, blue: 0.24)
        for pts in [
            (CGPoint(x: center.x - h, y: center.y - h), CGPoint(x: center.x + h, y: center.y + h)),
            (CGPoint(x: center.x + h, y: center.y - h), CGPoint(x: center.x - h, y: center.y + h))
        ] {
            var p = Path()
            p.move(to: pts.0); p.addLine(to: pts.1)
            ctx.stroke(p, with: .color(bodyDark), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }

    private func drawMouth(ctx: GraphicsContext, cx: CGFloat, cy: CGFloat) {
        let mY = cy + 13
        var path = Path()

        switch state {
        case .idle:
            // ∿ waveform squiggle — deciMate's signature idle face
            let mW: CGFloat = 26, x0 = cx - mW / 2
            path.move(to: CGPoint(x: x0, y: mY))
            path.addCurve(
                to: CGPoint(x: x0 + mW * 0.5, y: mY),
                control1: CGPoint(x: x0 + mW * 0.15, y: mY - 5),
                control2: CGPoint(x: x0 + mW * 0.35, y: mY + 5)
            )
            path.addCurve(
                to: CGPoint(x: x0 + mW, y: mY),
                control1: CGPoint(x: x0 + mW * 0.65, y: mY - 5),
                control2: CGPoint(x: x0 + mW * 0.85, y: mY + 5)
            )
            ctx.stroke(path, with: .color(.white.opacity(0.72)),
                       style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

        case .focused:
            let fw: CGFloat = 30
            path.move(to: CGPoint(x: cx - fw/2, y: mY - 1))
            path.addQuadCurve(to: CGPoint(x: cx + fw/2, y: mY - 1),
                              control: CGPoint(x: cx, y: mY + 12))
            ctx.stroke(path, with: .color(.white.opacity(0.90)),
                       style: StrokeStyle(lineWidth: 2.6, lineCap: .round))

        case .worried:
            let mW: CGFloat = 22
            path.move(to: CGPoint(x: cx - mW/2, y: mY + 6))
            path.addQuadCurve(to: CGPoint(x: cx + mW/2, y: mY + 6),
                              control: CGPoint(x: cx, y: mY - 1))
            ctx.stroke(path, with: .color(.white.opacity(0.80)),
                       style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

        case .alarmed:
            let oRect = CGRect(x: cx - 9, y: mY - 2, width: 18, height: 14)
            let op = Path(ellipseIn: oRect)
            ctx.fill(op, with: .color(.white.opacity(0.12)))
            ctx.stroke(op, with: .color(.white.opacity(0.82)),
                       style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

        case .peak:
            let oRect = CGRect(x: cx - 12, y: mY - 3, width: 24, height: 19)
            let op = Path(ellipseIn: oRect)
            ctx.fill(op, with: .color(.white.opacity(0.10)))
            ctx.stroke(op, with: .color(.white.opacity(0.88)),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            var teeth = Path()
            teeth.move(to: CGPoint(x: cx - 8, y: mY + 1))
            teeth.addLine(to: CGPoint(x: cx + 8, y: mY + 1))
            ctx.stroke(teeth, with: .color(.white.opacity(0.60)),
                       style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
        }
    }
}

// MARK: - EQ Level Bars

private struct EQLevelBars: View {
    let state: CompanionState
    let isAnimating: Bool
    private let baseH: [CGFloat] = [0.40, 0.65, 0.48, 0.88, 1.0, 0.82, 0.52, 0.68, 0.42]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(baseH.indices, id: \.self) { i in
                Capsule()
                    .fill(LinearGradient(
                        colors: [state.accentColor, state.accentColor.opacity(0.25)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 4, height: 24 * baseH[i])
                    .scaleEffect(y: isAnimating ? targetScale(i) : 0.45, anchor: .center)
                    .animation(
                        .easeInOut(duration: barDuration(i)).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .opacity(state == .idle ? 0.30 : 1.0)
        .animation(.easeInOut(duration: 0.35), value: state)
    }

    private func targetScale(_ i: Int) -> CGFloat {
        let e: CGFloat
        switch state {
        case .idle:    e = 0.55
        case .focused: e = 0.78
        case .worried: e = 1.05
        case .alarmed: e = 1.30
        case .peak:    e = 1.60
        }
        return e + (i % 2 == 0 ? 0.07 : -0.05) + CGFloat(i % 3) * 0.03
    }

    private func barDuration(_ i: Int) -> Double {
        let b: Double
        switch state {
        case .idle:    b = 1.50
        case .focused: b = 1.20
        case .worried: b = 0.85
        case .alarmed: b = 0.58
        case .peak:    b = 0.28
        }
        return b + Double(i) * 0.02
    }
}

// MARK: - CompanionState extensions (private to this file)

private extension CompanionState {
    var floatDuration: Double {
        switch self {
        case .idle:    return 2.8
        case .focused: return 2.2
        case .worried: return 1.7
        case .alarmed: return 1.1
        case .peak:    return 0.6
        }
    }

    var detailMessage: String {
        switch self {
        case .idle:    return "Tap Start to begin"
        case .focused: return "Levels sound great!"
        case .worried: return "Watch the threshold"
        case .alarmed: return "Reduce level or distance"
        case .peak:    return "High-energy burst!"
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 14) {
            ForEach([CompanionState.idle, .focused, .worried, .alarmed, .peak], id: \.message) { s in
                CompanionView(state: s)
            }
        }
        .padding(16)
    }
    .background(Color(red: 0.05, green: 0.07, blue: 0.11).ignoresSafeArea())
}
