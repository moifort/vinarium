import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct WineDetailView: View {
    let wineId: String
    var onRemoved: (() -> Void)?
    var onUpdated: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var detail: UserWineDetail?
    @State private var isLoading = true
    @State private var isRefreshing = false
    @State private var error: String?
    @State private var showConsumption = false
    @State private var showRemovalChoice = false
    @State private var showGift = false
    @State private var showDeleteConfirmation = false
    @State private var showPlacement = false
    @State private var showMove = false
    @State private var showFavorite = false
    @State private var showRecommendation = false
    @State private var isEditing = false
    @State private var showLocationEditor = false
    @State private var sheetError = ErrorPresenter()
    @State private var actionError = ErrorPresenter()
    @State private var showAttachmentChoice = false
    @State private var pendingAttachmentSource: AttachmentSource?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var showFileImporter = false
    @State private var isUploadingAttachment = false
    @State private var previewedFile: PreviewedFile?
    @State private var attachmentError = ErrorPresenter()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingStateView()
                } else if let detail {
                    if isEditing {
                        WineEditForm(
                            initial: Self.editFields(from: detail),
                            onSave: { submission in
                                self.detail = try await save(submission, of: detail)
                                isEditing = false
                                onUpdated?()
                            },
                            onCancel: { isEditing = false }
                        )
                    } else {
                        WineDetailPage(
                            content: Self.mapContent(
                                detail,
                                isUploadingAttachment: isUploadingAttachment
                            ),
                            onRemoveRequested: { showRemovalChoice = true },
                            onEditLocation: { showLocationEditor = true },
                            onAddAttachment: { showAttachmentChoice = true },
                            onOpenAttachment: { attachment in
                                Task { await openAttachment(attachment) }
                            },
                            onDeleteAttachment: { attachment in
                                Task { await deleteAttachment(attachment) }
                            },
                            onRefresh: { await loadData() }
                        )
                    }
                } else if let error {
                    ContentUnavailableView(
                        "Erreur",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEditing {
                    readToolbar
                }
            }
            // Menu actions (favorite, deletion, …) close the menu before the mutation
            // leaves, and a refresh keeps the content on screen: in both cases the
            // network call is made visible by a scrim and a spinner. A mutation hands
            // back the sheet it leaves behind, so none is followed by a second read.
            .overlay {
                if actionError.isRunning || isRefreshing {
                    ZStack {
                        Color.black.opacity(0.1).ignoresSafeArea()
                        ProgressView()
                    }
                }
            }
            .disabled(actionError.isRunning || isRefreshing)
            .errorAlert(actionError)
            .errorAlert(attachmentError)
            .attachmentPickers(
                showChoice: $showAttachmentChoice,
                pendingSource: $pendingAttachmentSource,
                showCamera: $showCamera,
                showPhotoPicker: $showPhotoPicker,
                pickedPhoto: $pickedPhoto,
                showFileImporter: $showFileImporter,
                onImage: { image in Task { await upload(image) } },
                onFile: { url in Task { await upload(fileAt: url) } },
                onFailure: { message in error = message }
            )
            .fullScreenCover(item: $previewedFile) { file in
                NavigationStack {
                    DocumentPreview(url: file.url)
                        .ignoresSafeArea(edges: .bottom)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                ToolbarIconButton(
                                    title: "Fermer",
                                    systemImage: "xmark",
                                    role: .cancel
                                ) { previewedFile = nil }
                            }
                        }
                }
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showConsumption) {
                if let detail {
                    ConsumptionSheet { date, rating, notes, contacts in
                        let formatter = ISO8601DateFormatter()
                        await sheetError.run {
                            _ = try await CellarAPI.remove(
                                wineId: detail.id,
                                consumedDate: formatter.string(from: date),
                                rating: rating,
                                tastingNotes: notes,
                                contacts: contacts.isEmpty ? nil : contacts
                            )
                        } onSuccess: {
                            showConsumption = false
                            dismiss()
                            onRemoved?()
                        }
                    }
                    .presentationDetents([.height(550)])
                    .errorAlert(sheetError)
                }
            }
            .sheet(isPresented: $showGift) {
                if let detail {
                    GiftSheet { date, recipientName in
                        let formatter = ISO8601DateFormatter()
                        await sheetError.run {
                            _ = try await CellarAPI.gift(
                                wineId: detail.id,
                                giftedDate: formatter.string(from: date),
                                recipientName: recipientName
                            )
                        } onSuccess: {
                            showGift = false
                            dismiss()
                            onRemoved?()
                        }
                    }
                    .presentationDetents([.height(250)])
                    .errorAlert(sheetError)
                }
            }
            .sheet(isPresented: $showPlacement) {
                if let detail {
                    NavigationStack {
                        CellarPlacementView(
                            wineId: detail.id,
                            wineName: detail.name,
                            beverageType: detail.beverageType,
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
                    BottleMoveView(
                        wineId: detail.id,
                        wineName: detail.name,
                        wineBeverageType: detail.beverageType,
                        wineColor: detail.color,
                        wineVintage: detail.vintage,
                        currentRow: cellar.row,
                        currentCol: cellar.col,
                        onCancel: { showMove = false }
                    ) { row, col in
                        showMove = false
                        self.detail?.cellar = CellarInfo(
                            row: row,
                            col: col,
                            dateIn: cellar.dateIn,
                            dateOut: nil
                        )
                        onUpdated?()
                    }
                }
            }
            .sheet(isPresented: $showFavorite) {
                if let detail {
                    FavoriteSheet { date, contacts, notes, rating in
                        let formatter = ISO8601DateFormatter()
                        await sheetError.run {
                            self.detail = try await WineAPI.saveNotes(
                                id: detail.id,
                                tasting: TastingEntry(
                                    consumedDate: formatter.string(from: date),
                                    rating: rating == 0 ? nil : rating,
                                    contacts: contacts.isEmpty ? nil : contacts,
                                    tastingNotes: notes,
                                    favorite: true
                                )
                            )
                        } onSuccess: {
                            showFavorite = false
                            onUpdated?()
                        }
                    }
                    .presentationDetents([.medium])
                    .errorAlert(sheetError)
                }
            }
            .sheet(isPresented: $showRecommendation) {
                if let detail {
                    RecommendationSheet { recommenderName, comment in
                        await sheetError.run {
                            self.detail = try await WineAPI.saveNotes(
                                id: detail.id,
                                recommendation: RecommendationEntry(
                                    recommenderName: recommenderName,
                                    comment: comment
                                )
                            )
                        } onSuccess: {
                            showRecommendation = false
                            onUpdated?()
                        }
                    }
                    .presentationDetents([.medium])
                    .errorAlert(sheetError)
                }
            }
            .sheet(isPresented: $showLocationEditor) {
                if let detail {
                    LocationEditorSheet(initial: Self.locationDraft(from: detail)) { draft in
                        // "Aucun lieu" has to say so out loud: an absent coordinate
                        // reads as "unchanged" and would leave the old pin in place.
                        let request = UpdateWineRequest(
                            latitude: draft?.latitude,
                            longitude: draft?.longitude,
                            placeName: draft?.placeName,
                            cleared: draft == nil ? [.latitude, .longitude, .placeName] : []
                        )
                        await sheetError.run {
                            self.detail = try await WineAPI.saveSheet(id: detail.id, wine: request)
                        } onSuccess: {
                            showLocationEditor = false
                            onUpdated?()
                        }
                    }
                    .errorAlert(sheetError)
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var readToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            ToolbarIconButton(title: "Fermer", systemImage: "xmark", role: .cancel) { dismiss() }
        }
        if let cellar = detail?.cellar, cellar.dateOut == nil {
            ToolbarItemGroup {
                Button("Déplacer", systemImage: "arrow.left.arrow.right") {
                    showMove = true
                }
                .labelStyle(.iconOnly)
                .accessibilityIdentifier("move-bottle-button")

                Button("Sortir", systemImage: "arrow.up") {
                    showRemovalChoice = true
                }
                .labelStyle(.iconOnly)
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
        if let detail, detail.isMine, detail.cellar == nil, detail.recommendation != nil {
            ToolbarItemGroup {
                ToolbarIconButton(title: "Ajouter à la cave", systemImage: "plus") {
                    showPlacement = true
                }

                AsyncToolbarButton(title: "Ajouter aux favoris", systemImage: "heart") {
                    await actionError.run {
                        try await WineAPI.setFavorite(id: detail.id, favorite: true)
                    } onSuccess: {
                        dismiss()
                        onRemoved?()
                    }
                }
            }
        }
        if let detail {
            let isFavorite = detail.consumption?.favorite == true
            let canOfferFromCellar = detail.cellar != nil && detail.cellar?.dateOut == nil

            ToolbarItemGroup {
                Menu {
                    if detail.isMine {
                        Button("Modifier", systemImage: "pencil") {
                            isEditing = true
                        }
                    }

                    Section {
                        if isFavorite {
                            Button {
                                Task {
                                    await actionError.run {
                                        self.detail = try await WineAPI.saveNotes(
                                            id: detail.id,
                                            tasting: TastingEntry(favorite: false)
                                        )
                                    } onSuccess: {
                                        onUpdated?()
                                    }
                                }
                            } label: {
                                Label("Retirer des favoris", systemImage: "heart.slash")
                            }
                            .accessibilityIdentifier("menu-favorite-button")
                        } else {
                            Button {
                                showFavorite = true
                            } label: {
                                Label("Ajouter aux favoris", systemImage: "heart")
                            }
                            .accessibilityIdentifier("menu-favorite-button")
                        }

                        if detail.isMine {
                            Button {
                                showRecommendation = true
                            } label: {
                                Label("Conseillé par un ami", systemImage: "person.badge.plus")
                            }
                            .accessibilityIdentifier("menu-recommendation-button")
                        }

                        if canOfferFromCellar {
                            Button {
                                showGift = true
                            } label: {
                                Label("Offrir", systemImage: "gift")
                            }
                            .accessibilityIdentifier("menu-gift-button")
                        }
                    }

                    if detail.isMine {
                        Button("Supprimer", systemImage: "trash", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                        .accessibilityIdentifier("delete-wine-button")
                    }
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
                            await actionError.run {
                                try await WineAPI.delete(id: detail.id)
                            } onSuccess: {
                                dismiss()
                                onRemoved?()
                            }
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
        // A pull-to-refresh: keep the content on screen and show the scrim rather
        // than replacing the whole page with a spinner.
        if detail != nil { isRefreshing = true }
        defer { isRefreshing = false }
        do {
            let loadedDetail = try await WineAPI.getDetail(id: wineId)
            detail = loadedDetail
            isLoading = false
        } catch {
            self.error = reportError(error)
            isLoading = false
        }
    }

    /// One screen, one save: the sheet goes up as a single mutation, so the four
    /// records it spans land together or not at all. Only what the user touched is
    /// sent — an untouched wine must not grow an empty tasting note because its
    /// name was corrected.
    private func save(
        _ submission: WineEditSubmission,
        of detail: UserWineDetail
    ) async throws -> UserWineDetail {
        let initial = Self.editFields(from: detail)
        return try await WineAPI.saveSheet(
            id: detail.id,
            wine: submission.wine,
            tasting: submission.tasting == initial.tasting ? nil : submission.tasting,
            gift: submission.gift == initial.gift ? nil : submission.gift,
            recommendation: submission.recommendation == initial.recommendation
                ? nil
                : submission.recommendation
        )
    }

    private static func locationDraft(from detail: UserWineDetail) -> TastingLocationDraft? {
        guard let latitude = detail.latitude, let longitude = detail.longitude else { return nil }
        return TastingLocationDraft(
            latitude: latitude,
            longitude: longitude,
            placeName: detail.placeName
        )
    }

    // MARK: - Attachments

    /// A photo is recompressed before it leaves: a 12-megapixel capture is four
    /// megabytes of detail nobody will look at on a wine sheet, and every one of
    /// them is billed for as long as the bottle exists.
    private func upload(_ image: UIImage) async {
        guard let data = image.resized(maxDimension: 2048).jpegData(compressionQuality: 0.8) else {
            error = String(localized: "Photo illisible")
            return
        }
        await upload(data: data, fileName: "photo-\(Int(Date().timeIntervalSince1970)).jpg", contentType: "image/jpeg")
    }

    private func upload(fileAt url: URL) async {
        // A file handed over by the Files app lives outside our sandbox and is
        // only readable while the scope is open.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            error = String(localized: "Fichier illisible")
            return
        }
        let contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
            ?? "application/octet-stream"
        await upload(data: data, fileName: url.lastPathComponent, contentType: contentType)
    }

    private func upload(data: Data, fileName: String, contentType: String) async {
        isUploadingAttachment = true
        defer { isUploadingAttachment = false }
        await attachmentError.run {
            let attachment = try await AttachmentAPI.upload(
                beverageId: wineId,
                data: data,
                fileName: fileName,
                contentType: contentType
            )
            self.detail?.attachments.append(attachment)
        } onSuccess: {
            onUpdated?()
        }
    }

    private func deleteAttachment(_ attachment: BeverageAttachment) async {
        await actionError.run {
            try await AttachmentAPI.delete(attachmentId: attachment.id)
            self.detail?.attachments.removeAll { $0.id == attachment.id }
        } onSuccess: {
            onUpdated?()
        }
    }

    /// The file is pulled down before it is shown: QuickLook renders photos and
    /// PDFs alike, but only from a local file.
    private func openAttachment(_ attachment: BeverageAttachment) async {
        await actionError.run {
            let url = try await AttachmentAPI.download(attachment)
            await MainActor.run { previewedFile = PreviewedFile(id: attachment.id, url: url) }
        }
    }

    private static func mapContent(
        _ detail: UserWineDetail,
        isUploadingAttachment: Bool
    ) -> WineDetailContent.Content {
        let formatter: (Date) -> String = { $0.formatted(date: .abbreviated, time: .omitted) }
        return WineDetailContent.Content(
            beverageType: detail.beverageType,
            color: detail.color,
            subtype: detail.subtype,
            name: detail.name,
            domain: detail.domain,
            cuvee: detail.cuvee,
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
            },
            ownerName: detail.ownerName,
            attachments: detail.attachments,
            canAttach: detail.isMine,
            isUploadingAttachment: isUploadingAttachment
        )
    }

    private static func editFields(from detail: UserWineDetail) -> WineEditForm.Fields {
        var parsedPurchaseDate: Date?
        if let dateString = detail.purchaseDate {
            parsedPurchaseDate = ISO8601DateFormatter().date(from: dateString)
        }
        return WineEditForm.Fields(
            name: detail.name,
            beverageType: detail.beverageType,
            color: detail.color ?? .red,
            subtype: detail.subtype,
            domain: detail.domain ?? "",
            cuvee: detail.cuvee ?? "",
            vintage: detail.vintage.map(String.init) ?? "",
            appellation: detail.appellation ?? "",
            region: detail.region ?? "",
            country: detail.country ?? "",
            classification: detail.classification ?? "",
            grapeVarieties: detail.grapeVarieties.joined(separator: ", "),
            purchasePrice: detail.purchasePrice.map(Money.editableTextFromEur) ?? "",
            purchaseDate: parsedPurchaseDate,
            drinkFrom: detail.drinkFrom.map(String.init) ?? "",
            drinkUntil: detail.drinkUntil.map(String.init) ?? "",
            giftedBy: detail.giftedBy ?? "",
            notes: detail.notes ?? "",
            alcoholContent: detail.alcoholContent.map(Money.decimalText) ?? "",
            place: Self.locationDraft(from: detail),
            gift: detail.gift.map {
                GiftDraft(recipientName: $0.recipientName ?? "", date: $0.giftedDate)
            },
            tasting: TastingDraft(
                rating: detail.consumption?.rating ?? 0,
                consumedDate: detail.consumption?.consumedDate,
                contacts: detail.consumption?.contacts ?? [],
                tastingNotes: detail.consumption?.tastingNotes ?? ""
            ),
            recommendation: RecommendationDraft(
                recommenderName: detail.recommendation?.recommenderName ?? "",
                comment: detail.recommendation?.comment ?? ""
            )
        )
    }
}

#Preview("Bottle taken out") {
    WineDetailView(wineId: "5d288fc9-864d-4633-862a-b4410cf8b64a")
}

#Preview("In cellar") {
    WineDetailView(wineId: "c2f5486a-29d6-4a32-b3e9-323ab1bee3d1")
}

#Preview("Recommend") {
    WineDetailView(wineId: "19fe3138-e125-4df9-afe6-90e1505a0326")
}


/// The local copy being shown in the document viewer.
private struct PreviewedFile: Identifiable {
    let id: String
    let url: URL
}

private extension View {
    /// The ways a file gets in, kept together so the sheet itself stays about
    /// the wine. A source picked on the sheet is acted on once it is closed:
    /// the camera, the system picker and the Files browser are presentations of
    /// their own and would fight the sheet on its way out.
    func attachmentPickers(
        showChoice: Binding<Bool>,
        pendingSource: Binding<AttachmentSource?>,
        showCamera: Binding<Bool>,
        showPhotoPicker: Binding<Bool>,
        pickedPhoto: Binding<PhotosPickerItem?>,
        showFileImporter: Binding<Bool>,
        onImage: @escaping (UIImage) -> Void,
        onFile: @escaping (URL) -> Void,
        onFailure: @escaping (String) -> Void
    ) -> some View {
        sheet(isPresented: showChoice) {
            switch pendingSource.wrappedValue {
            case .camera: showCamera.wrappedValue = true
            case .library: showPhotoPicker.wrappedValue = true
            case .files: showFileImporter.wrappedValue = true
            case nil: break
            }
            pendingSource.wrappedValue = nil
        } content: {
            AttachmentSourceSheet(
                onCamera: {
                    pendingSource.wrappedValue = .camera
                    showChoice.wrappedValue = false
                },
                onAllPhotos: {
                    pendingSource.wrappedValue = .library
                    showChoice.wrappedValue = false
                },
                onFiles: {
                    pendingSource.wrappedValue = .files
                    showChoice.wrappedValue = false
                },
                onPickedPhoto: onImage
            )
        }
        .fullScreenCover(isPresented: showCamera) {
            CameraPicker(
                onCapture: { image in
                    showCamera.wrappedValue = false
                    onImage(image)
                },
                onCancel: { showCamera.wrappedValue = false }
            )
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: showPhotoPicker, selection: pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto.wrappedValue) { _, item in
            guard let item else { return }
            Task {
                defer { pickedPhoto.wrappedValue = nil }
                guard let data = try? await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else {
                    onFailure(String(localized: "Photo illisible"))
                    return
                }
                onImage(image)
            }
        }
        .fileImporter(isPresented: showFileImporter, allowedContentTypes: [.pdf, .image]) { result in
            switch result {
            case .success(let url): onFile(url)
            case .failure(let error): onFailure(error.localizedDescription)
            }
        }
    }
}
