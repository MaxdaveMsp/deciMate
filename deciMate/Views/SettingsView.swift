import SwiftUI

// MARK: - Threshold Preset

struct ThresholdPreset: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let warning: Double
    let critical: Double
    let peak: Double

    static let all: [ThresholdPreset] = [
        ThresholdPreset(
            id: "conversation",
            name: "Conversation",
            icon: "person.2.fill",
            description: "Quiet office or home — ideal for calls and focus work",
            warning: 65,
            critical: 75,
            peak: 85
        ),
        ThresholdPreset(
            id: "classroom",
            name: "Classroom",
            icon: "building.columns.fill",
            description: "Recommended limits for learning environments",
            warning: 70,
            critical: 80,
            peak: 90
        ),
        ThresholdPreset(
            id: "event",
            name: "Live Event",
            icon: "music.mic",
            description: "Concerts and venues — OSHA 8-hour exposure limits",
            warning: 85,
            critical: 95,
            peak: 105
        ),
        ThresholdPreset(
            id: "broadcast",
            name: "Broadcast",
            icon: "radio.fill",
            description: "Studio recording and broadcast monitoring",
            warning: 80,
            critical: 90,
            peak: 100
        ),
        ThresholdPreset(
            id: "industrial",
            name: "Industrial",
            icon: "gearshape.2.fill",
            description: "Construction and heavy machinery environments",
            warning: 90,
            critical: 100,
            peak: 110
        ),
    ]

    static let custom = ThresholdPreset(
        id: "custom",
        name: "Custom",
        icon: "slider.horizontal.3",
        description: "Your manually adjusted thresholds",
        warning: 0, critical: 0, peak: 0   // values not used for matching
    )
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var vm: SPLMonitorViewModel
    @State private var referenceSPL = 94.0

    // Derive active preset from current threshold values
    private var activePreset: ThresholdPreset {
        ThresholdPreset.all.first {
            $0.warning == vm.warningThreshold &&
            $0.critical == vm.criticalThreshold &&
            $0.peak == vm.peakThreshold
        } ?? .custom
    }

    var body: some View {
        Form {

            // ── Threshold Presets ──────────────────────────────────────
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    // Active preset badge
                    HStack(spacing: 10) {
                        Image(systemName: activePreset.icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(activePreset == .custom ? .secondary : Color(red: 0.20, green: 0.82, blue: 0.98))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(activePreset.name)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                            Text(activePreset == .custom
                                 ? "W \(Int(vm.warningThreshold)) · C \(Int(vm.criticalThreshold)) · P \(Int(vm.peakThreshold)) dB"
                                 : activePreset.description)
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if activePreset == .custom {
                            Text("CUSTOM")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(.quaternary, in: Capsule())
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color(red: 0.20, green: 0.82, blue: 0.98))
                        }
                    }
                    .padding(.vertical, 4)

                    Divider()

                    // Preset grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ThresholdPreset.all) { preset in
                            PresetCard(
                                preset: preset,
                                isActive: activePreset.id == preset.id
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    vm.warningThreshold  = preset.warning
                                    vm.criticalThreshold = preset.critical
                                    vm.peakThreshold     = preset.peak
                                }
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            } header: {
                Text("Threshold Presets")
            } footer: {
                Text("Manually adjusting any slider below switches to Custom mode.")
            }

            // ── Manual Threshold Sliders ───────────────────────────────
            Section("Manual Thresholds") {
                ThresholdSliderRow(
                    label: "Warning",
                    value: $vm.warningThreshold,
                    range: 60...120,
                    color: .yellow
                )
                ThresholdSliderRow(
                    label: "Critical",
                    value: $vm.criticalThreshold,
                    range: 70...125,
                    color: .orange
                )
                ThresholdSliderRow(
                    label: "Peak",
                    value: $vm.peakThreshold,
                    range: 80...130,
                    color: Color(red: 0.95, green: 0.2, blue: 0.2)
                )
            }

            // ── Calibration ────────────────────────────────────────────
            Section("Calibration") {
                Stepper(value: $vm.calibrationOffset, in: -30...30, step: 0.5) {
                    Text("Offset: \(vm.calibrationOffset, specifier: "%.1f") dB")
                }
                Stepper(value: $referenceSPL, in: 60...120, step: 0.5) {
                    Text("Reference: \(referenceSPL, specifier: "%.1f") dB")
                }
                Button("Match current reading to reference") {
                    vm.applyCalibration(referenceSPL: referenceSPL)
                }
                .disabled(vm.currentSPL <= 0)
                Text("Use a trusted reference SPL meter or acoustic calibrator, then adjust deciMate until both readings match.")
                    .font(.footnote)
            }

            // ── Measurement ────────────────────────────────────────────
            Section("Measurement") {
                Picker("Weighting", selection: $vm.weighting) {
                    ForEach(MeasurementWeighting.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Response", selection: $vm.response) {
                    ForEach(TimeResponse.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            // ── Live Link ──────────────────────────────────────────────
            Section("deciMate Live Link Pro") {
                Button(vm.liveLink.isRunning ? "Stop Live Link" : "Start Live Link") {
                    vm.toggleLiveLink()
                }
                Text(vm.liveLink.endpointDescription)
                    .font(.footnote)
                    .textSelection(.enabled)
                Text("Streams live SPL as JSON over local HTTP for dashboards and bridge workflows.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Preset Card

private struct PresetCard: View {
    let preset: ThresholdPreset
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: preset.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isActive ? Color(red: 0.20, green: 0.82, blue: 0.98) : .secondary)
                    Spacer()
                    if isActive {
                        Circle()
                            .fill(Color(red: 0.20, green: 0.82, blue: 0.98))
                            .frame(width: 7, height: 7)
                    }
                }

                Text(preset.name)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(isActive ? .primary : .secondary)

                // Mini threshold indicators
                HStack(spacing: 3) {
                    ThreshDot(value: preset.warning,  color: .yellow)
                    ThreshDot(value: preset.critical, color: .orange)
                    ThreshDot(value: preset.peak,     color: Color(red: 0.95, green: 0.2, blue: 0.2))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isActive
                          ? Color(red: 0.20, green: 0.82, blue: 0.98).opacity(0.12)
                          : Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                isActive
                                    ? Color(red: 0.20, green: 0.82, blue: 0.98).opacity(0.45)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ThreshDot: View {
    let value: Double
    let color: Color

    var body: some View {
        Text("\(Int(value))")
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Threshold Slider Row

private struct ThresholdSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                Spacer()
                Text("\(Int(value)) dB")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(color)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: 1)
                .tint(color)
        }
        .padding(.vertical, 2)
    }
}
