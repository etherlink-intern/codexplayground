import Foundation

#if canImport(Vision) && canImport(CoreGraphics) && canImport(ImageIO)
import CoreGraphics
import ImageIO
import Vision
#endif

/// Uses Apple Vision text recognition to extract Markdown-ready text from images.
public struct ImageOCRConverter: DocumentConverter {
    public let supportedFormats: Set<DocumentFormat> = DocumentFormat.imageFormats

    public init() {}

    public func convert(_ request: ConversionRequest, format: DocumentFormat) throws -> MarkdownDocument {
        #if canImport(Vision) && canImport(CoreGraphics) && canImport(ImageIO)
        guard let imageSource = CGImageSourceCreateWithData(request.data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ConversionError.malformedInput("The input could not be decoded as an image.")
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.minimumTextHeight = 0.01

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        let lines = (request.results ?? [])
            .compactMap { observation -> RecognizedTextLine? in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return nil }
                return RecognizedTextLine(text: text, bounds: observation.boundingBox, confidence: candidate.confidence)
            }
            .sorted { lhs, rhs in
                let verticalDelta = abs(lhs.bounds.midY - rhs.bounds.midY)
                if verticalDelta > 0.02 {
                    return lhs.bounds.midY > rhs.bounds.midY
                }
                return lhs.bounds.minX < rhs.bounds.minX
            }

        let markdown = lines.map(\.text).joined(separator: "\n").smid_trimmedBlankLines
        return MarkdownDocument(
            markdown: markdown,
            sourceFormat: format,
            metadata: ["recognizedTextLineCount": String(lines.count)]
        )
        #else
        throw ConversionError.unsupportedFormat(format)
        #endif
    }
}

#if canImport(Vision) && canImport(CoreGraphics) && canImport(ImageIO)
private struct RecognizedTextLine {
    let text: String
    let bounds: CGRect
    let confidence: VNConfidence
}
#endif
