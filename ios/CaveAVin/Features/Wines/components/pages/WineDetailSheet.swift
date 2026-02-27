import Sentry
import SentrySwiftUI
import SwiftUI

struct WineDetailSheet: View {
    let wineId: String
    var onRemoved: (() -> Void)?
    var onUpdated: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var detail: UserWineDetail?
    @State private var isLoading = true
    @State private var error: String?
    @State private var showConsumption = false
    @State private var showRemovalChoice = false
    @State private var showGift = false
    @State private var showDeleteConfirmation = false
    @State private var showPlacement = false

    // MARK: - Edit state

    @State private var isEditing = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var editName = ""
    @State private var editColor: WineColor = .red
    @State private var editDomain = ""
    @State private var editVintage = ""
    @State private var editAppellation = ""
    @State private var editRegion = ""
    @State private var editCountry = ""
    @State private var editClassification = ""
    @State private var editGrapeVarieties = ""
    @State private var editPurchasePrice = ""
    @State private var editPurchaseDate: Date?
    @State private var editDrinkFrom = ""
    @State private var editDrinkUntil = ""
    @State private var editGiftedBy = ""
    @State private var showGiftedByPicker = false
    @State private var editNotes = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let detail {
                    if isEditing {
                        editContent
                    } else {
                        wineContent(detail)
                    }
                } else if let error {
                    ContentUnavailableView(
                        "Erreur",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                }
            }
            .sentryTrace("Wine Detail", waitForFullDisplay: true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    editToolbar
                } else {
                    readToolbar
                }
            }
            .task {
                await loadData()
                SentrySDK.reportFullyDisplayed()
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Annuler", systemImage: "xmark") {
                isEditing = false
            }
            .disabled(isSaving)
        }
        ToolbarItem(placement: .confirmationAction) {
            if isSaving {
                ProgressView()
            } else {
                Button("Enregistrer", systemImage: "checkmark") {
                    Task { await saveChanges() }
                }
                .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    @ToolbarContentBuilder
    private var readToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Fermer", systemImage: "xmark") { dismiss() }
        }
        if let cellar = detail?.cellar, cellar.dateOut == nil {
            ToolbarItemGroup {
                Button("Sortir", systemImage: "arrow.up") {
                    showRemovalChoice = true
                }
                .accessibilityIdentifier("remove-from-cellar-button")
                .confirmationDialog(
                    "Sortir de la cave",
                    isPresented: $showRemovalChoice,
                    titleVisibility: .visible
                ) {
                    Button("Consommer") { showConsumption = true }
                        .accessibilityIdentifier("choice-consume")
                    Button("Offrir") { showGift = true }
                        .accessibilityIdentifier("choice-gift")
                } message: {
                    Text("Comment souhaitez-vous sortir ce vin ?")
                }
            }
        }
        if let detail, detail.cellar == nil, detail.recommendation != nil {
            ToolbarItemGroup {
                Button {
                    showPlacement = true
                } label: {
                    Label("Ajouter à la cave", systemImage: "plus")
                }

                AsyncToolbarButton(title: "Ajouter aux favoris", systemImage: "heart") {
                    try? await WineAPI.addToFavorites(id: detail.id)
                    dismiss()
                    onRemoved?()
                }
            }
        }
        if detail != nil {
            ToolbarItemGroup {
                Menu {
                    Button("Modifier", systemImage: "pencil") {
                        if let detail {
                            populateEditFields(from: detail)
                            isEditing = true
                        }
                    }
                    Button("Supprimer", systemImage: "trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .accessibilityIdentifier("delete-wine-button")
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityIdentifier("wine-detail-menu")
                .confirmationDialog(
                    "Supprimer ce vin ?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible,
                    presenting: detail
                ) { detail in
                    Button("Supprimer", role: .destructive) {
                        Task {
                            try? await WineAPI.delete(id: detail.id)
                            dismiss()
                            onRemoved?()
                        }
                    }
                    .accessibilityIdentifier("choice-delete")
                } message: { _ in
                    Text("Cette action est irréversible. Le vin sera supprimé de votre collection, de la cave et de toutes les données associées.")
                }
            }
        }
    }

    // MARK: - Edit content

    private var editContent: some View {
        Form {
            Section {
                LabeledContent {
                    TextField("Nom du vin", text: $editName)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Nom", systemImage: "wineglass")
                }

                Picker(selection: $editColor) {
                    ForEach(WineColor.allCases) { c in
                        Text(c.label).tag(c)
                    }
                } label: {
                    Label("Couleur", systemImage: "paintpalette")
                }

                LabeledContent {
                    TextField("Domaine", text: $editDomain)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Domaine", systemImage: "building.2")
                }

                LabeledContent {
                    TextField("Année", text: $editVintage)
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
                    TextField("Appellation", text: $editAppellation)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Appellation", systemImage: "seal")
                }

                LabeledContent {
                    TextField("Région", text: $editRegion)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Région", systemImage: "map")
                }

                LabeledContent {
                    TextField("Pays", text: $editCountry)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Pays", systemImage: "globe.europe.africa")
                }

                LabeledContent {
                    TextField("Classification", text: $editClassification)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Classification", systemImage: "rosette")
                }
            } header: {
                Text("Origine")
            }

            Section {
                LabeledContent {
                    TextField("Cépages", text: $editGrapeVarieties)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("Cépages", systemImage: "leaf")
                }

                LabeledContent {
                    HStack(spacing: 4) {
                        TextField("0", text: $editPurchasePrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("€")
                            .foregroundStyle(.secondary)
                    }
                } label: {
                    Label("Prix", systemImage: "eurosign.circle")
                }

                LabeledContent {
                    if let date = Binding($editPurchaseDate) {
                        HStack {
                            DatePicker("", selection: date, in: ...Date(), displayedComponents: .date)
                                .labelsHidden()
                            Button {
                                editPurchaseDate = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button("Ajouter") {
                            editPurchaseDate = Date()
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
                    TextField("Année", text: $editDrinkFrom)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Label("À partir de", systemImage: "hourglass.bottomhalf.filled")
                }

                LabeledContent {
                    TextField("Année", text: $editDrinkUntil)
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
                    TextField("Nom", text: $editGiftedBy)
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
                TextField("Notes", text: $editNotes, axis: .vertical)
                    .lineLimit(3...8)
            } header: {
                Text("Notes")
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
            ContactPicker { editGiftedBy = $0 }
        }
    }

    // MARK: - Read content

    @ViewBuilder
    private func wineContent(_ detail: UserWineDetail) -> some View {
        List {
            WineDetailHeader(
                color: detail.color,
                name: detail.name,
                subtitle: headerSubtitle(detail),
                domain: detail.domain,
                vintage: detail.vintage
            )

            WineOriginSection(
                appellation: detail.appellation,
                region: detail.region,
                country: detail.country,
                classification: detail.classification
            )

            WineDetailsSection(
                alcoholContent: detail.alcoholContent,
                purchasePrice: detail.purchasePrice,
                purchaseDate: detail.purchaseDate,
                grapeVarieties: detail.grapeVarieties
            )

            WineAgingSection(drinkFrom: detail.drinkFrom, drinkUntil: detail.drinkUntil)

            if let cellar = detail.cellar {
                WineCellarSection(
                    position: "\(cellar.row)\(cellar.col)",
                    dateIn: formatted(cellar.dateIn),
                    dateOut: cellar.dateOut.map { formatted($0) },
                    isInCellar: cellar.dateOut == nil,
                    onRemoveRequested: { showRemovalChoice = true }
                )
            }

            if let consumption = detail.consumption {
                WineConsumptionSection(
                    consumedDate: consumption.consumedDate.map { formatted($0) },
                    rating: consumption.rating,
                    tastingNotes: consumption.tastingNotes,
                    contacts: consumption.contacts
                )
            }

            if let gift = detail.gift {
                WineGiftSection(giftedDate: formatted(gift.giftedDate), recipientName: gift.recipientName)
            }

            if let giftedBy = detail.giftedBy {
                Section("Offert par") {
                    Label {
                        Text(giftedBy)
                    } icon: {
                        Image(systemName: "gift")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let recommendation = detail.recommendation {
                WineRecommendationSection(
                    recommenderName: recommendation.recommenderName,
                    comment: recommendation.comment
                )
            }

            if let notes = detail.notes, !notes.isEmpty {
                Section("Notes") {
                    Label {
                        Text(notes)
                    } icon: {
                        Image(systemName: "note.text")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showConsumption) {
            ConsumptionSheet { date, rating, notes, contacts in
                let formatter = ISO8601DateFormatter()
                _ = try? await CellarAPI.remove(
                    wineId: detail.id,
                    consumedDate: formatter.string(from: date),
                    rating: rating,
                    tastingNotes: notes,
                    contacts: contacts.isEmpty ? nil : contacts
                )
                showConsumption = false
                dismiss()
                onRemoved?()
            }
            .presentationDetents([.height(550)])
        }
        .sheet(isPresented: $showGift) {
            GiftSheet { date, recipientName in
                let formatter = ISO8601DateFormatter()
                _ = try? await CellarAPI.gift(
                    wineId: detail.id,
                    giftedDate: formatter.string(from: date),
                    recipientName: recipientName
                )
                showGift = false
                dismiss()
                onRemoved?()
            }
            .presentationDetents([.height(250)])
        }
        .sheet(isPresented: $showPlacement) {
            NavigationStack {
                PlacementView(
                    wine: Wine(
                        id: detail.id,
                        name: detail.name,
                        color: detail.color,
                        createdAt: detail.createdAt,
                        updatedAt: detail.updatedAt
                    ),
                    onCancel: { showPlacement = false }
                ) { _ in
                    showPlacement = false
                    dismiss()
                    onRemoved?()
                }
            }
        }
    }

    // MARK: - Helpers

    private func headerSubtitle(_ detail: UserWineDetail) -> String {
        [detail.color.label,
         detail.domain,
         detail.vintage.map { "\($0)" }]
            .compactMap { $0 }
            .joined(separator: " \u{2022} ")
    }

    private func formatted(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    private func loadData() async {
        do {
            detail = try await WineAPI.getDetail(id: wineId)
            isLoading = false
        } catch {
            self.error = reportError(error)
            isLoading = false
        }
    }

    private func populateEditFields(from detail: UserWineDetail) {
        editName = detail.name
        editColor = detail.color
        editDomain = detail.domain ?? ""
        editVintage = detail.vintage.map(String.init) ?? ""
        editAppellation = detail.appellation ?? ""
        editRegion = detail.region ?? ""
        editCountry = detail.country ?? ""
        editClassification = detail.classification ?? ""
        editGrapeVarieties = detail.grapeVarieties.joined(separator: ", ")
        editPurchasePrice = detail.purchasePrice.map { String(format: "%.0f", $0) } ?? ""
        if let dateString = detail.purchaseDate {
            let formatter = ISO8601DateFormatter()
            editPurchaseDate = formatter.date(from: dateString)
        } else {
            editPurchaseDate = nil
        }
        editDrinkFrom = detail.drinkFrom.map(String.init) ?? ""
        editDrinkUntil = detail.drinkUntil.map(String.init) ?? ""
        editGiftedBy = detail.giftedBy ?? ""
        editNotes = detail.notes ?? ""
    }

    private func buildUpdateRequest() -> UpdateWineRequest {
        let varieties = editGrapeVarieties
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return UpdateWineRequest(
            name: editName,
            color: editColor,
            domain: editDomain.isEmpty ? nil : editDomain,
            vintage: Int(editVintage),
            appellation: editAppellation.isEmpty ? nil : editAppellation,
            region: editRegion.isEmpty ? nil : editRegion,
            country: editCountry.isEmpty ? nil : editCountry,
            grapeVarieties: varieties.isEmpty ? nil : varieties,
            classification: editClassification.isEmpty ? nil : editClassification,
            purchasePrice: Double(editPurchasePrice),
            purchaseDate: editPurchaseDate.map { ISO8601DateFormatter().string(from: $0) },
            drinkFrom: Int(editDrinkFrom),
            drinkUntil: Int(editDrinkUntil),
            giftedBy: editGiftedBy.isEmpty ? nil : editGiftedBy,
            notes: editNotes.isEmpty ? nil : editNotes
        )
    }

    private func saveChanges() async {
        isSaving = true
        do {
            _ = try await WineAPI.update(id: wineId, buildUpdateRequest())
            detail = try await WineAPI.getDetail(id: wineId)
            isEditing = false
            onUpdated?()
        } catch {
            saveError = reportError(error)
        }
        isSaving = false
    }
}

#Preview("Bouteille sortie") {
    WineDetailSheet(wineId: "5d288fc9-864d-4633-862a-b4410cf8b64a")
}

#Preview("En cave") {
    WineDetailSheet(wineId: "c2f5486a-29d6-4a32-b3e9-323ab1bee3d1")
}

#Preview("Conseiller") {
    WineDetailSheet(wineId: "19fe3138-e125-4df9-afe6-90e1505a0326")
}
