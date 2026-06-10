import SwiftUI
import Charts

// MARK: - Brand Colors (single source of truth)
private extension Color {
    static let dmCyan  = Color(red: 0.20, green: 0.82, blue: 0.98)
    static let dmBlue  = Color(red: 0.16, green: 0.50, blue: 0.95)
    static let dmBg    = Color(red: 0.05, green: 0.07, blue: 0.11)
    static let dmCard  = Color(red: 0.10, green: 0.13, blue: 0.20)
    static let dmBorder = Color.white.opacity(0.07)
}

// MARK: - Nav Bar Logo

private struct NavBarLogo: View {
    @State private var glowing = false

    var body: some View {
        Image("Logo")
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            .shadow(
                color: Color(red: 0.20, green: 0.82, blue: 0.98).opacity(glowing ? 0.70 : 0.30),
                radius: glowing ? 8 : 4
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var vm: SPLMonitorViewModel
    var screenshotScene: ScreenshotScene? = nil
    @State private var navPath = NavigationPath()

    private let openSettings = NotificationCenter.default.publisher(for: .init("deciMate.openSettings"))

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack {
                // Deep space background
                Color.dmBg.ignoresSafeArea()

                // Subtle radial glow at top center
                RadialGradient(
                    colors: [Color.dmCyan.opacity(0.07), .clear],
                    center: .top,
                    startRadius: 10,
                    endRadius: 360
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        // Mascot companion card
                        CompanionView(state: vm.companionState)

                        // Big SPL meter — the hero number + arc
                        SPLHeroCard(
                            spl: vm.currentSPL,
                            companionState: vm.companionState,
                            warningThreshold: vm.warningThreshold,
                            criticalThreshold: vm.criticalThreshold,
                            peakThreshold: vm.peakThreshold
                        )

                        // Metric row
                        HStack(spacing: 10) {
                            MetricPill(label: "AVG", value: vm.averageSPL, color: .dmCyan)
                            MetricPill(label: "PEAK", value: vm.peakSPL, color: .orange)
                            StatePill(state: vm.thresholdState, companionState: vm.companionState)
                        }

                        // History chart
                        HistoryCard(samples: vm.session.samples.suffix(90), companionState: vm.companionState)

                        // Thresholds
                        ThresholdCard(
                            warning: $vm.warningThreshold,
                            critical: $vm.criticalThreshold,
                            peak: $vm.peakThreshold
                        )

                        // CTA buttons
                        CTARow(vm: vm)

                        Text("Practical monitoring only — not a certified SPL meter.")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.quaternary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 6)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 8) {
                        NavBarLogo()
                        Text("deciMate")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navPath.append("settings")
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.dmCyan)
                            .frame(width: 34, height: 34)
                            .background(Color.dmCard, in: Circle())
                            .overlay(Circle().strokeBorder(Color.dmBorder, lineWidth: 1))
                    }
                }
            }
            .fileExporter(
                isPresented: $vm.showingExporter,
                document: vm.exportDocument,
                contentType: .commaSeparatedText,
                defaultFilename: vm.exportFilename
            ) { _ in }
            .navigationDestination(for: String.self) { _ in
                SettingsView().environmentObject(vm)
            }
            .onReceive(openSettings) { _ in
                navPath.append("settings")
            }
            .onAppear {
                #if DEBUG
                if screenshotScene == .settings {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        navPath.append("settings")
                    }
                }
                #endif
            }
        }
    }
}

// MARK: - SPL Hero Card

private struct SPLHeroCard: View {
    let spl: Double
    let companionState: CompanionState
    let warningThreshold: Double
    let criticalThreshold: Double
    let peakThreshold: Double

    private let minSPL = 40.0
    private let maxSPL = 130.0

    private var progress: Double {
        ((spl - minSPL) / (maxSPL - minSPL)).clamped(to: 0...1)
    }

    // The fill arc end angle
    private var fillAngle: Double { 210 + 300 * progress }  // 210° start, 300° sweep

