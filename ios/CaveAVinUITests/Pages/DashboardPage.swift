import XCTest

@MainActor
struct DashboardPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.navigationBars["Accueil"].waitForExistence(timeout: 5))
        return self
    }

    func verifyBottleCount(_ expected: String) {
        let widget = app.otherElements["stat-bottles"]
        XCTAssertTrue(widget.waitForExistence(timeout: 5))
        XCTAssertTrue(widget.staticTexts[expected].exists)
    }

    func verifyTotalValue(_ expected: String) {
        let widget = app.otherElements["stat-value"]
        XCTAssertTrue(widget.waitForExistence(timeout: 5))
        XCTAssertTrue(widget.staticTexts[expected].exists)
    }

    func verifyReadyToDrinkContains(_ wineName: String) {
        let label = app.staticTexts[wineName]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
    }

    func verifyJournalContains(_ wineName: String) {
        let label = app.staticTexts[wineName]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
    }

    func verifyJournalShowsEntry() {
        XCTAssertTrue(app.staticTexts["Entrée"].waitForExistence(timeout: 5))
    }

    func tapWine(named name: String) -> WineDetailPage {
        let wineButton = app.buttons.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(wineButton.waitForExistence(timeout: 5))
        wineButton.tap()
        return WineDetailPage(app: app)
    }
}
