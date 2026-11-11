import XCTest

@MainActor
struct DashboardPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Home"].waitOrFail()
        return self
    }

    @discardableResult
    func refresh() -> Self {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        start.press(forDuration: 0.1, thenDragTo: end)
        return self
    }

    func verifyBottleCount(_ expected: String) throws {
        let widget = try app.buttons["stat-bottles"].waitOrFail()
        XCTAssertTrue(widget.label.contains(expected), "stat-bottles label '\(widget.label)' should contain '\(expected)'")
    }

    func verifyTotalValue(_ expected: String) throws {
        let widget = try app.buttons["stat-value"].waitOrFail()
        XCTAssertTrue(widget.label.contains(expected), "stat-value label '\(widget.label)' should contain '\(expected)'")
    }

    func verifyJournalContains(_ wineName: String) throws {
        let predicate = NSPredicate(format: "label CONTAINS %@", wineName)
        let element = app.staticTexts.matching(predicate).firstMatch
        if !element.waitForExistence(timeout: 15) {
            let button = app.buttons.matching(predicate).firstMatch
            try button.waitOrFail(timeout: 2, "'\(wineName)' not found in journal")
        }
    }

    func verifyJournalShowsEntry() throws {
        // Each move card carries its direction as an identifier: its spoken label
        // starts with the arrow and the outlined tag, and a CONTAINS on "In" would
        // match "In cellar" whatever the cards show.
        try app.buttons["recent-move-entry"].firstMatch
            .waitOrFail(timeout: 15, "no entry card in the recent moves")
    }

    func verifyFavoritesContains(_ wineName: String) throws {
        // A shelf tile is a button whose label is the wine's name: the name itself
        // is drawn on the bottle, never written as text.
        let tile = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", wineName)).firstMatch
        if tile.waitForExistence(timeout: 15) { return }
        // "My favorites" is the home's last shelf, below the fold: bring it on
        // screen before giving up.
        app.swipeUp()
        if tile.waitForExistence(timeout: 5) { return }
        print("Home accessibility tree:\n\(app.debugDescription)")
        try tile.waitOrFail(timeout: 1, "'\(wineName)' not found in favorites")
    }

    func tapWine(named name: String) throws -> WineDetailPage {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        try app.buttons.matching(predicate).firstMatch.tapOrFail()
        return WineDetailPage(app: app)
    }
}
