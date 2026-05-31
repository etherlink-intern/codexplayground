import Foundation

/// Native Swift conversion orchestrator inspired by Microsoft MarkItDown.
public struct MarkItDown: Sendable {
    private let converters: [any DocumentConverter]

    public init(converters: [any DocumentConverter] = MarkItDown.defaultConverters) {
        self.converters = converters
    }

    public static var defaultConverters: [any DocumentConverter] {
        [
            PlainTextConverter(),
            HTMLConverter(),
            CSVConverter(),
            JSONConverter()
        ]
    }

    public func convert(_ request: ConversionRequest) throws -> MarkdownDocument {
        let format = request.formatHint ?? DocumentFormat.infer(
            fileName: request.fileName,
            contentType: request.contentType
        )

        guard let converter = converters.first(where: { $0.supportedFormats.contains(format) }) else {
            throw ConversionError.unsupportedFormat(format)
        }

        return try converter.convert(request, format: format)
    }

    public func convert(contentsOf url: URL, contentType: String? = nil) throws -> MarkdownDocument {
        let data = try Data(contentsOf: url)
        return try convert(ConversionRequest(data: data, fileName: url.lastPathComponent, contentType: contentType))
    }
}
