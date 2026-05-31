import Foundation

public struct JSONConverter: DocumentConverter {
    public let supportedFormats: Set<DocumentFormat> = [.json]

    public init() {}

    public func convert(_ request: ConversionRequest, format: DocumentFormat) throws -> MarkdownDocument {
        let object = try JSONSerialization.jsonObject(with: request.data)
        let markdown = render(object, level: 0).smid_trimmedBlankLines
        return MarkdownDocument(markdown: markdown, sourceFormat: .json)
    }

    private func render(_ value: Any, level: Int) -> String {
        switch value {
        case let dictionary as [String: Any]:
            return dictionary.keys.sorted().map { key in
                let child = dictionary[key]!
                if isScalar(child) {
                    return "\(indent(level))- **\(key)**: \(scalar(child))"
                }
                return "\(indent(level))- **\(key)**:\n\(render(child, level: level + 1))"
            }.joined(separator: "\n")
        case let array as [Any]:
            return array.map { child in
                if isScalar(child) {
                    return "\(indent(level))- \(scalar(child))"
                }
                return "\(indent(level))-\n\(render(child, level: level + 1))"
            }.joined(separator: "\n")
        default:
            return "\(indent(level))\(scalar(value))"
        }
    }

    private func isScalar(_ value: Any) -> Bool {
        !(value is [String: Any]) && !(value is [Any])
    }

    private func scalar(_ value: Any) -> String {
        switch value {
        case is NSNull: return "null"
        case let string as String: return string
        case let number as NSNumber: return number.stringValue
        default: return String(describing: value)
        }
    }

    private func indent(_ level: Int) -> String {
        String(repeating: "  ", count: level)
    }
}
