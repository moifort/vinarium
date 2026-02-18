import XCTest

@MainActor
struct DashboardPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.navigationBars["Accueil"].waitForExistence(timeout: 5))
        return self
    }

    @discardableResult
    func refresh() -> Self {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)
        return self
    }

    func verifyBottleCount(_ expected: String) {
        let widget = app.buttons["stat-bottles"]
        XCTAssertTrue(widget.waitForExistence(timeout: 5))
        XCTAssertTrue(widget.label.contains(expected), "stat-bottles label '\(widget.label)' should contain '\(expected)'")
    }

    func verifyTotalValue(_ expected: String) {
        let widget = app.buttons["stat-value"]
        XCTAssertTrue(widget.waitForExistence(timeout: 5))
        XCTAssertTrue(widget.label.contains(expected), "stat-value label '\(widget.label)' should contain '\(expected)'")
    }

    func verifyReadyToDrinkContains(_ wineName: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", wineName)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 3) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "'\(wineName)' not found in ready to drink")
        }
    }

    func verifyJournalContains(_ wineName: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", wineName)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 3) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "'\(wineName)' not found in journal")
        }
    }

    func verifyJournalShowsEntry() {
        let predicate = NSPredicate(format: "label CONTAINS %@", "Entrée")
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 3) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "'Entrée' not found in journal")
        }
    }

    func tapWine(named name: String) -> WineDetailPage {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let wineButton = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(wineButton.waitForExistence(timeout: 5), "Wine button '\(name)' not found")
        wineButton.tap()
        return WineDetailPage(app: app)
    }
}
