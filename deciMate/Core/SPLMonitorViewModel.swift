import Foundation
import SwiftUI
import Combine

@MainActor
final class SPLMonitorViewModel: ObservableObject {
    @Published var currentSPL: Double = 0
    @Published var averageSPL: Double = 0
    @Published var peakSPL: Double = 0
    @AppStorage("calibrationOffset") var calibrationOffset: Double = 0
    @AppStorage("warningThreshold") var warningThreshold: Double = 90
    @AppStorage("criticalThreshold") var criticalThreshold: Double = 100
    @AppStorage("peakThreshold") var peakThreshold: Double = 110
    @Published var thresholdState: ThresholdState = .safe
    @Published var companionState: CompanionState = .idle
    @Published var isRunning = false
    @Published var weighting: MeasurementWeighting = .a
    @Published var response: TimeResponse = .fast
    @Published var session = MeasurementSession()
    @Published var showingExporter = false
    @Published var exportDocument = CSVExportDocument()
    @Published var exportFilename = "deciMate-session.csv"
    @Published var liveLink = LiveLinkService()

    private let audioEngine = AudioInputManager()
    private let calculator = SPLCalculator()
    private let thresholds = ThresholdEngine()
    private var cancellables = Set<AnyCancellable>()

    init() {
        audioEngine.levelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in self?.handle(level: level) }
            .store(in: &cancellables)
    }

    func toggleMonitoring() { isRunning ? stopMonitoring() : startMonitoring() }

    func startMonitoring() {
        session = MeasurementSession(startedAt: Date())
        peakSPL = 0; averageSPL = 0
        audioEngine.start(); isRunning = true
    }

    func stopMonitoring() {
        audioEngine.stop(); session.endedAt = Date(); isRunning = false
    }

    private func handle(level: AudioLevel) {
        let spl = calculator.estimatedSPL(fromDBFS: level.dbFS, calibrationOffset: calibrationOffset, weighting: weighting)
        currentSPL = response.smoothed(previous: currentSPL == 0 ? spl : currentSPL, next: spl)
        peakSPL = max(peakSPL, currentSPL)
        thresholdState = thresholds.evaluate(spl: currentSPL, warning: warningThreshold, critical: criticalThreshold, peak: peakThreshold, previous: thresholdState)
        companionState = CompanionState(threshold: thresholdState)
        session.add(spl: currentSPL, peak: peakSPL, state: thresholdState)
        averageSPL = session.averageSPL
    }

    func prepareCSVExport() {
        exportDocument = CSVExportDocument(text: session.csvString())
        exportFilename = "deciMate-\(Self.filenameDate.string(from: session.startedAt)).csv"
        showingExporter = true
    }

    func applyCalibration(referenceSPL: Double) {
        guard currentSPL > 0 else { return }
        calibrationOffset += referenceSPL - currentSPL
    }

    func toggleLiveLink() {
        if liveLink.isRunning { liveLink.stop() }
        else { liveLink.start { [weak self] in self?.snapshot() ?? LiveLinkSnapshot(timestamp: Date(), splCurrent: 0, splAverage: 0, splPeak: 0, thresholdState: "unknown", companionState: "unknown") } }
    }

    private func snapshot() -> LiveLinkSnapshot {
        LiveLinkSnapshot(timestamp: Date(), splCurrent: currentSPL, splAverage: averageSPL, splPeak: peakSPL, thresholdState: thresholdState.rawValue, companionState: companionState.message)
    }

    private static let filenameDate: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss"; return f
    }()
}
