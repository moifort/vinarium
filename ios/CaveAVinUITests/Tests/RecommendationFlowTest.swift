import XCTest

final class RecommendationFlowTest: BaseUITest {

    private let wineName = "Vin Test Conseillé"

    // MARK: - Recommendation E2E Flow

    func testRecommendationFlow() async throws {
        // 1. SCAN: open scanner, pick photo, verify review
        let tabBar = TabBarPage(app: app)
        let scanner = try tabBar.openScanner()
        try scanner.verify()

        let review = try scanner.selectPhotoFromPicker()
        try review.verify()

        // 2. REVIEW: set name, tap "Conseillé par un ami" → fill sheet
        _ = try review.clearAndTypeName(wineName)
        try review.tapRecommend()

        // 3. RECOMMENDATION SHEET: fill recommender name, confirm
        let nameField = try app.textFields["Nom"].waitOrFail()
        nameField.tap()
        nameField.typeText("Jean")
        try app.buttons["confirm-recommendation-button"].tapOrFail()

        // 4. WINE LIST (CONSEILLÉS): verify navigation to Vins tab with recommended segment
        let wineList = try WineListPage(app: app).verify()
        try wineList.switchToRecommended()
        try wineList.verifyWineVisible(wineName)

        // 5. DETAIL: tap wine → verify recommendation section
        let detail = try wineList.tapWine(named: wineName)
        try detail.verify()
        try detail.verifyWineName(wineName)
        try detail.verifyRecommendationSection()
        try detail.close()
    }
}
