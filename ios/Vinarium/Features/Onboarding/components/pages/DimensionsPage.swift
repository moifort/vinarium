import SwiftUI

struct DimensionsPage: View {
    @Binding var rows: Int
    @Binding var cols: Int
    var onNext: () -> Void
    var onBack: () -> Void

    private var capacity: Int { rows * cols }
    private var lastRowLabel: String {
        String(UnicodeScalar(65 + max(0, rows - 1))!)
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    Stepper(value: $rows, in: 1...OnboardingLimits.maxRows) {
                        LabeledContent("Rangées", value: "\(rows) (A → \(lastRowLabel))")
                    }
                    .accessibilityIdentifier("onboarding-rows-stepper")
                    Stepper(value: $cols, in: 1...OnboardingLimits.maxCols) {
                        LabeledContent("Emplacements par rangée", value: "\(cols)")
                    }
                    .accessibilityIdentifier("onboarding-cols-stepper")
                } header: {
                    Text("Dimensions de la cave")
                } footer: {
                    Text("Les rangées sont étiquetées de A à Z (26 au maximum).")
                }

                Section {
                    LabeledContent("Capacité totale") {
                        Text("\(capacity) emplacements").fontWeight(.semibold)
                    }
                }
            }

            Button(action: onNext) {
                Text("Continuer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .accessibilityIdentifier("onboarding-dimensions-next")
        }
        .navigationTitle("Dimensions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Retour", systemImage: "chevron.left", action: onBack)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DimensionsPage(rows: .constant(12), cols: .constant(6), onNext: {}, onBack: {})
    }
}