    var body: some View {
        DMCard {
            HStack(spacing: 0) {
                // ── Arc meter ────────────────────────────────────
                ZStack {
                    // Track
                    ArcShape(start: 210, end: 510)  // 300° sweep
                        .stroke(Color.white.opacity(0.07), style: StrokeStyle(lineWidth: 11, lineCap: .round))

                    // Fill gradient
                    ArcShape(start: 210, end: fillAngle)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .dmCyan,                     location: 0.00),
                                    .init(color: .dmCyan,                     location: 0.35),
                                    .init(color: .yellow,                     location: 0.55),
                                    .init(color: .orange,                     location: 0.72),
                                    .init(color: Color(red: 0.95, green: 0.2, blue: 0.2), location: 1.00)
                                ]),
                                center: .center,
                                startAngle: .degrees(210),
                                endAngle: .degrees(510)
                            ),
                            style: StrokeStyle(lineWidth: 11, lineCap: .round)
                        )
                        .shadow(color: companionState.accentColor.opacity(0.50), radius: 8)
                        .animation(.spring(response: 0.30, dampingFraction: 0.78), value: progress)

                    // Threshold ticks
                    ArcTickMark(value: warningThreshold, min: minSPL, max: maxSPL, color: .yellow)
                    ArcTickMark(value: criticalThreshold, min: minSPL, max: maxSPL, color: .orange)
                    ArcTickMark(value: peakThreshold, min: minSPL, max: maxSPL, color: Color(red: 0.95, green: 0.2, blue: 0.2))
                }
                .frame(width: 168, height: 168)

                // ── Number + label ───────────────────────────────
                VStack(alignment: .leading, spacing: 2) {
                    Spacer()
                    Text(spl, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 58, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: spl)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text("dB SPL")
                        .font(.system(.callout, design: .rounded, weight: .semibold))
                        .foregroundStyle(companionState.accentColor)

                    Spacer()

                    // Scale labels
                    HStack {
                        Text("\(Int(minSPL))")
                        Spacer()
                        Text("\(Int(maxSPL))")
                    }
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.quaternary)
                    .frame(width: 110)
                    .padding(.bottom, 4)
                }
                .padding(.leading, 12)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Arc shapes

private struct ArcShape: Shape {
    let start: Double   // degrees
    let end: Double

    var animatableData: Double { end }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(start),
            endAngle: .degrees(end),
            clockwise: false
        )
        return p
    }
}

private struct ArcTickMark: View {
    let value: Double
    let min: Double
    let max: Double
    let color: Color

    private var angle: Double {
        let pct = (value - min) / (max - min)
        return 210 + 300 * pct.clamped(to: 0...1)
    }

