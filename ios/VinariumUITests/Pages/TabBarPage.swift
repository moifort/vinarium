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
        try app.tabBars.buttons["Home"].tapOrFail()
        return DashboardPage(app: app)
    }

    @discardableResult
    func goToCellar() throws -> CellarPage {
        try app.tabBars.buttons["Cellar"].tapOrFail()
        return CellarPage(app: app)
    }

    @discardableResult
    func goToWineList() throws -> WineListPage {
        try app.tabBars.buttons["Wines"].tapOrFail()
        return WineListPage(app: app)
    }

    /// The scan tab opens the add-a-wine sheet first; its camera tile opens
    /// the scanner once the sheet is gone.
    func openScanner() throws -> ScanFlowPage {
        try app.tabBars.buttons["Scan"].tapOrFail()
        try app.buttons["add-wine-camera"].tapOrFail()
        return ScanFlowPage(app: app)
    }
}
