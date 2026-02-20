import XCTest

final class DeleteWineFlowTest: BaseUITest {

    private let wineName = "Vin Test Suppression"

    func testDeleteWineFlow() async throws {
        // 1. Create a wine and place it in the cellar via the API
        let wine = try api.createWine([
            "name": wineName,
            "color": "red",
            "appellation": "Bordeaux",
            "region": "Bordeaux",
            "country": "France",
        ])
        try api.placeWine(wineId: wine.id, row: "A", col: 1)

        // 2. Navigate to Mes Vins and verify the wine is visible
        let tabBar = TabBarPage(app: app)
        let wineList = try tabBar.goToWineList().verify()
        try wineList.verifyWineVisible(wineName)

        // 3. Open wine detail, delete and confirm
        let detail = try wineList.tapWine(named: wineName)
        try detail.verify()
        try detail.tapDelete()

        // 4. Verify wine no longer appears in the list
        try wineList.verify()
        wineList.verifyWineNotVisible(wineName)
    }
}
