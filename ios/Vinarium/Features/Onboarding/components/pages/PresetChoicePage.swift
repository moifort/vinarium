import SwiftUI

struct PresetChoicePage: View {
    let presets: [CellarPreset]
    let selection: PresetChoice?
    var onSelect: (PresetChoice) -> Void
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var searchText = ""

    private var filtered: [CellarPreset] {
        let sorted = presets.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    row(
                        title: "Sur mesure",
                        subtitle: "Je saisis moi-même les dimensions",
                        isSelected: selection == .custom
                    ) { onSelect(.custom) }
                    .accessibilityIdentifier("onboarding-preset-custom")
                }

                Section {
                    ForEach(filtered) { preset in
                        row(
                            title: preset.displayName,
                            subtitle: subtitle(for: preset),
                            isSelected: selection == .preset(preset)
                        ) { onSelect(.preset(preset)) }
                        .accessibilityIdentifier("onboarding-preset-\(preset.id)")
                    }
                } header: {
                    Text("Marques de cave")
                } footer: {
                    Text("Sélectionnez votre modèle pour un dimensionnement automatique. Vous pourrez ajuster les valeurs ensuite.")
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher (marque, modèle)")

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

    private func subtitle(for preset: CellarPreset) -> String {
        let zones = preset.zones == 1 ? "1 zone" : "\(preset.zones) zones"
        return "\(preset.bottles) bouteilles · \(zones)"
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
