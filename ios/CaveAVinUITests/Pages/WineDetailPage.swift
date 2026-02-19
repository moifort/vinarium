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
        return ConsumptionPage(app: app)
    }

    func close() throws {
        try app.buttons["Fermer"].tapOrFail()
    }
}
