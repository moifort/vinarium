import SwiftUI

struct PresetChoicePage: View {
    let presets: [CellarPreset]
    var onSelect: (PresetChoice) -> Void
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var searchText = ""

    // MARK: Grouping (Contacts-style: one section per brand, alphabetical)

    private struct BrandSection: Identifiable {
        let id: String
        let brand: String
        let models: [CellarPreset]
    }

    private var query: String {
        normalized(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var isSearching: Bool { !query.isEmpty }

    private var brandSections: [BrandSection] {
        let sections = Dictionary(grouping: presets, by: \.brand)
            .map { brand, models in
                BrandSection(
                    id: brand,
                    brand: brand,
                    models: models.sorted {
                        $0.model.localizedCaseInsensitiveCompare($1.model) == .orderedAscending
                    }
                )
            }
            .sorted { $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedAscending }

        guard isSearching else { return sections }
        return sections.compactMap { section in
            let brandMatches = normalized(section.brand).contains(query)
            let models = brandMatches
                ? section.models
                : section.models.filter { normalized($0.displayName).contains(query) }
            return models.isEmpty
                ? nil
                : BrandSection(id: section.id, brand: section.brand, models: models)
        }
    }

    // MARK: Body

    var body: some View {
        List {
            Section {
                row(title: "Sur mesure", subtitle: "Je saisis moi-même les dimensions") {
                    choose(.custom)
                }
                .accessibilityIdentifier("onboarding-preset-custom")
            }

            ForEach(brandSections) { section in
                Section {
                    ForEach(section.models) { preset in
                        row(title: preset.model, subtitle: subtitle(for: preset)) {
                            choose(.preset(preset))
                        }
                        .accessibilityIdentifier("onboarding-preset-\(preset.id)")
                    }
                } header: {
                    Text(section.brand)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Rechercher (marque, modèle)")
        .navigationTitle("Votre cave")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Retour", systemImage: "chevron.left", action: onBack)
            }
        }
    }

    // MARK: Rows & helpers

    private func choose(_ choice: PresetChoice) {
        onSelect(choice)
        onNext()
    }

    private func subtitle(for preset: CellarPreset) -> String {
        let zones = preset.zones == 1 ? "1 zone" : "\(preset.zones) zones"
        return "\(preset.bottles) bouteilles · \(zones)"
    }

    private func normalized(_ string: String) -> String {
        string.folding(options: .diacriticInsensitive, locale: .current).lowercased()
    }

    private func row(
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body).fontWeight(.medium)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .tint(.primary)
    }
}

#Preview {
    NavigationStack {
        PresetChoicePage(
            presets: CellarPreset.all,
            onSelect: { _ in },
            onNext: {},
            onBack: {}
        )
    }
}
