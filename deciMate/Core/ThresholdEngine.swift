import Foundation
import SwiftUI

enum ThresholdState: String, Codable {
    case safe, warning, critical, peak

    var label: String {
        switch self {
        case .safe: "Safe"
        case .warning: "Warning"
        case .critical: "Critical"
        case .peak: "Peak"
        }
    }
}

struct ThresholdEngine {
    private let hysteresis = 3.0

    func evaluate(spl: Double, warning: Double, critical: Double, peak: Double, previous: ThresholdState) -> ThresholdState {
        if spl >= peak { return .peak }
        if spl >= critical { return .critical }
        if spl >= warning { return .warning }

        switch previous {
        case .peak where spl >= critical - hysteresis: return .critical
        case .critical where spl >= warning - hysteresis: return .warning
        case .warning where spl >= warning - hysteresis: return .warning
        default: return .safe
        }
    }
}

enum CompanionState: Equatable {
    case idle, focused, worried, alarmed, peak

    init(threshold: ThresholdState) {
        switch threshold {
        case .safe: self = .focused
        case .warning: self = .worried
        case .critical: self = .alarmed
        case .peak: self = .peak
        }
    }

    var emoji: String {
        switch self {
        case .idle: "😌"
        case .focused: "🙂"
        case .worried: "😟"
        case .alarmed: "😳"
        case .peak: "🤯"
        }
    }

    var message: String {
        switch self {
        case .idle:    "Ready to listen"
        case .focused: "All good!"
        case .worried: "Getting loud..."
        case .alarmed: "Too loud!"
        case .peak:    "PEAK! Oww!!"
        }
    }

    var color: Color {
        switch self {
        case .idle, .focused: .green
        case .worried: .yellow
        case .alarmed: .orange
        case .peak: .red
        }
    }
}
