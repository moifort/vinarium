import XCTest

@MainActor
struct WineDetailPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.buttons["Fermer"].waitForExistence(timeout: 5))
        return self
    }

    func verifyWineName(_ name: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let element = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Wine name '\(name)' not found")
    }

    func verifyTextVisible(_ text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 3) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "Text '\(text)' not found")
        }
    }

    func verifyPosition(_ position: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", position)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 3) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "Position '\(position)' not found")
        }
    }

    func verifyCellarSection() {
        XCTAssertTrue(app.staticTexts["En cave"].waitForExistence(timeout: 5), "'En cave' section not found")
    }

    func verifyConsumptionSection() {
        XCTAssertTrue(app.staticTexts["Consommé"].waitForExistence(timeout: 5), "'Consommé' section not found")
    }

    func tapRemoveFromCellar() -> ConsumptionPage {
        let removeButton = app.buttons["remove-from-cellar-button"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 5))
        removeButton.tap()
        return ConsumptionPage(app: app)
    }

    func close() {
        app.buttons["Fermer"].tap()
    }
}
