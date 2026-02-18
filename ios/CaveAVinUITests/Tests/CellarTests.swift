import XCTest

final class CellarTests: BaseUITest {

    func testCellarShowsBottlesByRow() async throws {
        let wine1 = try api.createWine(TestWineFactory.redBordeaux())
        let wine2 = try api.createWine(TestWineFactory.whiteBourgogne())
        try api.placeWine(wineId: wine1.id, row: "A", col: 1)
        try api.placeWine(wineId: wine2.id, row: "B", col: 3)

        let cellar = TabBarPage(app: app).goToCellar().verify()
        cellar.verifyRowHeader("A")
        cellar.verifyRowHeader("B")
    }

    func testCellarShowsPositionLabels() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let cellar = TabBarPage(app: app).goToCellar().verify()
        cellar.verifyPositionVisible("A1")
    }

    func testCellarJournalShowsEvents() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)
        try api.removeWine(wineId: wine.id)

        let cellar = TabBarPage(app: app).goToCellar().verify()
        let journal = cellar.switchToJournal()
        journal.verifyJournalShowsEntry()
        journal.verifyJournalShowsExit()
    }

    func testCellarSegmentSwitches() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let cellar = TabBarPage(app: app).goToCellar().verify()
        // Default is Cave
        cellar.verifyRowHeader("A")
        // Switch to Journal
        let journal = cellar.switchToJournal()
        journal.verifyJournalShowsEntry()
        // Switch back to Cave
        let cave = journal.switchToCave()
        cave.verifyRowHeader("A")
    }

    func testCellarTapWineOpensDetail() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let cellar = TabBarPage(app: app).goToCellar().verify()
        let detail = cellar.tapWine(named: "Chateau Test Bordeaux")
        detail.verify()
        detail.verifyWineName("Chateau Test Bordeaux")
    }
}
