import SwiftUI

struct PresetChoicePage: View {
    let presets: [CellarPreset]
    let selection: PresetChoice?
    var onSelect: (PresetChoice) -> Void
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var searchText = ""
    @State private var activeIndexLetter: String?

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

    /// The distinct leading letters of the visible brands, in order — the A-Z index.
    private var indexLetters: [String] {
        var seen: [String] = []
        for section in brandSections {
            let letter = String(section.brand.prefix(1)).uppercased()
            if !seen.contains(letter) { seen.append(letter) }
        }
        return seen
    }

    private func firstBrandId(for letter: String) -> String? {
        brandSections.first { String($0.brand.prefix(1)).uppercased() == letter }?.id
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    Section {
                        row(
                            title: "Sur mesure",
                            subtitle: "Je saisis moi-même les dimensions",
                            isSelected: selection == .custom
                        ) { onSelect(.custom) }
                        .accessibilityIdentifier("onboarding-preset-custom")
                    }

                    ForEach(brandSections) { section in
                        Section {
                            ForEach(section.models) { preset in
                                row(
                                    title: preset.model,
                                    subtitle: subtitle(for: preset),
                                    isSelected: selection == .preset(preset)
                                ) { onSelect(.preset(preset)) }
                                .accessibilityIdentifier("onboarding-preset-\(preset.id)")
                            }
                        } header: {
                            Text(section.brand)
                        }
                        .id(section.id)
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Rechercher (marque, modèle)")
                .overlay(alignment: .trailing) {
                    if !isSearching {
                        sectionIndex(proxy)
                    }
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

    // MARK: A-Z index

    private func sectionIndex(_ proxy: ScrollViewProxy) -> some View {
        let letters = indexLetters
        return GeometryReader { geo in
            VStack(spacing: 0) {
                ForEach(letters, id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.tint)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !letters.isEmpty else { return }
                        let step = geo.size.height / CGFloat(letters.count)
                        let index = min(letters.count - 1, max(0, Int(value.location.y / step)))
                        let letter = letters[index]
                        if letter != activeIndexLetter { activeIndexLetter = letter }
                        if let id = firstBrandId(for: letter) {
                            proxy.scrollTo(id, anchor: .top)
                        }
                    }
                    .onEnded { _ in activeIndexLetter = nil }
            )
        }
        .frame(width: 22)
        .padding(.trailing, 2)
        .sensoryFeedback(.selection, trigger: activeIndexLetter)
    }

    // MARK: Rows & helpers

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
