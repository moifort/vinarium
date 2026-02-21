import XCTest

@MainActor
struct ScanReviewPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Vérifier le vin"].waitOrFail()
        return self
    }

    func clearAndTypeName(_ name: String) throws -> Self {
        let nameField = try app.textFields["Nom du vin"].waitOrFail()
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

    func tapSave() throws -> PlacementPage {
        app.swipeUp()
        try app.buttons["review-save-button"].tapOrFail()
        return PlacementPage(app: app)
    }

    func tapFavorite() throws {
        app.swipeUp()
        try app.buttons["review-more-menu"].tapOrFail()
        try app.buttons["review-favorite-button"].tapOrFail()
    }

    func tapRecommend() throws {
        app.swipeUp()
        try app.buttons["review-more-menu"].tapOrFail()
        try app.buttons["review-recommend-button"].tapOrFail()
    }
}
