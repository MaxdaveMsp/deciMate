import Foundation
import Network

struct LiveLinkSnapshot: Codable {
    let app: String
    let timestamp: Date
    let splCurrent: Double
    let splAverage: Double
    let splPeak: Double
    let thresholdState: String
    let companionState: String

    init(app: String = "deciMate", timestamp: Date, splCurrent: Double, splAverage: Double, splPeak: Double, thresholdState: String, companionState: String) {
        self.app = app
        self.timestamp = timestamp
        self.splCurrent = splCurrent
        self.splAverage = splAverage
        self.splPeak = splPeak
        self.thresholdState = thresholdState
        self.companionState = companionState
    }
}

final class LiveLinkService: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var endpointDescription = "Not running"
    private var listener: NWListener?
    private var snapshotProvider: (() -> LiveLinkSnapshot)?

    func start(port: UInt16 = 8080, snapshotProvider: @escaping () -> LiveLinkSnapshot) {
        self.snapshotProvider = snapshotProvider
        do {
            let params = NWParameters.tcp
            let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener.newConnectionHandler = { [weak self] connection in self?.handle(connection) }
            listener.start(queue: .main)
            self.listener = listener
            isRunning = true
            endpointDescription = "http://iphone.local:\(port)/status"
        } catch {
            endpointDescription = "Live Link failed: \(error.localizedDescription)"
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
        endpointDescription = "Not running"
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] _, _, _, _ in
            guard let self, let snapshot = self.snapshotProvider?(),
                  let payload = try? JSONEncoder.liveLink.encode(snapshot) else { connection.cancel(); return }
            let body = String(data: payload, encoding: .utf8) ?? "{}"
            let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)"
            connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in connection.cancel() })
        }
    }
}

private extension JSONEncoder {
    static var liveLink: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
