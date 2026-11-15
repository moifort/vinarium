import Foundation

/// What the screen a wine was tapped on already knows of it: enough to draw the
/// sheet's hero (its bottle, its name, where it comes from, its colours) the
/// moment the sheet is pushed, while its own request is on its way. The rest of
/// the sheet follows when that request lands.
struct WineSheetPreview: Sendable {
    let id: String
    let name: String
    var beverageType: BeverageType = .wine
    var subtype: BeverageSubtype? = nil
    var color: WineColor? = nil
    var producer: String? = nil
    var vintage: Int? = nil
    var appellation: String? = nil
    var region: String? = nil
    var country: String? = nil
    var classification: String? = nil
    var labelFamily: BottleArtwork.LabelFamily? = nil
    var labelTraits: BottleArtwork.LabelTraits? = nil
    /// Whether the bottle stands in the cellar: its actions show under the hero.
    var isInCellar: Bool = false
    var rating: Int? = nil
}

extension WineSheetPreview {
    /// A row of the wine list, of the search or of the cellar.
    init(wine: Wine) {
        self.init(
            id: wine.id,
            name: wine.name,
            beverageType: wine.beverageType,
            subtype: wine.subtype,
            color: wine.color,
            producer: wine.domain,
            vintage: wine.vintage,
            appellation: wine.appellation,
            region: wine.region,
            country: wine.country,
            classification: wine.classification,
            labelFamily: wine.labelFamily,
            labelTraits: wine.labelTraits,
            isInCellar: wine.isInCellar,
            rating: wine.rating
        )
    }

    /// A bottle the home shows as ready to open.
    init(ready wine: DashboardWine) {
        self.init(
            id: wine.id,
            name: wine.name,
            beverageType: wine.beverageType,
            subtype: wine.subtype,
            color: wine.color,
            producer: wine.producer,
            vintage: wine.vintage,
            appellation: wine.appellation,
            classification: wine.classification,
            labelFamily: wine.labelFamily,
            labelTraits: wine.labelTraits,
            isInCellar: true
        )
    }

    /// A favourite on the home. Whether a bottle of it still stands in the cellar
    /// is the sheet's to say: its actions show once it has answered.
    init(favorite wine: DashboardFavorite) {
        self.init(
            id: wine.id,
            name: wine.name,
            beverageType: wine.beverageType,
            subtype: wine.subtype,
            color: wine.color,
            producer: wine.producer,
            vintage: wine.vintage,
            appellation: wine.appellation,
            classification: wine.classification,
            labelFamily: wine.labelFamily,
            labelTraits: wine.labelTraits,
            rating: wine.rating
        )
    }
}

extension DashboardData {
    /// The hero of a wine the home shows, for the sheet it opens. Nil for a wine
    /// only named in the activity, whose bottle the home does not know enough of.
    func sheetPreview(for id: String) -> WineSheetPreview? {
        if let wine = readyToDrink.first(where: { $0.id == id }) { return .init(ready: wine) }
        if let wine = favorites.first(where: { $0.id == id }) { return .init(favorite: wine) }
        return nil
    }
}
