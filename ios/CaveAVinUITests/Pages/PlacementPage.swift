import XCTest

@MainActor
struct PlacementPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Placement"].waitOrFail()
        return self
    }

    func verifyWineName(_ name: String) throws {
        try app.staticTexts[name].waitOrFail()
    }

    func selectPosition(_ position: String) throws -> ConfirmationPage {
        try app.buttons[position].tapOrFail()
        try app.buttons["confirm-place"].tapOrFail()
        return ConfirmationPage(app: app)
    }
}
