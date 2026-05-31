import Foundation

public struct CSVConverter: DocumentConverter {
    public let supportedFormats: Set<DocumentFormat> = [.csv]

    public init() {}

    public func convert(_ request: ConversionRequest, format: DocumentFormat) throws -> MarkdownDocument {
        let text = try TextDecoding.decode(request.data)
        let rows = try CSVParser.parse(text)
        guard !rows.isEmpty else {
            return MarkdownDocument(markdown: "", sourceFormat: .csv)
        }

        let columnCount = rows.map(\.count).max() ?? 0
        let normalized = rows.map { row in row + Array(repeating: "", count: max(0, columnCount - row.count)) }
        let header = normalized[0]
        let body = normalized.dropFirst()

        var lines: [String] = []
        lines.append(markdownRow(header, columnCount: columnCount))
        lines.append(markdownRow(Array(repeating: "---", count: columnCount), columnCount: columnCount))
        lines.append(contentsOf: body.map { markdownRow($0, columnCount: columnCount) })

        return MarkdownDocument(markdown: lines.joined(separator: "\n"), sourceFormat: .csv)
    }

    private func markdownRow(_ row: [String], columnCount: Int) -> String {
        let cells = (0..<columnCount).map { index in
            row[index]
                .replacingOccurrences(of: "|", with: "\\|")
                .replacingOccurrences(of: "\n", with: "<br>")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "| " + cells.joined(separator: " | ") + " |"
    }
}

enum CSVParser {
    static func parse(_ text: String) throws -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        var index = text.startIndex

        while index < text.endIndex {
            let char = text[index]
            let next = text.index(after: index)

            if char == "\"" {
                if isQuoted, next < text.endIndex, text[next] == "\"" {
                    field.append("\"")
                    index = text.index(after: next)
                    continue
                }
                isQuoted.toggle()
            } else if char == ",", !isQuoted {
                row.append(field)
                field = ""
            } else if (char == "\n" || char == "\r"), !isQuoted {
                row.append(field)
                field = ""
                if !row.allSatisfy({ $0.isEmpty }) {
                    rows.append(row)
                }
                row = []
                if char == "\r", next < text.endIndex, text[next] == "\n" {
                    index = text.index(after: next)
                    continue
                }
            } else {
                field.append(char)
            }
            index = next
        }

        if isQuoted {
            throw ConversionError.malformedInput("CSV contains an unterminated quoted field.")
        }

        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            if !row.allSatisfy({ $0.isEmpty }) {
                rows.append(row)
            }
        }

        return rows
    }
}
