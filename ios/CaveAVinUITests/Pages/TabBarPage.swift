import XCTest

struct TabBarPage {
    let app: XCUIApplication

    @discardableResult
    func verify() -> Self {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        return self
    }

    @discardableResult
    func goToDashboard() -> DashboardPage {
        app.tabBars.buttons["Accueil"].tap()
        return DashboardPage(app: app)
    }

    @discardableResult
    func goToCellar() -> CellarPage {
        app.tabBars.buttons["Cave"].tap()
        return CellarPage(app: app)
    }

    @discardableResult
    func goToWineList() -> WineListPage {
        app.tabBars.buttons["Vins"].tap()
        return WineListPage(app: app)
    }

    func openScanner() -> ScanFlowPage {
        app.tabBars.buttons["Scanner"].tap()
        return ScanFlowPage(app: app)
    }
}
