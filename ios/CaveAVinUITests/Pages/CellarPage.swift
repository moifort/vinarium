import XCTest

@MainActor
struct CellarPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.navigationBars["Ma Cave"].waitForExistence(timeout: 5))
        return self
    }

    func switchToCave() -> Self {
        app.segmentedControls["cellar-segment"].buttons["Cave"].tap()
        return self
    }

    func switchToJournal() -> Self {
        app.segmentedControls["cellar-segment"].buttons["Journal"].tap()
        return self
    }

    func verifyRowHeader(_ row: String) {
        let text = "Rangée \(row)"
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5), "Row header '\(text)' not found")
    }

    func verifyPositionVisible(_ position: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", position)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 3) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 2), "Position '\(position)' not found")
        }
    }

    func verifyJournalShowsEntry() {
        XCTAssertTrue(app.staticTexts["Entrée"].waitForExistence(timeout: 5), "'Entrée' not found")
    }

    func verifyJournalShowsExit() {
        XCTAssertTrue(app.staticTexts["Sortie"].waitForExistence(timeout: 5), "'Sortie' not found")
    }

    func tapWine(named name: String) -> WineDetailPage {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let wineButton = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(wineButton.waitForExistence(timeout: 5), "Wine button '\(name)' not found")
        wineButton.tap()
        return WineDetailPage(app: app)
    }
}
