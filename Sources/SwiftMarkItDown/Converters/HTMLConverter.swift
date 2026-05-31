import Foundation

public struct HTMLConverter: DocumentConverter {
    public let supportedFormats: Set<DocumentFormat> = [.html]

    public init() {}

    public func convert(_ request: ConversionRequest, format: DocumentFormat) throws -> MarkdownDocument {
        var html = try TextDecoding.decode(request.data)
        html = html.replacingOccurrences(of: "\r\n", with: "\n")

        let rules: [(String, String)] = [
            ("(?is)<head\\b[^>]*>.*?</head>", ""),
            ("(?is)<script\\b[^>]*>.*?</script>", ""),
            ("(?is)<style\\b[^>]*>.*?</style>", ""),
            ("(?is)<h1\\b[^>]*>(.*?)</h1>", "\n# $1\n"),
            ("(?is)<h2\\b[^>]*>(.*?)</h2>", "\n## $1\n"),
            ("(?is)<h3\\b[^>]*>(.*?)</h3>", "\n### $1\n"),
            ("(?is)<h4\\b[^>]*>(.*?)</h4>", "\n#### $1\n"),
            ("(?is)<h5\\b[^>]*>(.*?)</h5>", "\n##### $1\n"),
            ("(?is)<h6\\b[^>]*>(.*?)</h6>", "\n###### $1\n"),
            ("(?is)<(strong|b)\\b[^>]*>(.*?)</\\1>", "**$2**"),
            ("(?is)<(em|i)\\b[^>]*>(.*?)</\\1>", "*$2*"),
            ("(?is)<code\\b[^>]*>(.*?)</code>", "`$1`"),
            ("(?is)<a\\b[^>]*href=[\"']([^\"']+)[\"'][^>]*>(.*?)</a>", "[$2]($1)"),
            ("(?is)<li\\b[^>]*>(.*?)</li>", "\n- $1"),
            ("(?is)<br\\s*/?>", "\n"),
            ("(?is)</p>", "\n\n"),
            ("(?is)<[^>]+>", "")
        ]

        for (pattern, replacement) in rules {
            html = html.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }

        let markdown = html
            .smid_decodingHTMLEntities()
            .replacingOccurrences(of: "[ \t]+\n", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .smid_trimmedBlankLines

        return MarkdownDocument(markdown: markdown, sourceFormat: .html)
    }
}

private extension String {
    func smid_decodingHTMLEntities() -> String {
        var output = self
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&nbsp;": " "
        ]
        for (entity, value) in entities {
            output = output.replacingOccurrences(of: entity, with: value)
        }
        return output
    }
}
