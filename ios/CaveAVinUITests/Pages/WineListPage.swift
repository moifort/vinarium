import XCTest

@MainActor
struct WineListPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.navigationBars["Mes Vins"].waitForExistence(timeout: 5))
        return self
    }

    func verifyWineVisible(_ name: String) {
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    func verifyWineNotVisible(_ name: String) {
        XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 2))
    }

    func verifyTextVisible(_ text: String) {
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5))
    }

    func switchToFavorites() -> Self {
        app.segmentedControls["winelist-segment"].buttons["5 ⭐"].tap()
        return self
    }

    func switchToAll() -> Self {
        app.segmentedControls["winelist-segment"].buttons["Tous"].tap()
        return self
    }

    func openSortMenu() -> Self {
        app.buttons["winelist-sort-menu"].tap()
        return self
    }

    func selectSort(_ label: String) -> Self {
        app.buttons[label].tap()
        return self
    }

    func selectStatusFilter(_ label: String) -> Self {
        app.buttons[label].tap()
        return self
    }

    func tapWine(named name: String) -> WineDetailPage {
        let wineButton = app.buttons.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(wineButton.waitForExistence(timeout: 5))
        wineButton.tap()
        return WineDetailPage(app: app)
    }

    func verifyWineOrder(first: String, second: String) {
        let firstElement = app.staticTexts[first]
        let secondElement = app.staticTexts[second]
        XCTAssertTrue(firstElement.waitForExistence(timeout: 5))
        XCTAssertTrue(secondElement.exists)
        XCTAssertLessThan(firstElement.frame.minY, secondElement.frame.minY)
    }
}
