import SwiftUI

struct PresetChoicePage: View {
    let presets: [CellarPreset]
    let selection: PresetChoice?
    var onSelect: (PresetChoice) -> Void
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach(presets) { preset in
                        row(
                            title: preset.displayName,
                            subtitle: "\(preset.rows) rangées × \(preset.cols) — \(preset.capacity) emplacements",
                            isSelected: selection == .preset(preset)
                        ) { onSelect(.preset(preset)) }
                        .accessibilityIdentifier("onboarding-preset-\(preset.id)")
                    }
                } header: {
                    Text("Marques de cave")
                } footer: {
                    Text("Sélectionnez votre modèle pour un dimensionnement automatique. Vous pourrez ajuster les valeurs ensuite.")
                }

                Section {
                    row(
                        title: "Sur mesure",
                        subtitle: "Je saisis moi-même les dimensions",
                        isSelected: selection == .custom
                    ) { onSelect(.custom) }
                    .accessibilityIdentifier("onboarding-preset-custom")
                }
            }

            Button(action: onNext) {
                Text("Continuer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(selection == nil)
            .padding()
            .accessibilityIdentifier("onboarding-preset-next")
        }
        .navigationTitle("Votre cave")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Retour", systemImage: "chevron.left", action: onBack)
            }
        }
    }

    private func row(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body).fontWeight(.medium)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
        .tint(.primary)
    }
}

#Preview {
    NavigationStack {
        PresetChoicePage(
            presets: CellarPreset.all,
            selection: .custom,
            onSelect: { _ in },
            onNext: {},
            onBack: {}
        )
    }
}
