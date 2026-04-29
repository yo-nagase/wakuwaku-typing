import XCTest

final class OnboardingFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Walks through onboarding (NEXT → NEXT → enter name → START)
    /// and verifies that the app reaches the home screen.
    @MainActor
    func testOnboardingFlowLandsOnHome() throws {
        let app = XCUIApplication()
        // Reset persisted state so we always start at onboarding.
        app.launchArguments += ["-com.apple.configuration.managed", "-AppleLanguages", "(en)"]
        app.launchEnvironment["WT_RESET"] = "1"
        app.launch()

        let next1 = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'NEXT'"))
        XCTAssertTrue(next1.waitForExistence(timeout: 5), "NEXT button should appear on first onboarding slide")
        next1.tap()

        let next2 = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'NEXT'"))
        XCTAssertTrue(next2.waitForExistence(timeout: 2))
        next2.tap()

        let nameField = app.textFields["ENTER NAME"]
        if nameField.waitForExistence(timeout: 2) {
            nameField.tap()
            nameField.typeText("TESTER")
        }

        let start = app.buttons.element(matching: NSPredicate(format: "label CONTAINS 'START'"))
        if start.waitForExistence(timeout: 2) {
            start.tap()
        }

        let press = app.staticTexts["▶ PRESS START"]
        XCTAssertTrue(press.waitForExistence(timeout: 5), "Home should show PRESS START after onboarding")
    }
}
