import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var vm: SPLMonitorViewModel

    var body: some View {
        Form {
            Section("Calibration") {
                Stepper(value: $vm.calibrationOffset, in: -30...30, step: 0.5) {
                    Text("Offset: \(vm.calibrationOffset, specifier: "%.1f") dB")
                }
                Text("Use a trusted reference SPL meter or acoustic calibrator, then adjust deciMate until both readings match.")
                    .font(.footnote)
            }

            Section("Measurement") {
                Picker("Weighting", selection: $vm.weighting) {
                    ForEach(MeasurementWeighting.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Response", selection: $vm.response) {
                    ForEach(TimeResponse.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section("Pro Preview") {
                Label("deciMate Live Link", systemImage: "network")
                Text("Planned: stream live SPL data over HTTP, WebSocket, OSC, CSV, or JSON to SMAART, RiTA, Max/MSP, TouchDesigner, OBS, and dashboards.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}
