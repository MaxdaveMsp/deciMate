import SwiftUI

@main
struct DeciMateApp: App {
    @StateObject private var viewModel = SPLMonitorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
