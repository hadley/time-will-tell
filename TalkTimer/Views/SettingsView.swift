import SwiftUI

struct SettingsView: View {
    @Binding var totalSeconds: Int
    @Binding var yellowThresholdSeconds: Int
    @Binding var redThresholdSeconds: Int
    @Binding var playGongOnFinish: Bool
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var totalMinutes: Binding<Int> {
        Binding(
            get: { totalSeconds / 60 },
            set: { totalSeconds = $0 * 60 }
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Stepper(value: totalMinutes, in: 1 ... 120, step: 1) {
                        HStack {
                            Text("Total time")
                            Spacer()
                            Text("\(totalMinutes.wrappedValue) min")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: totalSeconds) { newValue in
                        // Ensure thresholds don't exceed total time
                        if yellowThresholdSeconds > newValue {
                            yellowThresholdSeconds = newValue
                        }
                        if redThresholdSeconds > newValue {
                            redThresholdSeconds = newValue
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Warning thresholds")
                        DualThresholdSlider(
                            yellowSeconds: $yellowThresholdSeconds,
                            redSeconds: $redThresholdSeconds,
                            maxSeconds: totalSeconds
                        )
                    }
                    .padding(.vertical, 8)

                    Toggle("Play gong", isOn: $playGongOnFinish)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DualThresholdSlider: View {
    @Binding var yellowSeconds: Int
    @Binding var redSeconds: Int
    let maxSeconds: Int

    private let handleSize: CGFloat = 28
    private let trackHeight: CGFloat = 24
    private let snapIncrement: Int = 15

    // Percentages (0 to 1) - yellow is always >= red since it triggers first
    private var yellowFraction: CGFloat {
        guard maxSeconds > 0 else { return 0 }
        return CGFloat(yellowSeconds) / CGFloat(maxSeconds)
    }

    private var redFraction: CGFloat {
        guard maxSeconds > 0 else { return 0 }
        return CGFloat(redSeconds) / CGFloat(maxSeconds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                let trackWidth = geometry.size.width

                ZStack(alignment: .leading) {
                    // Fixed-width track with colored regions using percentages
                    // Left = more time remaining, Right = less time remaining
                    // So: Black (safe) | Yellow (warning) | Red (danger)
                    GeometryReader { _ in
                        HStack(spacing: 0) {
                            // Black region: from left edge to yellow threshold
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: trackWidth * (1 - yellowFraction))

                            // Yellow region: from yellow to red threshold
                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: trackWidth * (yellowFraction - redFraction))

                            // Red region: from red threshold to right edge (0 time)
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: trackWidth * redFraction)
                        }
                    }
                    .frame(width: trackWidth, height: trackHeight)
                    .cornerRadius(trackHeight / 2)

                    // Yellow handle - positioned at yellow threshold
                    // Higher seconds = more to the left
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: handleSize, height: handleSize)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .position(
                            x: trackWidth * (1 - yellowFraction),
                            y: trackHeight / 2
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let fraction = 1 - (value.location.x / trackWidth)
                                    let clampedFraction = min(max(fraction, 0), 1)
                                    let newSeconds = Int(clampedFraction * CGFloat(maxSeconds))
                                    let snapped = snap(newSeconds)
                                    // Yellow must be >= red (can't go right of red handle)
                                    yellowSeconds = max(snapped, redSeconds)
                                }
                        )

                    // Red handle - positioned at red threshold
                    Circle()
                        .fill(Color.red)
                        .frame(width: handleSize, height: handleSize)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .position(
                            x: trackWidth * (1 - redFraction),
                            y: trackHeight / 2
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let fraction = 1 - (value.location.x / trackWidth)
                                    let clampedFraction = min(max(fraction, 0), 1)
                                    let newSeconds = Int(clampedFraction * CGFloat(maxSeconds))
                                    let snapped = snap(newSeconds)
                                    // Red must be <= yellow (can't go left of yellow handle)
                                    redSeconds = min(snapped, yellowSeconds)
                                }
                        )
                }
                .frame(height: handleSize)
            }
            .frame(height: handleSize)

            // Labels showing current values with matching app colors
            HStack {
                Text("Yellow: \(formatTime(yellowSeconds))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow)
                    .cornerRadius(4)
                Spacer()
                Text("Red: \(formatTime(redSeconds))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
            }
        }
    }

    private func snap(_ seconds: Int) -> Int {
        let snapped = (seconds / snapIncrement) * snapIncrement
        return min(max(snapped, 0), maxSeconds)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
