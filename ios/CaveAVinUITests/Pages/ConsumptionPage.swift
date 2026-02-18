import XCTest

@MainActor
struct ConsumptionPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.navigationBars["Consommation"].waitForExistence(timeout: 5))
        return self
    }

    func tapStar(_ number: Int) -> Self {
        let star = app.buttons["star-rating-\(number)"]
        XCTAssertTrue(star.waitForExistence(timeout: 5))
        star.tap()
        return self
    }

    func typeTastingNotes(_ notes: String) -> Self {
        // Multi-line TextField (axis: .vertical) is exposed as a textView
        let notesField = app.textViews["Vos impressions..."]
        if notesField.waitForExistence(timeout: 3) {
            notesField.tap()
            notesField.typeText(notes)
        }
        return self
    }

    func tapConfirm() {
        let confirmButton = app.buttons["confirm-consumption-button"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()
    }
}
