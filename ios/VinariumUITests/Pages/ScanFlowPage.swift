import XCTest

@MainActor
struct ScanFlowPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.buttons["scan-capture-button"].waitOrFail()
        return self
    }

    func captureLabel() throws -> ScanReviewPage {
        try app.buttons["scan-capture-button"].tapOrFail()

        // In test mode (-UITestPhoto), the shutter loads the bundled image
        // instead of the camera, which the simulator does not have. The scan
        // is stubbed, but the image still goes to the backend and back, and on
        // CI the first one of a run left the app on "Identifying the label..."
        // well past 15s.
        // After the analysis the flow lands straight on the editable review form.
        try app.navigationBars["Check the bottle"].waitOrFail(timeout: 60)

        return ScanReviewPage(app: app)
    }
}
