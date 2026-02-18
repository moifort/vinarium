import XCTest

@MainActor
struct TabBarPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.tabBars.firstMatch.waitOrFail()
        return self
    }

    @discardableResult
    func goToDashboard() throws -> DashboardPage {
        try app.tabBars.buttons["Accueil"].tapOrFail()
        return DashboardPage(app: app)
    }

    @discardableResult
    func goToCellar() throws -> CellarPage {
        try app.tabBars.buttons["Cave"].tapOrFail()
        return CellarPage(app: app)
    }

    @discardableResult
    func goToWineList() throws -> WineListPage {
        try app.tabBars.buttons["Vins"].tapOrFail()
        return WineListPage(app: app)
    }

    func openScanner() throws -> ScanFlowPage {
        try app.tabBars.buttons["Scanner"].tapOrFail()
        return ScanFlowPage(app: app)
    }
}
