import XCTest

final class CellarFlowTest: BaseUITest {

    private let wineName = "Vin Test Nominal"

    // MARK: - Cellar E2E Flow

    func testCellarFlow() async throws {
        // 1. SCAN: open scanner, pick photo, save
        let tabBar = TabBarPage(app: app)
        let scanner = try tabBar.openScanner()
        try scanner.verify()

        let review = try scanner.selectPhotoFromPicker()
        try review.verify()

        _ = try review.clearAndTypeName(wineName)
        let placement = try review.tapSave()

        // 2. PLACEMENT: verify, select position, done
        try placement.verify()
        let confirmation = try placement.selectPosition("A1")
        try confirmation.verify()
        try confirmation.tapDone()

        // 3. CAVE: verify wine visible, tap → detail, check "Cave", close
        let cellar = try CellarPage(app: app).verify()
        let cellarDetail = try cellar.tapWine(named: wineName)
        try cellarDetail.verify()
        try cellarDetail.verifyWineName(wineName)
        try cellarDetail.verifyCellarSection()
        try cellarDetail.close()

        // Cave Journal: switch to Journal, verify "Entrée"
        let journal = try cellar.switchToJournal()
        try journal.verifyJournalShowsEntry()

        // Tap journal entry → detail → close
        let journalDetail = try journal.tapWine(named: wineName)
        try journalDetail.verify()
        try journalDetail.verifyWineName(wineName)
        try journalDetail.close()

        // 4. WINE LIST: go to Vins tab, verify wine visible, tap → detail → close
        let wineList = try tabBar.goToWineList().verify()
        try wineList.verifyWineVisible(wineName)
        let listDetail = try wineList.tapWine(named: wineName)
        try listDetail.verify()
        try listDetail.verifyWineName(wineName)
        try listDetail.close()

        // 5. DASHBOARD: go to Accueil, verify stats and journal
        let dashboard = try tabBar.goToDashboard().verify()
        try dashboard.verifyBottleCount("1")
        try dashboard.verifyJournalContains(wineName)
        try dashboard.verifyJournalShowsEntry()

        // 6. CONSUMPTION: back to Cave, tap wine, remove, rate 5 stars + comment
        _ = try tabBar.goToCellar().verify()
        let detailForRemoval = try cellar.tapWine(named: wineName)
        try detailForRemoval.verify()
        let consumption = try detailForRemoval.tapRemoveFromCellar()
        try consumption.verify()
        try consumption
            .tapStar(5)
            .typeTastingNotes("Excellent")
            .tapConfirm()

        // Should return to cellar
        try app.navigationBars["Ma Cave"].waitOrFail()

        // 7. FAVORITES: go to Vins tab, switch to "❤️ Favoris", verify wine visible
        _ = try tabBar.goToWineList().verify()
        let favorites = try WineListPage(app: app).switchToFavorites()
        try favorites.verifyWineVisible(wineName)
        
        // 8. Open wine detail, delete and confirm
        let detail = try wineList.tapWine(named: wineName)
        try detail.verify()
        try detail.tapDelete()

        // 9. Verify wine no longer appears in the list
        try wineList.verify()
        wineList.verifyWineNotVisible(wineName)
    }
}
