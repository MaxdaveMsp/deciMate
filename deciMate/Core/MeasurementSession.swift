import Foundation

struct MeasurementSample: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let spl: Double
    let peak: Double
    let thresholdState: ThresholdState

    init(id: UUID = UUID(), timestamp: Date, spl: Double, peak: Double, thresholdState: ThresholdState) {
        self.id = id
        self.timestamp = timestamp
        self.spl = spl
        self.peak = peak
        self.thresholdState = thresholdState
    }
}

struct MeasurementSession: Codable {
    var startedAt: Date = Date()
    var endedAt: Date?
    var samples: [MeasurementSample] = []

    mutating func add(spl: Double, peak: Double, state: ThresholdState) {
        samples.append(MeasurementSample(timestamp: Date(), spl: spl, peak: peak, thresholdState: state))
    }

    var averageSPL: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.spl).reduce(0, +) / Double(samples.count)
    }

    func csvString() -> String {
        var lines = ["timestamp,spl,peak,state"]
        let formatter = ISO8601DateFormatter()
        lines += samples.map { "\(formatter.string(from: $0.timestamp)),\(String(format: "%.2f", $0.spl)),\(String(format: "%.2f", $0.peak)),\($0.thresholdState.rawValue)" }
        return lines.joined(separator: "\n")
    }
}
