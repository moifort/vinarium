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
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 5) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 3), "Wine '\(name)' not visible")
        }
    }

    func verifyWineNotVisible(_ name: String) {
        XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 2), "Wine '\(name)' should not be visible")
    }

    func verifyTextVisible(_ text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 5) {
            let button = app.buttons.matching(predicate).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 3), "Text '\(text)' not found")
        }
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
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let wineButton = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(wineButton.waitForExistence(timeout: 5), "Wine button '\(name)' not found")
        wineButton.tap()
        return WineDetailPage(app: app)
    }

    func verifyWineOrder(first: String, second: String) {
        let predicate1 = NSPredicate(format: "label CONTAINS %@", first)
        let predicate2 = NSPredicate(format: "label CONTAINS %@", second)
        let firstElement = app.staticTexts.matching(predicate1).firstMatch
        let secondElement = app.staticTexts.matching(predicate2).firstMatch
        if !firstElement.waitForExistence(timeout: 5) {
            XCTFail("First wine '\(first)' not found")
            return
        }
        XCTAssertTrue(secondElement.exists, "Second wine '\(second)' not found")
        XCTAssertLessThan(firstElement.frame.minY, secondElement.frame.minY, "'\(first)' should appear before '\(second)'")
    }
}
