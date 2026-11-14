import SwiftUI

/// One wine's sheet in the TV app's grammar: a hero over the wine's colours (the
/// bottle turning on itself, what the wine is, how long it has been in the cellar,
/// what is done to it), then where it stands in the cellar and in its drinking window
/// on two glass cards, then blocks on the page without cards around them: the facts,
/// what happened to the bottle (tasted, given), what was said of it as a conversation,
/// where it was tasted and the files. Only what is known is drawn. Pure and previewable: the screen
/// owns the sheets and the calls, the page says what was tapped.
struct WineDetailPage: View {
    let content: Content
    var onAction: (Action) -> Void = { _ in }
    var onRefresh: () async -> Void = {}

    enum Action {
        case removeFromCellar
        case toggleFavorite
        case move
        case edit
        case editLocation
        case addAttachment
        case openAttachment(BeverageAttachment)
        case deleteAttachment(BeverageAttachment)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                WineSheetHero(
                    item: content.hero,
                    onRemove: { onAction(.removeFromCellar) },
                    onToggleFavorite: { onAction(.toggleFavorite) },
                    onMove: { onAction(.move) }
                )
                .padding(.horizontal, 20)
                .padding(.top, 4)

                cards

                VStack(alignment: .leading, spacing: 30) {
                    block("Informations", detail: content.canEdit ? "modifier" : nil, action: { onAction(.edit) }) {
                        WineFactList(facts: content.facts)
                    }
                    if let consumption = content.consumption, consumption.hasFacts {
                        block("Consommé") { consumptionBody(consumption) }
                    }
                    if !content.history.isEmpty {
                        block("Historique") { WineFactList(facts: content.history) }
                    }
                    comments
                    block("Lieu de dégustation") {
                        WineLocationMap(
                            placeName: content.placeName,
                            latitude: content.latitude,
                            longitude: content.longitude,
                            onTap: { onAction(.editLocation) }
                        )
                    }
                    if content.canAttach || !content.attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            header("Pièces jointes")
                            AttachmentShelf(
                                attachments: content.attachments,
                                canEdit: content.canAttach,
                                isUploading: content.isUploadingAttachment,
                                onAdd: { onAction(.addAttachment) },
                                onOpen: { onAction(.openAttachment($0)) },
                                onDelete: { onAction(.deleteAttachment($0)) }
                            )
                        }
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 44)
            }
            .background(alignment: .top) {
                // Up under the toolbar, whose glass buttons float over the colours.
                WineSheetBackdrop(tone: content.tone)
                    .padding(.top, -200)
            }
        }
        .background(Color(.systemGroupedBackground))
        .refreshable { await onRefresh() }
    }

    // MARK: - Cards

    /// The slot and the drinking window side by side; either one alone takes the row.
    @ViewBuilder private var cards: some View {
        if content.slot != nil || content.window != nil {
            HStack(spacing: 13) {
                if let slot = content.slot {
                    CellarSlotCard(
                        position: slot.position,
                        cellarName: slot.cellarName,
                        grid: slot.grid,
                        accent: content.tone.accent
                    )
                }
                if let window = content.window {
                    DrinkingWindowCard(from: window.from, until: window.until, accent: content.tone.accent)
                }
            }
            .frame(height: 196)
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
    }

    // MARK: - Blocks

    private func block(
        _ title: LocalizedStringKey,
        detail: LocalizedStringKey? = nil,
        action: @escaping () -> Void = {},
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            header(title, detail: detail, action: action)
            content()
                .padding(.horizontal, 20)
        }
    }

    /// A block's title, as the TV app heads a row; "modifier" on its right when the
    /// block can be edited.
    private func header(
        _ title: LocalizedStringKey,
        detail: LocalizedStringKey? = nil,
        action: @escaping () -> Void = {}
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let detail {
                Button(action: action) {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("wine-detail-edit")
            }
        }
        .padding(.horizontal, 20)
    }

    private func consumptionBody(_ consumption: Content.Consumption) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            WineFactList(facts: consumption.facts)
            if let rating = consumption.rating {
                HStack {
                    Text("Note")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    StarRatingView(rating: rating, font: .subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Comments

    /// What was said of the wine, as a conversation: the words of whoever
    /// recommended it in a grey bubble under their name, the owner's own notes and
    /// tasting notes in blue ones, as Messages draws a group. Nothing when nobody
    /// said anything: the words are written from the edit form, which a tap on a
    /// bubble opens.
    @ViewBuilder private var comments: some View {
        let tastingNotes = content.consumption?.tastingNotes
        if content.recommendation != nil || content.notes != nil || tastingNotes != nil {
            let edit: (() -> Void)? = content.canEdit ? { onAction(.edit) } : nil
            block("Commentaires") {
                VStack(spacing: 10) {
                    // A recommendation that names someone and says nothing still
                    // reads as their word on it.
                    if let recommendation = content.recommendation {
                        MessageBubble(
                            text: recommendation.comment ?? String(localized: "Je te le conseille."),
                            sender: recommendation.recommenderName ?? String(localized: "Conseillé"),
                            action: edit
                        )
                        .accessibilityIdentifier("wine-recommendation-comment")
                    }
                    if let notes = content.notes {
                        MessageBubble(text: notes, isMine: true, action: edit)
                            .accessibilityIdentifier("wine-notes")
                    }
                    if let tastingNotes {
                        MessageBubble(text: tastingNotes, isMine: true, action: edit)
                            .accessibilityIdentifier("wine-tasting-notes")
                    }
                }
            }
        }
    }
}

// MARK: - Content

extension WineDetailPage {
    /// Everything the sheet draws, already worded: the screen maps the wine to it.
    struct Content {
        let tone: WineSheetTone
        let hero: WineSheetHero.Item
        var slot: Slot?
        var window: Window?
        let facts: [WineFactList.Fact]
        var consumption: Consumption?
        /// Given, received, taken out: when and to whom.
        var history: [WineFactList.Fact] = []
        var recommendation: Recommendation?
        var placeName: String?
        var latitude: Double?
        var longitude: Double?
        var notes: String?
        var attachments: [BeverageAttachment] = []
        /// Only the owner edits the sheet and attaches files; a housemate's bottle
        /// shows its facts and files read-only.
        var canEdit = false
        var canAttach = false
        var isUploadingAttachment = false

        struct Slot {
            let position: String
            var cellarName: String?
            var grid: CellarSlotCard.Grid?
        }

        struct Window {
            let from: Int
            let until: Int
        }

        struct Consumption {
            let facts: [WineFactList.Fact]
            let rating: Int?
            let tastingNotes: String?

            /// The tasting's day, company or rating: its words alone go to the comments.
            var hasFacts: Bool { !facts.isEmpty || rating != nil }
        }

        struct Recommendation {
            let recommenderName: String?
            let comment: String?
        }
    }
}

extension WineDetailPage.Content {
    static let preview = WineDetailPage.Content(
        tone: .red,
        hero: .preview,
        slot: .init(position: "A1", grid: .init(rows: 4, cols: 6, row: 0, col: 0)),
        window: .init(from: 2025, until: 2040),
        facts: [
            .init(title: "Domaine", value: "Château Margaux", id: "producer"),
            .init(title: "Cuvée", value: "Pavillon Rouge", id: "cuvee"),
            .init(title: "Millésime", value: "2015", id: "vintage"),
            .init(title: "Alcool", value: "13,5 % vol", id: "alcohol"),
            .init(title: "Appellation", value: "Margaux", id: "appellation"),
            .init(title: "Région", value: "Bordeaux", id: "region"),
            .init(title: "Pays", value: "France", id: "country"),
            .init(title: "Entrée le", value: "4 oct. 2026", id: "dateIn"),
            .init(title: "Prix d'achat", value: "250 €", id: "price"),
            .init(title: "Date d'achat", value: "12 sept. 2026", id: "purchaseDate"),
            .init(title: "Cépages", value: "Cabernet Sauvignon, Merlot", isWide: true, id: "grapes"),
        ],
        placeName: "Margaux, France",
        latitude: 45.0436,
        longitude: -0.6731,
        notes: "Acheté chez Lavinia pour les 40 ans de Paul. À carafer deux heures avant.",
        canEdit: true,
        canAttach: true
    )
}

#Preview("In cellar") {
    NavigationStack {
        WineDetailPage(content: .preview)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Tasted") {
    var content = WineDetailPage.Content(
        tone: .white,
        hero: .init(
            bottle: .init(
                style: .of(id: "2", beverageType: .wine, subtype: nil, color: .white, family: .loire, vintage: 2022),
                text: .init(producer: nil, name: "Pouilly-Fumé", vintage: 2022, appellation: "Pouilly-Fumé", classification: nil, kind: nil)
            ),
            producer: nil,
            name: "Pouilly-Fumé",
            meta: "2022 · Pouilly-Fumé",
            tag: "Blanc",
            status: nil,
            isInCellar: false,
            isFavorite: true
        ),
        facts: [
            .init(title: "Millésime", value: "2022", id: "vintage"),
            .init(title: "Région", value: "Loire", id: "region"),
            .init(title: "Cépages", value: "Sauvignon Blanc", isWide: true, id: "grapes"),
        ]
    )
    content.consumption = .init(
        facts: [
            .init(title: "Consommé le", value: "14 avr. 2024", id: "consumed"),
            .init(title: "Avec", value: "Jean, Marie", id: "contacts"),
        ],
        rating: 4,
        tastingNotes: "Très frais, belle minéralité"
    )
    content.recommendation = .init(recommenderName: "Marie", comment: "Parfait sur des huîtres.")
    return NavigationStack {
        WineDetailPage(content: content)
    }
}
