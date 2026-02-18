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

    func selectPosition(_ position: String) throws -> Self {
        try app.buttons[position].tapOrFail()
        return self
    }

    func tapPlace() throws -> ConfirmationPage {
        try app.buttons["place-button"].tapOrFail()
        return ConfirmationPage(app: app)
    }
}
