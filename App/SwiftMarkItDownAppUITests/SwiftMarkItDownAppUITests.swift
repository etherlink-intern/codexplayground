import XCTest

final class SwiftMarkItDownAppUITests: XCTestCase {
    func testDefaultHTMLSampleConvertsToMarkdown() throws {
        let app = XCUIApplication()
        app.launch()

        let convertButton = app.buttons["convertButton"]
        XCTAssertTrue(convertButton.waitForExistence(timeout: 10), "Convert button should be visible")
        convertButton.tap()

        let output = app.textViews["conversionOutput"]
        XCTAssertTrue(output.waitForExistence(timeout: 10), "Markdown output editor should be visible")

        let markdown = String(describing: output.value ?? output.label)
        XCTAssertTrue(markdown.contains("# Hello from iOS"), "Expected converted heading in output, got: \(markdown)")
        XCTAssertTrue(markdown.contains("**native Swift**"), "Expected converted emphasis in output, got: \(markdown)")
        XCTAssertTrue(markdown.contains("[Example](https://example.com)"), "Expected converted link in output, got: \(markdown)")
        XCTAssertFalse(markdown.contains("Ignored title"), "HTML head content should not appear in output")
    }
}
