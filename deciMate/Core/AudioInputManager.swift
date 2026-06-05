import Foundation
import AVFoundation
import Combine

struct AudioLevel {
    let dbFS: Double
    let rms: Double
}

final class AudioInputManager {
    let levelPublisher = PassthroughSubject<AudioLevel, Never>()
    private let engine = AVAudioEngine()

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            let frameCount = Int(buffer.frameLength)
            guard frameCount > 0 else { return }
            var sum: Float = 0
            for i in 0..<frameCount { sum += channel[i] * channel[i] }
            let rms = sqrt(sum / Float(frameCount))
            let dbFS = 20.0 * log10(max(Double(rms), 0.000_000_1))
            self?.levelPublisher.send(AudioLevel(dbFS: dbFS, rms: Double(rms)))
        }

        do { try engine.start() } catch { print("Audio engine start error: \(error)") }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
