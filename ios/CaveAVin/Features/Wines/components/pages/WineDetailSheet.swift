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
    @State private var showMove = false
    @State private var showShortlist = false
    @State private var showFavorite = false
    @State private var showRecommendation = false
    @State private var isEditing = false
    @State private var bottleImage: UIImage?
    @State private var showLocationEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let detail {
                    if isEditing {
                        WineEditForm(
                            initial: editFields(from: detail),
                            onSave: { request in
                                _ = try await WineAPI.update(id: wineId, request)
                                self.detail = try await WineAPI.getDetail(id: wineId)
                                isEditing = false
                                onUpdated?()
                            },
                            onCancel: { isEditing = false }
                        )
                    } else {
                        WineDetailContent(
                            content: Self.mapContent(detail),
                            bottleImage: bottleImage,
                            onRemoveRequested: { showRemovalChoice = true },
                            onEditLocation: { showLocationEditor = true }
                        )
                        .refreshable { await loadData() }
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
                if !isEditing {
                    readToolbar
                }
            }
            .task {
                await loadData()
                SentrySDK.reportFullyDisplayed()
            }
            .sheet(isPresented: $showConsumption) {
                if let detail {
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
            }
            .sheet(isPresented: $showGift) {
                if let detail {
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
            }
            .sheet(isPresented: $showPlacement) {
                if let detail {
                    NavigationStack {
                        PlacementView(
                            wineId: detail.id,
                            wineName: detail.name,
                            wineColor: detail.color,
                            wineVintage: detail.vintage,
                            onCancel: { showPlacement = false }
                        ) { _ in
                            showPlacement = false
                            dismiss()
                            onRemoved?()
                        }
                    }
                }
            }
            .sheet(isPresented: $showMove) {
                if let detail, let cellar = detail.cellar {
                    BottleMoveSheet(
                        wineId: detail.id,
                        wineName: detail.name,
                        wineColor: detail.color,
                        wineVintage: detail.vintage,
                        currentRow: cellar.row,
                        currentCol: cellar.col,
                        onCancel: { showMove = false }
                    ) {
                        showMove = false
                        Task {
                            await loadData()
                            onUpdated?()
                        }
                    }
                }
            }
            .sheet(isPresented: $showShortlist) {
                if let detail {
                    ShortlistSheet { date, contacts, notes, rating in
                        let formatter = ISO8601DateFormatter()
                        try? await WineAPI.addToShortlist(
                            id: detail.id,
                            consumedDate: formatter.string(from: date),
                            rating: rating,
                            contacts: contacts.isEmpty ? nil : contacts,
                            tastingNotes: notes
                        )
                        showShortlist = false
                        Task {
                            await loadData()
                            onUpdated?()
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showFavorite) {
                if let detail {
                    FavoriteSheet { _, _, _ in
                        try? await WineAPI.addToFavorites(id: detail.id)
                        showFavorite = false
                        Task {
                            await loadData()
                            onUpdated?()
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showRecommendation) {
                if let detail {
                    RecommendationSheet { recommenderName, comment in
                        try? await RecommendationAPI.create(
                            wineId: detail.id,
                            recommenderName: recommenderName,
                            comment: comment
                        )
                        showRecommendation = false
                        Task {
                            await loadData()
                            onUpdated?()
                        }
                    }
                    .presentationDetents([.medium])
                }
            }
            .sheet(isPresented: $showLocationEditor) {
                if let detail {
                    LocationEditorSheet(initial: locationDraft(from: detail)) { draft in
                        let request = UpdateWineRequest(
                            latitude: draft?.latitude,
                            longitude: draft?.longitude,
                            placeName: draft?.placeName
                        )
                        _ = try? await WineAPI.update(id: detail.id, request)
                        showLocationEditor = false
                        Task {
                            await loadData()
                            onUpdated?()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var readToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Fermer", systemImage: "xmark") { dismiss() }
        }
        if let cellar = detail?.cellar, cellar.dateOut == nil {
            ToolbarItemGroup {
                Button("Déplacer", systemImage: "arrow.left.arrow.right") {
                    showMove = true
                }
                .accessibilityIdentifier("move-bottle-button")

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

                Button {
                    showShortlist = true
                } label: {
                    Label("À retenir", systemImage: "bookmark")
                }
                .accessibilityIdentifier("detail-shortlist-button")
            }
        }
        if let detail {
            let isFavorite = detail.consumption?.rating == 5
            let isShortlisted = detail.consumption?.shortlist == true && !isFavorite
            let canOfferFromCellar = detail.cellar != nil && detail.cellar?.dateOut == nil

            ToolbarItemGroup {
                Menu {
                    Button("Modifier", systemImage: "pencil") {
                        isEditing = true
                    }

                    Section {
                        Button {
                            showFavorite = true
                        } label: {
                            Label(isFavorite ? "Déjà en favoris" : "Ajouter aux favoris", systemImage: isFavorite ? "heart.fill" : "heart")
                        }
                        .disabled(isFavorite)
                        .accessibilityIdentifier("menu-favorite-button")

                        Button {
                            showShortlist = true
                        } label: {
                            Label(isShortlisted ? "Déjà à retenir" : "À retenir", systemImage: isShortlisted ? "bookmark.fill" : "bookmark")
                        }
                        .disabled(isShortlisted)
                        .accessibilityIdentifier("menu-shortlist-button")

                        Button {
                            showRecommendation = true
                        } label: {
                            Label("Conseillé par un ami", systemImage: "person.badge.plus")
                        }
                        .accessibilityIdentifier("menu-recommendation-button")

                        if canOfferFromCellar {
                            Button {
                                showGift = true
                            } label: {
                                Label("Offrir", systemImage: "gift")
                            }
                            .accessibilityIdentifier("menu-gift-button")
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

    // MARK: - Helpers

    private func loadData() async {
        do {
            let loadedDetail = try await WineAPI.getDetail(id: wineId)
            detail = loadedDetail
            isLoading = false

            if loadedDetail.hasBottleImage {
                let imageData = try? await WineAPI.getBottleImage(id: wineId)
                if let imageData {
                    bottleImage = UIImage(data: imageData)
                }
            }
        } catch {
            self.error = reportError(error)
            isLoading = false
        }
    }

    private func locationDraft(from detail: UserWineDetail) -> DiscoveryLocationDraft? {
        guard let latitude = detail.latitude, let longitude = detail.longitude else { return nil }
        return DiscoveryLocationDraft(
            latitude: latitude,
            longitude: longitude,
            placeName: detail.placeName
        )
    }

    private static func mapContent(_ detail: UserWineDetail) -> WineDetailContent.Content {
        let formatter: (Date) -> String = { $0.formatted(date: .abbreviated, time: .omitted) }
        return WineDetailContent.Content(
            color: detail.color,
            name: detail.name,
            domain: detail.domain,
            vintage: detail.vintage,
            appellation: detail.appellation,
            region: detail.region,
            country: detail.country,
            classification: detail.classification,
            placeName: detail.placeName,
            latitude: detail.latitude,
            longitude: detail.longitude,
            alcoholContent: detail.alcoholContent,
            purchasePrice: detail.purchasePrice,
            purchaseDate: detail.purchaseDate,
            grapeVarieties: detail.grapeVarieties,
            drinkFrom: detail.drinkFrom,
            drinkUntil: detail.drinkUntil,
            giftedBy: detail.giftedBy,
            notes: detail.notes,
            cellar: detail.cellar.map { cellar in
                .init(
                    position: "\(cellar.row)\(cellar.col)",
                    dateIn: formatter(cellar.dateIn),
                    dateOut: cellar.dateOut.map(formatter),
                    isInCellar: cellar.dateOut == nil
                )
            },
            consumption: detail.consumption.map { consumption in
                .init(
                    consumedDate: consumption.consumedDate.map(formatter),
                    rating: consumption.rating,
                    tastingNotes: consumption.tastingNotes,
                    contacts: consumption.contacts
                )
            },
            gift: detail.gift.map { gift in
                .init(giftedDate: formatter(gift.giftedDate), recipientName: gift.recipientName)
            },
            recommendation: detail.recommendation.map { reco in
                .init(recommenderName: reco.recommenderName, comment: reco.comment)
            }
        )
    }

    private func editFields(from detail: UserWineDetail) -> WineEditForm.Fields {
        var parsedPurchaseDate: Date?
        if let dateString = detail.purchaseDate {
            parsedPurchaseDate = ISO8601DateFormatter().date(from: dateString)
        }
        return WineEditForm.Fields(
            name: detail.name,
            color: detail.color,
            domain: detail.domain ?? "",
            vintage: detail.vintage.map(String.init) ?? "",
            appellation: detail.appellation ?? "",
            region: detail.region ?? "",
            country: detail.country ?? "",
            classification: detail.classification ?? "",
            grapeVarieties: detail.grapeVarieties.joined(separator: ", "),
            purchasePrice: detail.purchasePrice.map { String(format: "%.0f", $0) } ?? "",
            purchaseDate: parsedPurchaseDate,
            drinkFrom: detail.drinkFrom.map(String.init) ?? "",
            drinkUntil: detail.drinkUntil.map(String.init) ?? "",
            giftedBy: detail.giftedBy ?? "",
            notes: detail.notes ?? ""
        )
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
