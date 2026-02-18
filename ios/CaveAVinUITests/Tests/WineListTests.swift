import XCTest

final class WineListTests: BaseUITest {

    func testWineListShowsAllWines() async throws {
        try api.createWine(TestWineFactory.redBordeaux())
        try api.createWine(TestWineFactory.whiteBourgogne())
        try api.createWine(TestWineFactory.roseProvence())

        let list = TabBarPage(app: app).goToWineList().verify()
        list.verifyWineVisible("Chateau Test Bordeaux")
        list.verifyWineVisible("Chablis Test")
        list.verifyWineVisible("Rose Test Provence")
    }

    func testWineListShowsDetails() async throws {
        try api.createWine(TestWineFactory.redBordeaux()) // 2020, Bordeaux, 25 EUR

        let list = TabBarPage(app: app).goToWineList().verify()
        list.verifyTextVisible("2020")
        list.verifyTextVisible("Bordeaux")
        list.verifyTextVisible("25 €")
    }

    func testWineListFavorites() async throws {
        let wine1 = try api.createWine(TestWineFactory.redBordeaux())
        try api.createWine(TestWineFactory.whiteBourgogne())

        // Give wine1 a 5-star rating by placing and removing
        try api.placeWine(wineId: wine1.id, row: "A", col: 1)
        try api.removeWine(wineId: wine1.id, rating: 5)

        let list = TabBarPage(app: app).goToWineList().verify()
        let favorites = list.switchToFavorites()
        favorites.verifyWineVisible("Chateau Test Bordeaux")
        favorites.verifyWineNotVisible("Chablis Test")
    }

    func testWineListSortByVintage() async throws {
        try api.createWine(TestWineFactory.wineWithVintage(2022, name: "Vin 2022"))
        try api.createWine(TestWineFactory.wineWithVintage(2018, name: "Vin 2018"))

        let list = TabBarPage(app: app).goToWineList().verify()
        let menu = list.openSortMenu()
        let sorted = menu.selectSort("Millésime")

        // Default ascending: 2018 should come before 2022
        sorted.verifyWineOrder(first: "Vin 2018", second: "Vin 2022")
    }

    func testWineListFilterInCellar() async throws {
        let wine1 = try api.createWine(TestWineFactory.redBordeaux())
        try api.createWine(TestWineFactory.whiteBourgogne())

        // Place only wine1 in cellar
        try api.placeWine(wineId: wine1.id, row: "A", col: 1)

        let list = TabBarPage(app: app).goToWineList().verify()
        let menu = list.openSortMenu()
        let filtered = menu.selectStatusFilter("En cave")

        filtered.verifyWineVisible("Chateau Test Bordeaux")
        filtered.verifyWineNotVisible("Chablis Test")
    }

    func testWineListTapWineOpensDetail() async throws {
        try api.createWine(TestWineFactory.redBordeaux())

        let list = TabBarPage(app: app).goToWineList().verify()
        let detail = list.tapWine(named: "Chateau Test Bordeaux")
        detail.verify()
        detail.verifyWineName("Chateau Test Bordeaux")
    }
}
