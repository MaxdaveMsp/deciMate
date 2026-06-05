import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: SPLMonitorViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                CompanionView(state: vm.companionState)

                VStack(spacing: 8) {
                    Text(vm.currentSPL, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 76, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("dB SPL approx")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    MetricTile(title: "Average", value: vm.averageSPL)
                    MetricTile(title: "Peak", value: vm.peakSPL)
                    MetricTile(title: "State", text: vm.thresholdState.label)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ThresholdSlider(title: "Warning", value: $vm.warningThreshold, range: 60...120)
                    ThresholdSlider(title: "Critical", value: $vm.criticalThreshold, range: 70...125)
                    ThresholdSlider(title: "Peak", value: $vm.peakThreshold, range: 80...130)
                }

                HStack {
                    Button(vm.isRunning ? "Stop" : "Start") { vm.toggleMonitoring() }
                        .buttonStyle(.borderedProminent)
                    Button("Export CSV") { vm.exportCSV() }
                        .buttonStyle(.bordered)
                        .disabled(vm.session.samples.isEmpty)
                }

                Text("Calibration offset: \(vm.calibrationOffset, specifier: "%.1f") dB")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("deciMate")
            .toolbar {
                NavigationLink("Settings") { SettingsView().environmentObject(vm) }
            }
        }
    }
}

private struct MetricTile: View {
    let title: String
    var value: Double? = nil
    var text: String? = nil

    var body: some View {
        VStack {
            Text(title).font(.caption).foregroundStyle(.secondary)
            if let value { Text(value, format: .number.precision(.fractionLength(1))).monospacedDigit() }
            if let text { Text(text).font(.caption2).multilineTextAlignment(.center) }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct ThresholdSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading) {
            Text("\(title): \(value, specifier: "%.0f") dB")
            Slider(value: $value, in: range, step: 1)
        }
    }
}

#Preview {
    ContentView().environmentObject(SPLMonitorViewModel())
}
