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
        XCTAssertTrue(app.staticTexts["Rangée \(row)"].waitForExistence(timeout: 5))
    }

    func verifyPositionVisible(_ position: String) {
        XCTAssertTrue(app.staticTexts[position].waitForExistence(timeout: 5))
    }

    func verifyJournalShowsEntry() {
        XCTAssertTrue(app.staticTexts["Entrée"].waitForExistence(timeout: 5))
    }

    func verifyJournalShowsExit() {
        XCTAssertTrue(app.staticTexts["Sortie"].waitForExistence(timeout: 5))
    }

    func tapWine(named name: String) -> WineDetailPage {
        let wineButton = app.buttons.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(wineButton.waitForExistence(timeout: 5))
        wineButton.tap()
        return WineDetailPage(app: app)
    }
}
