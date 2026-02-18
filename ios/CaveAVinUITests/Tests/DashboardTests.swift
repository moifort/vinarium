import XCTest

final class DashboardTests: BaseUITest {

    func testDashboardShowsBottleCount() async throws {
        let wine1 = try api.createWine(TestWineFactory.redBordeaux())
        let wine2 = try api.createWine(TestWineFactory.whiteBourgogne())
        try api.placeWine(wineId: wine1.id, row: "A", col: 1)
        try api.placeWine(wineId: wine2.id, row: "A", col: 2)

        let dashboard = DashboardPage(app: app).verify()
        dashboard.verifyBottleCount("2")
    }

    func testDashboardShowsTotalValue() async throws {
        let wine1 = try api.createWine(TestWineFactory.redBordeaux()) // 25 EUR
        let wine2 = try api.createWine(TestWineFactory.cheapWine(price: 15)) // 15 EUR
        try api.placeWine(wineId: wine1.id, row: "A", col: 1)
        try api.placeWine(wineId: wine2.id, row: "A", col: 2)

        let dashboard = DashboardPage(app: app).verify()
        dashboard.verifyTotalValue("40 €")
    }

    func testDashboardShowsReadyToDrink() async throws {
        // redBordeaux has drinkFrom=2024 (past) and drinkUntil=2030 → ready to drink
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let dashboard = DashboardPage(app: app).verify()
        dashboard.verifyReadyToDrinkContains("Chateau Test Bordeaux")
    }

    func testDashboardShowsJournal() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let dashboard = DashboardPage(app: app).verify()
        dashboard.verifyJournalContains("Chateau Test Bordeaux")
        dashboard.verifyJournalShowsEntry()
    }

    func testDashboardTapWineOpensDetail() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let dashboard = DashboardPage(app: app).verify()
        let detail = dashboard.tapWine(named: "Chateau Test Bordeaux")
        detail.verify()
        detail.verifyWineName("Chateau Test Bordeaux")
    }
}
