import XCTest

@MainActor
final class ScreenshotTest: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-serverURLDev", "http://localhost:3000", "-serverMode", "dev", "-UITestPhoto"]
        app.launch()
    }

    override func tearDown() async throws {
        app.terminate()
    }

    func testCaptureAllScreenshots() throws {
        let tabBar = TabBarPage(app: app)
        try tabBar.verify()

        // 1. Dashboard (default screen)
        try tabBar.goToDashboard().verify()
        saveScreenshot("dashboard")

        // 2. Cellar → Cave segment
        let cellar = try tabBar.goToCellar().verify()
        try cellar.switchToCave()
        saveScreenshot("cellar")

        // 3. Cellar → Journal segment
        try cellar.switchToJournal()
        saveScreenshot("journal")

        // 4. Wine list
        try tabBar.goToWineList().verify()
        saveScreenshot("wine-list")

        // 5. Wine detail (tap first wine in the list)
        let firstWine = app.collectionViews.buttons.firstMatch
        try firstWine.tapOrFail()
        let detail = WineDetailPage(app: app)
        try detail.verify()
        saveScreenshot("wine-detail")
        try detail.close()

        // 6. Scan
        let scanner = try tabBar.openScanner()
        try scanner.verify()
        saveScreenshot("scan")

        // 7. Scan → review (fiche modifiable directe)
        let review = try scanner.selectPhotoFromPicker()
        try review.verify()
        saveScreenshot("scan-review")
    }

    private func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // VinariumUITests/
            .deletingLastPathComponent() // ios/
            .deletingLastPathComponent() // project root
        let url = projectRoot.appendingPathComponent("screenshots/\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: url)
        } catch {
            XCTFail("Failed to save screenshot '\(name)' to \(url.path): \(error)")
        }
    }
}
