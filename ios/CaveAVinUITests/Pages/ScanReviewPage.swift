import XCTest

struct ScanReviewPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.navigationBars["Vérifier le vin"].waitForExistence(timeout: 5))
        return self
    }

    func clearAndTypeName(_ name: String) -> Self {
        let nameField = app.textFields["Nom du vin"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        // Select all and delete
        nameField.press(forDuration: 1.0)
        if app.menuItems["Tout sélectionner"].waitForExistence(timeout: 2) {
            app.menuItems["Tout sélectionner"].tap()
        }
        nameField.typeText(name)
        return self
    }

    func selectColor(_ color: String) -> Self {
        let colorPicker = app.buttons["Couleur"]
        XCTAssertTrue(colorPicker.waitForExistence(timeout: 5))
        colorPicker.tap()
        app.buttons[color].tap()
        return self
    }

    func typeVintage(_ vintage: String) -> Self {
        let vintageField = app.textFields["Année"]
        if vintageField.waitForExistence(timeout: 3) {
            vintageField.tap()
            vintageField.press(forDuration: 1.0)
            if app.menuItems["Tout sélectionner"].waitForExistence(timeout: 2) {
                app.menuItems["Tout sélectionner"].tap()
            }
            vintageField.typeText(vintage)
        }
        return self
    }

    func tapSave() -> PlacementPage {
        let saveButton = app.buttons["review-save-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        return PlacementPage(app: app)
    }
}
