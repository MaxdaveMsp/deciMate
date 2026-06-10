import Foundation

// MARK: - MeasurementSample

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

// MARK: - MeasurementSession

struct MeasurementSession: Codable {
    var startedAt: Date = Date()
    var endedAt: Date?
    var samples: [MeasurementSample] = []

    mutating func add(spl: Double, peak: Double, state: ThresholdState) {
        samples.append(MeasurementSample(timestamp: Date(), spl: spl, peak: peak, thresholdState: state))
    }

    // MARK: - Basic stats

    var averageSPL: Double {
        guard !samples.isEmpty else { return 0 }
        return samples.map(\.spl).reduce(0, +) / Double(samples.count)
    }

    var peakSPL: Double {
        samples.map(\.spl).max() ?? 0
    }

    var minSPL: Double {
        samples.map(\.spl).min() ?? 0
    }

    /// Duration in seconds
    var durationSeconds: Double {
        guard let end = endedAt else {
            return samples.isEmpty ? 0 : samples.last!.timestamp.timeIntervalSince(startedAt)
        }
        return end.timeIntervalSince(startedAt)
    }

    var durationFormatted: String {
        let t = Int(durationSeconds)
        let h = t / 3600; let m = (t % 3600) / 60; let s = t % 60
        if h > 0 { return String(format: "%dh %02dm %02ds", h, m, s) }
        if m > 0 { return String(format: "%dm %02ds", m, s) }
        return String(format: "%ds", s)
    }

    // MARK: - Leq (Equivalent Continuous Level)
    // Leq = 10 * log10( (1/N) * Σ 10^(Li/10) )
    // This is the energy-averaged level — the single most important number
    // for noise exposure assessment.

    var leq: Double {
        guard !samples.isEmpty else { return 0 }
        let energySum = samples.map { pow(10.0, $0.spl / 10.0) }.reduce(0, +)
        return 10.0 * log10(energySum / Double(samples.count))
    }

    // MARK: - OSHA Noise Dose
    // OSHA uses 90 dBA criterion level with 5 dB exchange rate.
    // Allowable hours at level L: T(L) = 8 / 2^((L-90)/5)
    // Dose % = Σ (ti / T(Li)) * 100
    // Action level: 50% dose (85 dBA TWA)
    // Permissible Exposure Limit (PEL): 100% dose (90 dBA TWA)

    var oshaDosePercent: Double {
        guard durationSeconds > 0, !samples.isEmpty else { return 0 }
        let sampleDuration = durationSeconds / Double(samples.count)  // seconds per sample
        var dose = 0.0
        for s in samples {
            let allowableSeconds = 8.0 * 3600.0 / pow(2.0, (s.spl - 90.0) / 5.0)
            dose += sampleDuration / allowableSeconds
        }
        return dose * 100.0
    }

    /// OSHA 8-hour TWA from dose
    var oshaTWA: Double {
        guard oshaDosePercent > 0 else { return 0 }
        return 16.61 * log10(oshaDosePercent / 100.0) + 90.0
    }

    // MARK: - NIOSH Noise Dose
    // NIOSH uses 85 dBA criterion level with 3 dB exchange rate (more protective).
    // T(L) = 8 / 2^((L-85)/3)

    var nioshDosePercent: Double {
        guard durationSeconds > 0, !samples.isEmpty else { return 0 }
        let sampleDuration = durationSeconds / Double(samples.count)
        var dose = 0.0
        for s in samples {
            let allowableSeconds = 8.0 * 3600.0 / pow(2.0, (s.spl - 85.0) / 3.0)
            dose += sampleDuration / allowableSeconds
        }
        return dose * 100.0
    }

    var nioshTWA: Double {
        guard nioshDosePercent > 0 else { return 0 }
        return 10.0 * log10(nioshDosePercent / 100.0) + 85.0
    }

    // MARK: - EU Directive 2003/10/EC
    // Lower action value: LEX,8h = 80 dB(A)
    // Upper action value: LEX,8h = 85 dB(A)
    // Limit value: LEX,8h = 87 dB(A)
    // Normalised to 8-hour working day from actual Leq and duration

    var euLex8h: Double {
        guard durationSeconds > 0 else { return 0 }
        // LEX,8h = Leq + 10 * log10(Te / T0) where T0 = 8h = 28800s
        return leq + 10.0 * log10(durationSeconds / 28800.0)
    }

    var euComplianceStatus: EUComplianceStatus {
        let lex = euLex8h
        if lex >= 87 { return .exceedsLimit }
        if lex >= 85 { return .upperActionValue }
        if lex >= 80 { return .lowerActionValue }
        return .compliant
    }

    // MARK: - Threshold event counts

    var warningEventCount: Int { samples.filter { $0.thresholdState == .warning }.count }
    var criticalEventCount: Int { samples.filter { $0.thresholdState == .critical }.count }
    var peakEventCount: Int { samples.filter { $0.thresholdState == .peak }.count }

    /// % of session time above warning threshold
    var timeAboveWarningPercent: Double {
        guard !samples.isEmpty else { return 0 }
        let above = samples.filter { $0.thresholdState != .safe }.count
        return Double(above) / Double(samples.count) * 100.0
    }

    // MARK: - Report generation

