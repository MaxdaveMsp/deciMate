import SwiftUI

@main
struct DeciMateApp: App {
    @StateObject private var viewModel = SPLMonitorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    #if DEBUG
                    applyScreenshotModeIfNeeded()
                    #endif
                }
        }
    }

    #if DEBUG
    private func applyScreenshotModeIfNeeded() {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-SCREENSHOT_SCENE"),
              idx + 1 < args.count,
              let scene = ScreenshotScene(rawValue: args[idx + 1])
        else { return }

        // Inject data first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            viewModel.applyScreenshotScene(scene)
        }
        // Then navigate if needed — after data + layout settle
        if scene == .settings {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                NotificationCenter.default.post(name: .init("deciMate.openSettings"), object: nil)
            }
        }
    }
    #endif
}
