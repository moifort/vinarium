import XCTest

class BaseUITest: XCTestCase {
    var app: XCUIApplication!
    var api: TestAPIClient!

    override func setUp() async throws {
        continueAfterFailure = false
        api = TestAPIClient.shared
        try api.deleteAllWines()
        app = XCUIApplication()
        app.launchArguments = ["-serverURL", "http://localhost:3000"]
        app.launch()
    }

    override func tearDown() async throws {
        try? api.deleteAllWines()
        app.terminate()
    }
}
