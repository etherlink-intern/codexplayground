import Foundation
import Testing
@testable import SwiftMarkItDown

#if canImport(Vision) && canImport(CoreGraphics) && canImport(ImageIO)
import CoreGraphics
import ImageIO
import Vision
#endif

@Suite("SwiftMarkItDown core conversions")
struct SwiftMarkItDownTests {
    @Test("infers format from extension")
    func infersFormatFromExtension() {
        #expect(DocumentFormat.infer(fileName: "report.csv", contentType: nil) == .csv)
        #expect(DocumentFormat.infer(fileName: "deck.pptx", contentType: nil) == .pptx)
        #expect(DocumentFormat.infer(fileName: "scan.png", contentType: nil) == .png)
        #expect(DocumentFormat.infer(fileName: "receipt.jpeg", contentType: nil) == .jpeg)
        #expect(DocumentFormat.infer(fileName: "photo.HEIC", contentType: nil) == .heic)
    }

    @Test("infers image formats from content type")
    func infersImageFormatsFromContentType() {
        #expect(DocumentFormat.infer(fileName: nil, contentType: "image/png") == .png)
        #expect(DocumentFormat.infer(fileName: nil, contentType: "image/jpeg; charset=binary") == .jpeg)
        #expect(DocumentFormat.infer(fileName: nil, contentType: "image/heic") == .heic)
        #expect(DocumentFormat.infer(fileName: nil, contentType: "image/tiff") == .tiff)
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

    @Test("converts every fixture-backed supported text path")
    func convertsFixtureBackedSupportedTextPaths() throws {
        let cases: [(String, DocumentFormat, String)] = [
            ("note.txt", .plainText, "Hello SwiftMarkItDown\nThis is plain text."),
            ("page.html", .html, "# Smoke Test\n\nHello **native Swift** & Markdown.\n\n[Example](https://example.com)"),
            ("table.csv", .csv, "| Name | Note |\n| --- | --- |\n| Swift | Native |\n| Mark, It Down | CSV \\| escaped |"),
            ("data.json", .json, "- **formats**:\n  - txt\n  - html\n- **title**: Roadmap"),
            ("empty.txt", .plainText, ""),
            ("empty.md", .markdown, ""),
            ("empty.html", .html, ""),
            ("empty.csv", .csv, "")
        ]

        for (fileName, format, expectedMarkdown) in cases {
            let document = try MarkItDown().convert(contentsOf: fixtureURL(fileName))
            #expect(document.sourceFormat == format, "Unexpected format for \(fileName)")
            #expect(document.markdown == expectedMarkdown, "Unexpected Markdown for \(fileName)")
        }
    }

    @Test("surfaces a targeted malformed-input error for empty JSON")
    func throwsMalformedInputForEmptyJSON() throws {
        #expect(throws: ConversionError.malformedInput("JSON input is empty.")) {
            try MarkItDown().convert(contentsOf: fixtureURL("empty.json"))
        }
    }

    @Test("surfaces a targeted malformed-input error for invalid JSON")
    func throwsMalformedInputForInvalidJSON() throws {
        let request = ConversionRequest(data: Data("not json".utf8), fileName: "broken.json")
        #expect(throws: ConversionError.malformedInput("The input could not be parsed as JSON.")) {
            try MarkItDown().convert(request)
        }
    }

    #if canImport(Vision) && canImport(CoreGraphics) && canImport(ImageIO)
    @Test("registers image OCR formats and decodes the text-backed PNG fixture")
    func registersImageOCRFormatsAndDecodesTextBackedPNGFixture() throws {
        let data = try blankPNGFixtureData()
        #expect(ImageOCRConverter().supportedFormats == DocumentFormat.imageFormats)
        #expect(!data.isEmpty)
    }
    #else
    @Test("throws unsupported for text-fixture-backed images when Vision OCR is unavailable")
    func throwsForImagesWhenVisionOCRIsUnavailable() throws {
        #expect(throws: ConversionError.unsupportedFormat(.png)) {
            try MarkItDown().convert(ConversionRequest(data: try blankPNGFixtureData(), fileName: "blank.png"))
        }
    }
    #endif

    @Test("throws unsupported for every reserved document path, including empty documents")
    func throwsUnsupportedForReservedDocumentPaths() throws {
        let cases: [(String, DocumentFormat)] = [
            ("sample.pdf", .pdf),
            ("sample.docx", .docx),
            ("sample.pptx", .pptx),
            ("sample.xlsx", .xlsx),
            ("empty.pdf", .pdf),
            ("empty.docx", .docx),
            ("empty.pptx", .pptx),
            ("empty.xlsx", .xlsx)
        ]

        for (fileName, format) in cases {
            #expect(throws: ConversionError.unsupportedFormat(format), "Unexpected error for \(fileName)") {
                try MarkItDown().convert(contentsOf: fixtureURL(fileName))
            }
        }
    }

    @Test("throws unsupported for unknown imports")
    func throwsUnsupportedForUnknownImports() throws {
        #expect(throws: ConversionError.unsupportedFormat(.unknown)) {
            try MarkItDown().convert(contentsOf: fixtureURL("unknown.bin"))
        }
    }
}

private func fixtureURL(_ fileName: String) -> URL {
    URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("Tests/Fixtures")
        .appendingPathComponent(fileName)
}

private func blankPNGFixtureData() throws -> Data {
    let base64 = try String(contentsOf: fixtureURL("blank.png.base64"), encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let data = Data(base64Encoded: base64) else {
        throw ConversionError.malformedInput("Blank PNG fixture is not valid base64.")
    }
    return data
}
