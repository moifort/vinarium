import XCTest

@MainActor
struct ConfirmationPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.staticTexts["Bouteille ajoutée !"].waitForExistence(timeout: 10))
        return self
    }

    func verifyWineName(_ name: String) {
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    func verifyPosition(_ position: String) {
        XCTAssertTrue(app.staticTexts["Position : \(position)"].waitForExistence(timeout: 5))
    }

    func tapDone() {
        let doneButton = app.buttons["done-button"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
    }
}
