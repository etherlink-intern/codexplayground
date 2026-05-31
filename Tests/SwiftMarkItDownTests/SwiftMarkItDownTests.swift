import Foundation
import Testing
@testable import SwiftMarkItDown

@Suite("SwiftMarkItDown core conversions")
struct SwiftMarkItDownTests {
    @Test("infers format from extension")
    func infersFormatFromExtension() {
        #expect(DocumentFormat.infer(fileName: "report.csv", contentType: nil) == .csv)
        #expect(DocumentFormat.infer(fileName: "deck.pptx", contentType: nil) == .pptx)
    }

    @Test("converts plain text without surrounding blank lines")
    func convertsPlainText() throws {
        let request = ConversionRequest(data: Data("\nHello iOS\n\n".utf8), fileName: "note.txt")
        let document = try MarkItDown().convert(request)
        #expect(document.markdown == "Hello iOS")
        #expect(document.sourceFormat == .plainText)
    }

    @Test("converts simple HTML to Markdown")
    func convertsHTML() throws {
        let html = "<html><head><title>Ignored</title></head><body><h1>Title</h1><p>Hello <strong>Swift</strong> &amp; iOS.</p><a href=\"https://example.com\">Link</a></body></html>"
        let request = ConversionRequest(data: Data(html.utf8), fileName: "index.html")
        let document = try MarkItDown().convert(request)
        #expect(document.markdown == "# Title\nHello **Swift** & iOS.\n\n[Link](https://example.com)")
    }

    @Test("converts CSV to a Markdown table")
    func convertsCSV() throws {
        let csv = "Name,Note\nSwift,Native\n\"Mark, It Down\",\"CSV | escaped\""
        let request = ConversionRequest(data: Data(csv.utf8), fileName: "data.csv")
        let document = try MarkItDown().convert(request)
        #expect(document.markdown == "| Name | Note |\n| --- | --- |\n| Swift | Native |\n| Mark, It Down | CSV \\| escaped |")
    }

    @Test("converts JSON to nested Markdown bullets")
    func convertsJSON() throws {
        let json = #"{"title":"Roadmap","formats":["txt","html"]}"#
        let request = ConversionRequest(data: Data(json.utf8), fileName: "roadmap.json")
        let document = try MarkItDown().convert(request)
        #expect(document.markdown == "- **formats**:\n  - txt\n  - html\n- **title**: Roadmap")
    }

    @Test("throws for reserved but unimplemented formats")
    func throwsForUnimplementedFormats() throws {
        let request = ConversionRequest(data: Data(), fileName: "paper.pdf")
        #expect(throws: ConversionError.unsupportedFormat(.pdf)) {
            try MarkItDown().convert(request)
        }
    }
}
