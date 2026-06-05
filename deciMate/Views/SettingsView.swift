import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: SPLMonitorViewModel
    @State private var referenceSPL = 94.0

    var body: some View {
        Form {
            Section("Calibration") {
                Stepper(value: $vm.calibrationOffset, in: -30...30, step: 0.5) { Text("Offset: \(vm.calibrationOffset, specifier: "%.1f") dB") }
                Stepper(value: $referenceSPL, in: 60...120, step: 0.5) { Text("Reference: \(referenceSPL, specifier: "%.1f") dB") }
                Button("Match current reading to reference") { vm.applyCalibration(referenceSPL: referenceSPL) }.disabled(vm.currentSPL <= 0)
                Text("Use a trusted reference SPL meter or acoustic calibrator, then adjust deciMate until both readings match.").font(.footnote)
            }
            Section("Measurement") {
                Picker("Weighting", selection: $vm.weighting) { ForEach(MeasurementWeighting.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Response", selection: $vm.response) { ForEach(TimeResponse.allCases) { Text($0.rawValue).tag($0) } }
            }
            Section("deciMate Live Link Pro") {
                Button(vm.liveLink.isRunning ? "Stop Live Link" : "Start Live Link") { vm.toggleLiveLink() }
                Text(vm.liveLink.endpointDescription).font(.footnote).textSelection(.enabled)
                Text("Streams live SPL as JSON over local HTTP for dashboards and bridge workflows. WebSocket/OSC adapters are planned for the Pro release.").font(.footnote)
            }
        }.navigationTitle("Settings")
    }
}
