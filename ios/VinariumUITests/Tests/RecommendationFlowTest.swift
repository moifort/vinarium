import XCTest

final class RecommendationFlowTest: BaseUITest {

    private let wineName = "Vin Test Conseillé"

    // MARK: - Recommendation E2E Flow

    func testRecommendationFlow() async throws {
        // 1. SCAN: open scanner, pick photo, verify review
        let tabBar = TabBarPage(app: app)
        let scanner = try tabBar.openScanner()
        try scanner.verify()

        // 2. REVIEW: land directly on the editable form, fill the inline recommender
        // then save — the popup no longer offers a "Conseillé" destination
        let review = try scanner.selectPhotoFromPicker()
        try review.verify()

        _ = try review.clearAndTypeName(wineName)
        _ = try review.typeRecommenderName("Jean")
        try review.justSave()

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
