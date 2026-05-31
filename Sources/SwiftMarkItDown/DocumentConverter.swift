import Foundation

/// A focused converter for one or more source formats.
public protocol DocumentConverter: Sendable {
    var supportedFormats: Set<DocumentFormat> { get }
    func convert(_ request: ConversionRequest, format: DocumentFormat) throws -> MarkdownDocument
}

public enum ConversionError: Error, Equatable, LocalizedError, Sendable {
    case unsupportedFormat(DocumentFormat)
    case unreadableTextEncoding
    case malformedInput(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            "No converter is registered for \(format.rawValue)."
        case .unreadableTextEncoding:
            "The input could not be decoded as text."
        case .malformedInput(let message):
            message
        }
    }
}
