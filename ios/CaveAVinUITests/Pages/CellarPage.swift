import XCTest

@MainActor
struct CellarPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Ma Cave"].waitOrFail()
        return self
    }

    func switchToCave() throws -> Self {
        try app.segmentedControls["cellar-segment"].buttons["Cave"].tapOrFail()
        return self
    }

    func switchToJournal() throws -> Self {
        try app.segmentedControls["cellar-segment"].buttons["Journal"].tapOrFail()
        return self
    }

    func verifyRowHeader(_ row: String) throws {
        let text = "Rangée \(row)"
        try app.staticTexts[text].waitOrFail(timeout: 4, "Row header '\(text)' not found")
    }

    func verifyJournalShowsEntry() throws {
        try app.staticTexts["Entrée"].waitOrFail(timeout: 4, "'Entrée' not found")
    }

    func verifyJournalShowsExit() throws {
        try app.staticTexts["Sortie"].waitOrFail(timeout: 4, "'Sortie' not found")
    }

    func tapWine(named name: String) throws -> WineDetailPage {
        let predicate = NSPredicate(format: "label CONTAINS %@", name)
        try app.buttons.matching(predicate).firstMatch.tapOrFail()
        return WineDetailPage(app: app)
    }
}
