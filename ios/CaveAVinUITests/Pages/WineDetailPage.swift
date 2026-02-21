import XCTest

@MainActor
struct WineDetailPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.buttons["Fermer"].waitOrFail()
        return self
    }

    func verifyWineName(_ name: String) throws {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        try app.staticTexts.matching(predicate).firstMatch.waitOrFail(timeout: 4, "Wine name '\(name)' not found")
    }

    func verifyCellarSection() throws {
        app.swipeUp()
        try app.staticTexts["Cave"].waitOrFail(timeout: 4, "'Cave' section not found")
    }

    func verifyConsumptionSection() throws {
        app.swipeUp()
        try app.staticTexts["Consommé"].waitOrFail(timeout: 4, "'Consommé' section not found")
    }

    func tapRemoveFromCellar() throws -> ConsumptionPage {
        app.swipeUp()
        try app.buttons["remove-from-cellar-button"].tapOrFail()
        try app.buttons["choice-consume"].firstMatch.tapOrFail()
        return ConsumptionPage(app: app)
    }

    func tapRemoveAndChooseGift() throws -> GiftPage {
        app.swipeUp()
        try app.buttons["remove-from-cellar-button"].tapOrFail()
        try app.buttons["choice-gift"].firstMatch.tapOrFail()
        return GiftPage(app: app)
    }

    func verifyGiftSection() throws {
        app.swipeUp()
        try app.staticTexts["Offert"].waitOrFail(timeout: 4, "'Offert' section not found")
    }

    func tapDelete() throws {
        try app.buttons["delete-wine-button"].tapOrFail()
        try app.buttons["choice-delete"].firstMatch.tapOrFail()
    }

    func close() throws {
        try app.buttons["Fermer"].tapOrFail()
    }
}
