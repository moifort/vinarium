import XCTest

@MainActor
struct PlacementPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.navigationBars["Placement"].waitForExistence(timeout: 10))
        return self
    }

    func verifyWineName(_ name: String) {
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    func selectPosition(_ position: String) -> Self {
        let posButton = app.buttons[position]
        XCTAssertTrue(posButton.waitForExistence(timeout: 5))
        posButton.tap()
        return self
    }

    func tapPlace() -> ConfirmationPage {
        let placeButton = app.buttons["place-button"]
        XCTAssertTrue(placeButton.waitForExistence(timeout: 5))
        placeButton.tap()
        return ConfirmationPage(app: app)
    }
}