    var body: some View {
        GeometryReader { g in
            let cx = g.size.width / 2
            let cy = g.size.height / 2
            let r  = g.size.width / 2
            let rad = angle * .pi / 180
            let outer = CGPoint(x: cx + r * cos(rad), y: cy + r * sin(rad))
            let inner = CGPoint(x: cx + (r - 16) * cos(rad), y: cy + (r - 16) * sin(rad))
            Path { p in
                p.move(to: inner)
                p.addLine(to: outer)
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Metric Pills

private struct MetricPill: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(color.opacity(0.80))
                .tracking(1.2)
            Text(value, format: .number.precision(.fractionLength(1)))
                .font(.system(.callout, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.25), value: value)
            Text("dB")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.dmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(color.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct StatePill: View {
    let state: ThresholdState
    let companionState: CompanionState

    var body: some View {
        VStack(spacing: 3) {
            Text("STATE")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(companionState.accentColor.opacity(0.80))
                .tracking(1.2)
            Text(state.label.uppercased())
                .font(.system(.caption, design: .rounded, weight: .black))
                .foregroundStyle(companionState.accentColor)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: state.label)
            Circle()
                .fill(companionState.accentColor)
                .frame(width: 6, height: 6)
                .shadow(color: companionState.accentColor, radius: 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.dmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(companionState.accentColor.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - History Chart

private struct HistoryCard: View {
    let samples: ArraySlice<MeasurementSample>
    let companionState: CompanionState

    var body: some View {
        DMCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("LEVEL HISTORY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(companionState.accentColor.opacity(0.8))
                        .tracking(1.5)
                    Spacer()
                    Text("90 samples")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.quaternary)
                }

                Chart(Array(samples)) { s in
                    AreaMark(
                        x: .value("t", s.timestamp),
                        y: .value("dB", s.spl)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [companionState.accentColor.opacity(0.28), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("t", s.timestamp),
                        y: .value("dB", s.spl)
                    )
                    .foregroundStyle(companionState.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 1.8))
                }
                .frame(height: 110)
                .chartYScale(domain: 40...120)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(values: [40, 60, 80, 100, 120]) { _ in
                        AxisGridLine().foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(.quaternary)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Threshold Card

private struct ThresholdCard: View {
    @Binding var warning: Double
    @Binding var critical: Double
    @Binding var peak: Double

    var body: some View {
        DMCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("THRESHOLDS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.dmCyan.opacity(0.8))
                    .tracking(1.5)

                ThreshRow(label: "Warning",  value: $warning,  lo: 60, hi: 120, color: .yellow)
                ThreshRow(label: "Critical", value: $critical, lo: 70, hi: 125, color: .orange)
                ThreshRow(label: "Peak",     value: $peak,     lo: 80, hi: 130, color: Color(red: 0.95, green: 0.2, blue: 0.2))
            }
            .padding(16)
        }
    }
}

private struct ThreshRow: View {
    let label: String
    @Binding var value: Double
    let lo: Double
    let hi: Double
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            // Color swatch
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 3, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Slider(value: $value, in: lo...hi, step: 1)
                    .tint(color)
            }

            Text("\(Int(value))")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - CTA Row

private struct CTARow: View {
    @ObservedObject var vm: SPLMonitorViewModel
    @State private var pressed = false

    @ViewBuilder private var startButtonBackground: some View {
        if vm.isRunning {
            Color(red: 0.85, green: 0.15, blue: 0.15)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            LinearGradient(colors: [.dmCyan, .dmBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Start / Stop — primary CTA
            Button {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.45)) { pressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring()) { pressed = false }
                }
                vm.toggleMonitoring()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: vm.isRunning ? "stop.fill" : "mic.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(vm.isRunning ? "Stop" : "Start")
                        .font(.system(.body, design: .rounded, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(startButtonBackground)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: vm.isRunning
                        ? Color.red.opacity(0.40)
                        : Color.dmCyan.opacity(0.40),
                    radius: 14, y: 5
                )
            }
            .scaleEffect(pressed ? 0.94 : 1.0)

            // Export — secondary
            Button { vm.prepareCSVExport() } label: {
                HStack(spacing: 7) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Export")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.dmCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .foregroundStyle(vm.session.samples.isEmpty ? .quaternary : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.dmBorder, lineWidth: 1)
                )
            }
            .disabled(vm.session.samples.isEmpty)
        }
    }
}

// MARK: - DMCard container

struct DMCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.dmCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.dmBorder, lineWidth: 1)
                    )
            )
    }
}

// MARK: - CompanionState accent (shared with ContentView)

extension CompanionState {
    var accentColor: Color {
        switch self {
        case .idle:    return Color(red: 0.20, green: 0.62, blue: 0.98)
        case .focused: return Color(red: 0.20, green: 0.82, blue: 0.62)
        case .worried: return Color(red: 0.98, green: 0.82, blue: 0.20)
        case .alarmed: return Color(red: 0.98, green: 0.52, blue: 0.16)
        case .peak:    return Color(red: 0.98, green: 0.24, blue: 0.24)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView().environmentObject(SPLMonitorViewModel())
}
