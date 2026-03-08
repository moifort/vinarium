import SwiftUI

struct WineEditForm: View {
    let initial: Fields
    let onSave: (UpdateWineRequest) async throws -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var color: WineColor
    @State private var domain: String
    @State private var vintage: String
    @State private var appellation: String
    @State private var region: String
    @State private var country: String
    @State private var classification: String
    @State private var grapeVarieties: String
    @State private var purchasePrice: String
    @State private var purchaseDate: Date?
    @State private var drinkFrom: String
    @State private var drinkUntil: String
    @State private var giftedBy: String
    @State private var notes: String
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showGiftedByPicker = false

    init(initial: Fields, onSave: @escaping (UpdateWineRequest) async throws -> Void, onCancel: @escaping () -> Void) {
        self.initial = initial
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: initial.name)
        _color = State(initialValue: initial.color)
        _domain = State(initialValue: initial.domain)
        _vintage = State(initialValue: initial.vintage)
        _appellation = State(initialValue: initial.appellation)
        _region = State(initialValue: initial.region)
        _country = State(initialValue: initial.country)
        _classification = State(initialValue: initial.classification)
        _grapeVarieties = State(initialValue: initial.grapeVarieties)
        _purchasePrice = State(initialValue: initial.purchasePrice)
        _purchaseDate = State(initialValue: initial.purchaseDate)
        _drinkFrom = State(initialValue: initial.drinkFrom)
        _drinkUntil = State(initialValue: initial.drinkUntil)
        _giftedBy = State(initialValue: initial.giftedBy)
        _notes = State(initialValue: initial.notes)
    }

    var body: some View {
        Form {
            Section {
                LabeledContent {
                    TextField("Nom du vin", text: $name)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Nom", systemImage: "wineglass")
                }

                Picker(selection: $color) {
                    ForEach(WineColor.allCases) { c in
                        Text(c.label).tag(c)
                    }
                } label: {
                    Label("Couleur", systemImage: "paintpalette")
                }

                LabeledContent {
                    TextField("Domaine", text: $domain)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Domaine", systemImage: "building.2")
                }

                LabeledContent {
                    TextField("Année", text: $vintage)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Millésime", systemImage: "calendar")
                }
            } header: {
                Text("Informations principales")
            }

            Section {
                LabeledContent {
                    TextField("Appellation", text: $appellation)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Appellation", systemImage: "seal")
                }

                LabeledContent {
                    TextField("Région", text: $region)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Région", systemImage: "map")
                }

                LabeledContent {
                    TextField("Pays", text: $country)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Pays", systemImage: "globe.europe.africa")
                }

                LabeledContent {
                    TextField("Classification", text: $classification)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Classification", systemImage: "rosette")
                }
            } header: {
                Text("Origine")
            }

            Section {
                LabeledContent {
                    TextField("Cépages", text: $grapeVarieties)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Cépages", systemImage: "leaf")
                }

                LabeledContent {
                    HStack(spacing: 4) {
                        TextField("0", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("€")
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Label("Prix", systemImage: "eurosign.circle")
                }

                LabeledContent {
                    if let date = Binding($purchaseDate) {
                        HStack {
                            DatePicker("", selection: date, in: ...Date(), displayedComponents: .date)
                                .labelsHidden()
                            Button {
                                purchaseDate = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button("Ajouter") {
                            purchaseDate = Date()
                        }
                    }
                } label: {
                    Label("Date d'achat", systemImage: "cart")
                }
            } header: {
                Text("Détails")
            }

            Section {
                LabeledContent {
                    TextField("Année", text: $drinkFrom)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("À partir de", systemImage: "hourglass.bottomhalf.filled")
                }

                LabeledContent {
                    TextField("Année", text: $drinkUntil)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Jusqu'à", systemImage: "hourglass.tophalf.filled")
                }
            } header: {
                Text("Garde")
            }

            Section {
                HStack {
                    Label("Offert par", systemImage: "gift")
                    TextField("Nom", text: $giftedBy)
                        .textInputAutocapitalization(.words)
                        .multilineTextAlignment(.trailing)
                    Button {
                        showGiftedByPicker = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Cadeau")
            }

            Section {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("Notes")
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler", systemImage: "xmark") {
                    onCancel()
                }
                .disabled(isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                if isSaving {
                    ProgressView()
                } else {
                    Button("Enregistrer", systemImage: "checkmark") {
                        Task { await save() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .alert("Erreur", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .sheet(isPresented: $showGiftedByPicker) {
            ContactPicker { giftedBy = $0 }
        }
    }

    private func save() async {
        isSaving = true
        let varieties = grapeVarieties
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let request = UpdateWineRequest(
            name: name,
            color: color,
            domain: domain.isEmpty ? nil : domain,
            vintage: Int(vintage),
            appellation: appellation.isEmpty ? nil : appellation,
            region: region.isEmpty ? nil : region,
            country: country.isEmpty ? nil : country,
            grapeVarieties: varieties.isEmpty ? nil : varieties,
            classification: classification.isEmpty ? nil : classification,
            purchasePrice: Double(purchasePrice),
            purchaseDate: purchaseDate.map { ISO8601DateFormatter().string(from: $0) },
            drinkFrom: Int(drinkFrom),
            drinkUntil: Int(drinkUntil),
            giftedBy: giftedBy.isEmpty ? nil : giftedBy,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            try await onSave(request)
        } catch {
            saveError = reportError(error)
        }
        isSaving = false
    }
}

extension WineEditForm {
    struct Fields {
        var name: String
        var color: WineColor
        var domain: String
        var vintage: String
        var appellation: String
        var region: String
        var country: String
        var classification: String
        var grapeVarieties: String
        var purchasePrice: String
        var purchaseDate: Date?
        var drinkFrom: String
        var drinkUntil: String
        var giftedBy: String
        var notes: String
    }
}

#Preview {
    NavigationStack {
        WineEditForm(
            initial: .init(
                name: "Château Margaux",
                color: .red,
                domain: "Château Margaux",
                vintage: "2018",
                appellation: "Margaux",
                region: "Bordeaux",
                country: "France",
                classification: "Premier Grand Cru Classé",
                grapeVarieties: "Cabernet Sauvignon, Merlot",
                purchasePrice: "350",
                purchaseDate: Date(),
                drinkFrom: "2025",
                drinkUntil: "2045",
                giftedBy: "",
                notes: "Superbe millésime"
            ),
            onSave: { _ in },
            onCancel: {}
        )
    }
}
