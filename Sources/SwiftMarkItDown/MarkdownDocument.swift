import Foundation

/// Result of a successful conversion.
public struct MarkdownDocument: Equatable, Sendable {
    public let markdown: String
    public let sourceFormat: DocumentFormat
    public let metadata: [String: String]

    public init(
        markdown: String,
        sourceFormat: DocumentFormat,
        metadata: [String: String] = [:]
    ) {
        self.markdown = markdown
        self.sourceFormat = sourceFormat
        self.metadata = metadata
    }
}
