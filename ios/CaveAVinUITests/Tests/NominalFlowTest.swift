import XCTest

final class NominalFlowTest: BaseUITest {

    private let wineName = "Vin Test Nominal"
    private let winePrice = "25"

    // MARK: - Nominal E2E Flow

    func testNominalFlow() async throws {
        // 1. SCAN: open scanner, pick photo, edit name & price, save
        let tabBar = TabBarPage(app: app)
        let scanner = tabBar.openScanner()
        scanner.verify()

        let review = scanner.selectPhotoFromPicker()
        review.verify()

        let editedReview = review
            .clearAndTypeName(wineName)
            .typePrice(winePrice)

        let placement = editedReview.tapSave()

        // 2. PLACEMENT: verify, place, confirm, done
        placement.verify()
        let confirmation = placement.tapPlace()
        confirmation.verify()
        confirmation.tapDone()

        // 3. CAVE: verify wine visible, tap → detail, check "En cave", close
        let cellar = CellarPage(app: app).verify()
        let cellarDetail = cellar.tapWine(named: wineName)
        cellarDetail.verify()
        cellarDetail.verifyWineName(wineName)
        cellarDetail.verifyCellarSection()
        cellarDetail.close()

        // Cave Journal: switch to Journal, verify "Entrée"
        let journal = cellar.switchToJournal()
        journal.verifyJournalShowsEntry()

        // Tap journal entry → detail → close
        let journalDetail = journal.tapWine(named: wineName)
        journalDetail.verify()
        journalDetail.verifyWineName(wineName)
        journalDetail.close()

        // 4. WINE LIST: go to Vins tab, verify wine visible, tap → detail → close
        let wineList = tabBar.goToWineList().verify()
        wineList.verifyWineVisible(wineName)
        let listDetail = wineList.tapWine(named: wineName)
        listDetail.verify()
        listDetail.verifyWineName(wineName)
        listDetail.close()

        // 5. DASHBOARD: go to Accueil, verify stats and journal
        let dashboard = tabBar.goToDashboard().verify()
        dashboard.verifyBottleCount("1")
        dashboard.verifyTotalValue("25")
        dashboard.verifyJournalContains(wineName)
        dashboard.verifyJournalShowsEntry()

        // 6. CONSUMPTION: back to Cave, tap wine, remove, rate 5 stars + comment
        _ = tabBar.goToCellar().verify()
        let detailForRemoval = cellar.tapWine(named: wineName)
        detailForRemoval.verify()
        let consumption = detailForRemoval.tapRemoveFromCellar()
        consumption.verify()
        consumption
            .tapStar(5)
            .typeTastingNotes("Excellent")
            .tapConfirm()

        // Should return to cellar
        XCTAssertTrue(app.navigationBars["Ma Cave"].waitForExistence(timeout: 10))

        // 7. FAVORITES: go to Vins tab, switch to "5 ⭐", verify wine visible
        _ = tabBar.goToWineList().verify()
        let favorites = WineListPage(app: app).switchToFavorites()
        favorites.verifyWineVisible(wineName)
    }
}
