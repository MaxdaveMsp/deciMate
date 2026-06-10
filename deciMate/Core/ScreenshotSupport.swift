import Foundation
import SwiftUI
import Combine

// MARK: - Screenshot mock data
// Launched with -SCREENSHOT_SCENE <name> to inject realistic data for App Store screenshots.

#if DEBUG
enum ScreenshotScene: String {
    case idle      = "idle"
    case focused   = "focused"
    case worried   = "worried"
    case peak      = "peak"
    case settings  = "settings"
}

extension SPLMonitorViewModel {
    /// Call once after init when running in screenshot mode.
    func applyScreenshotScene(_ scene: ScreenshotScene) {
        switch scene {
        case .idle:
            currentSPL      = 0.0
            averageSPL      = 0.0
            peakSPL         = 0.0
            thresholdState  = .safe
            companionState  = .idle
            isRunning       = false

        case .focused:
            currentSPL      = 72.4
            averageSPL      = 70.1
            peakSPL         = 75.8
            thresholdState  = .safe
            companionState  = .focused
            isRunning       = true
            injectSamples(around: 72, state: .safe, count: 60)

        case .worried:
            currentSPL      = 87.6
            averageSPL      = 83.2
            peakSPL         = 91.4
            thresholdState  = .warning
            companionState  = .worried
            isRunning       = true
            injectSamples(around: 87, state: .warning, count: 60)

        case .peak:
            currentSPL      = 106.2
            averageSPL      = 88.5
            peakSPL         = 106.2
            thresholdState  = .peak
            companionState  = .peak
            isRunning       = true
            injectSamples(around: 100, state: .peak, count: 60)

        case .settings:
            currentSPL      = 74.1
            averageSPL      = 71.8
            peakSPL         = 78.3
            thresholdState  = .safe
            companionState  = .focused
            isRunning       = true
        }
    }

    private func injectSamples(around base: Double, state: ThresholdState, count: Int) {
        session = MeasurementSession(startedAt: Date().addingTimeInterval(-Double(count)))
        for i in 0..<count {
            let t = Date().addingTimeInterval(Double(i - count))
            let jitter = Double.random(in: -4...4)
            let spl = base + jitter + sin(Double(i) * 0.4) * 3
            session.samples.append(MeasurementSample(timestamp: t, spl: spl, peak: spl + 2, thresholdState: state))
        }
        averageSPL = session.samples.map(\.spl).reduce(0, +) / Double(session.samples.count)
    }
}
#endif
