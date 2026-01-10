import SwiftUI

struct SettingsView: View {
    @Binding var totalMinutes: Int
    @Binding var yellowThreshold: Int
    @Binding var redThreshold: Int
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Talk Duration")) {
                    Stepper("Total Time: \(totalMinutes) min", value: $totalMinutes, in: 1...120)
                }

                Section(header: Text("Warning Thresholds")) {
                    Stepper("Yellow at: \(yellowThreshold) min remaining", value: $yellowThreshold, in: 1...totalMinutes)
                        .onChange(of: yellowThreshold) { newValue in
                            if redThreshold > newValue {
                                redThreshold = newValue
                            }
                        }

                    Stepper("Red at: \(redThreshold) min remaining", value: $redThreshold, in: 0...yellowThreshold)
                }

                Section {
                    Text("Yellow warning appears when time remaining equals the yellow threshold. Red warning appears when time remaining equals the red threshold.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
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
