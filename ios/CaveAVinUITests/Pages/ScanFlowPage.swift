import XCTest

@MainActor
struct ScanFlowPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.buttons["scan-photo-picker"].waitForExistence(timeout: 5))
        return self
    }

    func selectPhotoFromPicker() -> ScanReviewPage {
        let picker = app.buttons["scan-photo-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()

        // Wait for PHPicker to appear and select first photo
        let firstPhoto = app.collectionViews.cells.firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        firstPhoto.tap()

        // Wait for scan review to appear (AI scan may take time)
        let reviewTitle = app.navigationBars["Vérifier le vin"]
        XCTAssertTrue(reviewTitle.waitForExistence(timeout: 30))

        return ScanReviewPage(app: app)
    }
}
