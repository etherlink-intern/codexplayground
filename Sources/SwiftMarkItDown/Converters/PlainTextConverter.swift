import Foundation

public struct PlainTextConverter: DocumentConverter {
    public let supportedFormats: Set<DocumentFormat> = [.plainText, .markdown]

    public init() {}

    public func convert(_ request: ConversionRequest, format: DocumentFormat) throws -> MarkdownDocument {
        let text = try TextDecoding.decode(request.data).smid_trimmedBlankLines
        return MarkdownDocument(markdown: text, sourceFormat: format)
    }
}
