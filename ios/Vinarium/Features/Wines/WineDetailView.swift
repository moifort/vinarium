import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct WineDetailView: View {
    let wineId: String
    /// What the page opens straight onto once the wine is loaded: the home screen's
    /// buttons take a bottle out, mark it a favorite or move it from here.
    var initialAction: InitialAction?
    var onRemoved: (() -> Void)?
    var onUpdated: (() -> Void)?

    enum InitialAction { case remove, favorite, move }

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
    /// The household's cellars, to name the bottle's one once there are several.
    @State private var cellars: [CellarSummary] = []
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
    @State private var initialActionDone = false

    var body: some View {
        Group {
            if isLoading {
                LoadingStateView()
            } else if let detail {
                WineDetailPage(
                    content: Self.mapContent(
                        detail,
                        cellars: cellars,
                        isUploadingAttachment: isUploadingAttachment
                    ),
                    onAction: handle,
                    onRefresh: { await loadData() }
                )
            } else if error != nil {
                // Nothing shows, and a pull tries again.
                PullToRefreshSpace()
                    .refreshable { await loadData() }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { readToolbar }
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
            runInitialAction()
        }
        // Editing is a task, so a sheet over the page, as Shiori edits a book.
        .sheet(isPresented: $isEditing) {
            if let detail {
                NavigationStack {
                    WineEditForm(
                        initial: Self.editFields(from: detail),
                        onSave: { submission in
                            self.detail = try await save(submission, of: detail)
                            isEditing = false
                            onUpdated?()
                        },
                        onCancel: { isEditing = false }
                    )
                }
            }
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
                    currentCellarId: cellar.cellarId,
                    onCancel: { showMove = false }
                ) { _, _ in
                    showMove = false
                    // The bottle may have changed cellar as well as slot: the
                    // sheet reads it back rather than guess.
                    Task { await loadData() }
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var readToolbar: some ToolbarContent {
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

    // MARK: - Actions

    /// What the page asks for. Taking the bottle out, moving it, editing it and its
    /// place open their sheets; the favourite opens its sheet or, already set, is
    /// taken off at once.
    private func handle(_ action: WineDetailPage.Action) {
        switch action {
        case .removeFromCellar: showRemovalChoice = true
        case .toggleFavorite: toggleFavorite()
        case .move: showMove = true
        case .edit: isEditing = true
        case .editLocation: showLocationEditor = true
        case .addAttachment: showAttachmentChoice = true
        case .openAttachment(let attachment): Task { await openAttachment(attachment) }
        case .deleteAttachment(let attachment): Task { await deleteAttachment(attachment) }
        }
    }

    /// A favourite is taken off at once; a wine that is not one asks the tasting
    /// that makes it one.
    private func toggleFavorite() {
        guard let detail else { return }
        if detail.consumption?.favorite == true {
            Task {
                await actionError.run {
                    self.detail = try await WineAPI.saveNotes(id: detail.id, tasting: TastingEntry(favorite: false))
                } onSuccess: {
                    onUpdated?()
                }
            }
        } else {
            showFavorite = true
        }
    }

    // MARK: - Helpers

    /// Opens what the caller asked for, once, over the loaded wine. A bottle that left
    /// the cellar meanwhile simply shows its sheet.
    private func runInitialAction() {
        guard let initialAction, !initialActionDone, let detail else { return }
        initialActionDone = true
        let inCellar = detail.cellar != nil && detail.cellar?.dateOut == nil
        switch initialAction {
        case .remove:
            if inCellar { showRemovalChoice = true }
        case .move:
            if inCellar { showMove = true }
        case .favorite:
            toggleFavorite()
        }
    }

    private func loadData() async {
        // A pull-to-refresh: keep the content on screen and show the scrim rather
        // than replacing the whole page with a spinner.
        if detail != nil { isRefreshing = true }
        defer { isRefreshing = false }
        do {
            // The cellars only name the slot: the sheet opens without them.
            async let household = try? CellarAPI.cellars()
            let loadedDetail = try await WineAPI.getDetail(id: wineId)
            cellars = await household ?? cellars
            detail = loadedDetail
            error = nil
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

    /// Internal so the debug gallery can draw a sheet from a wine fixture.
    static func mapContent(
        _ detail: UserWineDetail,
        cellars: [CellarSummary],
        isUploadingAttachment: Bool,
        now: Date = .now
    ) -> WineDetailPage.Content {
        let day: (Date) -> String = { $0.formatted(date: .abbreviated, time: .omitted) }
        let inCellar = detail.cellar.map { $0.dateOut == nil } ?? false
        let place = detail.appellation ?? detail.region ?? detail.country
        let meta = [detail.vintage.map(String.init), place].compactMap { $0 }.joined(separator: " · ")

        var facts: [WineFactList.Fact] = []
        func fact(_ title: String, _ value: String?, wide: Bool = false, _ id: String) {
            guard let value, !value.isEmpty else { return }
            facts.append(.init(title: title, value: value, isWide: wide, id: id))
        }
        fact(detail.beverageType.producerLabel, detail.domain, "producer")
        fact(String(localized: "Cuvée"), detail.cuvee, "cuvee")
        fact(String(localized: "Millésime"), detail.vintage.map(String.init), "vintage")
        fact(String(localized: "Alcool"), detail.alcoholContent.map { String(format: "%.1f %% vol", $0) }, "alcohol")
        fact(String(localized: "Appellation"), detail.appellation, "appellation")
        fact(String(localized: "Région"), detail.region, "region")
        fact(String(localized: "Pays"), detail.country, "country")
        fact(String(localized: "Classification"), detail.classification, "classification")
        fact(String(localized: "Entrée le"), detail.cellar.map { day($0.dateIn) }, "dateIn")
        fact(String(localized: "Prix d'achat"), detail.purchasePrice.map { Money.formattedFromEur($0, fractionLength: 0) }, "price")
        fact(String(localized: "Date d'achat"), detail.purchaseDate.map { Self.purchaseDay($0) ?? $0 }, "purchaseDate")
        fact(String(localized: "Propriétaire"), detail.ownerName, "owner")
        fact(String(localized: "Cépages"), detail.grapeVarieties.isEmpty ? nil : detail.grapeVarieties.joined(separator: ", "), wide: true, "grapes")

        var history: [WineFactList.Fact] = []
        if let dateOut = detail.cellar?.dateOut {
            history.append(.init(title: String(localized: "Sortie le"), value: day(dateOut), id: "dateOut"))
        }
        if let gift = detail.gift {
            history.append(.init(title: String(localized: "Offert le"), value: day(gift.giftedDate), id: "giftedDate"))
            if let recipient = gift.recipientName {
                history.append(.init(title: String(localized: "Destinataire"), value: recipient, id: "recipient"))
            }
        }
        if let giftedBy = detail.giftedBy {
            history.append(.init(title: String(localized: "Offert par"), value: giftedBy, id: "giftedBy"))
        }

        let tone = WineSheetTone(beverageType: detail.beverageType, color: detail.color)
        let tag: String? = detail.subtype?.label(for: detail.beverageType)
            ?? (detail.beverageType == .wine ? detail.color?.label : detail.beverageType.label)

        return WineDetailPage.Content(
            tone: tone,
            hero: .init(
                bottle: .init(
                    style: .of(
                        id: detail.id,
                        beverageType: detail.beverageType,
                        subtype: detail.subtype,
                        color: detail.color,
                        family: detail.labelFamily,
                        traits: detail.labelTraits,
                        vintage: detail.vintage
                    ),
                    // Written as the home writes it, so the bottle is the same one.
                    text: .init(
                        producer: ProducerOverline.text(for: detail.domain, name: detail.name),
                        name: detail.name,
                        vintage: detail.vintage,
                        appellation: detail.appellation,
                        classification: detail.classification,
                        kind: detail.beverageType == .wine
                            ? nil
                            : detail.subtype?.label(for: detail.beverageType) ?? detail.beverageType.label
                    )
                ),
                producer: detail.domain,
                name: detail.name,
                meta: meta.isEmpty ? nil : meta,
                tag: tag,
                status: inCellar ? detail.cellar.map { Self.timeInCellar(since: $0.dateIn, now: now) } : nil,
                isInCellar: inCellar,
                isFavorite: detail.consumption?.favorite == true
            ),
            slot: inCellar ? detail.cellar.map { cellar in
                let household = cellars.map { ($0.id, $0.name) }
                let summary = cellars.first { $0.id == cellar.cellarId } ?? (cellars.count == 1 ? cellars.first : nil)
                var grid: CellarSlotCard.Grid?
                if let summary, summary.rows > 0, summary.cols > 0,
                   let row = cellar.rowIndex, let col = cellar.colIndex,
                   row < summary.rows, col < summary.cols {
                    grid = .init(rows: summary.rows, cols: summary.cols, row: row, col: col)
                }
                return .init(
                    position: "\(cellar.row)\(cellar.col)",
                    cellarName: CellarPositionLabel.cellarName(cellarId: cellar.cellarId, cellars: household),
                    grid: grid
                )
            } : nil,
            // Like the slot, the drinking window only matters for a bottle still to open.
            window: inCellar ? detail.drinkFrom.flatMap { from in
                detail.drinkUntil.flatMap { until in until >= from ? .init(from: from, until: until) : nil }
            } : nil,
            facts: facts,
            consumption: detail.consumption.flatMap { consumption in
                var facts: [WineFactList.Fact] = []
                if let date = consumption.consumedDate {
                    facts.append(.init(title: String(localized: "Consommé le"), value: day(date), id: "consumed"))
                }
                if let contacts = consumption.contacts, !contacts.isEmpty {
                    facts.append(.init(title: String(localized: "Avec"), value: contacts.joined(separator: ", "), id: "contacts"))
                }
                let notes = consumption.tastingNotes.flatMap { $0.isEmpty ? nil : $0 }
                guard !facts.isEmpty || consumption.rating != nil || notes != nil else { return nil }
                return .init(facts: facts, rating: consumption.rating, tastingNotes: notes)
            },
            history: history,
            recommendation: detail.recommendation.map {
                .init(
                    recommenderName: $0.recommenderName.flatMap { $0.isEmpty ? nil : $0 },
                    comment: $0.comment.flatMap { $0.isEmpty ? nil : $0 }
                )
            },
            placeName: detail.placeName,
            latitude: detail.latitude,
            longitude: detail.longitude,
            notes: detail.notes.flatMap { $0.isEmpty ? nil : $0 },
            attachments: detail.attachments,
            canEdit: detail.isMine,
            canAttach: detail.isMine,
            isUploadingAttachment: isUploadingAttachment
        )
    }

    /// "En cave depuis 41 jours", then in months past two months and in years past two
    /// years, as a person would say it.
    private static func timeInCellar(since dateIn: Date, now: Date) -> String {
        let parts = Calendar.current.dateComponents([.day, .month, .year], from: dateIn, to: now)
        let days = max(Calendar.current.dateComponents([.day], from: dateIn, to: now).day ?? 0, 0)
        if let years = parts.year, years >= 2 {
            return String(localized: "En cave depuis \(years) ans")
        }
        let months = (parts.year ?? 0) * 12 + (parts.month ?? 0)
        if months >= 2 {
            return String(localized: "En cave depuis \(months) mois")
        }
        return String(localized: "En cave depuis \(days) jours")
    }

    /// The purchase day the API gives ("2026-09-12"), written as the sheet writes days.
    private static func purchaseDay(_ raw: String) -> String? {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withFullDate]
        let date = parser.date(from: String(raw.prefix(10)))
        return date?.formatted(date: .abbreviated, time: .omitted)
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
    NavigationStack { WineDetailView(wineId: "5d288fc9-864d-4633-862a-b4410cf8b64a") }
}

#Preview("In cellar") {
    NavigationStack { WineDetailView(wineId: "c2f5486a-29d6-4a32-b3e9-323ab1bee3d1") }
}

#Preview("Recommend") {
    NavigationStack { WineDetailView(wineId: "19fe3138-e125-4df9-afe6-90e1505a0326") }
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
