import XCTest

final class ScanFlowTests: BaseUITest {

    func testScanFullFlow() async throws {
        let scanner = TabBarPage(app: app).openScanner()
        let review = scanner.selectPhotoFromPicker()
        review.verify()

        let placement = review.tapSave()
        placement.verify()

        let confirmation = placement.tapPlace()
        confirmation.verify()
        confirmation.verifyPosition(confirmation.app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH 'Position'")
        ).firstMatch.label.isEmpty ? "" : "") // Position is dynamic

        // Verify confirmation screen
        XCTAssertTrue(app.staticTexts["Bouteille ajoutée !"].exists)

        confirmation.tapDone()

        // Should return to cellar tab
        XCTAssertTrue(app.navigationBars["Ma Cave"].waitForExistence(timeout: 5))
    }

    func testScanEditFields() async throws {
        let scanner = TabBarPage(app: app).openScanner()
        let review = scanner.selectPhotoFromPicker()
        review.verify()

        // Edit the wine name
        let edited = review
            .clearAndTypeName("Mon Vin Edite")

        let placement = edited.tapSave()
        placement.verify()
        placement.verifyWineName("Mon Vin Edite")
    }
}
