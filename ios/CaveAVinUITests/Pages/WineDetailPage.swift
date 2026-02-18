import XCTest

@MainActor
struct WineDetailPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        // Wine detail is presented as a sheet - wait for the close button
        XCTAssertTrue(app.buttons["Fermer"].waitForExistence(timeout: 5))
        return self
    }

    func verifyWineName(_ name: String) {
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    func verifyTextVisible(_ text: String) {
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5))
    }

    func verifyPosition(_ position: String) {
        XCTAssertTrue(app.staticTexts[position].waitForExistence(timeout: 5))
    }

    func verifyCellarSection() {
        XCTAssertTrue(app.staticTexts["En cave"].waitForExistence(timeout: 5))
    }

    func verifyConsumptionSection() {
        XCTAssertTrue(app.staticTexts["Consommé"].waitForExistence(timeout: 5))
    }

    func verifyStarRating(_ count: Int) {
        // Stars are displayed as star.fill images in the consumption section
        let stars = app.images.matching(NSPredicate(format: "label == 'star.fill'"))
        XCTAssertGreaterThanOrEqual(stars.count, count)
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
