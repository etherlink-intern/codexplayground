import Foundation

/// Input payload and optional metadata for a document-to-Markdown conversion.
public struct ConversionRequest: Sendable {
    public let data: Data
    public let fileName: String?
    public let contentType: String?
    public let formatHint: DocumentFormat?

    public init(
        data: Data,
        fileName: String? = nil,
        contentType: String? = nil,
        formatHint: DocumentFormat? = nil
    ) {
        self.data = data
        self.fileName = fileName
        self.contentType = contentType
        self.formatHint = formatHint
    }
}
