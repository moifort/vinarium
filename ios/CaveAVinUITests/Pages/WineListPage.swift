import XCTest

@MainActor
struct WineListPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Mes Vins"].waitOrFail()
        return self
    }

    func verifyWineVisible(_ name: String) throws {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 4) {
            let button = app.buttons.matching(predicate).firstMatch
            try button.waitOrFail(timeout: 2, "Wine '\(name)' not visible")
        }
    }

    func verifyWineNotVisible(_ name: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        let element = app.staticTexts.matching(predicate).firstMatch
        XCTAssertFalse(element.waitForExistence(timeout: 2), "Wine '\(name)' should not be visible")
    }

    func switchToFavorites() throws -> Self {
        try app.segmentedControls["winelist-segment"].buttons["❤️ Favoris"].tapOrFail()
        return self
    }

    func switchToGifted() throws -> Self {
        try app.segmentedControls["winelist-segment"].buttons["🎁 Offerts"].tapOrFail()
        return self
    }

    func switchToAll() throws -> Self {
        try app.segmentedControls["winelist-segment"].buttons["Tous"].tapOrFail()
        return self
    }

    func tapWine(named name: String) throws -> WineDetailPage {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        try app.buttons.matching(predicate).firstMatch.tapOrFail()
        return WineDetailPage(app: app)
    }
}
