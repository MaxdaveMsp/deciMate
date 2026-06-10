import SwiftUI

// MARK: - DeciMate Logo Mark
// A purpose-built SwiftUI view that IS the logo — used everywhere (nav bar, splash, icon).
// Design: dark pill/circle → three radiating sound-wave arcs on the left → bold "dB" letterform.
// No PNG required.

struct DeciMateLogo: View {
    let size: CGFloat
    var animated: Bool = false

    @State private var pulse: CGFloat = 0

    private var cyan: Color { Color(red: 0.20, green: 0.82, blue: 0.98) }
    private var blue: Color { Color(red: 0.16, green: 0.50, blue: 0.95) }

    var body: some View {
        Canvas { ctx, sz in
            let s = sz.width                      // square canvas
            let cx = s * 0.56                     // face center X (shifted right to leave room for arcs)
            let cy = s * 0.50

            // ── Background circle ──────────────────────────────────────────
            let bgPath = Path(ellipseIn: CGRect(x: 0, y: 0, width: s, height: s))
            ctx.fill(bgPath, with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.09, green: 0.12, blue: 0.20),
                    Color(red: 0.06, green: 0.08, blue: 0.14)
                ]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: s, y: s)
            ))

            // ── Sound-wave arcs (left side, 3 arcs) ───────────────────────
            let arcCx = s * 0.38
            let arcCy = cy
            let arcStartAngle = Angle.degrees(-52)
            let arcEndAngle   = Angle.degrees(52)
            let arcRadii: [CGFloat] = [s * 0.13, s * 0.20, s * 0.28]
            let arcAlphas: [CGFloat] = [1.0, 0.72, 0.45]
            let lineW = s * 0.055
            let cap = StrokeStyle(lineWidth: lineW, lineCap: .round)

            for (i, r) in arcRadii.enumerated() {
                var arc = Path()
                arc.addArc(
                    center: CGPoint(x: arcCx, y: arcCy),
                    radius: r,
                    startAngle: arcStartAngle,
                    endAngle: arcEndAngle,
                    clockwise: false
                )
                ctx.stroke(arc, with: .linearGradient(
                    Gradient(colors: [
                        cyan.opacity(Double(arcAlphas[i])),
                        blue.opacity(Double(arcAlphas[i]) * 0.7)
                    ]),
                    startPoint: CGPoint(x: arcCx - r, y: arcCy),
                    endPoint: CGPoint(x: arcCx + r, y: arcCy)
                ), style: cap)
            }

            // ── Center dot (mic/source point) ──────────────────────────────
            let dotR = s * 0.055
            let dot = Path(ellipseIn: CGRect(
                x: arcCx - dotR, y: arcCy - dotR,
                width: dotR * 2, height: dotR * 2
            ))
            ctx.fill(dot, with: .color(cyan))

            // ── "dB" letterform ────────────────────────────────────────────
            // Drawn as geometric paths for crispness at all sizes
            let letterScale = s / 100
            let lx = cx - 2 * letterScale   // left edge of 'd'
            let letterH = s * 0.42
            let letterTop = cy - letterH / 2
            let letterBot = cy + letterH / 2
            let stemW = s * 0.058
            let bowlR = letterH * 0.32

            // 'd' — vertical stem
            var dStem = Path()
            dStem.move(to: CGPoint(x: lx, y: letterTop))
            dStem.addLine(to: CGPoint(x: lx, y: letterBot))
            ctx.stroke(dStem, with: .color(Color.white.opacity(0.95)),
                       style: StrokeStyle(lineWidth: stemW, lineCap: .round))

            // 'd' — bowl (right side circle)
            let bowlCx = lx + bowlR + stemW * 0.3
            let bowlCy = cy + letterH * 0.02
            var dBowl = Path()
            dBowl.addArc(
                center: CGPoint(x: bowlCx, y: bowlCy),
                radius: bowlR,
                startAngle: .degrees(-10),
                endAngle: .degrees(370),
                clockwise: false
            )
            ctx.stroke(dBowl, with: .color(Color.white.opacity(0.95)),
                       style: StrokeStyle(lineWidth: stemW * 0.88, lineCap: .round))

            // gap — space between 'd' and 'B'
            let gap = s * 0.07
            let bx = lx + bowlR * 2 + stemW + gap

            // 'B' — vertical stem
            var bStem = Path()
            bStem.move(to: CGPoint(x: bx, y: letterTop))
            bStem.addLine(to: CGPoint(x: bx, y: letterBot))
            ctx.stroke(bStem, with: .color(Color.white.opacity(0.95)),
                       style: StrokeStyle(lineWidth: stemW, lineCap: .round))

            // 'B' — top bump
            let bumpH = letterH * 0.48
            let bumpR = bumpH * 0.38
            let topBumpCx = bx + bumpR * 0.9
            let topBumpCy = letterTop + bumpH * 0.5
            var topBump = Path()
            topBump.addArc(
                center: CGPoint(x: topBumpCx, y: topBumpCy),
                radius: bumpR,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: false
            )
            ctx.stroke(topBump, with: .color(Color.white.opacity(0.95)),
                       style: StrokeStyle(lineWidth: stemW * 0.82, lineCap: .round))

            // 'B' — bottom bump (slightly wider)
            let botBumpR = bumpR * 1.12
            let botBumpCx = bx + botBumpR * 0.85
            let botBumpCy = letterBot - bumpH * 0.5 + stemW * 0.1
            var botBump = Path()
            botBump.addArc(
                center: CGPoint(x: botBumpCx, y: botBumpCy),
                radius: botBumpR,
                startAngle: .degrees(-90),
                endAngle: .degrees(90),
                clockwise: false
            )
            ctx.stroke(botBump, with: .color(Color.white.opacity(0.95)),
                       style: StrokeStyle(lineWidth: stemW * 0.82, lineCap: .round))

            // ── Subtle cyan glow ring ──────────────────────────────────────
            let ring = Path(ellipseIn: CGRect(
                x: s * 0.03, y: s * 0.03,
                width: s * 0.94, height: s * 0.94
            ))
            ctx.stroke(ring, with: .linearGradient(
                Gradient(colors: [cyan.opacity(0.18), blue.opacity(0.06)]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: s, y: s)
            ), style: StrokeStyle(lineWidth: s * 0.018))
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(
            color: cyan.opacity(animated ? 0.50 + Double(pulse) * 0.20 : 0.30),
            radius: animated ? 10 + pulse * 6 : 6
        )
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = 1
            }
        }
    }
}

// MARK: - Preview

#Preview("Logo sizes") {
    ZStack {
        Color(red: 0.06, green: 0.08, blue: 0.13).ignoresSafeArea()
        HStack(spacing: 24) {
            DeciMateLogo(size: 44, animated: true)
            DeciMateLogo(size: 80, animated: true)
            DeciMateLogo(size: 120, animated: true)
        }
    }
}