    func reportString(calibrationOffset: Double, weighting: String, response: String,
                      warningThreshold: Double, criticalThreshold: Double, peakThreshold: Double) -> String {
        let iso = ISO8601DateFormatter()
        let display = DateFormatter()
        display.dateStyle = .long
        display.timeStyle = .medium

        var lines: [String] = []

        // ── Header ───────────────────────────────────────────────────────
        lines += [
            "================================================================================",
            "  deciMate — Noise Exposure Report",
            "  Generated: \(display.string(from: Date()))",
            "================================================================================",
            "",
        ]

        // ── Session info ─────────────────────────────────────────────────
        lines += [
            "SESSION INFORMATION",
            "──────────────────────────────────────────────────────────────────────────────",
            "  Start time         : \(display.string(from: startedAt))",
            "  End time           : \(endedAt.map { display.string(from: $0) } ?? "In progress")",
            "  Duration           : \(durationFormatted)",
            "  Total samples      : \(samples.count)",
            "  Weighting          : \(weighting)",
            "  Response           : \(response)",
            "  Calibration offset : \(String(format: "%+.1f", calibrationOffset)) dB",
            "",
        ]

        // ── Level summary ────────────────────────────────────────────────
        lines += [
            "LEVEL SUMMARY",
            "──────────────────────────────────────────────────────────────────────────────",
            "  Leq (equiv. continuous) : \(String(format: "%.1f", leq)) dB",
            "  Average (arithmetic)    : \(String(format: "%.1f", averageSPL)) dB",
            "  Peak                    : \(String(format: "%.1f", peakSPL)) dB",
            "  Minimum                 : \(String(format: "%.1f", minSPL)) dB",
            "  Dynamic range           : \(String(format: "%.1f", peakSPL - minSPL)) dB",
            "",
        ]

        // ── Exposure assessment ──────────────────────────────────────────
        let oshaStatus  = oshaDosePercent >= 100 ? "⚠ EXCEEDS PEL" : oshaDosePercent >= 50 ? "⚠ Above action level" : "✓ Within limits"
        let nioshStatus = nioshDosePercent >= 100 ? "⚠ EXCEEDS REL" : nioshDosePercent >= 50 ? "⚠ Above action level" : "✓ Within limits"
        let euStatus    = euComplianceStatus.label

        lines += [
            "NOISE EXPOSURE ASSESSMENT",
            "──────────────────────────────────────────────────────────────────────────────",
            "  OSHA (29 CFR 1910.95)  — 5 dB exchange rate, 90 dBA criterion",
            "    Noise dose           : \(String(format: "%.1f", oshaDosePercent))%  \(oshaStatus)",
            "    8-hour TWA           : \(String(format: "%.1f", oshaTWA)) dB(A)",
            "    Action level         : 50% dose / 85 dB TWA",
            "    PEL                  : 100% dose / 90 dB TWA",
            "",
            "  NIOSH REL              — 3 dB exchange rate, 85 dBA criterion (more protective)",
            "    Noise dose           : \(String(format: "%.1f", nioshDosePercent))%  \(nioshStatus)",
            "    8-hour TWA           : \(String(format: "%.1f", nioshTWA)) dB(A)",
            "    REL                  : 100% dose / 85 dB TWA",
            "",
            "  EU Directive 2003/10/EC",
            "    LEX,8h               : \(String(format: "%.1f", euLex8h)) dB  \(euStatus)",
            "    Lower action value   : 80 dB(A)  — hearing protection made available",
            "    Upper action value   : 85 dB(A)  — hearing protection mandatory",
            "    Limit value          : 87 dB(A)  — must not be exceeded",
            "",
        ]

        // ── Threshold events ─────────────────────────────────────────────
        lines += [
            "THRESHOLD EVENTS",
            "──────────────────────────────────────────────────────────────────────────────",
            "  Warning  (≥\(String(format: "%.0f", warningThreshold)) dB)  : \(warningEventCount) samples  (\(String(format: "%.1f", Double(warningEventCount)/Double(max(samples.count,1))*100))% of session)",
            "  Critical (≥\(String(format: "%.0f", criticalThreshold)) dB)  : \(criticalEventCount) samples  (\(String(format: "%.1f", Double(criticalEventCount)/Double(max(samples.count,1))*100))% of session)",
            "  Peak     (≥\(String(format: "%.0f", peakThreshold)) dB)  : \(peakEventCount) samples  (\(String(format: "%.1f", Double(peakEventCount)/Double(max(samples.count,1))*100))% of session)",
            "  Time above warning     : \(String(format: "%.1f", timeAboveWarningPercent))%",
            "",
        ]

        // ── Disclaimer ───────────────────────────────────────────────────
        lines += [
            "DISCLAIMER",
            "──────────────────────────────────────────────────────────────────────────────",
            "  deciMate uses the device microphone for practical SPL estimation. It is NOT",
            "  a certified Class 1 or Class 2 sound level meter (IEC 61672). Readings are",
            "  approximate and device/environment dependent. This report is intended for",
            "  practical monitoring guidance only and should not be used as the sole basis",
            "  for legal compliance, occupational health decisions, or enforcement actions.",
            "  For compliance measurements consult a certified Type 1/Type 2 integrating",
            "  sound level meter and a qualified occupational hygienist.",
            "",
            "================================================================================",
            "",
        ]

        // ── Raw sample data ──────────────────────────────────────────────
        lines += [
            "RAW SAMPLE DATA",
            "──────────────────────────────────────────────────────────────────────────────",
            "timestamp,spl_db,peak_db,state",
        ]
        lines += samples.map {
            "\(iso.string(from: $0.timestamp)),\(String(format: "%.2f", $0.spl)),\(String(format: "%.2f", $0.peak)),\($0.thresholdState.rawValue)"
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - EU Compliance Status

enum EUComplianceStatus {
    case compliant, lowerActionValue, upperActionValue, exceedsLimit

    var label: String {
        switch self {
        case .compliant:         return "✓ Below lower action value (< 80 dB)"
        case .lowerActionValue:  return "⚠ At/above lower action value (≥ 80 dB)"
        case .upperActionValue:  return "⚠ At/above upper action value (≥ 85 dB)"
        case .exceedsLimit:      return "✗ EXCEEDS LIMIT VALUE (≥ 87 dB)"
        }
    }
}
