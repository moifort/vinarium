import XCTest

final class ShortlistFlowTest: BaseUITest {

    private let wineName = "Cidre Test À Retenir"

    // MARK: - Shortlist E2E Flow

    func testShortlistFlow() async throws {
        // 1. SCAN: open scanner, pick photo, verify review
        let tabBar = TabBarPage(app: app)
        let scanner = try tabBar.openScanner()
        try scanner.verify()

        // 2. DESTINATION: choose "À retenir"
        let destination = try scanner.selectPhotoFromPicker()
        try destination.verify()
        let review = try destination.chooseShortlist()
        try review.verify()

        // 3. REVIEW: set name, save (rating defaults to 3 in the inline section)
        _ = try review.clearAndTypeName(wineName)
        try review.submit()

        // 3. WINE LIST: navigation lands on Vins tab with shortlist segment selected
        let wineList = try WineListPage(app: app).verify()
        try wineList.verifyWineVisible(wineName)

        // 4. DASHBOARD: go to Accueil, verify section "À retenir" contains the wine
        let dashboard = try tabBar.goToDashboard().verify()
        try dashboard.verifyShortlistContains(wineName)

        // 5. DETAIL: tap wine in shortlist dashboard → verify detail sheet
        let detail = try dashboard.tapWine(named: wineName)
        try detail.verify()
        try detail.verifyWineName(wineName)
        try detail.close()
    }
}
