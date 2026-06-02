import Foundation
#if canImport(PDFKit)
import PDFKit
#endif

/// Extracts Markdown-ready text from PDF documents using Apple PDFKit when available.
public struct PDFConverter: DocumentConverter {
    public let supportedFormats: Set<DocumentFormat> = [.pdf]

    public init() {}

    public func convert(_ request: ConversionRequest, format: DocumentFormat) throws -> MarkdownDocument {
        #if canImport(PDFKit)
        guard let document = PDFDocument(data: request.data) else {
            throw ConversionError.malformedInput("The input could not be parsed as a PDF document.")
        }

        var extractedPageCount = 0
        let pages = (0..<document.pageCount).map { index in
            let text = document.page(at: index)?.string?.smid_trimmedBlankLines ?? ""
            if !text.isEmpty {
                extractedPageCount += 1
            }
            return text
        }

        let markdown = pages
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
            .smid_trimmedBlankLines

        return MarkdownDocument(
            markdown: markdown,
            sourceFormat: format,
            metadata: [
                "pageCount": String(document.pageCount),
                "extractedTextPageCount": String(extractedPageCount)
            ]
        )
        #else
        throw ConversionError.unsupportedFormat(format)
        #endif
    }
}
