import Foundation

enum MeasurementWeighting: String, CaseIterable, Identifiable {
    case a = "A-weighted approx"
    case c = "C-weighted approx"
    case z = "Flat / Z approx"
    var id: String { rawValue }
}

enum TimeResponse: String, CaseIterable, Identifiable {
    case fast = "Fast"
    case slow = "Slow"
    var id: String { rawValue }

    func smoothed(previous: Double, next: Double) -> Double {
        let alpha = self == .fast ? 0.35 : 0.08
        return previous + alpha * (next - previous)
    }
}

struct SPLCalculator {
    // Provisional reference. Real app requires per-device calibration.
    private let nominalDBFSAt94dBSPL = -20.0

    func estimatedSPL(fromDBFS dbFS: Double, calibrationOffset: Double, weighting: MeasurementWeighting) -> Double {
        let unweighted = 94.0 + (dbFS - nominalDBFSAt94dBSPL) + calibrationOffset
        switch weighting {
        case .a: return unweighted // TODO: replace with real A-weighting filter before production claim.
        case .c: return unweighted
        case .z: return unweighted
        }
    }
}
