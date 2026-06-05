import Foundation
import SwiftUI
import Combine

@MainActor
final class SPLMonitorViewModel: ObservableObject {
    @Published var currentSPL: Double = 0
    @Published var averageSPL: Double = 0
    @Published var peakSPL: Double = 0
    @Published var calibrationOffset: Double = 0
    @Published var warningThreshold: Double = 90
    @Published var criticalThreshold: Double = 100
    @Published var peakThreshold: Double = 110
    @Published var thresholdState: ThresholdState = .safe
    @Published var companionState: CompanionState = .idle
    @Published var isRunning = false
    @Published var weighting: MeasurementWeighting = .a
    @Published var response: TimeResponse = .fast
    @Published var session = MeasurementSession()

    private let audioEngine = AudioInputManager()
    private let calculator = SPLCalculator()
    private let thresholds = ThresholdEngine()
    private var cancellables = Set<AnyCancellable>()

    init() {
        audioEngine.levelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.handle(level: level)
            }
            .store(in: &cancellables)
    }

    func toggleMonitoring() {
        isRunning ? stopMonitoring() : startMonitoring()
    }

    func startMonitoring() {
        session = MeasurementSession(startedAt: Date())
        peakSPL = 0
        averageSPL = 0
        audioEngine.start()
        isRunning = true
    }

    func stopMonitoring() {
        audioEngine.stop()
        session.endedAt = Date()
        isRunning = false
    }

    private func handle(level: AudioLevel) {
        let spl = calculator.estimatedSPL(fromDBFS: level.dbFS, calibrationOffset: calibrationOffset, weighting: weighting)
        currentSPL = response.smoothed(previous: currentSPL == 0 ? spl : currentSPL, next: spl)
        peakSPL = max(peakSPL, currentSPL)
        session.add(spl: currentSPL, peak: peakSPL, state: thresholdState)
        averageSPL = session.averageSPL
        thresholdState = thresholds.evaluate(spl: currentSPL, warning: warningThreshold, critical: criticalThreshold, peak: peakThreshold, previous: thresholdState)
        companionState = CompanionState(threshold: thresholdState)
    }

    func exportCSV() {
        // Placeholder for ShareLink/document exporter integration.
        print(session.csvString())
    }
}
