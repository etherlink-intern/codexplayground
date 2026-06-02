import Foundation
import Testing
@testable import SwiftMarkItDown

#if canImport(Vision) && canImport(CoreGraphics) && canImport(CoreText) && canImport(ImageIO)
import CoreGraphics
import CoreText
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


    @Test("throws for reserved but unimplemented formats")
    func throwsForUnimplementedFormats() throws {
        let request = ConversionRequest(data: Data(), fileName: "paper.pdf")
        #expect(throws: ConversionError.unsupportedFormat(.pdf)) {
            try MarkItDown().convert(request)
        }
    }

    #if canImport(Vision) && canImport(CoreGraphics) && canImport(CoreText) && canImport(ImageIO)
    @Test("uses Vision OCR to convert rendered images to Markdown")
    func convertsRenderedImagesWithVisionOCR() throws {
        for sample in try renderedOCRSamples() {
            let request = ConversionRequest(data: sample.data, fileName: sample.fileName)
            let document = try MarkItDown().convert(request)
            let normalized = document.markdown.uppercased()

            #expect(document.sourceFormat == sample.format)
            #expect(normalized.contains("SWIFT"))
            #expect(normalized.contains("OCR"))
            #expect(normalized.contains("MARKDOWN"))
            #expect(document.metadata["recognizedTextLineCount"] != "0")
        }
    }

    @Test("converts text-fixture-backed blank PNG through the image pipeline")
    func convertsTextFixtureBackedBlankPNG() throws {
        let request = ConversionRequest(data: try blankPNGFixtureData(), fileName: "blank.png")
        let document = try MarkItDown().convert(request)
        #expect(document.sourceFormat == .png)
        #expect(document.markdown == "")
        #expect(document.metadata["recognizedTextLineCount"] == "0")
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

#if canImport(Vision) && canImport(CoreGraphics) && canImport(CoreText) && canImport(ImageIO)
private struct OCRSample {
    let fileName: String
    let format: DocumentFormat
    let data: Data
}

private func renderedOCRSamples() throws -> [OCRSample] {
    [
        OCRSample(fileName: "ocr-sample.png", format: .png, data: try renderOCRImage(typeIdentifier: "public.png" as CFString)),
        OCRSample(fileName: "ocr-sample.jpg", format: .jpeg, data: try renderOCRImage(typeIdentifier: "public.jpeg" as CFString))
    ]
}

private func renderOCRImage(typeIdentifier: CFString) throws -> Data {
    let width = 1_200
    let height = 520
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw ConversionError.malformedInput("Could not create OCR test image context.")
    }

    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, 112, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    ]

    for (index, line) in ["SWIFT OCR", "MARKDOWN"].enumerated() {
        let attributed = NSAttributedString(string: line, attributes: attributes)
        let textLine = CTLineCreateWithAttributedString(attributed)
        context.textPosition = CGPoint(x: 80, y: height - 170 - (index * 150))
        CTLineDraw(textLine, context)
    }

    guard let image = context.makeImage() else {
        throw ConversionError.malformedInput("Could not render OCR test image.")
    }

    let output = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(output, typeIdentifier, 1, nil) else {
        throw ConversionError.malformedInput("Could not create OCR test image destination.")
    }

    let options = [kCGImageDestinationLossyCompressionQuality as String: 0.95] as CFDictionary
    CGImageDestinationAddImage(destination, image, options)
    guard CGImageDestinationFinalize(destination) else {
        throw ConversionError.malformedInput("Could not encode OCR test image.")
    }

    return output as Data
}

#endif
