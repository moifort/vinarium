import XCTest

@MainActor
struct ScanReviewPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Vérifier la bouteille"].waitOrFail()
        return self
    }

    func clearAndTypeName(_ name: String) throws -> Self {
        let nameField = try app.textFields["review-name-field"].waitOrFail()
        // Triple-tap to select all text, then type to replace
        nameField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        nameField.typeText(name)
        return self
    }

    func selectColor(_ color: String) throws -> Self {
        try app.buttons["Couleur"].tapOrFail()
        try app.buttons[color].tapOrFail()
        return self
    }

    func typeVintage(_ vintage: String) throws -> Self {
        let vintageField = try app.textFields["Année"].waitOrFail()
        vintageField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        vintageField.typeText(vintage)
        return self
    }

    func typePrice(_ price: String) throws -> Self {
        app.swipeUp()
        let priceField = try app.textFields["review-price-field"].waitOrFail()
        priceField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        priceField.typeText(price)
        return self
    }

    func typeRecommenderName(_ name: String) throws -> Self {
        let field = try app.textFields["review-recommender-field"].waitOrFail()
        field.tap()
        field.typeText(name)
        return self
    }

    /// Ouvre la popup de choix (bouton +) puis tape le choix demandé.
    private func chooseDestination(_ identifier: String) throws {
        app.swipeUp()
        try app.buttons["review-save-button"].tapOrFail()
        try app.buttons[identifier].tapOrFail()
    }

    /// Ajout vers la cave : enchaîne sur le placement.
    func addToCellar() throws -> PlacementPage {
        try chooseDestination("choice-cellar")
        return PlacementPage(app: app)
    }

    func addAsFavorite() throws {
        try chooseDestination("choice-favorite")
    }

    func addAsRecommendation() throws {
        try chooseDestination("choice-recommendation")
    }

    func justSave() throws {
        try chooseDestination("choice-justSave")
    }
}
