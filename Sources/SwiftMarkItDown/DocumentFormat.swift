import Foundation

/// File families the native pipeline understands today or has reserved extension points for.
public enum DocumentFormat: String, CaseIterable, Sendable {
    case plainText = "txt"
    case markdown = "md"
    case html = "html"
    case csv = "csv"
    case json = "json"
    case png = "png"
    case jpeg = "jpg"
    case heic = "heic"
    case tiff = "tiff"
    case gif = "gif"
    case pdf = "pdf"
    case docx = "docx"
    case pptx = "pptx"
    case xlsx = "xlsx"
    case unknown

    public static func infer(fileName: String?, contentType: String?) -> DocumentFormat {
        if let contentType {
            let normalized = contentType.lowercased().split(separator: ";", maxSplits: 1).first.map(String.init) ?? contentType
            if let format = format(forContentType: normalized) {
                return format
            }
        }

        guard let fileName else { return .unknown }
        let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        switch ext {
        case "txt", "text": return .plainText
        case "md", "markdown": return .markdown
        case "htm", "html": return .html
        case "csv": return .csv
        case "json": return .json
        case "png": return .png
        case "jpg", "jpeg": return .jpeg
        case "heic", "heif": return .heic
        case "tif", "tiff": return .tiff
        case "gif": return .gif
        case "pdf": return .pdf
        case "docx": return .docx
        case "pptx": return .pptx
        case "xlsx": return .xlsx
        default: return .unknown
        }
    }

    private static func format(forContentType contentType: String) -> DocumentFormat? {
        switch contentType {
        case "text/plain": .plainText
        case "text/markdown", "text/x-markdown": .markdown
        case "text/html", "application/xhtml+xml": .html
        case "text/csv", "application/csv": .csv
        case "application/json", "text/json": .json
        case "image/png": .png
        case "image/jpeg", "image/jpg": .jpeg
        case "image/heic", "image/heif": .heic
        case "image/tiff": .tiff
        case "image/gif": .gif
        case "application/pdf": .pdf
        case "application/vnd.openxmlformats-officedocument.wordprocessingml.document": .docx
        case "application/vnd.openxmlformats-officedocument.presentationml.presentation": .pptx
        case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": .xlsx
        default: nil
        }
    }
}

public extension DocumentFormat {
    static let imageFormats: Set<DocumentFormat> = [.png, .jpeg, .heic, .tiff, .gif]
}
