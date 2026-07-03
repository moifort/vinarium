import XCTest

final class RecommendationFlowTest: BaseUITest {

    private let wineName = "Vin Test Conseillé"

    // MARK: - Recommendation E2E Flow

    func testRecommendationFlow() async throws {
        // 1. SCAN: open scanner, pick photo, verify review
        let tabBar = TabBarPage(app: app)
        let scanner = try tabBar.openScanner()
        try scanner.verify()

        // 2. DESTINATION: choose "Conseillé"
        let destination = try scanner.selectPhotoFromPicker()
        try destination.verify()
        let review = try destination.chooseRecommendation()
        try review.verify()

        // 3. REVIEW: set name, fill recommender inline, save
        _ = try review.clearAndTypeName(wineName)
        _ = try review.typeRecommenderName("Jean")
        try review.submit()

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
