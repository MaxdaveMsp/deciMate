import XCTest
@testable import deciMate

final class deciMateTests: XCTestCase {
    func testThresholdEngineUsesPeakFirst() {
        let engine = ThresholdEngine()
        XCTAssertEqual(engine.evaluate(spl: 111, warning: 90, critical: 100, peak: 110, previous: .safe), .peak)
    }

    func testSPLCalibrationOffset() {
        let calc = SPLCalculator()
        let base = calc.estimatedSPL(fromDBFS: -20, calibrationOffset: 0, weighting: .z)
        let calibrated = calc.estimatedSPL(fromDBFS: -20, calibrationOffset: 3, weighting: .z)
        XCTAssertEqual(calibrated - base, 3, accuracy: 0.001)
    }
}
