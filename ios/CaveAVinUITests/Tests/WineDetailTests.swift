import XCTest

final class WineDetailTests: BaseUITest {

    func testWineDetailShowsAllInfo() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let list = TabBarPage(app: app).goToWineList().verify()
        let detail = list.tapWine(named: "Chateau Test Bordeaux")
        detail.verify()

        detail.verifyWineName("Chateau Test Bordeaux")
        detail.verifyTextVisible("Chateau Test") // domain
        detail.verifyTextVisible("2020") // vintage
        detail.verifyTextVisible("Bordeaux") // region
    }

    func testWineDetailShowsCellarPosition() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "B", col: 3)

        let list = TabBarPage(app: app).goToWineList().verify()
        let detail = list.tapWine(named: "Chateau Test Bordeaux")
        detail.verify()

        detail.verifyCellarSection()
        detail.verifyPosition("B3")
    }

    func testWineDetailRemoveWithRating() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        let list = TabBarPage(app: app).goToWineList().verify()
        let detail = list.tapWine(named: "Chateau Test Bordeaux")
        detail.verify()

        let consumption = detail.tapRemoveFromCellar()
        consumption.verify()

        consumption
            .tapStar(4)
            .typeTastingNotes("Excellent vin de test")
            .tapConfirm()

        // Sheet should dismiss after confirmation
        XCTAssertTrue(app.navigationBars["Mes Vins"].waitForExistence(timeout: 10))
    }

    func testWineDetailShowsConsumption() async throws {
        let wine = try api.createWine(TestWineFactory.redBordeaux())
        try api.placeWine(wineId: wine.id, row: "A", col: 1)
        try api.removeWine(wineId: wine.id, rating: 4, notes: "Notes de test")

        let list = TabBarPage(app: app).goToWineList().verify()
        let detail = list.tapWine(named: "Chateau Test Bordeaux")
        detail.verify()

        detail.verifyConsumptionSection()
        detail.verifyTextVisible("Notes de test")
    }
}
