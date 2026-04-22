import XCTest

@MainActor
struct GiftPage {
    let app: XCUIApplication

    @discardableResult
    func verify() throws -> Self {
        try app.navigationBars["Offrir"].waitOrFail()
        return self
    }

    func typeRecipientName(_ name: String) -> Self {
        let field = app.textFields["Nom du destinataire"]
        if field.waitForExistence(timeout: 3) {
            field.tap()
            field.typeText(name)
        }
        return self
    }

    func tapConfirm() throws {
        try app.buttons["confirm-gift-button"].tapOrFail()
    }
}
