import XCTest

/// Écran de choix de destination affiché juste après l'analyse IA.
@MainActor
struct ScanDestinationChoicePage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Nouvelle bouteille"].waitOrFail()
        return self
    }

    func chooseCellar() throws -> ScanReviewPage {
        try choose("destination-cellar")
    }

    func chooseFavorite() throws -> ScanReviewPage {
        try choose("destination-favorite")
    }

    func chooseShortlist() throws -> ScanReviewPage {
        try choose("destination-shortlist")
    }

    func chooseRecommendation() throws -> ScanReviewPage {
        try choose("destination-recommendation")
    }

    private func choose(_ identifier: String) throws -> ScanReviewPage {
        try app.buttons[identifier].tapOrFail()
        return ScanReviewPage(app: app)
    }
}
